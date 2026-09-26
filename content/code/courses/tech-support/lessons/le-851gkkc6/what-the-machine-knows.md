---
title: What a computer knows about itself
version: 1
---

Every PC's firmware carries a small table describing the machine, and `dmidecode` reads it:

```
ana@pc1:~$ sudo dmidecode -t system | grep -E "Manufacturer|Product Name|Serial Number|UUID"
        Manufacturer: QEMU
        Product Name: Ubuntu 24.04 PC (Q35 + ICH9, 2009)
        Serial Number: Not Specified
        UUID: eb9d0818-b197-423d-b984-f7fe52a6797f
ana@pc1:~$ bash /tmp/inventory.sh
"pc1","QEMU","Ubuntu 24.04 PC (Q35 + ICH9, 2009)","Not Specified","QEMU Virtual CPU version 2.5+","961 MiB","6.8G","52:54:00:8c:26:a7","24.04"
```

A laptop from a shop would say its maker's name, the model and a serial number printed on its label.
This one says **`QEMU`** and **`Not Specified`**: it is a virtual machine, and nobody gave it a serial.
That is worth knowing as a fact rather than a lab quirk, because **virtual machines are assets too**, on
paper, and they have no label to read. The organisation gives them an identifier of its own.

The script behind that last line collects the rest:

```schooling-example
{"language": "bash", "parts": [{"code": "#!/usr/bin/env bash\n# inventory.sh: one CSV line describing this computer, for the asset register.", "note": "Run on each computer; each run prints one line, and the lines together are the register's machine half."}, {"code": "maker=$(sudo dmidecode -s system-manufacturer)\nmodel=$(sudo dmidecode -s system-product-name)\nserial=$(sudo dmidecode -s system-serial-number)", "note": "**`dmidecode` reads what the firmware says about the machine**: who made it, the model, the serial number. It needs `sudo`, because the tables it reads are not open to every user."}, {"code": "cpu=$(lscpu | awk -F': +' '/^Model name/ {print $2}')\nmem=$(free -m | awk '/^Mem:/ {print $2 \" MiB\"}')", "note": "The processor's name, and the memory the system sees, in MiB: a little less than what is installed, because the kernel keeps some for itself."}, {"code": "root=$(df -h --output=size / | tail -n 1 | tr -d ' ')\nmac=$(ip -br link | awk '$1 != \"lo\" {print $3; exit}')", "note": "The size of the system's file system, and the first network card's MAC address, which is often how a computer is recognised on the network."}, {"code": ". /etc/os-release\nprintf '\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\",\"%s\"\\n' \\\n  \"$(hostname)\" \"$maker\" \"$model\" \"$serial\" \"$cpu\" \"$mem\" \"$root\" \"$mac\" \"$VERSION_ID\"", "note": "**Every field in quotes**, because a model name can contain a comma, and this one does: `Ubuntu 24.04 PC (Q35 + ICH9, 2009)`. Without the quotes, a spreadsheet would split it into two columns and shift every column after it."}]}
```

Everything in it comes from the machine, which is exactly its limit: **no command can tell you who uses
this computer, where it is, when it was bought or until when the warranty runs**. Those come from people
and from paperwork, and they are the other half of the register.
