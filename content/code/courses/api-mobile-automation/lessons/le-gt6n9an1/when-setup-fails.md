---
title: When the mobile setup fails
version: 1
---

The mobile half fails in more places than the first, because more programs are involved: Android
Studio, Gradle, the emulator, adb, the app and boxoffice, and any one of them can stop the rest.
These are the failures that come up most, each with the sign it gives and what to do. Only the
first was produced on the recording machine, which happens to be a computer that shows it; the
rest are described from Android's own messages.

## The emulator will not start: no acceleration

On a computer whose processor's virtualisation is switched off, or absent, the emulator refuses to
run an x86_64 image. Android Studio shows a dialog; the command line says why:

```
ana@laptop:~$ emulator -accel-check
accel:
3
KVM requires a CPU that supports vmx or svm
accel
```

That is the machine this course was recorded on: a virtual machine with no virtualisation passed
through, which is why no emulator appears in this half. The fix on a real computer is in its
firmware settings (*Intel Virtualization Technology*, *VT-x*, *SVM* or *AMD-V*, depending on the
make), and on Windows also in *Turn Windows features on or off*, where *Windows Hypervisor Platform*
must be ticked. Run `emulator -accel-check` again afterwards: on a computer that can run the
emulator it names the accelerator it found instead of `KVM requires a CPU`. If your computer
cannot have it at all, take the phone path of section 03.

## `adb devices` lists nothing, or `unauthorized`

An empty list with an emulator open means adb started before the emulator and lost track of it;
`adb kill-server` and then `adb devices` starts it fresh. With a phone, `unauthorized` beside its
serial number means the phone is still asking whether to trust this computer: unlock it and accept
the prompt on its screen. If it never asks, try another cable; many charging cables carry no data.

## The app shows *Could not reach the box office*

The app ran and its request failed. In order:

1. **Is boxoffice running?** `curl localhost:8080/health` on your computer, as in lesson 1.
2. **Is the app asking the right address?** `10.0.2.2` from an emulator, `localhost` from a phone
   after `adb reverse tcp:8080 tcp:8080`. The address is `baseUrl` in `Shows.kt`.
3. **Did the network rule arrive?** Android refuses plain HTTP to any address the network security
   file of section 05 does not name, and reports it in the device's log, which Android Studio shows
   in its *Logcat* window, with the words `CLEARTEXT communication to 10.0.2.2 not permitted by
   network security policy`. That sentence means the file is missing, misnamed, or not mentioned in
   the manifest.
4. On Windows with boxoffice in WSL, open `http://localhost:8080/health` in a Windows browser. If
   Windows cannot reach it, neither can the emulator.

## The build fails with an unresolved reference

Gradle's error names the file and the line, as `Unresolved reference 'banner'` or similar. Almost
always a file was saved in the wrong folder, under the wrong name, or one of the nine was not saved
at all. Compare the folders in the *Project* view with the paths in section 05; a layout saved in
`res/layouts` instead of `res/layout` is the classic case.
