Using type hints in Python 2 libraries
======================================

.. raw:: html

    <time>2019-06-25</time>

With `PEP 484`_ Python allows you to annotate variables and functions with
their types::

    from typing import Iterable
    
    def stringify_list(xs: Iterable[int]) -> Iterable[str]:
        return [str(x) for x in xs]

.. _`PEP 484`: https://www.python.org/dev/peps/pep-0484/

Why is this useful?

- You can use mypy_ to lint your code against mismatching types.
- PyCharm_ supports those type annotations.

.. _mypy: http://mypy-lang.org/
.. _PyCharm: https://www.jetbrains.com/pycharm/ 

For application developers this is a great story. The ``typing`` module is part
of Python 3's standard library, and for Python 2 `a PyPI package <https://pypi.org/project/typing/>`_ exists.
They don't care about the extra dependency because their app has already too
many. Or they port their app to Python 3 first.

What about libraries? At Sentry_ we recently added type hints to our `SDK for
Python`_. The motivation was to give IDE users nicer autocompletion and find a
few bugs in our own code.

.. _Sentry: https://sentry.io
.. _`SDK for Python`: https://sentry.io/for/python/

We defined two requirements. They apply to a lot of libraries that support
Python 2:

* **No new install dependencies, no new runtime dependencies.** Sure, `pip is
  good now`_, but the majority of our users don't use type hints and
  won't see the value of having to install ``typing``.  We have users who
  forked our SDK to remove all dependencies because of their constrained legacy
  environment. This would become a harder job if every file imported types
  from ``typing``.

* **As little runtime cost as possible.** Importing ``typing`` is runtime cost,
  defining types is runtime cost. There's no reason for any of that to happen
  when using our library outside of development.

.. _`pip is good now`: https://glyph.twistedmatrix.com/2016/08/python-packaging.html


This blogpost is about the decisions we made within those requirements. We had
two options: Stub files and type hint comments.

Stub files 
----------

`Stub files`_ are a way to annotate regular Python 2-compatible code in Python
3 syntax. For each ``.py`` file one would have a ``.pyi`` file that contains
function and type definitions in Python 3 syntax, but with empty function
bodies.

This satisfies our requirements because all imports from ``typing`` would only
live in the ``.pyi`` files, which are not used at runtime.

.. _`Stub files`: https://mypy.readthedocs.io/en/latest/stubs.html#stub-files

Stub files seem to overwrite what mypy would've otherwise found out about
the real code::

    # File: test.py
    def stringify_list(xs, random_new_parameter):
        return [str(x) for x in xs]

    # File: test.pyi
    from typing import Iterable

    def stringify_list(xs: Iterable[int]) -> Iterable[str]:
        return [str(x) for x in xs]

Even though we added a new argument to ``stringify_list``, mypy still accepts
this code because it thinks the function takes one argument. For this reason we
decided against using stub files because we feared that those could get out of
sync with their companion ``.py`` files.

Type hint comments
------------------

We chose the only other option: Use `type hint comments`_. Those work across
Python 2 and 3 as well as stub files do, but can't get out of sync with the
implementation::

    from typing import Iterable

    def stringify_list(xs, random_new_parameter):
        # type: (Iterable[int]) -> Iterable[str]
        return [str(x) for x in xs]

This time mypy rejects the code with ``error: Type signature has too few arguments``.

.. _`type hint comments`: https://mypy.readthedocs.io/en/latest/python2.html

Eliminating imports
-------------------

With this approach we need to import ``typing``. This adds runtime cost, and
while that alone would be negligible, we also now have to install the
``typing`` module under Python 2.

Luckily there is a cheap way to get rid of these pesky imports::

    if False:
        from typing import Iterable

    def stringify_list(xs, random_new_parameter):
        # type: (Iterable[int]) -> Iterable[str]
        return [str(x) for x in xs]

This avoids importing the ``typing`` module at runtime while keeping mypy
happy. We had this version in use for quite a while until we discovered that
mypy had a more official way that didn't depend on undocumented quirks::

    MYPY = False
    if MYPY:
        from typing import Iterable

    <rest of the code as above>

The mypy documentation mentions this hack as a `solution to import cycles while
type-checking
<https://mypy.readthedocs.io/en/latest/common_issues.html#import-cycles>`_, but
it works just as well for our purposes.

Function overloading
--------------------

All of our imports are now disabled at runtime. This works for type hint
comments, but some other annotations are not comments. For example, function
overloads::

    from typing import Union, overload

    @overload
    def foo(x):
        # type: (int) -> None
        pass

    @overload
    def foo(x):
        # type: (str) -> None
        pass

    def foo(x):
        # type: (Union[int, str]) -> None
        pass

The issue is the ``overload`` decorator. Wrapping only the first two function
declarations in ``if MYPY`` confuses mypy so much it thinks the last
declaration is an unnecessary redefinition. Other approaches we tried typecheck
successfully but require more duplicated type signatures which could get out of
sync unnoticed.

Our solution is::

    MYPY = False

    if MYPY:
        from typing import Union, overload
    else:
        def overload(x):
            return x

    <rest of the code as above>


This is not quite zero runtime overhead but close enough.

Conclusion
----------

What we have right now gives us nicer code intelligence in IDEs without
disrupting the rest of our users with added dependencies or runtime
overhead. The majority of our SDK is still untyped or weakly typed, but we did
find some bugs in the SDK using mypy.

Mypy is generally a good, useful piece of software. Unfortunately the story for
annotating existing Python 2 code ignores the issues that come from additional
dependencies. Documented workarounds like ``if MYPY`` are an afterthought even
for their intended purpose. This will likely slow down adoption of type hints
in libraries and make the typeshed_ (the repository of type annotations for
third-party packages that don't have any) a permanent necessity.

.. _typeshed: https://github.com/python/typeshed
