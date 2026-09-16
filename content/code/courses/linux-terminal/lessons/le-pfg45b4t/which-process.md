---
title: Which process, which is the question you ask last
version: 1
---

The previous four sections find the **resource**. This one finds the
**culprit**, and it comes last on purpose: knowing that one process is using a
lot of processor tells you nothing until you know the processor is the problem.

## `pidstat`

```
ana@vm:~$ pidstat -u 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:25:38      UID       PID    %usr %system  %guest   %wait    %CPU   CPU  Command
11:25:39        0       103    0.99    0.99    0.00    0.99    1.98     3  claude
11:25:39     1001     15588   99.01    0.00    0.00    0.00   99.01     0  bash
11:25:39     1001     15589   99.01    0.00    0.00    0.99   99.01     1  bash
11:25:39     1001     15590   99.01    0.00    0.00    0.00   99.01     2  bash
11:25:39     1001     15591   98.02    0.00    0.00    1.98   98.02     3  bash
```

**`pidstat` is `top` that you can read in a script.** It samples over an
interval, prints plain lines, and has a flag per resource:

| | |
|---|---|
| `pidstat -u 1` | processor |
| `pidstat -r 1` | memory, and **page faults** |
| `pidstat -d 1` | disk |
| `pidstat -w 1` | context switches |
| `pidstat -t` | per **thread**, not per process |

Four columns above are worth naming. `%usr` and `%system` split the work the way
section 04 did. `%wait` is time the process spent **runnable but not running** —
waiting for a core — which is per-process saturation and is not in `top`. And
`CPU` is which core it was last on.

The `claude` process at 1.98% is this machine being a sandbox, as lesson 6 section
06 explained: PID 103 is the agent that drives these captures, and it is in every
process listing in this course because it is genuinely there.

## For disk

```
ana@vm:~$ pidstat -d 1 1
Linux 6.18.44-fc-v33 (vm)       09/15/26        _x86_64_        (4 CPU)

11:31:35      UID       PID   kB_rd/s   kB_wr/s kB_ccwr/s iodelay  Command
11:31:36     1001     16494      0.00 512016.00      0.00       0  bash
11:31:36     1001     16495      0.00 512000.00      0.00       0  bash
11:31:36     1001     16650      0.00  38912.00      0.00       0  dd
11:31:36     1001     16651      0.00  36864.00      0.00       0  dd
```

**That is the end of the investigation** from the disk-io section: two shells
writing 512 MB a second each, with the `dd` processes they launched underneath.

| | |
|---|---|
| `kB_rd/s` `kB_wr/s` | actually read from and written to the device |
| `kB_ccwr/s` | **cancelled** writes — dirtied and then deleted or truncated before writeback |
| `iodelay` | clock ticks the process was blocked on I/O |

`kB_ccwr/s` is a strange column with one good use: a process with large
cancelled writes is creating and deleting files, which is a temporary-file
pattern and often a mistake.

`pidstat -d` needs to read `/proc/PID/io`, which for other users' processes
needs privilege. As an ordinary user you see your own.

## `/proc/PID/io`

```
ana@vm:~$ cat /proc/self/io
rchar: 7088
wchar: 0
syscr: 10
syscw: 0
read_bytes: 0
write_bytes: 0
cancelled_write_bytes: 0
```

These are **counters since the process started**, not rates — the distinction
the next section is about.

| | |
|---|---|
| `rchar` `wchar` | bytes the process asked for, including ones served from cache |
| `read_bytes` `write_bytes` | bytes that actually went to a device |
| `syscr` `syscw` | how many read and write **calls** |

**`rchar` far above `read_bytes` means the cache is doing its job.** The other
way round is impossible; the two being equal means every read went to the disk,
which for a database is expected and for a web server is a problem.

And `syscr` enormous with `rchar` small is a program doing millions of tiny
reads, which is the pattern that shows up as `sy` in `vmstat` and is fixed by
buffering rather than by a faster disk.

## `iotop`

`iotop` is `top` for disk, and on most machines needs root because the kernel
will not report other users' I/O to you.

```sh
iotop -o          # only processes actually doing I/O
iotop -b -n 3     # batch mode, three samples — for a script or an ssh session
iotop -a          # accumulated totals rather than rates
```

It is the fastest way to answer "what is hammering the disk" interactively, and
`pidstat -d` is the one to use when you want the answer in a file.

## When nothing is obvious

Two cases where the per-process tools show nothing and the machine is still
busy.

**Kernel threads.** `kswapd` reclaiming memory, `jbd2` committing a journal,
`kworker` doing writeback. They appear in `top` with names in square brackets and
they are the kernel doing work *on behalf of* processes that have already
returned. High `kworker` I/O usually means writeback catching up.

**Something that already exited.** A cron job that runs for four seconds every
minute does not appear in a sample you took between runs. This is the argument
for `sar`, which collects continuously:

```sh
sar -u 1 3        # processor, live
sar -d -p         # disks, from today's collected history
sar -r -f /var/log/sysstat/sa15   # memory, from the 15th
```

**`sar` reads history that was recorded while nobody was watching**, which is
the only way to answer "what happened at 3am". It needs `sysstat`'s collector to
have been enabled — `systemctl enable --now sysstat` — and enabling it after the
incident helps with the next one and not this one.
