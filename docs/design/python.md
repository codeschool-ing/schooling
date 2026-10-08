---
format: 5
course: python
---

# python

**Python** · `co-xy18stba` · 90 h declared · beginner · 21 lessons · `programming` · **free**

## Reach

In **9 tracks** — `ai`(2), `backend`(5, choice *Python*), `bi`(10), `data`(5), `data-science`(1), `devops`(4, choice *Python*), `devsecops`(3, choice *Python*), `networks-infra`(9), `security`(14).

**Reached through a choice**, never in sequence — so **no course after that fork may assume it was taken**.

**Depends on it:** `ai-models`, `bigdata`, `data-fundamentals`, `ml-mlops`, `networks-automation`, `pentest`, `python-back`, `python-data`, `streaming`

## Assumes, and leaves ready

**Assumes:** **nothing.** Beginner, no `requires`, and position 1 of `data-science`.

**Leaves ready:** **more than any other course in the catalogue, jointly with `sql-databases`** — nine dependents: `ai-models`, `bigdata`, `data-fundamentals`, `ml-mlops`, `networks-automation`, `pentest`, `python-back`, `python-data` and `streaming`. Across **nine tracks**.

## Shape

| | |
|---|---|
| declared hours | 90 h |
| lessons | 21 |
| **hours per lesson** | **4.29** |
| section budget | ~193, about 9.2 a lesson — **and 257 are designed**; the arithmetic is below |
| sections | **257** — 173 reading, 63 video, 21 practice |
| exercises | ~1100, at the catalogue's MEASURED density; the arithmetic is below |

## Execution

| | |
|---|---|
| runtime | **a Python interpreter** — the plainest environment in the catalogue |
| browser · database | no · no |
| exercises **blocked** | **~600 (65%)** |
| exercises that would **improve** | the remainder |
| diagrams to draw | ~50 — the collections compared, scope drawn as boxes, a decorator wrapping, a generator yielding, Big-O curves |

## Sections

Five volumes. **The volumes are a reading device; the lessons and their ids are the contract
with the portal and do not move.** The numbering 01–257 is the path a student walks, in the
order they walk it.

### Every lesson opens on a face, demonstrates once, and closes

Three videos and a drill in each of the twenty-one: an **opening** that says what the lesson is
for, one **demonstration** in the middle where the thing is done rather than described, and a
**closing** that is the sentence to leave with. The drill is the only section of kind
`practice` — the questions attached to the readings are the lesson's own, and the drill's are the
ones that put the whole lesson together. `drillable` is a property of a question rather than of a
section, and in a lesson file it is `true`: what it decides is whether the practice queue may draw
that card, and the only place it is `false` is an exam pool, which `validate-content` refuses
otherwise.

The demonstration is the section this course cannot do without. Python is taught by watching
somebody type it wrong and read the message — `reading-a-traceback` is section 09 for that
reason, before the student has written anything long enough to break.

### What a section is worth here, and why there are 257 of them

The budget of ~193 came from declared hours at "the catalogue's density", and the catalogue now
has a measured one to compare against. **595 sections across 240 written hours is 2.48 an hour**,
and at that density 90 hours is **223** — so the budget was already under the only figure anybody
has counted, in the same way `linux-terminal`'s ~150 was.

**And this is a language course, which is the denser kind.** The two written courses either side
of that average are `linux-terminal` at 3.26 sections an hour and `sql-databases` at 2.07, and
the difference is not effort: a section about `zypper` is one command, its flags, its output and
five questions, where a section about normalisation is an idea that takes five paragraphs to
build. Python is the first kind. **257 sections in 90 hours is 21.0 minutes each** — between
`linux-terminal`'s 18.4 and `web-fundamentals`' 25.5, which is where a language taught from
nothing belongs.

**The declared hours do not move**: they are on the course card and in the portal, and this
course is free, so the ninety hours are also the egress argument in `Flags`. If the real figure
turns out to be higher, that is a catalogue change with its own argument.

**AND THE LIST BELOW IS THE CONTRACT WITH `content/`, not a sketch.** `tools/check-design`
compares it to the written course by slug and kind, lesson by lesson, so a section renamed while
it is being written fails on the commit that renames it. That check exists because
`linux-terminal` was written against a different arrangement from the one its sheet listed and
the only symptom was a total five out — this course starts on the other side of that.


## Volume I — The language, from nothing

**Lesson 1 · Installation, the interpreter and your first script** — `le-yed42k3g`

