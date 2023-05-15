A guide to test parametrization in Rust
=======================================

<time id=post-date>2023-05-09</time>

Sometimes you want to run the same test with a set of different inputs. In Python, it would look like this:

```{.sourceCode .python}
@pytest.mark.parametrize("value", [1, 2, 3])
def test_add(value):
    assert value + value == 2 * value
```

[pytest](https://docs.pytest.org/) will cleanly separate test failures from each other, print stdout/stderr scrollback for each test, and all the good things that test frameworks are supposed to do.

Sometimes you want to run the same test repeatedly based on a folder of test files. A really low-linecount approach to that in Python would be this:

```{.sourceCode .python}
@pytest.mark.parametrize("input_filename", os.listdir("./testcases/"))
def test_add(input_filename):
    with open(input_filename) as f:
        value = json.load(input_filename)

    assert value + value == 2 * value
```

Putting your testcases into pure data files has the distinct advantage that you can reuse those testcases across languages, and since your testcases are now machine-readable data instead of arbitrary code, they can be mass-refactored more easily.

But how would that look like in Rust?

Basically, you have two choices to parametrize tests in Rust:

- Code generation
- Custom test harness

They’re both not great.

## Code generation

We have a solution for metaprogramming in Rust. It’s called macros. Here’s how the first Python code snippet would look like in Rust:

```{.sourceCode .rust}
macro_rules! make_testcase_add {
    ($value:expr, $testname:ident) => {
        #[test]
        fn $testname() {
            let value = $value;
            assert_eq!(value + value, 2 * value);
        }
    }
}

make_testcase_add!(1, test_add_1);
make_testcase_add!(2, test_add_2);
make_testcase_add!(3, test_add_3);
```

There are many crates, such as [rstest](https://docs.rs/rstest/latest/rstest/), [test-case](https://docs.rs/test-case/latest/test_case/), [test-generator](https://docs.rs/test-generator/latest/test_generator/), or [datatest](https://docs.rs/test-case/latest/test_case/) that take off some of the boilerplate for you. You can find them by searching for "test parametrization" or "data-driven tests" on [crates.io](http://crates.io/). Some of these crates are designed for specific use cases, assuming that one file equals one test case.

For simple cases of programmatic test generation, code generation is very easy to integrate into existing testsuites.

For more advanced usecases such as parametrizing a function by two dimensions [^1], or producing a number of testcases based on a single file, I found that those macros compose poorly both with each other and any macros you might write, and sometimes impose themselves as “test frameworks” on your entire testsuite (rather than a few tests). The function coloring problem, but relived with macros.

To overcome this while still using codegen, you can use procedural macros. These have compile-time overhead and must be written in a separate crate, even for simple logic in generating test cases.

With increasing number of testcases, compilation times become a problem regardless. Each testcase is a function to compile, making it difficult to include community-maintained testsuites like [html5lib-tests](https://github.com/html5lib/html5lib-tests) which have 20k test cases. Guess how well rustc performs on a file with linecount being a multiple of 20k? There are some things you can potentially optimize here, such as “sharding” your testcases into multiple `mod { }` blocks. But I haven’t tried that.

## Just throw away the whole test framework

Cargo allows you to replace the entire test harness with your own. You do that by adding something like this to `Cargo.toml`

```{.sourceCode .toml}
[[test]]
name = "integration"
path = "integration/main.rs"
harness = false
```

Now `integration/main.rs` is just another program with a `main()` function which will be run as part of `cargo test`. This is great because it allows you to use arbitrary Rust code to generate your testcases, not some weird, limited macro-based meta-language.

You are however now also responsible for:

- Terminal output (indicating progress of your testsuite, suppressing stdout)
- Handling of panics in your tests (if there is a panic, it will just crash the test runner unless you handle it)
- supporting all the CLI arguments on `cargo test` for filtering and listing tests

You can reimplement all of that, but it would be really annoying to do so. The servo people have concluded the same thing, and forked Rust’s nightly-only `test` crate, [and put it on crates.io](https://crates.io/crates/rustc-test).

Now the implication is that, should Rust ever evolve its test harness (for example to add new CLI arguments), servo’s tests will still run with the old harness.

To further complicate things, alternative test CLIs like [nextest](https://github.com/nextest-rs/nextest) effectively assume the default test harness. In order to support custom ones, nextest had to come up with [an ad-hoc specification](https://nexte.st/book/custom-test-harnesses.html) as to which CLI arguments need to be supported in order to be able to run nextest over test targets with custom harnesses.

It’s not just nextest that breaks that way. [insta](https://insta.rs/), a snapshot-testing library, needs special attention when using it with custom test harnesses, as it employs some contrived hacks to figure out the current test’s name. Apparently [insta also comes with its own way to do data-driven tests](https://insta.rs/docs/advanced/#globbing). Which is, again, just another macro that composes with nothing else. Speaking of composability, insta has its own test runner CLI called `cargo insta test`. It shells out to `cargo test`, which in turn shells out to test targets.

Anyway, the best off-the-shelf (but not default) test harness people seem to use is [libtest-mimic](https://github.com/LukasKalbertodt/libtest-mimic). It is relatively easy to write custom test generators on top of it, mostly looks and feels like the default test harness included in Rust, and appears to be compatible with nextest according to nextest’s documentation.

libtest-mimic, or any custom test harness for that matter, [cannot intercept stdout](https://github.com/LukasKalbertodt/libtest-mimic/issues/9), meaning that printf debugging is now slightly less convenient. All because you wanted to parametrize some tests.

## Conclusion

If you come here from Google, your best shot at this problem is either regular macros or libtest-mimic. But it’s not a satisfying answer.

I want to programmatically generate testcases in Rust in a way that is as low-boilerplate as the Python equivalent. I want to write a one-liner of Rust code that generates a collection of test items, and I want that neither to be an entirely new API and language separate from how one would normally write tests, nor do I want it to arbitrarily slow down compiletimes because obscene amounts of generated code are involved.

I made a rough sketch of what the surface-level experience would look like by releasing [script-macro](https://github.com/untitaker/script-macro), but while RHAI is a pretty nice scripting language, it is not normal Rust code, and now you have a significant amount of complexity on top of all the problems coming with the code generation approach. In going down that particular prototyping rabbithole I also found [inline-proc](https://github.com/SabrinaJewson/inline-proc.rs), which is a proc macro shelling out to cargo.

## Addendum

* <time>2023-05-15</time> Several peope have pointed out that an easy way to
  solve test parametrization is to execute all tests within a single test item
  as such:

  ```{.sourceCode .rust}
  #[test]
  fn test_add() {
      for value in [1, 2, 3] {
          assert_eq!(value + value, 2 * value);
      }
  }
  ```

  This works, and is a very popular approach to running multiple tests, but now
  your "subtests" are not a first-class test item, which comes with some
  disadvantages (bad CLI ergonomics, bad debuggability). So to me this is
  probably the most viable approach right now, but also really a non-solution
  to the problem.

[^1]: For example, a list of `n` files and `m` possible configuration profiles,
  effectively running the test function `n * m` times.
