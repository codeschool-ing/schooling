---
title: Installing JMeter, and where its window fits
version: 1
---

Apache JMeter is the oldest load testing tool in this course and still among the most used: a
Java program, first released in 1998, that builds tests in a desktop window and runs them anywhere
Java runs. It is distributed as one archive with nothing to compile. Java 21 is already on the
machine from lesson 1, so installing JMeter is a download and an unpack, in your home directory:

```sh
cd ~
curl -fsSLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
tar -xzf apache-jmeter-5.6.3.tgz
```

**Those three lines were not run for this course**: the machine in the transcripts had the same
archive unpacked the same way, into `~/apache-jmeter-5.6.3`. The programs are in its `bin`
directory. Two links put the two you need on the path, and the first call prints the version:

```
ana@nft:~$ sudo ln -s ~/apache-jmeter-5.6.3/bin/jmeter ~/apache-jmeter-5.6.3/bin/jmeter-server /usr/local/bin/
ana@nft:~$ jmeter --version
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Oct 10, 2026 4:52:01 PM java.util.prefs.FileSystemPreferences$1 run
INFO: Created user preferences directory.
    _    ____   _    ____ _   _ _____       _ __  __ _____ _____ _____ ____
   / \  |  _ \ / \  / ___| | | | ____|     | |  \/  | ____|_   _| ____|  _ \
  / _ \ | |_) / _ \| |   | |_| |  _|    _  | | |\/| |  _|   | | |  _| | |_) |
 / ___ \|  __/ ___ \ |___|  _  | |___  | |_| | |  | | |___  | | | |___|  _ <
/_/   \_\_| /_/   \_\____|_| |_|_____|  \___/|_|  |_|_____| |_| |_____|_| \_\ 5.6.3

Copyright (c) 1999-2024 The Apache Software Foundation
```

The four `WARN StatusConsoleListener` lines come from the logging library JMeter 5.6.3 ships with,
and every JMeter command prints them. They are harmless, and they appear in every transcript of
this lesson, because a transcript prints what the program printed. The two lines about user
preferences appear only the first time Java runs.

## The window, and why runs do not use it

`jmeter` with no arguments opens the **GUI**, a tree of elements on the left and the settings of
the selected one on the right. It is the comfortable way to build a plan: right-click an element,
*Add*, pick a sampler or a timer from a menu, fill in its fields, and *File → Save* writes the
`.jmx`. It also has listeners that show each request and response as they happen, which is how a
plan is debugged, with one or two users, before it is trusted.

The VM has no desktop, so the GUI does not run there. **Running it means JMeter on your own
computer**, where you have a screen: install Java and unpack the same archive there, or on
Windows use the `jmeter.bat` in the same `bin` directory. Build and debug the plan there, then copy
the `.jmx` into the VM with `multipass transfer plan.jmx nft:loadtest/`. None of that was run for
this course, which has no desktop either; the plan in the next section was written by hand.

The run itself is never done from the window, and JMeter says so in the terminal it was started
from, every time the GUI opens. **A load test runs in non-GUI mode**, `jmeter -n`, for three reasons:

- The GUI draws every sample it collects. At a few hundred requests a second, that drawing takes
  processor time and memory from the threads that are supposed to be sending requests, and the
  result describes JMeter's window as much as the system under test.
- A non-GUI run is a command, so it can be scripted, repeated exactly, and run by a pipeline,
  which lesson 11 does.
- It runs on a machine with no screen, which is where a load generator belongs: close to the
  system under test, and on hardware of its own.
