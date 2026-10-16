---
title: What the emulator hides
version: 1
---

**The emulator runs Android faithfully and the phone unfaithfully.** A defect in the app's logic,
its screens, its layouts in another language or size, its permissions or its handling of a failed
request shows up on the emulator exactly as on a phone. A defect that lives in the hardware, in a manufacturer's changes or in the world around the phone
does not. Those are the ones users report with the words *it only happens on my phone*.

The usual belief is that a test on the emulator with the right Android version and screen size is
a test of "that phone". It is a test of Google's Android at that version on a very fast, very
regular machine. These are the places it parts company with a phone in someone's pocket.

## Speed and memory

The emulator borrows your computer's processor, and a laptop's processor is usually faster than a
budget phone's, with more memory behind it. **A list that scrolls smoothly on the emulator can
stutter on a three-year-old phone that costs a tenth of the laptop.** On a phone with little memory,
Android would close an app that uses too much of it. On a virtual device with plenty, the same app
keeps running. The emulator lets you give a device less memory and fewer cores when you create it,
which brings some of this back. None of it makes the processor slower.

## The screen's drawing

A phone draws with its own graphics chip and its maker's driver. The emulator draws with yours, or
in software when it cannot:

```
ana@laptop:~$ emulator -help-gpu | head -16

  Use -gpu <mode> to override the mode of hardware OpenGL ES emulation
  indicated by the AVD. The following <mode> values should cover most
  use cases:

     auto (default)       -> Auto-select the renderer.
     auto-no-window       -> Auto-select the renderer when
                             running headless. This will use the same
                             gpu selection mechanism as running without
                             the "-no-window" flag and the "-gpu auto"
                             option. See auto for details on the behavior.
     host                 -> Use the host system's OpenGL driver.
     swiftshader_indirect -> Use SwiftShader software renderer on the
                             host, which can be beneficial if you are
                             experiencing issues with your GPU drivers
                             or need to run on systems without GPUs.
```

`host` is your computer's own graphics driver, and `swiftshader_indirect` is SwiftShader, a renderer
that runs on the processor. Neither is the phone's chip. A glitch that comes from one family of
phone GPUs, a black screen or a flicker in an animation, will not be seen here.

## The maker's Android

The emulator runs Google's Android. Most phones in Brazil run a manufacturer's version of it, with
its own launcher, its own settings and, above all, **its own rules about what an app may do in the
background**. Several makers stop background work far more aggressively than Google's Android does,
to save battery. Take an app's scheduled task, such as a reminder on the day of a show, the kind Tickets's switch
offers. It can fire every time on the emulator and never on a particular brand of phone. Developers
document these differences brand by brand, and only that brand's phone shows them.

## Sensors, location and the camera

Every sensor is a property you switch on and feed. The GPS reports exactly the position typed into
*Extended controls*, with none of the drift of a phone indoors. The accelerometer turns when you
rotate the virtual phone, never because someone is walking. The camera is the clearest case:

```
ana@laptop:~$ emulator -help-camera-back

  Use -camera-back <mode> to control emulation of a camera facing back.
  Valid values for <mode> are:

     emulated     -> camera will be emulated using software ('fake') camera emulation
     webcam<N>    -> camera will be emulated using a webcamera connected to the host
     virtualscene -> If the feature is enabled, camera will render a virtual scene
     videoplayback -> If the feature is enabled, camera will support playing back a video
     none         -> camera emulation will be disabled
```

`emulated` is a picture drawn in software, `webcam0` is your computer's own camera, and
`virtualscene` is a drawn room you can walk around in. **None of them is the phone's lens.** An app
that reads a QR code on a ticket can be tested for its flow here, and for its reading only on a
phone.

## Google's services

An app that uses Google Play services, for maps, sign-in with Google or push messages through
Firebase, needs them on the device. Every certified phone sold with Google's store has them. An
emulator has them only if its system image says *Google APIs* or *Google Play*, which is why lesson
14 chose a *Google APIs* image. On a plain image those features fail, and the failure is the image's.

## The network and the fingers

The emulator's network is your computer's: a cable or a good Wi-Fi, steady. It has no lift, no
tunnel and no hand-over from Wi-Fi to the mobile network halfway through a request. It can be slowed
on purpose, and lesson 22 does it. And a mouse click lands on the exact pixel you aimed at, which a
thumb on a bus never does. A button too small to hit reliably passes every test on the emulator.
