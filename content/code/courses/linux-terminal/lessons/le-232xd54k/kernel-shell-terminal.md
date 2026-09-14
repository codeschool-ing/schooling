---
title: Kernel, shell, terminal — three things, one word
version: 1
---

People say "the terminal" for all three of these, and most of the time nobody is harmed. It starts
costing you the first time something breaks, because **the three fail differently and the error
message tells you which one it was** — if you know there are three.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 336\" role=\"img\" aria-label=\"Four layers stacked: you at the top, then the terminal emulator, then the shell, then the kernel, then the hardware. Arrows run down the stack. Beside each layer is the failure it produces: a mangled screen from the terminal, command not found from the shell, permission denied from the kernel.\"><defs><marker id=\"ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"ahd\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"190\" y=\"14\" width=\"300\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">You</text><rect x=\"190\" y=\"68\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"85.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Terminal emulator</text><text x=\"340.0\" y=\"103.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">draws characters, sends keys</text><text x=\"506\" y=\"84\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">a mangled screen</text><text x=\"506\" y=\"98\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the drawing is confused,</text><text x=\"506\" y=\"110\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">not the command</text><rect x=\"190\" y=\"140\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Shell — bash</text><text x=\"340.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">reads the line, finds the program</text><text x=\"506\" y=\"156\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">bash: fooo: command not found</text><text x=\"506\" y=\"170\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">it looked, and there is</text><text x=\"506\" y=\"182\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no such program</text><rect x=\"190\" y=\"212\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"229.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Kernel — Linux</text><text x=\"340.0\" y=\"247.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">processor, memory, disk, network</text><text x=\"506\" y=\"228\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Permission denied</text><text x=\"506\" y=\"242\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the shell asked, and</text><text x=\"506\" y=\"254\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the kernel refused</text><rect x=\"190\" y=\"284\" width=\"300\" height=\"38\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"340.0\" y=\"303.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Hardware</text><path d=\"M340 48 L340 66\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 118 L340 138\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 190 L340 210\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><path d=\"M340 262 L340 282\" stroke=\"var(--paper)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ah)\"></path><text x=\"172\" y=\"43\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">you type</text><text x=\"172\" y=\"165\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">the only layer</text><text x=\"172\" y=\"178\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">this course teaches</text><text x=\"172\" y=\"237\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">the only one that is</text><text x=\"172\" y=\"250\" text-anchor=\"end\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">not just a program</text><text x=\"340\" y=\"326\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">read the first word: it names the layer</text></svg>", "caption": "Three of the four are ordinary programs and one is not. When something refuses you, the message says which layer said no."}
```

## The kernel

The kernel is the program that owns the machine. It is loaded when the computer starts and it does
not stop until the computer does.

It has the hardware: the processor's time, memory, disks, the network card. It decides which
program runs next and for how long. It knows which files exist and who may open them. Nothing else
touches the hardware directly — a program that wants to read a file **asks the kernel**, and the
kernel decides.

That last sentence is where permissions come from, and it is worth holding on to. When lesson 4
tells you a file is readable by its owner and nobody else, the thing enforcing that is the kernel,
at the moment of asking. It is not a convention that programs politely follow.

**"Linux" is the kernel and nothing else.** Strictly, that is all Linus Torvalds' project is: the
one program in the middle. Everything you will type in this course — `ls`, `grep`, `bash` itself —
came from somewhere else, mostly the GNU project. That is the whole of the "GNU/Linux" argument you
will see people having, and now you know what it is about.

You never talk to the kernel directly. You talk to something that does.

## The shell

The shell is a program that reads a line you typed, works out what you meant, and runs it.

That is the entire job, and the most useful thing to understand about it is how ordinary it is:
**the shell is just a program**, like `ls` is a program. It has a name, it lives in a file, it can
be started and stopped, and you can replace it with a different one. It is not part of Linux. It is
not privileged. It is a program whose job happens to be starting other programs.

A loop, roughly:

1. print a prompt;
2. wait for you to type a line and press enter;
3. expand what you wrote — `*` becomes a list of files, `$HOME` becomes your home directory;
4. find the program you named;
5. ask the kernel to run it, and wait for it to finish;
6. print the prompt again.

Step 3 is the one that surprises people later, and section 10 of lesson 3 comes back to it: **the
expansion is the shell's, not the command's.** When you type `rm *.txt`, `rm` never sees the `*` —
it receives a list of filenames the shell built first.

**Which shell am I in?** Several exist — `bash` is the common default on Linux, `zsh` on macOS,
`dash` as the small strict one, `fish` for people who want a friendlier set of trade-offs. Two ways
to ask, and they answer two different questions:

```
ana@vm:~$ echo $0
bash
ana@vm:~$ echo $SHELL
/bin/bash
```

`$0` is **the shell running right now**. `$SHELL` is the shell **your account is set to start when
you log in**. They are usually the same and the difference matters exactly when it bites you: if
you type `zsh` and get a zsh, `$0` says `zsh` and `$SHELL` still says `/bin/bash`, because your
account has not changed. Trust `$0` for "what am I typing into".

This course is a bash course. Where something is bash-specific rather than POSIX, it says so.

## The terminal

The terminal is the window. It draws the characters, sends your keystrokes onward, and handles the
fact that text arrives in colours and moves the cursor around.

The name is a museum piece, and knowing that makes the behaviour make sense. A terminal was once a
physical object: a keyboard and a screen, on a desk, wired to a computer in another room. A
*terminal emulator* is a program pretending to be one of those, and the pretence goes deep enough
that it still has a device file:

```
ana@vm:~$ tty
/dev/pts/0
```

`pts` is "pseudo-terminal, slave" — the modern software stand-in for a cable to a machine in the
basement. Your shell believes it is talking to hardware. It is talking to a window.

What you are actually using is one of these: GNOME Terminal, Konsole, Windows Terminal, iTerm2,
Alacritty, Kitty, the black rectangle that opens when you run `wsl`. **They are interchangeable and
none of them is Linux.** Choosing one is like choosing a text editor for writing email — a matter
of preference that changes nothing about what you can do.

## Why the three-way split earns its keep

Because the failure tells you where to look, and that is most of debugging:

| what you see | which layer | what it means |
|---|---|---|
| `bash: fooo: command not found` | **the shell** | it looked for a program called `fooo` and there is none. The message even names itself: `bash:` |
| `Permission denied` | **the kernel** | the shell found it and asked; the kernel refused |
| `Killed` | **the kernel** | the kernel stopped the program, usually because memory ran out (lesson 11) |
| a mangled screen, text in the wrong place | **the terminal** | the drawing is confused, not the command — `reset` usually fixes it |
| nothing happens, no new prompt | **the program** | it is running and has not finished. `Ctrl+C` is how you say stop, and section 8 explains what that key actually sends |

Read the prefix on an error. `bash:` means bash is telling you. `ls:` means `ls` is telling you.
`sudo:` means sudo is. The program that printed the message is the program that has a problem, and
half the questions people ask are answered by the first word of the line they pasted.

## The stack in one sentence

**You type into a terminal, which feeds a shell, which asks the kernel, which owns the machine.**

Four things, three of which are ordinary programs and one of which is not. The rest of this course
spends its time at the second layer — the shell is the tool you are learning — and the reason it
was worth naming all four is that when you are stuck, knowing which one is refusing you is very
nearly the answer.
