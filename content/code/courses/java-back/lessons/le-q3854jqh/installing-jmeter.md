---
title: Installing JMeter
version: 1
---

**Apache JMeter** is a load generator: it plays many clients at once, records how each request
went, and summarises the lot. It is written in Java, has been around since 1998, and is still the
tool most Java teams meet first.

Ubuntu's archive has a `jmeter` package, and it is the wrong one to install:

```
RUN-APT
```

2.13 is a release from 2015, three major versions behind. JMeter comes instead from the Apache
Software Foundation's own downloads, as one archive that unpacks into a directory and needs no
installer. This lesson uses 5.6.3. Like Gradle in lesson 2, it goes into `~/opt`, which needs no
`sudo`.

## The archive, and its checksum

Apache keeps every release at `archive.apache.org`, with a checksum file beside each archive:

```
ana@vm:~$ curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz
ana@vm:~$ curl -sLO https://archive.apache.org/dist/jmeter/binaries/apache-jmeter-5.6.3.tgz.sha512
ana@vm:~$ ls -l apache-jmeter-5.6.3.tgz*
-rw-r--r-- 1 ana ana 87414762 Oct 22 20:15 apache-jmeter-5.6.3.tgz
-rw-r--r-- 1 ana ana      154 Oct 22 20:15 apache-jmeter-5.6.3.tgz.sha512
```

Lesson 2 compared a checksum by eye. Apache's `.sha512` file is written in the format `sha512sum`
itself reads: the hash, then the file name, with a `*` in front of it that means the file is read
as binary. So `-c` can do the comparison:

```
ana@vm:~$ cat apache-jmeter-5.6.3.tgz.sha512
5978a1a35edb5a7d428e270564ff49d2b1b257a65e17a759d259a9283fc17093e522fe46f474a043864aea6910683486340706d745fcdf3db1505fd71e689083 *apache-jmeter-5.6.3.tgz
ana@vm:~$ sha512sum -c apache-jmeter-5.6.3.tgz.sha512
apache-jmeter-5.6.3.tgz: OK
```

**`OK` means the 128 hexadecimal characters of the published hash match the bytes on your disk.**
Anything else, `FAILED` or a complaint that the file is missing, means the archive is not the one
Apache published, and it is deleted rather than unpacked. A checksum from the same server proves
the download is complete and undamaged; proving who made the file needs the signature in the
`.asc` file beside it and the release manager's public key, which this lesson does not check.

## Unpacking it

```
ana@vm:~$ mkdir -p ~/opt && tar -xzf apache-jmeter-5.6.3.tgz -C ~/opt
ana@vm:~$ ls ~/opt/apache-jmeter-5.6.3 ~/opt/apache-jmeter-5.6.3/bin | head -n 14
/home/ana/opt/apache-jmeter-5.6.3:
LICENSE
NOTICE
README.md
bin
docs
extras
lib
licenses
printable_docs

/home/ana/opt/apache-jmeter-5.6.3/bin:
ApacheJMeter.jar
BeanShellAssertion.bshrc
```

`bin` holds the `jmeter` script and its settings, `lib` the jars, `docs` the manual. The plans in
`bin/templates` and `bin/examples` are worth opening once.

Unlike Gradle, which only ran once before its wrapper took over, `jmeter` is a command you will
type again and again, so its `bin` goes on your `PATH`. The line goes at the end of `~/.bashrc`,
which every new interactive shell reads:

```
ana@vm:~$ echo 'export PATH="$HOME/opt/apache-jmeter-5.6.3/bin:$PATH"' >> ~/.bashrc
```

Open a new terminal, or run `source ~/.bashrc` in this one, and ask for it:

```
ana@vm:~$ command -v jmeter
/home/ana/opt/apache-jmeter-5.6.3/bin/jmeter
ana@vm:~$ jmeter --version
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
    _    ____   _    ____ _   _ _____       _ __  __ _____ _____ _____ ____
   / \  |  _ \ / \  / ___| | | | ____|     | |  \/  | ____|_   _| ____|  _ \
  / _ \ | |_) / _ \| |   | |_| |  _|    _  | | |\/| |  _|   | | |  _| | |_) |
 / ___ \|  __/ ___ \ |___|  _  | |___  | |_| | |  | | |___  | | | |___|  _ <
/_/   \_\_| /_/   \_\____|_| |_|_____|  \___/|_|  |_|_____| |_| |_____|_| \_\ 5.6.3

Copyright (c) 1999-2024 The Apache Software Foundation
```

The banner and the version are the answer. The four `WARN StatusConsoleListener` lines come from
the logging library inside JMeter, which disapproves of how JMeter's own configuration file names
its plugins; JMeter 5.6.3 prints them on every start, and they say nothing about your plan.

JMeter runs on the same JDK 25 as everything else in this course. It needs no other Java.
