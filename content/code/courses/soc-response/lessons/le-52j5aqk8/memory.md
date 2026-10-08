---
title: Memory
version: 1
---

A disk holds what was saved. **Memory holds what was running**: processes, network connections, commands typed,
encryption keys, documents open and never saved. Lesson 13 collected the volatile state as text; a **memory
dump** is the whole of it, as bytes, for analysis later.

The lab shows the idea on one process, the smallest case. Write this as `holder.py`:

```schooling-example
{"language": "python", "file": "holder.py", "parts": [{"code": "# holder.py: a program holding a value in memory that it never writes anywhere\nimport os\nimport secrets\nimport time\n"}, {"code": "token = \"session-\" + secrets.token_hex(8)  # made here, kept only in this process", "note": "A random value, made when the program starts. It is never printed, saved or sent: the only copy is in this process's memory."}, {"code": "print(os.getpid(), flush=True)\ntime.sleep(600)", "note": "The program prints its process id, so the dump knows which process to take, and then waits ten minutes."}]}
```

Start it in the background, then dump its memory with `gcore`, which comes with the debugger `gdb` (`sudo apt
install gdb`):

```
root@soc:~/case# python3 holder.py > holder.pid &
root@soc:~/case# cat holder.pid
6340
root@soc:~/case# gcore -o mem $(cat holder.pid) 2>&1 | tail -2
Saved corefile mem.6340
[Inferior 1 (process 6340) detached]
root@soc:~/case# ls -l mem.*
-rw-r--r-- 1 root root 7955232 Oct  7 21:05 mem.6340
root@soc:~/case# strings mem.* | grep -m 1 '^session-'
session-221150b3744351ae
root@soc:~/case# sha256sum mem.*
3fbb717e63f017d61330400fb6d99453b3e167f6309fb07647490de5d7570d47  mem.6340
```

`gcore` writes the process's memory to `mem.` followed by the process id, almost 8 MB here. `strings` pulls out
every run of printable characters, and `grep` finds the value: **it was never written to a file, and the dump has
it**. The hash goes into the custody record, like any other evidence. Stop the program afterwards with
`kill $(cat holder.pid)`.

For a whole machine the principle is the same and the tools are different, and **none of them was run here**:

| step | Linux | Windows |
|---|---|---|
| acquire all of memory | AVML, LiME | WinPmem, DumpIt |
| analyse it | Volatility 3 | Volatility 3 |

**Volatility 3** reads a whole-memory image and answers questions with plugins: the process list as the kernel
saw it (`windows.pslist`, `linux.pslist`), the network connections (`windows.netscan`), the shell history still in
memory (`linux.bash`). For Linux images it needs a symbol table that matches the exact kernel, which is the usual
obstacle, and the reason to prepare one for each server build before an incident, not during it.

Two rules decide whether memory is captured at all. **It comes first**, before anything that would end it, as
lesson 13's order of volatility says. And **the capture tool changes the memory it captures**, a little, by running;
the record says which tool ran, when, and from where, so the change is known.
