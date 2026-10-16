---
title: What the iOS simulator hides
version: 1
---

**The simulator hides more than the emulator, because it imitates less**: there is no virtual
iPhone under it, only the Mac. What it shows well is the app's own behaviour, its screens on every
iPhone size Apple lists, its text in every language, its permission prompts and its handling of
boxoffice's answers. What it cannot show is anything that belongs to the phone. This section was
written without a Mac, as lesson 18 said of everything iOS in this course, and **Apple's own
Simulator documentation lists the hardware and frameworks it lacks**; that list changes with every
Xcode, so read it for the version you use.

## A different binary

The app in the simulator is built for the Mac's processor. The app on an iPhone is built again, for
the phone's processor, with the settings of a device build, and it is signed with the team's
certificate. So **the simulator never runs the file a user installs.** A defect that comes from the
device build, a setting that differs between the two, or a permission that only a signed app on a
phone is checked for, shows up for the first time on a phone. The commonest case is signing itself:
the simulator asks for none of the provisioning a phone checks, so a build whose signing is set up
wrong runs in the simulator every day and refuses to install on the first real iPhone.

## No phone's limits

The simulator has the Mac's memory and the Mac's processor. iOS on a phone closes an app that uses
too much memory, and on an older iPhone that limit is low; in the simulator the same app keeps
running. Everything is faster, too, so a screen that takes a second to build on an old iPhone
appears at once. **Speed and memory are questions for a phone**, the oldest one your users still
carry.

## No phone's hardware

At the time of writing, the simulator has no camera to read a ticket's QR code with, and its motion
and location are whatever you set from its *Features* menu, with no drift and no walking. Anything
that touches the radio, such as the mobile network, Bluetooth or a phone call arriving, is either
missing or imitated. Its network is the Mac's, steady and fast, which made lesson 18 easy and makes
a lift or a tunnel impossible to meet by accident.

## The same rule as the emulator

None of this makes the simulator a poor tool. It is where most iOS tests should run, for the same
reason most Android tests run on the emulator: it is quick, it resets cleanly, and it is wrong only
in places you can name. **The skill is knowing which places**, and the next section puts both
platforms in one table.
