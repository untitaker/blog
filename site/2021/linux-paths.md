Relative paths are faster than absolute paths on Linux (and other jokes I tell myself)
======================================================================================

<time id=post-date>2021-10-04</time>

Has this ever happened to you?

``` {.sourceCode .bash}
$ pwd
/tmp/bar
$ git status
fatal: Unable to read current working directory: No such file or directory
```

This happens when one deletes some temporary directory from one
terminal, then uses another terminal where it is still the current
working directory.

What if we simply recreate `/tmp/bar`?

``` {.sourceCode .bash}
$ git init $(pwd)
$ git status
fatal: Unable to read current working directory: No such file or directory
```

Still doesn't work. However, `cd`-ing into the directory that we already
are fixes it:

``` {.sourceCode .bash}
$ cd $(pwd)
$ git status
On branch master

No commits yet

nothing to commit (create/copy files and use "git add" to track)
```

This is not a `git`-problem, by the way. Opening `vim` or other programs
in a directory that somebody else deleted will throw similar errors.

But why does `cd $(pwd)` fix it?

How the current working directory is stored
-------------------------------------------

The current working directory (cwd or pwd) is not a shell concept, but
something Linux stores for every process. Your shell is a process with a
cwd, and when you launch other processes from that shell, they inherit
the cwd. You can use `pwdx` to check the cwd of a running process:

``` {.sourceCode .bash}
$ pwdx $(pidof vim)
230789: /tmp/bar
```

