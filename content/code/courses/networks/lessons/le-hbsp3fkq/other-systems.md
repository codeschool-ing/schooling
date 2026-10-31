---
title: SSH from Windows and macOS
version: 1
---

The client in this lesson is OpenSSH, and Windows and macOS ship it too:

```schooling-example
{"language": "sh", "parts": [
 {"code": "ssh ana@192.168.10.10", "note": "Windows 10 and 11, in PowerShell: the same OpenSSH client."},
 {"code": "ssh-keygen -t ed25519", "note": "Windows: the keys go to `C:\\Users\\<you>\\.ssh`."},
 {"code": "Get-Service ssh-agent | Set-Service -StartupType Automatic\nStart-Service ssh-agent", "note": "Windows, both lines as administrator: the agent is off by default."},
 {"code": "type $env:USERPROFILE\\.ssh\\id_ed25519.pub | ssh ana@192.168.10.10 \"cat >> ~/.ssh/authorized_keys\"", "note": "Windows has no `ssh-copy-id`."},
 {"code": "ssh-add --apple-use-keychain ~/.ssh/id_ed25519", "note": "macOS: keep the passphrase in the keychain."}
]}
```

**None of these were run for this lesson.** Windows 10 and 11 ship the same OpenSSH client, so `ssh`,
`ssh-keygen` and `~/.ssh/config` work in PowerShell as they did here, with the files under
`C:\Users\<you>\.ssh`. The agent is a Windows service that starts disabled, and there is no
`ssh-copy-id`; the `type … | ssh` line does its job, as long as `~/.ssh` already exists on the server.

**PuTTY** is the other client many offices use. It keeps its own list of saved sessions and its own
key format, `.ppk`; PuTTYgen makes keys and converts between the two formats, and Pageant is its agent.

macOS has OpenSSH in the Terminal, and `ssh-add --apple-use-keychain` stores the passphrase in the
keychain, so it survives a restart. Whatever the client, the host key question and the changed-key
warning mean what sections 02 and 12 said.