| | slug | kind | covers |
|---|---|---|---|
| 01 | `intro` | video | Code is a file you write and a program that reads it — **opening** |
| 02 | `what-python-is` | reading | An interpreter rather than a compiler, what that buys and what it costs, and where Python actually runs |
| 03 | `three-ways` | reading | Three places to keep a Python — installed (recommended), a virtual machine with Ubuntu Server 24.04, online — and what each costs the computer |
| 04 | `getting-one` | reading | The three you will meet — the system's, python.org's, and the one a manager installed — and why `python3` and not `python` |
| 05 | `when-it-fails` | reading | `python` not found, `pip` and `venv` missing until the `apt` line, Windows' PATH, a version too old — captured on a fresh Ubuntu 24.04 |
| 06 | `the-repl` | reading | The prompt that answers back: evaluating, the last value, `help()` and `dir()`, and when it is the wrong tool |
| 07 | `a-file-with-a-name` | reading | `hello.py`, running it, the shebang on a machine that has one, and the difference between running and importing |
| 08 | `an-error-is-a-message` | video | One typo, read out of the traceback rather than guessed at — **demonstration** |
| 09 | `reading-a-traceback` | reading | Bottom-up: the exception, its message, and the line the interpreter was on — the single most useful skill in the course |
| 10 | `print-and-input` | reading | `print` with several arguments, `sep` and `end`, and `input` always returning a string |
| 11 | `comments-and-style` | reading | `#`, why a docstring is not a comment, and four characters of indentation being the syntax rather than a preference |
| 12 | `an-editor` | reading | What an editor gives you that the REPL does not, and the two settings that matter before anything else |
| 13 | `closing` | video | Write it in a file, run it, read the traceback — **closing** |
| 14 | `drill` | practice | Predict the output, name the error, say which line the interpreter was on |

**Lesson 2 · Types, variables, operators and string formatting** — `le-pddr2qqm`

| | slug | kind | covers |
|---|---|---|---|
| 15 | `intro` | video | Every value has a type, and the type decides what the operator means — **opening** |
| 16 | `names-and-values` | reading | A name is a label on a value, not a box: assignment, rebinding, and `id()` for when you need to see it |
| 17 | `numbers` | reading | `int` with no limit, `float` and what it cannot represent, `//` against `/`, and `%` on a negative |
| 18 | `strings` | reading | Immutable sequences: quoting, escapes, triple quotes, and what `+` and `*` do |
| 19 | `string-methods` | reading | The dozen that carry the work — `strip`, `split`, `join`, `replace`, `startswith`, `find` — and that each returns a new string |
| 20 | `formatting` | reading | f-strings, the format spec after the colon, `=` for debugging, and why `%` and `.format()` still exist |
| 21 | `booleans-and-truthiness` | reading | `True` and `False` as integers, what is falsy, and `and`/`or` returning an operand rather than a boolean |
| 22 | `none` | reading | The value that means nothing: `is None` rather than `== None`, and the default argument it belongs in |
| 23 | `converting` | reading | `int()`, `float()`, `str()`, `bool()` — where they refuse, and the `ValueError` that is the point |
| 24 | `type-errors` | video | Four values, four operators, and the message each wrong pairing produces — **demonstration** |
| 25 | `closing` | video | The type decides the operator, and `type()` answers when you are not sure — **closing** |
| 26 | `drill` | practice | Say the type, predict the operator, spot the conversion that will raise |

**Lesson 3 · Collections: lists, tuples, dictionaries and sets** — `le-084gr9e9`

| | slug | kind | covers |
|---|---|---|---|
| 27 | `intro` | video | Four containers, and the question each one answers — **opening** |
| 28 | `lists` | reading | Ordered and mutable: indexing, negative indices, `append`, `extend`, `insert`, `pop`, `remove` and `sort` |
| 29 | `slicing` | reading | `[start:stop:step]`, stop being exclusive, the copy it makes, and `[::-1]` |
| 30 | `tuples` | reading | Immutable, unpacking, the one-element tuple's comma, and why a tuple can be a dictionary key |
| 31 | `dictionaries` | reading | Keys to values: `[]` against `get`, `setdefault`, `keys`/`values`/`items`, and insertion order being guaranteed |
| 32 | `sets` | reading | Membership and uniqueness: `add`, `discard`, union, intersection and difference — and no order at all |
| 33 | `choosing` | reading | The four side by side: what each costs to search, to append and to hold, and the question that picks one |
| 34 | `nesting` | reading | A list of dictionaries, which is what every JSON file you will read looks like |
| 35 | `copying` | reading | Assignment being a second name, `copy()` being shallow, and `deepcopy` for when it is not enough |
| 36 | `mutable-defaults` | reading | The default argument evaluated once, the list that grows between calls, and `None` as the fix |
| 37 | `the-same-data-four-ways` | video | One record, held as a list, a tuple, a dictionary and a set — and what each makes easy — **demonstration** |
| 38 | `closing` | video | Order, mutability, uniqueness, lookup — the four questions — **closing** |
| 39 | `drill` | practice | Pick the container, predict the mutation, say what the slice returns |

**Lesson 4 · Conditionals, loops and comprehensions (list/dict comprehensions)** — `le-ahrts32p`

