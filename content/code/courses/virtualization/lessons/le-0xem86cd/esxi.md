---
title: VMware ESXi
version: 1
---

**ESXi** is VMware's type 1 hypervisor. It is installed on a server's own disk, and its screen, the **DCUI**, is a yellow and grey page showing the server's address. Pressing F2 there
opens a small menu for the few things that cannot wait for the network: the root password, the
management address, restarting the management agents. Everything else is done from a browser.

Each ESXi server has its own web page, the **Host Client**, at `https://` followed by its address and
`/ui`. It creates and runs machines, and it is enough for one server. With several, companies add
**vCenter**, a separate appliance that manages all of them as one, which is section 03.

**ESXi's terms changed in 2024 as well.** Broadcom ended the free edition that labs had used for years
and moved the paid ones to subscriptions; some of that has changed again since. A lab on ESXi is only
worth planning once you have checked what it costs today, and Proxmox, lesson 6, is where most people
went instead.

Its command line is reached over SSH, when an administrator enables it, and looks like this:

```sh
esxcli system version get          # the ESXi version and build
esxcli network ip interface ipv4 get   # the host's own addresses
esxcli storage filesystem list     # the datastores this host sees
vim-cmd vmsvc/getallvms            # every VM registered on this host, with its id
vim-cmd vmsvc/power.getstate 12    # whether VM 12 is on
vim-cmd vmsvc/power.shutdown 12    # ask VM 12's guest to shut down, through VMware Tools
```

**None of these were run for this lesson**; ESXi is not installed on the course's host and cannot be.
