---
title: Certificates on Windows and macOS
version: 1
---

The ideas are the same everywhere; the stores and the tools are not:

```sh
certlm.msc                                   # Windows: the computer's certificate stores
certmgr.msc                                  # Windows: the signed-in user's stores
certutil -addstore Root office-ca.crt        # Windows, as administrator: trust a root for the whole PC
Get-ChildItem Cert:\LocalMachine\Root       # Windows PowerShell: the trusted roots
security find-certificate -a -c "Example" /Library/Keychains/System.keychain   # macOS
sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain office-ca.crt   # macOS
```

**None of these were run for this lesson.** On Windows, `certlm.msc` opens the computer's stores and
`certmgr.msc` the current user's; a root trusted for the whole PC goes in *Trusted Root Certification
Authorities* of the computer, which is what `certutil -addstore Root` does. In an office with a Windows
domain, roots like the office CA are pushed to every PC by Group Policy rather than installed by hand.

On a Mac, *Keychain Access* shows the same, and the `security` command adds a root to the system
keychain. In any browser, the padlock (or the icon beside the address) opens the certificate the site
sent: its names, its dates and its chain, the three things that section 06's failures are about.