| | slug | kind | covers |
|---|---|---|---|
| 40 | `intro` | video | Doing something only sometimes, and doing it to everything — **opening** |
| 41 | `if-elif-else` | reading | The indentation is the block, `elif` rather than a nested `if`, and the conditional expression |
| 42 | `comparing` | reading | Chained comparisons, `==` against `is`, `in` on each container, and comparing different types |
| 43 | `for` | reading | Iterating the thing itself rather than its indices, `range`, `enumerate` and `zip` |
| 44 | `while` | reading | The condition that has to change, `break` and `continue`, and the `else` on a loop that nobody expects |
| 45 | `nested-loops` | reading | Two loops and the work that grows with the product — the first place lesson 20 will point back to |
| 46 | `list-comprehensions` | reading | `[f(x) for x in xs if p(x)]`, reading it in the order it executes, and when it stops being clearer |
| 47 | `dict-and-set-comprehensions` | reading | The same shape with braces, and the generator expression that is neither |
| 48 | `common-loop-mistakes` | reading | Mutating the list you are iterating, the off-by-one, and the variable that outlives the loop |
| 49 | `a-loop-rewritten` | video | The same task as a loop, a comprehension and a `map` — and which one to keep — **demonstration** |
| 50 | `closing` | video | Iterate the thing, not the index; comprehend when it fits on a line — **closing** |
| 51 | `drill` | practice | Predict the iteration, rewrite as a comprehension, find the off-by-one |

**Lesson 5 · Functions: arguments, return values, scope and lambdas** — `le-5t5jer2h`

| | slug | kind | covers |
|---|---|---|---|
| 52 | `intro` | video | A name for a piece of work, so it happens once — **opening** |
| 53 | `defining-and-calling` | reading | `def`, the body, the call, and what a function with no `return` gives you back |
| 54 | `arguments` | reading | Positional and keyword, defaults, and why the default is evaluated once at definition |
| 55 | `star-args` | reading | `*args` and `**kwargs`, unpacking at the call site, and the `*` that forces keyword-only arguments |
| 56 | `return` | reading | Returning several values as a tuple, early return, and the difference between returning and printing |
| 57 | `scope` | reading | Local, enclosing, global, built-in — resolved in that order, and the assignment that makes a name local |
| 58 | `global-and-nonlocal` | reading | The two keywords, what each one reaches, and why needing them is usually a sign |
| 59 | `docstrings` | reading | The first statement of the body, what `help()` does with it, and the three lines worth writing |
| 60 | `lambdas` | reading | An expression with parameters: where it is right — `key=` — and where a `def` is better |
| 61 | `functions-as-values` | reading | Passing one, returning one, and storing one in a dictionary — the idea lesson 12 is built on |
| 62 | `scope-drawn` | video | The same name at three levels, and which one each line sees — **demonstration** |
| 63 | `closing` | video | Arguments in, a value out, and a name that says what it does — **closing** |
| 64 | `drill` | practice | Predict the return, resolve the name, say which default is shared |


## Volume II — Structure, and the library that is already there

**Lesson 6 · Object orientation: classes, inheritance and special methods** — `le-vw3kvqct`

| | slug | kind | covers |
|---|---|---|---|
| 65 | `intro` | video | Data and the operations on it, kept in one place — **opening** |
| 66 | `a-class-and-an-instance` | reading | `class`, `__init__`, `self` being the instance and not magic, and attributes set where you can see them |
| 67 | `methods` | reading | Functions that take the instance, calling one from another, and the method that returns a new object |
| 68 | `class-against-instance` | reading | The attribute shared by every instance, the mutable one that is a trap, and `@classmethod` against `@staticmethod` |
| 69 | `inheritance` | reading | Reusing a class, overriding a method, `super()`, and what the method resolution order decides |
| 70 | `special-methods` | reading | `__str__` against `__repr__`, `__len__`, `__eq__`, `__lt__` — the interface the language already knows how to call |
| 71 | `dataclasses` | reading | `@dataclass` writing `__init__`, `__repr__` and `__eq__` for you, `field(default_factory=…)`, and `frozen=True` |
| 72 | `composition` | reading | Holding an object rather than inheriting from one, and the question that decides between them |
| 73 | `properties` | reading | `@property` for the attribute that is computed, and the setter that validates |
| 74 | `when-not-a-class` | reading | The class with one method, the one with no state — and the function or dataclass each should have been |
| 75 | `two-designs` | video | The same problem by inheritance and by composition, side by side — **demonstration** |
| 76 | `closing` | video | `__init__`, `__repr__`, and a dataclass when that is all it was — **closing** |
| 77 | `drill` | practice | Say what `self` is, predict the resolution, choose composition or inheritance |

**Lesson 7 · Modules, packages and the standard library** — `le-0e263dy1`