We've got the process ID and the path there. You might think that Linux
just stores that path as a string for every process. However, that can't
be true. Otherwise we would not have to use `cd $(pwd)` to "fix up" our
shell's cwd after deleting and re-creating a folder! So how is the cwd
really represented? Does it point to an
[inode](https://en.wikipedia.org/wiki/Inode), maybe?

Thanks to Linux being open-source we can find out for ourselves by
reading Linux's sourcecode. Thanks to [this StackOverflow
answer](https://stackoverflow.com/a/3781614/1544347) we don't have to
read as much.

The answer says a process's cwd is stored in
[fs\_struct](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/linux/fs_struct.h?id=HEAD):

``` {.sourceCode .c}
struct fs_struct {
    int users;
    spinlock_t lock;
    seqcount_spinlock_t seq;
    int umask;
    int in_exec;
    struct path root, pwd;
} __randomize_layout;
```

So our cwd is stored as `struct path`. That struct is defined in
[path.h](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/linux/path.h?id=HEAD):

``` {.sourceCode .c}
struct path {
    struct vfsmount *mnt;
    struct dentry *dentry;
} __randomize_layout;
```

Searching for `dentry` leads us to
[dcache.h](https://git.kernel.org/pub/scm/linux/kernel/git/torvalds/linux.git/tree/include/linux/dcache.h?id=HEAD):

``` {.sourceCode .c}
struct dentry {
    /* RCU lookup touched fields */
    unsigned int d_flags;       /* protected by d_lock */
    seqcount_spinlock_t d_seq;  /* per dentry seqlock */
    struct hlist_bl_node d_hash;    /* lookup hash list */
    struct dentry *d_parent;    /* parent directory */
    struct qstr d_name;
    struct inode *d_inode;      /* Where the name belongs to - NULL is
                     * negative */
    unsigned char d_iname[DNAME_INLINE_LEN];    /* small names */

    /* Ref lookup also touches following */
    struct lockref d_lockref;   /* per-dentry lock and refcount */
    const struct dentry_operations *d_op;
    struct super_block *d_sb;   /* The root of the dentry tree */
    unsigned long d_time;       /* used by d_revalidate */
    void *d_fsdata;         /* fs-specific data */

    union {
        struct list_head d_lru;     /* LRU list */
        wait_queue_head_t *d_wait;  /* in-lookup ones only */
    };
    struct list_head d_child;   /* child of parent list */
    struct list_head d_subdirs; /* our children */
    /*
     * d_alias and d_rcu can share memory
     */
    union {
        struct hlist_node d_alias;  /* inode alias list */
        struct hlist_bl_node d_in_lookup_hash;  /* only for in-lookup ones */
        struct rcu_head d_rcu;
    } d_u;
} __randomize_layout;
```

I know that Linux has an in-memory filesystem cache but I don't
understand this struct. However, the mention of inodes in `d_inode` sort
of explains why we need to run `cd $(pwd)`. By recreating the directory
`/tmp/bar`, it will point to a new inode, and doing `cd $(pwd)` will
update our path struct to point to the right `dentry` (or update our
`dentry` to point to the correct inode, not sure.)

Detour: Deeply nested paths
---------------------------

Okay, mystery kind of solved, now let's explore a different question:
**What's the maximum path depth I can have on Linux?**

The answer is: [There is no
limit.](https://unix.stackexchange.com/a/596656/31598) There's a limit
on the path lenghts that you can pass to syscalls. What does that mean
in practice?

If we create a deeply nested directory tree using this simple Rust
program:

``` {.sourceCode .rust}
use std::fs;
use std::env;

fn main() {
    for _ in 0..100_000 {
        let _ = fs::create_dir("a");
        env::set_current_dir("a").unwrap();
    }
    Ok(())
}
```

...then try to `rm` it, everything is fine.

``` {.sourceCode .bash}
$ target/release/verydeep
$ rm -r ./a
```

What if we recreate the directory and run `ripgrep` on it?

``` {.sourceCode .bash}
$ rg --files ./a
a/a/a/a/[...]: File name too long (os error 36)
```

What is `ripgrep` doing that is causing problems here? Probably a
syscall. We can inspect syscalls using `strace`.

The output is really messy. What I did to narrow it down was to search
for `ENAMETOOLONG`, which according to a Google search for "linux os
error 36" is the human-readable version of `os error 36`.

``` {.sourceCode .bash}
$ strace rg -j1 --files ./a
[...]
openat(AT_FDCWD, "./a/a/[...]/a/a/a"..., O_RDONLY|O_NONBLOCK|O_CLOEXEC|O_DIRECTORY) = -1 ENAMETOOLONG (File name too long)
[...]
```

That string passed to `openat()` is extremely long. So `ripgrep`
constructs too large paths for `open()` to handle. But what does `rm` do
to not run into this problem?

Here's a theory: `rm` changes directories using `chdir("./a")` to
traverse to the innermost directory, calls `rmdir("./a")` or equivalent,
calls `chdir("..")`, removes the directory it just stepped out of and
repeats. This avoids creating very large strings in memory that can't be
passed to any system calls.

In fact this is exactly how it used to work until [rm was rewritten to
use different system calls that avoid changing the current working
directory.](https://github.com/coreutils/coreutils/commit/b8616748f232f6e75dc330cee25069f45f1c6a21)
But how does it work today?

How `rm` traverses directories using entirely too many filedescriptors
----------------------------------------------------------------------

Another round of `strace`. Here's the output towards the end:

``` {.sourceCode .bash}
$ strace rm -r ./a
[...]
newfstatat(3, "a", {st_mode=S_IFDIR|0775, st_size=4096, ...}, AT_SYMLINK_NOFOLLOW) = 0
faccessat(3, "a", W_OK)                 = 0
unlinkat(3, "a", AT_REMOVEDIR)          = 0
openat(3, "..", O_RDONLY|O_NOCTTY|O_NONBLOCK|O_NOFOLLOW|O_CLOEXEC|O_DIRECTORY) = 4
fstat(4, {st_mode=S_IFDIR|0775, st_size=4096, ...}) = 0
close(3)                                = 0
newfstatat(4, "a", {st_mode=S_IFDIR|0775, st_size=4096, ...}, AT_SYMLINK_NOFOLLOW) = 0
faccessat(4, "a", W_OK)                 = 0
unlinkat(4, "a", AT_REMOVEDIR)          = 0
close(4)                                = 0
newfstatat(AT_FDCWD, "./a", {st_mode=S_IFDIR|0775, st_size=4096, ...}, AT_SYMLINK_NOFOLLOW) = 0
faccessat(AT_FDCWD, "./a", W_OK)        = 0
unlinkat(AT_FDCWD, "./a", AT_REMOVEDIR) = 0
[...]
```

I believe what happens is:

1.  `rm` opens a file descriptor for `./a` (let's pretend that this fd
    is `3`)
2.  ...then opens a file descriptor for `./a/a` using the *first* file
    descriptor: `openat(3, "./a")`.
3.  ...and repeats that process until it arrives at the parent directory
    that contains innermost directory (let's pretend that this fd is
    `99`)
4.  ...then deletes that directory using `unlinkat(99, "./a")`
5.  ...then uses `openat(99, "..")` to traverse back out of the tree
    (giving us fd `98`)
6.  ...then deletes *that* directory using `unlink(98, "./a")`.
7.  ...and so on until it arrives back at the directory it was executed
    from.

The sourcecode (linked above) that introduces this calls it a "virtual
chdir".

Putting it all together
-----------------------

Originally I was wondering whether it's possible to traverse large
directory trees in Rust without:

1.  ...allocating so many `PathBuf` objects. Those are basically strings
    containing absolute paths.
    [walkdir](https://github.com/BurntSushi/walkdir) and similar crates
    appear to construct those for every directory entry at every level.
2.  making the filesystem look up every subpath starting from the root.
    Most filesystems store one table per directory. When one calls
    `open()` with an absolute path `/a/b/c/d/...`, containing `n` path
    segments, ext4 needs to "chase pointers", i.e. look up the first
    path segment `a` in one table, which leads to another table where it
    looks up `b`. So resolving a path to an inode is `O(n)` over number
    of path segments. [And only ext4 made those tables
    hashtables](https://ext4.wiki.kernel.org/index.php/Ext4_Disk_Layout#Hash_Tree_Directories),
    so the running time may have been worse in practice.

Turns out both is achievable: GNU `rm` does it all, in both versions.

1.  `rm` only allocates path segments, in both versions.
2.  `rm` either keeps a file descriptor open to directly point to an
    inode (after the `openat()` rewrite in 2005), or changes its own
    directory (before the rewrite). At the beginning of this blogpost
    we've observed that the current working directory points directly to
    an inode.

The `openat()` solution is probably the way to go. After all
`chdir()`-based directory walking mutates process-global state and can't
be parallelized.

What speaks against either solution is:

-   the *potential* amount of extra syscalls and open file descriptors.
    If you only want to keep one file descriptor open, then walking out
    of the tree takes as many syscalls as walking into it does.
-   If you want to avoid *that*, then you need to keep more file
    descriptors from parent directories open. In addition, printing the
    current path while walking is now harder too.
-   If you want to parallelize tree traversal, managing open file
    descriptors may become too annoying. I can imagine that reference
    counting (`Arc<MyFd>`) or using `dup(2)` will be "good enough", but
    either way there's increased risk in opening too many fds at once.

`ripgrep` is not the only tool that will fail on very deep directory
trees, most programs will. The author may have considered to implement
directory traversal this way already, and may have chosen not to do it
because of the mentioned problems.
