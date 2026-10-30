---
title: The editor, the preview, and the limits
version: 1
---

**Cloud Shell comes with an editor**, opened from the terminal's toolbar or with `cloudshell edit FILE`, that
edits the files in your home directory in the browser. It is built on the open-source core of Visual Studio
Code, with Google's extensions for its own services, and it is a reasonable place to change a Terraform file
during an incident from a borrowed computer. It is not a reason to keep work in Cloud Shell: the files are
still in the home directory of the previous section, with its rules.

## Web preview

A program in Cloud Shell can listen on a port, and **web preview** opens it in your browser through Google's
proxy, on port 8080 unless another is chosen. Only you can open that address: it is authenticated as your
Google account. It is how a small web application is tried before anything is deployed, and it is the only way
anything inside Cloud Shell can be reached from outside.

## The limits that shape it

Cloud Shell is a free machine shared by everybody who opens one, and it is rationed. Google documents:

- **a weekly quota of hours** of use, after which Cloud Shell refuses to start until the quota renews;
- **a maximum length for one session**, and an end to any session left idle for a while;
- **a small home directory**, a few gigabytes;
- **an ephemeral mode**, chosen per session, with no home directory at all: everything is gone when it ends.

The numbers change, which is why they are not here; the Cloud Shell documentation's page on limits has them.

## Two things to decide before relying on it

**It acts as you.** A script pasted into Cloud Shell runs with every role your account holds, in every project,
with no confirmation. For an engineer with production roles that is the same exposure as their laptop, in a
place where it is easier to paste a command found on the internet. The planner's rule from lesson 22 applies
here too: production through a service account, impersonated, never as oneself.

**It can be switched off.** A Google Workspace or Cloud Identity administrator, lesson 10, can disable Cloud
Shell for the organisation's users. A company whose engineers must work only from managed machines does that,
and a runbook that says *open Cloud Shell* is then a runbook that fails on the night it is needed. The
planner's runbooks say what to type, and assume only a terminal with gcloud: Cloud Shell, or the laptop of
lesson 1.