| | slug | kind | covers |
|---|---|---|---|
| 78 | `intro` | video | Somebody has already written it, and it is already installed — **opening** |
| 79 | `a-module-is-a-file` | reading | `import`, `from … import`, the alias, and why `import *` is a way to lose track of where a name came from |
| 80 | `running-against-importing` | reading | `__name__ == "__main__"`, what it is actually for, and the script that ran twice |
| 81 | `packages` | reading | A directory with modules in it, `__init__.py`, and relative against absolute imports |
| 82 | `where-python-looks` | reading | `sys.path`, the current directory being on it, and the file named `random.py` that shadows the library |
| 83 | `the-library-worth-knowing` | reading | `pathlib`, `datetime`, `collections`, `itertools`, `json`, `re`, `math`, `random`, `os` and `sys` — what each is for in one line |
| 84 | `pathlib` | reading | A path as an object: `/` to join, `exists`, `read_text`, `glob` — and why not string concatenation |
| 85 | `datetime` | reading | `date`, `datetime`, `timedelta`, parsing and formatting, and the naive datetime that has no time zone |
| 86 | `collections-and-itertools` | reading | `Counter`, `defaultdict`, `namedtuple`, `deque` — and the four `itertools` that earn their import |
| 87 | `finding-it` | video | A question answered three ways: the docs, `help()`, and the source on disk — **demonstration** |
| 88 | `closing` | video | Import it before you write it, and know where Python looked — **closing** |
| 89 | `drill` | practice | Name the module, predict the import, find the shadowed name |

**Lesson 8 · Errors and exceptions: try, except, else and finally** — `le-50d6sygp`

| | slug | kind | covers |
|---|---|---|---|
| 90 | `intro` | video | Failure is a value the language hands you, not an accident — **opening** |
| 91 | `the-exception-hierarchy` | reading | `BaseException` down to the ones you will catch, and why `except Exception` and never a bare `except` |
| 92 | `try-and-except` | reading | Catching one kind, catching several, `as e`, and the block kept as small as the thing that can fail |
| 93 | `else-and-finally` | reading | `else` for the code that must not be inside the `try`, `finally` for the cleanup that happens either way |
| 94 | `raising` | reading | `raise`, choosing the class, the message a person will read, and `raise … from e` keeping the cause |
| 95 | `your-own-exception` | reading | A class inheriting `Exception`, when one is worth defining, and the module that exports it |
| 96 | `easier-to-ask-forgiveness` | reading | Trying and catching rather than checking first, where each reads better, and the race the check has |
| 97 | `the-ones-you-will-meet` | reading | `ValueError`, `TypeError`, `KeyError`, `IndexError`, `FileNotFoundError`, `AttributeError` — and what each is telling you |
| 98 | `a-failure-handled-badly` | video | The same bug behind a bare `except`, a broad one, and a narrow one — **demonstration** |
| 99 | `closing` | video | Catch what you can answer, and let the rest reach the traceback — **closing** |
| 100 | `drill` | practice | Name the exception, choose the clause, say what `finally` runs |

**Lesson 9 · Files, JSON and CSV** — `le-1xv5mzwc`

| | slug | kind | covers |
|---|---|---|---|
| 101 | `intro` | video | The data is on disk, and it is somebody else's shape — **opening** |
| 102 | `opening-a-file` | reading | `open` and its modes, `with` closing it for you, and the file left open being the reason `with` exists |
| 103 | `text-and-encoding` | reading | `encoding="utf-8"` written out, the default that differs per platform, and `UnicodeDecodeError` read properly |
| 104 | `reading-and-writing` | reading | Whole file, line by line, and why iterating the file object is the one that scales |
| 105 | `paths-again` | reading | `pathlib` for the file that is beside the script, and the relative path that depends on where you ran it |
| 106 | `json` | reading | `load`/`loads`, `dump`/`dumps`, `indent`, and the Python types each JSON type becomes |
| 107 | `json-that-is-not-yours` | reading | Missing keys, nulls, a list where you expected an object — and `get` with a default rather than a `KeyError` |
| 108 | `csv` | reading | `csv.reader` against `DictReader`, the header row, `newline=""`, and the comma inside a quoted field |
| 109 | `writing-data-back` | reading | `DictWriter`, writing JSON a person can read, and never building either format with string concatenation |
| 110 | `binary-and-bytes` | reading | `rb`/`wb`, `bytes` against `str`, and when you need neither |
| 111 | `a-file-read-three-ways` | video | One CSV, read by hand, by `csv`, and by `DictReader` — **demonstration** |
| 112 | `closing` | video | Use `with`, name the encoding, and let a library parse the format — **closing** |
| 113 | `drill` | practice | Predict the parse, name the mode, find the encoding bug |


## Volume III — What separates a script from Python

**Lesson 10 · Regular expressions: matching, groups and substitution** — `le-x5k33vhd`

