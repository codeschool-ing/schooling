---
title: Closing the socket on Linux and on Windows
version: 1
---

**Nothing in the lab can plug in a USB device.** The machines are containers, and a container has no
USB bus and no kernel modules of its own: both belong to the computer the containers run on. Here is
what that looks like from inside `web`:

```
ana@web:~$ ls /sys/bus/usb
ls: cannot access '/sys/bus/usb': No such file or directory
ana@web:~$ sudo usbguard generate-policy; echo "exit $?"
ERROR: loadFiles: /sys/bus/usb/devices: No such file or directory
exit 1
ana@web:~$ command -v modprobe || echo "no modprobe here"
no modprobe here
```

There is no `/sys/bus/usb` to read, so USBGuard has nothing to build a policy from, and there is no
`modprobe`, because no module can be loaded from inside a container. **The rest of this section was
not run for this course.** It is taught from the documentation of each tool; on a Linux computer of
your own, with real USB sockets, every command in it works as described.

## No driver for USB storage

Linux reaches a USB stick through the `usb-storage` kernel module. If the module never loads, a stick
is detected and never becomes a disk. A file in `/etc/modprobe.d/` does it:

```
blacklist usb-storage
install usb-storage /bin/false
```

`blacklist` stops the module loading automatically when a device appears. `install … /bin/false`
goes further: any attempt to load it, even `modprobe usb-storage` by hand, runs `/bin/false` instead
and fails. Check with `modprobe --showconfig | grep usb.storage`, and remember that a module already
loaded stays loaded until it is removed or the machine reboots. It stops storage and nothing else: a
device announcing itself as a keyboard is untouched.

## An allow-list of devices: USBGuard

USBGuard, installed on every machine in the lab, decides per device. Its daemon reads each device's
attributes as it connects, vendor and product id, serial number, class of interface, the port it is
plugged into, and applies a rule list where the first match wins:

```
allow id 046d:c52b serial "" name "USB Receiver" with-interface { 03:01:01 03:01:02 }
allow id 0781:5583 serial "4C530001231115" with-interface 08:06:50
block
```

The first rule allows one particular wireless keyboard receiver, and only with the two keyboard and
mouse interfaces it really has. The second allows one named stick, by serial number. The last blocks
everything else. `usbguard generate-policy` writes a starting list from what is plugged in when it
runs, which is how you build one on a machine you trust; `usbguard list-devices` and `usbguard
allow-device` manage it afterwards. The `with-interface` clause is the defence against the device that
lies: a "stick" that also presents a keyboard interface (class `03`) does not match a rule written for
storage (class `08`).

Its limit is the same as MAC filtering's in lesson 4, and the same honesty applies: vendor ids and
serial numbers are values the device reports about itself. An allow-list keeps out the unknown stick
in the car park; it does not stop a device built to copy an allowed one.

## Windows

Windows has the same two controls under Group Policy, which lesson 3 described. **Removable Storage
Access** policies, under Computer Configuration, deny read or write access to removable disks by
class. **Device Installation Restrictions** prevent the installation of devices that match listed
device ids or setup classes, or of any device not on an allow-list. Microsoft Defender for Endpoint
adds **device control**, with rules per device and per user, and an audit mode that records what would
have been blocked. None of these was run for this course.

Whatever the system, start the way this course always does: in audit mode, measure which devices
people actually use, then write the list.
