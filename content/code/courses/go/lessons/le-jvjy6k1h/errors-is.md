---
title: "errors.Is: is that error anywhere in the chain?"
version: 1
---

Lesson 32 checked every error with `err != nil`, and for that question `!=` is exactly right. The habit
that follows from it is to compare against a particular error the same way: `err ==
fs.ErrNotExist`, "is this a missing file?". **After one wrap that comparison is false, whatever
is inside.** Here is a `main` for the program of section 02, with `readConfig` and `start`
unchanged, asking the question four ways:

```go
func main() {
	err := start()
	fmt.Println("==           ", err == fs.ErrNotExist)
	fmt.Println("errors.Is    ", errors.Is(err, fs.ErrNotExist))
	fmt.Println("os.IsNotExist", os.IsNotExist(err))
	fmt.Println("permission   ", errors.Is(err, fs.ErrPermission))

	if errors.Is(err, fs.ErrNotExist) {
		fmt.Println("no settings.json: starting with the defaults")
	}
}
```

```
ana@vm:~/is-as-is$ go run .
==            false
errors.Is     true
os.IsNotExist false
permission    false
no settings.json: starting with the defaults
```

`==` compares the value it is given, and the value `start` returned is the outermost
`*fmt.wrapError` of section 02's figure. That is not `fs.ErrNotExist` and never will be, however
many layers deep the missing file sits. **`errors.Is(err, target)` asks the same question of every
link in the chain**, starting with `err` itself, and says `true` as soon as one link matches. The
last line is the shape it takes in real code: a branch that does something sensible about one
particular failure, here starting with default settings, and lets every other error through.

The fourth line matters as much as the second. `errors.Is` does not answer "is there an error"; it
answers "is *this* error in there", and a missing file is not a permission problem.

## The older function that does not unwrap

`os.IsNotExist` answered `false` to the same chain. It is older than wrapping, and its own
documentation says so:

```
ana@vm:~/is-as-is$ go doc os.IsNotExist
package os // import "os"

func IsNotExist(err error) bool
    IsNotExist returns a boolean indicating whether its argument is known
    to report that a file or directory does not exist. It is satisfied by
    ErrNotExist as well as some syscall errors.

    This function predates errors.Is. It only supports errors returned by the os
    package. New code should use errors.Is(err, fs.ErrNotExist).

```

You will still meet `os.IsNotExist`, `os.IsExist` and `os.IsPermission` in older code. They work on
an error straight from the `os` package and fail silently on the same error after one `%w`, which
is the kind of bug that appears the day somebody adds context to a message. The variable is also
spelled two ways, and the two are one: `os.ErrNotExist` is `fs.ErrNotExist` under another name.

```
ana@vm:~/is-as-is$ go doc os.ErrNotExist | grep NotExist
	ErrNotExist   = fs.ErrNotExist   // "file does not exist"
```

## What "matches" means

Look at that comment, `"file does not exist"`, and then at section 02's chain, whose bottom link
said `no such file or directory`. **The chain never contained `fs.ErrNotExist` at all.** Its last
link was a `syscall.Errno`, and this program checks it directly:

```go
func main() {
	_, err := os.ReadFile("settings.json")
	inner := errors.Unwrap(err)
	fmt.Println(inner == fs.ErrNotExist)
	fmt.Println(inner == syscall.ENOENT)
	fmt.Println(syscall.ENOENT.Is(fs.ErrNotExist))
}
```

```
ana@vm:~/is-as-errno$ go run .
false
true
true
```

The link is `syscall.ENOENT`, the system's code for a missing file, and it is not equal to
`fs.ErrNotExist`. What it has is a method `Is(error) bool`, and that method says yes when asked
about `fs.ErrNotExist`. **`errors.Is` counts a link as a match if it equals the target or if the
link's own `Is` method claims it.** That is how one portable question, "is this a missing file",
gets a yes from the operating system's numeric answer underneath. Your own error types can have an
`Is` method too, though most never need one.

## `%v` cuts the chain

Section 02's chain exists because every layer used `%w`. Change one of them to `%v`, the verb
lesson 33 used for adding words without wrapping, and run the same loop and the same question:

```go
		return nil, fmt.Errorf("read config: %v", err)
```

```
ana@vm:~/is-as-cut$ go run .
start server: read config: open settings.json: no such file or directory
*fmt.wrapError       start server: read config: open settings.json: no such file or directory
*errors.errorString  read config: open settings.json: no such file or directory
false
```

The first line is word for word what section 02 printed. Underneath it, the chain is two links
long: `readConfig` now returns an `*errors.errorString`, the type `errors.New` makes, holding a
copy of the text and nothing else. The `*fs.PathError` and the `syscall.Errno` are gone, so
`errors.Is` answers `false` and the program above would no longer start with the defaults.
**Nothing in the printed message tells you the chain was cut**; only the code that inspects the
error finds out, and it finds out by taking the wrong branch.