| | slug | kind | covers |
|---|---|---|---|
| 114 | `intro` | video | A pattern that describes a shape of text — **opening** |
| 115 | `when-not-to` | reading | The three jobs a string method already does, and HTML, which is the classic wrong answer |
| 116 | `matching-one-character` | reading | Literals, `.`, classes, `\d` `\w` `\s` and their negations, and the escape inside a class |
| 117 | `how-many` | reading | `*`, `+`, `?`, `{m,n}` — and greedy against lazy, which is the first thing to go wrong |
| 118 | `where` | reading | `^`, `$`, `\b`, and why `match` and `search` are two different functions |
| 119 | `groups` | reading | Parentheses to capture, `group()`, numbered and named groups, and the non-capturing `(?:…)` |
| 120 | `the-re-module` | reading | `search`, `match`, `fullmatch`, `findall`, `finditer` — and what each gives back |
| 121 | `substitution` | reading | `sub` with a backreference, `sub` with a function, and `count` |
| 122 | `raw-strings-and-compiling` | reading | `r""` and the backslash you would otherwise double, and `re.compile` for the pattern used in a loop |
| 123 | `a-pattern-built-up` | video | One log line, matched wrongly four times, then right — **demonstration** |
| 124 | `closing` | video | Describe the shape, capture what you want, and stop before HTML — **closing** |
| 125 | `drill` | practice | Predict the match, name the group, fix the greedy quantifier |

**Lesson 11 · Iterators and generators: producing one value at a time** — `le-6ptndnp4`

| | slug | kind | covers |
|---|---|---|---|
| 126 | `intro` | video | A million rows, and memory for one — **opening** |
| 127 | `the-iterator-protocol` | reading | `__iter__` and `__next__`, `StopIteration`, and what `for` is actually doing |
| 128 | `iterable-against-iterator` | reading | The list you can loop twice and the iterator you cannot, and the exhausted generator that quietly gives nothing |
| 129 | `generator-functions` | reading | `yield`, the function that pauses, and the state kept between calls without a class |
| 130 | `generator-expressions` | reading | The comprehension with parentheses, `sum(… for …)` without the brackets, and when it saves the memory |
| 131 | `laziness` | reading | Nothing computed until it is asked for, the infinite generator, and what that makes possible |
| 132 | `itertools` | reading | `islice`, `chain`, `groupby`, `count`, `cycle`, `takewhile` — six that are worth the import |
| 133 | `a-pipeline` | reading | Generators chained end to end, which is lesson 8 of `linux-terminal` in one process |
| 134 | `writing-one-as-a-class` | reading | The same generator written with `__iter__`, and why the `yield` version is the one to keep |
| 135 | `one-file-two-ways` | video | The same ten-million-line file, read into a list and read lazily — **demonstration** |
| 136 | `closing` | video | Yield when you can, and remember an iterator is spent — **closing** |
| 137 | `drill` | practice | Say what it yields, spot the exhausted iterator, choose the lazy form |

**Lesson 12 · Decorators: the function that wraps another function** — `le-c1sg9184`

| | slug | kind | covers |
|---|---|---|---|
| 138 | `intro` | video | The same three lines at the top of nine functions — **opening** |
| 139 | `a-function-that-takes-a-function` | reading | Functions as values, the inner function, and the closure that remembers |
| 140 | `the-at-sign` | reading | `@wrapper` being `f = wrapper(f)` and nothing else, written out both ways |
| 141 | `arguments-and-returns` | reading | `*args, **kwargs` so the wrapper fits anything, and returning the wrapped call's value |
| 142 | `functools-wraps` | reading | The name and docstring the wrapper eats, what breaks without it, and the one-line fix |
| 143 | `a-decorator-with-arguments` | reading | The third layer, read from the inside out, and why it is the part everybody has to look up |
| 144 | `the-ones-you-will-meet` | reading | `@property`, `@staticmethod`, `@classmethod`, `@functools.cache`, `@pytest.fixture` — each now readable |
| 145 | `stacking` | reading | Two decorators, the order they apply in, and the order they run in — which are not the same |
| 146 | `when-not-to` | reading | The decorator that hides a branch, and the argument that would have been clearer |
| 147 | `timing-nine-functions` | video | One decorator, written wrong twice, then applied to a module — **demonstration** |
| 148 | `closing` | video | It is a function that takes a function; use `wraps` — **closing** |
| 149 | `drill` | practice | Rewrite the `@` as a call, predict the order, say what `wraps` restores |

**Lesson 13 · Context managers, and writing a `with` block of your own** — `le-9zx9txbc`

| | slug | kind | covers |
|---|---|---|---|
| 150 | `intro` | video | Something has to happen even when it fails — **opening** |
| 151 | `what-with-guarantees` | reading | Setup, the body, and teardown that runs on the exception too — `try/finally` with a name |
| 152 | `the-protocol` | reading | `__enter__` returning what `as` binds, `__exit__` and its three arguments, and the return value that swallows |
| 153 | `contextlib` | reading | `@contextmanager`, the single `yield`, and the `try/finally` around it that is not optional |
| 154 | `several-at-once` | reading | Two managers in one `with`, nesting, and `ExitStack` for the number you do not know |
| 155 | `the-ones-already-written` | reading | `open`, a lock, a database transaction, `tempfile`, `suppress`, `redirect_stdout` |
| 156 | `writing-a-useful-one` | reading | A timer, a working directory changed and restored, and a temporary setting |
| 157 | `what-it-is-not` | reading | Not a scope, not a transaction by itself, and the exception it does not handle unless you say so |
| 158 | `the-file-left-open` | video | The same loop with and without `with`, and the descriptors counted — **demonstration** |
| 159 | `closing` | video | If it must be undone, put it in `__exit__` — **closing** |
| 160 | `drill` | practice | Say what runs on the exception, write the `@contextmanager`, name what `as` binds |


