---
title: When the setup fails
version: 1
---

**Most setups that fail, fail in one of six ways, and each has a symptom you can recognise.** This
section is the list. Come back to it whenever a command in a later lesson stops before it starts:
nearly always, the cause is here rather than in the lesson.

## `node` is not found, or answers with the wrong version

`command not found` right after installing almost always means the terminal was opened before the
installation changed `PATH`. Close it and open a new one. If that does not help, ask the shell where
it looks and what it finds:

```sh
echo $PATH
which -a node
```

`~/.local/bin` must be in the first answer. If the second prints **two** paths, an older Node.js
installed some other way (a system package, `nvm`, Homebrew) is being found first. Either remove
that one, or make sure `~/.local/bin` comes earlier in `PATH`. Two installations are a trap that
reopens every time a terminal starts, so settling it now is cheaper than settling it in lesson 12.

## npm says `EACCES`

`EACCES` is a permission refusal: npm tried to write somewhere your user may not. This course never
installs anything globally, and never needs `sudo` for npm. If you see it, the usual cause is a
`node_modules` or an npm cache that an earlier `sudo npm` left owned by root. Find it with
`ls -l`, and give it back to yourself with `sudo chown -R "$USER" <that folder>` rather than running
npm as root again, which makes the next refusal more likely.

## The download stalls, or fails with a certificate error

`npm install` and `npx` both fetch from `registry.npmjs.org`. A school or office network that
inspects traffic re-signs it with its own certificate, and Node.js refuses it with an error naming a
certificate in the chain. The fix belongs to that network: its administrators publish the
certificate, and `NODE_EXTRA_CA_CERTS` pointing at that file tells Node.js to trust it. **Never turn
verification off** to get past it: that makes every download from then on accept anybody's answer.
If you are on such a network and cannot get the certificate, the cloud path of the last section
avoids the problem entirely.

## The Expo CLI waits, then complains about the network

Some Expo commands ask Expo's servers which package versions match your SDK. Offline, or behind a
network that blocks them, they wait and then give up. Setting `EXPO_OFFLINE=1` in the terminal tells
the CLI to use the table of versions shipped inside the `expo` package instead, which is what it
would have been told anyway. Lesson 3's `npx expo install` is where you are most likely to need it.

## Linux: `ENOSPC: System limit for number of file watchers reached`

The development server watches every file in the project for changes, and a project with
`node_modules` has tens of thousands. Linux limits how many files one user may watch. The message is
misleading: `ENOSPC` usually means *no space on the device*, and here it means *no watchers left*.
Raise the limit, as root, and make it survive a restart:

```sh
echo fs.inotify.max_user_watches=524288 | sudo tee /etc/sysctl.d/40-watches.conf
sudo sysctl --system
```

## Windows: everything works and is very slow

A project under `/mnt/c` is on Windows' disk, and WSL reaches it through a translation layer that is
slow for many small files. `npm install` that takes minutes instead of seconds is the symptom. Move
the project into WSL's own home, `~`, and open it from there with your editor's WSL support.

## When none of these is it

Read the **first** error in the output, not the last: npm and the Expo CLI print several lines of
consequences after the cause. Search for that first line in quotation marks, with the tool's name.
And check the disk: `df -h ~` shows the space left, and a full disk makes nearly every tool in this
list fail with a message about something else.
