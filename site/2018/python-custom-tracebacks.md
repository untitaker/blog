How to create a traceback object in Python
==========================================

<time id=post-date>2018-07-19</time>

I\'ve been writing [a library for errorhandling when calling Rust code
from Python](https://github.com/untitaker/shippai). One peculiar
challenge I faced was when I wanted to have stacktraces that look like
this:

    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "/home/untitaker/projects/shippai/examples/python/shippai_example/__init__.py", line 17, in authenticate
        errors.check_exception(err[0])
      File "/home/untitaker/projects/shippai/python/shippai/__init__.py", line 110, in check_exception
        _raise_with_more_frames(exc, frames)
      File "/home/untitaker/projects/shippai/python/shippai/__init__.py", line 228, in _raise_with_more_frames
        func()
      File "/home/untitaker/projects/shippai/examples/python/rust/c/_cffi_backend.c", line 3025, in cdata_call
      File "/home/untitaker/projects/shippai/examples/python/rust/../src/x86/ffi64.c", line 525, in ffi_call
      File "/home/untitaker/projects/shippai/examples/python/rust/src/lib.rs", line 43, in authenticate
        let res = authenticate_impl(
      File "/home/untitaker/projects/shippai/examples/python/rust/src/lib.rs", line 27, in shippai_example__authenticate_impl__h040a48b77826a8f4
        return Err(MyError::UserWrong.into());
    [...]
    shippai.UserWrong: Invalid username

So when we call some Rust code from Python, and the Rust code fails, we
get this merged traceback with the Rust frames stitched onto it. To me
personally this kind of error reporting is very appealing. If you think
this is too much magic, you will not like what comes next. We\'ll
explore how to do exactly that, how to add extra frames to a traceback
object.

The Jinja templating engine has the same problem and its author Armin
[solved it extremely
thoroughly](https://github.com/pallets/jinja/blob/fb7e12cce67b9849899f934e697f7e2a91d604c2/jinja2/debug.py).
This article is about a simpler version, and documents some known flaws.
If you attempt to properly fix those, you\'ll probably end up with code
similar to Jinja\'s. But there\'s a chance you\'ll be able to work
around them in a simpler way that just fits your usecase.

Tracebacks in Python are just objects. Unfortunately creating them is
not directly possible:

    >>> try:
    ...     1/0
    ... except:
    ...     import sys
    ...     tb = sys.exc_info()[-1]
    ...
    >>> cls = type(tb)
    >>> cls()
    TypeError: cannot create 'traceback' instances

However, `tb` is already a traceback object. Printing its frames shows
it\'s not quite where we want it yet:

    >>> import traceback
    >>> traceback.print_tb(tb)
    File "<stdin>", line 2, in <module>

Let\'s say we want to append the frame
`File "foo.rs", line 3, in foofun`. We can do it like this:

    >>> filename = 'foo.rs'
    >>> location = 'foofun'
    >>> linenumber = 3
    >>> code = compile('{}def {}(): 1/0'.format('\n' * (linenumber - 1), location), filename, 'exec')
    >>> namespace = {}
    >>> exec(code, namespace)
    >>> foofun = namespace['foofun']
    >>> foofun()
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "foo.rs", line 3, in foofun
    ZeroDivisionError: division by zero

The last frame now has a non-Python filename and linenumber like we
wanted. How to append more frames? By `eval`-ing more code:

    >>> filename = 'bar.rs'
    >>> location = 'barfun'
    >>> linenumber = 4
    >>> code = compile('{}def {}(): foofun()'.format('\n' * (linenumber - 1), location), filename, 'exec')
    >>> namespace = {'foofun': foofun}
    >>> exec(code, namespace)
    >>> barfun = namespace['barfun']
    >>> barfun()
    Traceback (most recent call last):
      File "<stdin>", line 1, in <module>
      File "foo.rs", line 3, in foofun
      File "bar.rs", line 4, in barfun
    ZeroDivisionError: division by zero

Using this technique you can already construct arbitrary tracebacks:

1.  Create one codeobject (or function) that raises the exception.
2.  For each frame, create a new codeobject (or function) that calls the
    previous one.

This code has a few problems:

-   `location` must be a valid Python identifier. You cannot use a
    location with whitespace or special chars in it, or use a reserved
    keyword. Shippai contains some ugly sanitization logic for this,
    which is not even correct in the general case.
-   A user stepping through our artificial frames with `pdb` will be
    able to access our defined helper functions, call them again etc.
    This might be something you can live with.
-   I\'m sure it has many more.

That\'s it for now. I\'ll eventually write a follow-up to this blogpost
where we explore fixes for both problems. It will probably involve
creating our own code objects, like Jinja does.
