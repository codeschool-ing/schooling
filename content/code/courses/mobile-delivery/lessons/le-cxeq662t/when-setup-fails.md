---
title: When the setup fails
version: 1
---

**Most setups that fail here fail in one of five ways, and each one says which in its first
line.** Read the first line of the error before anything else.

## `keytool: command not found`, or `java: command not found`

There is no JDK on the terminal's `PATH`. Here keytool is asked for with a `PATH` that reaches
nothing at all, which is what a computer with no JDK looks like to the shell:

```
ana@dev:~/signing$ PATH=/nonexistent keytool -list -keystore upload.jks
bash: line 1: keytool: command not found
```

On Ubuntu and WSL, `sudo apt install openjdk-21-jdk-headless` installs it, and an interactive
terminal there may suggest the same line itself. On a Mac, install the
Temurin build of JDK 21 from Adoptium and open a new terminal.

## `sdkmanager: command not found`, or `apksigner` is missing

The two lines at the end of `~/.profile` are read when a terminal starts, so a terminal opened
before you added them does not have them. Open a new one. If it still fails, `ls ~/android` should
show `cmdline-tools`, `build-tools` and `platforms`; a `cmdline-tools` folder holding another
`cmdline-tools` instead of `latest` means the `mv` step was skipped, and sdkmanager then refuses
to start with a message about its install location.

## The wrong password

keytool cannot tell a wrong password from a damaged file, and says the same thing for both:

```
ana@dev:~/signing$ keytool -list -keystore upload.jks -storepass not-the-password
keytool error: java.io.IOException: keystore password was incorrect
```

Nothing can recover a keystore whose password is lost. That is the point of it. If this is your
upload key and the password is gone, lesson 3's account owner asks Google for an upload key reset.

## `sdkmanager` stops at the licences

Every package Google ships has terms that must be accepted once on each computer. Run
`sdkmanager --licenses`, answer `y` to each, and run the install line again.

## On Windows: keep the folders in Linux

In WSL, Windows drives appear under `/mnt/c`, and a project there is slow, because every file
access crosses from Linux to Windows. Keep `~/planner`, `~/signing` and `~/android` in your Linux
home directory, where the transcripts have them.
