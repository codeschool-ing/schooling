---
title: macOS: launchd and Login Items
version: 1
---

On a Mac, PID 1 is **`launchd`**, lesson 1's name for the same job. It starts services and scheduled
jobs from small XML files called **property lists**, `.plist`:

| folder | what lives there |
|---|---|
| `/System/Library/LaunchDaemons` | Apple's own system services; do not touch |
| `/Library/LaunchDaemons` | system services other software installed |
| `/Library/LaunchAgents`, `~/Library/LaunchAgents` | jobs that run in a person's session |

```sh
launchctl list | head                         # what launchd is running for this user
sudo launchctl list | grep -v com.apple        # system services not from Apple
ls /Library/LaunchDaemons ~/Library/LaunchAgents
```

**None of those were run for this lesson.** A plist can say *keep this running* like a service, or
*run at 02:00* with a `StartCalendarInterval`, like a timer; launchd does both jobs. cron still works on
a Mac, and Apple recommends launchd instead.

**Login Items**, in *System Settings > General*, is the Mac's *Startup apps*: what opens when a person
signs in, and a list of background items each app has added. Software that "keeps coming back" after
being quit is usually one of those.

## The same three questions everywhere

For any machine, whichever system:

1. *What runs in the background*, and does anybody need it?
2. *What starts at boot or at login*, and is that list short?
3. *What is scheduled*, when, in which time zone, and has it been **tested by running it now**?
