---
title: What makes a site an app
version: 1
---

**A Progressive Web App is a website that a browser can install.** Installed, it gets an icon on the home
screen or in the list of applications, opens in a window of its own with no address bar, and keeps working
offline if its service worker says how. Nothing about it is compiled for a platform: it is the same HTML,
CSS and JavaScript, from the same server, with the same address.

Three things make a site installable, and the planner has two of them already:

| what | why | the planner |
|---|---|---|
| **HTTPS**, or `localhost` | an installed app is trusted with a window and an icon of its own | `localhost`, since lesson 1 |
| **a service worker** | so the app opens when the network does not | since lesson 10 |
| **a web app manifest** | the app's name, its icons, the window it wants and the page it starts at | the next section |

**Recent Chromium versions no longer insist on the service worker** for installation; a manifest with a
name and an icon is enough. An installed app that shows the browser's offline
error is a poor app, though, which is why lesson 10 came first.

## Which browsers install

**Chrome and Edge** on desktop and Android install from the address bar or the menu, and fire an event a
page can use to offer it itself. **Safari** on iOS and iPadOS installs through the share menu, *Add to Home
Screen*, and on macOS through *Add to Dock*; it fires no such event, so a page can only explain how. **Firefox**
on Android adds a site to the home screen; on desktop its support has come and gone, so check the version in
front of you. A site that works as an app works in all of
them as a site, which is the *progressive* in the name.

**What installing does not do** is put the app in an app store, give it access to more of the device than the
site had, or make it faster. The speed is the previous ten lessons'; installing is how a person keeps it at hand.
