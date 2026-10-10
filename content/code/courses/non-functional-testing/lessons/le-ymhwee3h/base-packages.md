---
title: The base packages
version: 1
---

The base is what every third of the course needs: Python for the application and two of the load
generators, Java for JMeter and Gatling, SQLite to look inside the application's database, `curl`
and `jq` to talk to it, and `git` for the lessons that scan a repository. All of it comes from
Ubuntu's own archive, in one command. In the VM's shell:

```sh
sudo apt-get update
sudo apt-get install -y curl jq sqlite3 git nano unzip xz-utils python3 python3-venv \
    python3-pip openjdk-21-jdk-headless
```

Most of what it downloads is Java: the JDK and not only the runtime, because
Gatling compiles its tests before it runs them, and a runtime cannot compile.

Then check that each piece answers:

```
ana@nft:~$ grep PRETTY /etc/os-release; python3 --version
PRETTY_NAME="Ubuntu 24.04.5 LTS"
Python 3.12.3
ana@nft:~$ java -version 2>&1 | head -1; sqlite3 --version | cut -d" " -f1; git --version
openjdk version "21.0.12.1" 2026-08-18
3.45.1
git version 2.43.0
boxoffice/seed.py
boxoffice/app.py
```

Your patch versions may be higher than these, because Ubuntu keeps publishing updates to the same
release; the major versions are what the lessons depend on. If any line says `command not found`,
the install did not finish, and "When the setup fails" is the place to look.

Everything else is installed in the lesson that first uses it:

| lesson | what it installs |
|---|---|
| 4 | JMeter, unpacked into your home directory |
| 5 | k6, one program |
| 6 | Gatling, unpacked into your home directory, and Locust in a Python virtual environment |
| 7 | Node.js, then Artillery; and Vegeta, one program |
| 10 | Lighthouse, and the Chromium that Playwright downloads for it |
| 13 | the axe engine, in a Playwright project of its own |
| 18 | gitleaks, one program |
| 21 | pip-audit, in the virtual environment from lesson 6 |
| 22 | Prometheus, from Ubuntu's archive |