## Volume IV — Saying what you mean, and proving it

**Lesson 14 · Type hints: annotating arguments, returns and collections** — `le-3j07dksy`

| | slug | kind | covers |
|---|---|---|---|
| 161 | `intro` | video | The type was always in your head; now it is in the file — **opening** |
| 162 | `the-syntax` | reading | `def f(x: int) -> str`, the annotated variable, and that Python does not check any of it at runtime |
| 163 | `the-built-ins` | reading | `int`, `str`, `bool`, `float`, `bytes`, and `None` as a return |
| 164 | `collections` | reading | `list[int]`, `dict[str, int]`, `tuple[int, str]` and the `tuple[int, ...]` that is not the same |
| 165 | `optional-and-unions` | reading | `X | None`, what `Optional` used to mean, and the union that is a design smell |
| 166 | `any-and-object` | reading | `Any` turning the checker off for that value, `object` keeping it on, and which one you meant |
| 167 | `callables-and-generics` | reading | `Callable[[int], str]`, `Iterable`, `Sequence`, and taking the widest type you can accept |
| 168 | `your-own-types` | reading | A class as a type, `TypeAlias`, `NewType`, and the `TypedDict` for the JSON you parsed in lesson 9 |
| 169 | `protocols` | reading | Structural typing: the interface a class satisfies without inheriting anything |
| 170 | `where-to-put-them` | reading | Public functions first, the ones that take a collection, and the annotation that says nothing |
| 171 | `an-api-annotated` | video | One module, before and after, and the two bugs the annotations made visible — **demonstration** |
| 172 | `closing` | video | Annotate the boundary; the body usually speaks for itself — **closing** |
| 173 | `drill` | practice | Write the annotation, name the union, say what the checker cannot see |

**Lesson 15 · mypy and pyright: the checker that reads the annotations** — `le-wvw53jb4`

| | slug | kind | covers |
|---|---|---|---|
| 174 | `intro` | video | The annotation is a comment until something reads it — **opening** |
| 175 | `what-a-checker-does` | reading | Static analysis: no code runs, and the errors it can find before a test can |
| 176 | `running-mypy` | reading | Installing it, pointing it at a file and at a package, and reading one error properly |
| 177 | `strictness` | reading | The default that passes almost anything, `--strict` and what each flag under it turns on |
| 178 | `configuring-it` | reading | The settings in `pyproject.toml`, the module you exclude and why, and `disallow_untyped_defs` |
| 179 | `pyright` | reading | The other one: faster, in the editor, and where the two disagree on purpose |
| 180 | `third-party-stubs` | reading | The library with no annotations, `types-…` packages, and `# type: ignore` with a reason beside it |
| 181 | `adopting-it-on-what-exists` | reading | Starting loose, one module at a time, and the flag that stops the untyped half growing |
| 182 | `two-bugs-found` | video | A checker run over a working module, and the `None` nobody had hit yet — **demonstration** |
| 183 | `closing` | video | A checker that runs is worth more than annotations that are right — **closing** |
| 184 | `drill` | practice | Read the error, name the flag, decide the ignore |

**Lesson 16 · Testing with pytest: assertions, fixtures, parametrisation and coverage** — `le-6vtyy8jc`

| | slug | kind | covers |
|---|---|---|---|
| 185 | `intro` | video | A question you ask once and a machine asks forever — **opening** |
| 186 | `a-first-test` | reading | A file, a function named `test_…`, a bare `assert`, and running `pytest` |
| 187 | `reading-a-failure` | reading | The assertion rewritten, both values printed, and the report read from the bottom |
| 188 | `what-to-assert` | reading | One behaviour per test, the name that says it, and the test that asserts the implementation |
| 189 | `fixtures` | reading | `@pytest.fixture`, the argument by name, scopes, and the teardown after the `yield` |
| 190 | `parametrisation` | reading | `@pytest.mark.parametrize`, one case per row, and the table that replaces nine near-identical tests |
| 191 | `exceptions-and-approximations` | reading | `pytest.raises` with a match, and `approx` for the float that is never equal |
| 192 | `test-layout` | reading | `tests/`, what `conftest.py` is for, and the import that works because of it |
| 193 | `doubles` | reading | `monkeypatch` and `unittest.mock` — and the test that now only proves the mock |
| 194 | `coverage` | reading | `pytest --cov`, what the number does and does not say, and the line covered by no assertion |
| 195 | `a-bug-caught` | video | A test written from the bug report, red, then green — **demonstration** |
| 196 | `closing` | video | One behaviour, a name that says it, and a failure you can read — **closing** |
| 197 | `drill` | practice | Name the test, choose the fixture scope, say what the coverage number hides |

