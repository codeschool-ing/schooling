---
title: Every argument is a copy
version: 1
---

Most people come to Go from a language where handing an object to a function lets the function
change it. In Python, a function that runs `p.score += 1` on the player it was given changes the
caller's player, and Java and JavaScript behave the same way. Go has structs where those languages
have objects, and the habit comes along with the syntax. It is the first idea to drop. **A Go call
copies each argument into a new variable that belongs to the function, whatever the argument's
type.** Lesson 11 showed it for an array. Here it is for an `int`, a struct, and a struct with an
array inside, all in `~/byvalue`:

```schooling-example
{
  "language": "go",
  "file": "main.go",
  "parts": [
    {
      "code": "package main\n\nimport \"fmt\"\n\ntype Player struct {\n\tName  string\n\tScore int\n\tLast  [3]int\n}\n",
      "note": "A struct with a string, an `int` and an array of three `int`. Nothing in the declaration says how a `Player` is passed, because there is only one way."
    },
    {
      "code": "\nfunc double(n int) {\n\tn = n * 2\n}\n",
      "note": "**`n` is the function's own variable**, created for this call and filled with the argument's value. Doubling it changes that variable and nothing outside."
    },
    {
      "code": "\nfunc win(p Player) {\n\tp.Score++\n\tp.Last[0] = 100\n}\n",
      "note": "**`p` is a whole second `Player`**: the name, the score and all three elements of the array were copied into it. `p.Score++` and `p.Last[0] = 100` change the copy."
    },
    {
      "code": "\nfunc main() {\n\tn := 21\n\tdouble(n)\n\tfmt.Println(n)\n",
      "note": "`double(n)` leaves `n` at 21, the first line of the output."
    },
    {
      "code": "\n\tana := Player{Name: \"Ana\", Score: 10}\n\twin(ana)\n\tfmt.Println(ana)\n",
      "note": "After `win(ana)` the caller's player still has a score of 10 and an array of zeros. Nothing `win` did reached `ana`."
    },
    {
      "code": "\n\tbia := ana\n\tbia.Name = \"Bia\"\n\tbia.Last[1] = 50\n\tfmt.Println(ana)\n\tfmt.Println(bia)\n}\n",
      "note": "**Assigning copies exactly as calling does.** `bia` is a second `Player`, so renaming it and writing into its array leave `ana` as it was: the last two lines differ."
    }
  ],
  "output": "21\n{Ana 10 [0 0 0]}\n{Ana 10 [0 0 0]}\n{Bia 10 [0 50 0]}"
}
```

```
ana@vm:~/byvalue$ go run .
21
{Ana 10 [0 0 0]}
{Ana 10 [0 0 0]}
{Bia 10 [0 50 0]}
```

A parameter is an ordinary local variable that the call fills in before the function's first line
runs. The function can read it, change it and throw it away, and none of that is visible outside,
because the caller's variable was never handed over, only its value. `fmt.Println` prints a struct
as its fields in braces, `{Ana 10 [0 0 0]}`; lesson 15 is the lesson about structs.

The struct carried an array, and the array was copied with it: `bia.Last[1] = 50` wrote into
`bia`'s three `int` and left `ana`'s alone. **A copy of a struct is as deep as the struct's own
fields**, and an array field is part of the struct, every element of it. Section 03 is about the
fields that are not, the ones that hold a pointer to something stored elsewhere.

## Getting a change back out

A function that has to change a value has two ways to get the change to the caller. The first is
the one lesson 11 used for `append`: return the new value and let the caller store it.

```go
package main

import "fmt"

type Player struct {
	Name  string
	Score int
}

func win(p Player) Player {
	p.Score++
	return p
}

func main() {
	ana := Player{Name: "Ana", Score: 10}
	ana = win(ana)
	fmt.Println(ana)
}
```

```
ana@vm:~/byvalue-return$ go run .
{Ana 11}
```

Three copies happened in that program. `ana` was copied into `p`, `p` was copied out as the result,
and the result was copied into `ana` by the assignment. What you can read off the call is the
useful part: **`ana = win(ana)` says, at the call, that `ana` changes**, and a reader does not have
to open `win` to find out.

The second way is to pass the address of `ana` instead of `ana`, so that the function can reach
the caller's variable through it. That is a pointer, and lesson 23 is about them. The rule does not
bend for pointers either. A pointer is a value like any other, and passing one copies it; what it
copies is an address.

## Assignments, results and loops copy too

The call is one place a value is copied, and the same copy happens everywhere a value moves into a
variable: `bia := ana` above, the result of `win` stored back into `ana`, and the variable a
`range` loop hands you on each turn, which lesson 17 showed is a copy of the element and not the
element. Once that is the picture, the question for any piece of Go code is not "is this passed by
value or by reference?", because the answer is always the first. The question is **what does this
type's value contain**, and section 03 answers it for the types where the answer surprises people.
