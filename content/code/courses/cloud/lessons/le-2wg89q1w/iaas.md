---
title: "IaaS: a machine, a disk and a network"
version: 1
---

**Infrastructure as a service** rents you the layers a server room used to hold, and stops there.
You get a virtual machine of the size you asked for, a disk attached to it, and a place on a virtual
network with an address. When you create the machine you choose an **image**, the operating system it
starts from, such as Ubuntu 24.04. From the moment it boots, everything from the virtual network
upwards is yours.

Amazon EC2, Azure Virtual Machines and Google Compute Engine are IaaS, and so are the machines that
smaller providers such as DigitalOcean and Hetzner rent. Lesson 4 is about the machines themselves and
lesson 5 about their disks.

## What it costs, line by line

Because IaaS is metered by the piece, a small machine can be priced from the course's sheet. Take the
smallest one in São Paulo, a 20 GB disk of the ordinary SSD kind, and a public IPv4 address so the
internet can reach it. The program below does the arithmetic; the prices are lines of the sheet, and
nothing here created a machine.

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "HOURS = 730", "note": "A month in hours: 365 days times 24, divided by 12."}, {"code": "machine = 0.01680 * HOURS", "note": "The `t3.micro` line of the sheet, on demand in `sa-east-1`: dollars per hour, times the hours in the month."}, {"code": "disk = 20 * 0.1520", "note": "20 GB of `gp3`, the ordinary SSD volume, at the sheet's price per GB-month. **A disk is billed by its size, full or empty.**"}, {"code": "address = 0.0050 * HOURS", "note": "One public IPv4 address, priced by the hour like the machine, whether anybody connects to it or not."}, {"code": "print(f\"machine  {machine:6.2f}\")\nprint(f\"disk     {disk:6.2f}\")\nprint(f\"address  {address:6.2f}\")\nprint(f\"total    {machine + disk + address:6.2f}\")", "note": "Two decimal places, because a bill is in cents. The total is what the three pieces cost for a month in São Paulo, before any data leaves for the internet."}], "output": "machine   12.26\ndisk       3.04\naddress    3.65\ntotal     18.95"}
```

**Every line of that total is something you could switch off separately**, and each is billed whether
the machine is doing useful work or not. Data sent out to the internet is priced on top, per
gigabyte, which lesson 10 comes back to.

## What is left to you

The provider runs the facility, the hardware, the physical network and the virtualisation, and does
it well: replacing a failed disk in their building is not your job, and you will never be asked to patch
the hypervisor. Everything above that line is yours, and **the provider will not touch it**, including
the parts that feel like maintenance:

- the virtual network's firewall rules, which decide whether the database port is open to the whole
  internet;
- the operating system's patches. Nobody at the provider logs in to update your machine; if
  updates arrive on their own, it is because the image you chose switched them on, and a new kernel
  still waits for a reboot that nobody schedules for you;
- the runtime and the application, their versions and their dependencies;
- the backups: the provider sells snapshots of the disk, and taking them, keeping them and testing a
  restore is your job;
- the logins: who holds an SSH key to the machine, and whether the key of somebody who left is still
  on it;
- noticing that the machine is down, or that its disk is full.

The last item surprises people most. **A virtual machine can stop answering while everything the
provider watches looks healthy**: the hardware is fine, the hypervisor is fine, and the web server on
it crashed at four in the morning. The provider's view ends at the line, and so does its alarm.

## What you get back for the work

Control. Any operating system the provider offers an image for, any software, any port, any setting
of the kernel. A program that needs a particular system library, a process that runs for three days,
a database tuned by hand: IaaS runs them all, because to the program it is just a server.

It is also the model that moves most easily. An Ubuntu machine running PostgreSQL and a Python
application is the same system on any provider that rents virtual machines. That is why **IaaS is
where a move to the cloud usually starts**: the servers a company already had are rebuilt as virtual machines
with as little change as possible, which the trade calls *lift and shift*. It is the smallest step
from the server room, and it leaves the most work behind.