**Lesson 17 · Formatting and linting with black and ruff** — `le-0hxvf3pd`

| | slug | kind | covers |
|---|---|---|---|
| 198 | `intro` | video | Stop having the opinion; have the tool — **opening** |
| 199 | `formatting-against-linting` | reading | One rewrites the file, the other reports what it found — and why they are two tools |
| 200 | `black` | reading | No options on purpose, what it does to a long call, and the diff that is settled once |
| 201 | `ruff` | reading | One tool replacing several, the rule families, and what `--fix` is allowed to change |
| 202 | `choosing-rules` | reading | The default set, turning a family on, and the per-file ignore that belongs in the config |
| 203 | `configuring-both` | reading | `[tool.ruff]` and `[tool.black]` in `pyproject.toml`, line length, and the target version |
| 204 | `in-the-editor-and-in-ci` | reading | Format on save, `--check` in the pipeline, and the pre-commit hook that stops the argument |
| 205 | `the-rules-worth-reading` | reading | Unused imports, mutable defaults, bare `except`, shadowed built-ins — the ones that are bugs |
| 206 | `a-file-run-through-both` | video | Ninety lines reformatted and four findings, read one by one — **demonstration** |
| 207 | `closing` | video | Format everything, lint what matters, argue about neither — **closing** |
| 208 | `drill` | practice | Predict the reformat, name the rule, say which finding is a bug |


## Volume V — A project, and what it rests on

**Lesson 18 · Virtual environments (venv), pip and requirements** — `le-vmjas70m`

| | slug | kind | covers |
|---|---|---|---|
| 209 | `intro` | video | Two projects, two versions of the same library, one machine — **opening** |
| 210 | `why-an-environment` | reading | The system interpreter that belongs to the system, and the install that broke something you did not write |
| 211 | `venv` | reading | `python -m venv`, what is inside it, activating and deactivating, and the directory you never commit |
| 212 | `pip` | reading | `install`, `uninstall`, `list`, `show`, `--upgrade` — and `python -m pip` rather than `pip` |
| 213 | `versions` | reading | `==`, `>=`, `~=`, and what a version number is promising you |
| 214 | `requirements` | reading | `requirements.txt`, `pip freeze` and why its output is not a requirements file |
| 215 | `pinning-and-reproducing` | reading | The install that worked yesterday, the transitive dependency that moved, and the lock file that answers it |
| 216 | `where-things-went` | reading | `site-packages`, `pip show -f`, and the import that found the wrong copy |
| 217 | `two-projects-one-machine` | video | The same import, two environments, two versions — **demonstration** |
| 218 | `closing` | video | One environment per project, and never the system interpreter — **closing** |
| 219 | `drill` | practice | Predict the resolution, read the specifier, say what `freeze` got wrong |

**Lesson 19 · uv, Poetry and pyproject.toml: how a project declares itself today** — `le-nax0q0k5`

| | slug | kind | covers |
|---|---|---|---|
| 220 | `intro` | video | The project says what it is, in one file — **opening** |
| 221 | `pyproject-toml` | reading | The file that replaced four, `[project]`, and the metadata a tool reads |
| 222 | `declaring-dependencies` | reading | `dependencies`, optional groups, the development group, and requires-python |
| 223 | `uv` | reading | `uv venv`, `uv add`, `uv run`, `uv sync` — and the lock file it writes |
| 224 | `poetry` | reading | The other one: `poetry add`, `poetry install`, its lock, and where it differs |
| 225 | `which-one` | reading | The three arrangements you will meet, how to tell which a repository uses, and what to do on somebody else's |
| 226 | `lock-files` | reading | What is in one, why it is committed, and the difference between installing and syncing |
| 227 | `a-package-of-your-own` | reading | Layout, `build-system`, building a wheel, and installing it locally with `-e` |
| 228 | `the-churn` | reading | Why this lesson ages fastest in the course, and the part that does not: the file |
| 229 | `the-same-project-twice` | video | One project set up with uv and with Poetry, side by side — **demonstration** |
| 230 | `closing` | video | Declare it in `pyproject.toml`, commit the lock, and read before you install — **closing** |
| 231 | `drill` | practice | Read the file, name the tool, say what the lock guarantees |

**Lesson 20 · Data structures and a sense of complexity (Big-O)** — `le-bs5rwtwc`

| | slug | kind | covers |
|---|---|---|---|
| 232 | `intro` | video | The same answer, a thousand times slower — **opening** |
| 233 | `counting-work` | reading | Counting operations rather than seconds, what `n` is, and why the constant is dropped |
| 234 | `the-curves` | reading | O(1), O(log n), O(n), O(n log n), O(n²) — and what each looks like at a thousand and a million |
| 235 | `what-python-costs` | reading | The table worth knowing: list index, append, `in`, `insert(0)`, dict lookup, set membership |
| 236 | `the-list-that-should-be-a-set` | reading | `in` on a list against `in` on a set, measured — the single most common fix |
| 237 | `dictionaries-as-indexes` | reading | Building a lookup once rather than searching repeatedly, which turns O(n²) into O(n) |
| 238 | `sorting` | reading | `sort` and `sorted`, `key=`, stability, and what it costs |
| 239 | `stacks-queues-and-deques` | reading | A list as a stack, why it is a bad queue, and `deque` |
| 240 | `measuring-rather-than-guessing` | reading | `timeit` for the small thing, `cProfile` for the program, and the hot line that was not where you thought |
| 241 | `nested-loops-again` | reading | Lesson 4's nested loop, counted — and the three rewrites that remove it |
| 242 | `one-function-made-fast` | video | Eleven seconds to forty milliseconds, one data structure at a time — **demonstration** |
| 243 | `closing` | video | Know the shape of the growth, then measure — **closing** |
| 244 | `drill` | practice | Name the complexity, pick the structure, say which line the profile will blame |

**Lesson 21 · pandas for tables and requests for consuming APIs** — `le-1mk7ex2r`

| | slug | kind | covers |
|---|---|---|---|
| 245 | `intro` | video | The two libraries you will reach for on the first day of the next course — **opening** |
| 246 | `why-a-dataframe` | reading | A table as one object, and the loop over rows that this lesson is about not writing |
| 247 | `reading-data-in` | reading | `read_csv` and `read_json`, `dtype`, the header, and the column of the wrong type |
| 248 | `looking-at-it-first` | reading | `head`, `info`, `describe`, `shape`, `value_counts` — the five minutes before any analysis |
| 249 | `selecting` | reading | A column, several, `loc` against `iloc`, and the boolean mask that is the idea |
| 250 | `missing-data` | reading | `NaN`, `isna`, `fillna`, `dropna`, and the mean that quietly skipped them |
| 251 | `grouping` | reading | `groupby` and an aggregation, which is `sort | uniq -c` with arithmetic |
| 252 | `requests` | reading | `get`, the query string, `raise_for_status`, `json()`, and the timeout that is not optional |
| 253 | `headers-auth-and-paging` | reading | Sending a token, reading the rate limit, and the loop that follows the next page |
| 254 | `an-api-into-a-table` | reading | Two pages of JSON into a DataFrame, which is the shape of most data work |
| 255 | `a-small-piece-of-work` | video | An endpoint, a table, a question answered — **demonstration** |
| 256 | `closing` | video | Vectorise rather than loop, and always set a timeout — **closing** |
| 257 | `drill` | practice | Predict the selection, name the aggregation, spot the request with no timeout |

## Exercises

| where | how many |
|---|---|
| in each of the 171 reading sections | 4–6 → ~815 |
| in each of the 21 practice sections, all `drillable` | 12–16 → ~295 |
| total proposed | ~1100 |
| floor, below which it is not published | 850 |

**The ~910 this sheet opened with was the same kind of number as the ~193 above it.** Both were
derived from "the catalogue's density" before anybody had counted one. The four written courses
hold **2,897 questions across 452 reading sections** — 4.77 a reading once the drills are taken
out at fourteen apiece — and 171 readings at that rate is 815, plus 295 in the drills.

**The floor is the number that means something if the writing comes in short.** 850 is a little
under the projection and a long way above the ~910 the sheet used to carry as a target, which is
the point: a target you clear by writing less is not a floor.

**About two thirds of them want a runtime.** The Execution table above says ~600 blocked, and
that number moves with this one — it is the largest single argument in the catalogue for the
Python sandbox, and it is why `expected-output` and `code` are the types this course reaches for
and `EXECUTOR.md` is the document that decides what a student sees until then.

## Ageing

**Low.** Lesson 19 (uv, Poetry, `pyproject.toml`) is the packaging churn and it is one lesson; the rest of the language is settled.

## Flags

**1 ·** **Free, ninety hours, nine dependents, nine tracks — the most valuable free course the catalogue could have.** It is position 1 of `data-science`, a track that continues nothing, so `C-28` gives it away correctly. With `security-fundamentals` it is the second working case of the rule, and it is a far stronger conversion instrument than `web-fundamentals`: a visitor who finishes it can enter eight other tracks.

**2 ·** **And it is the largest free thing the platform serves**, which is exactly the cost `C-28` worries about. Ninety hours of video at unmetered egress is the arithmetic that decision was sized on, and this course is bigger than the one it was sized for.

**3 ·** **The plainest sandbox in the catalogue, and the one with the most behind it.** No browser, no database, no account, no cluster — an interpreter and a file. Nine dependents wait on it. If the sandbox ships one runtime after a shell, the reach argument says Python and the `sql-databases` argument says a database; **those are the two, and they are not in conflict.**
