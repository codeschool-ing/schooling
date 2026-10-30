---
title: The app bundle, and the APKs Google builds from it
version: 1
---

**An APK is what a phone installs; an app bundle is what you give Google Play so that it can build the
APKs.** Google's documentation states it plainly: from August 2021, new apps are required to publish
with the Android App Bundle on Google Play. `bundlePlayRelease`, in section 04's release build, wrote
one:

```
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | tail -1
 15398689                     87 files
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E " (BundleConfig.pb|base/manifest/AndroidManifest.xml|base/dex/classes.dex|base/resources.pb|META-INF/UPLOAD.RSA)$"
      628  1981-01-01 01:01   BundleConfig.pb
  1130676  1981-01-01 01:01   base/dex/classes.dex
     5063  1981-01-01 01:01   base/manifest/AndroidManifest.xml
    46001  1981-01-01 01:01   base/resources.pb
     1983  1981-01-01 01:01   META-INF/UPLOAD.RSA
ana@vm:~/planner$ unzip -l app/build/outputs/bundle/playRelease/app-play-release.aab | grep -E "base/lib/" | awk "{print \$4}"
base/lib/arm64-v8a/libandroidx.graphics.path.so
base/lib/armeabi-v7a/libandroidx.graphics.path.so
base/lib/x86/libandroidx.graphics.path.so
base/lib/x86_64/libandroidx.graphics.path.so
```

The bundle is a zip like the APK, laid out differently. `base/` is the app's one module, with its
manifest, its dex and its resources in a format Play reads, `resources.pb`. `BundleConfig.pb`
describes how Play may split it. `META-INF/UPLOAD.RSA` is the signature, by the upload key of
section 04. And `base/lib/` holds a native library in four builds, one per processor family, of
which any one phone needs exactly one.

**That last fact is the point of the format.** A phone with an `arm64-v8a` processor and a screen of a
given density needs one native library, one density of images and the language resources it uses.
From a bundle, Google Play builds **split APKs** per device and serves each phone only what it needs;
the documentation describes this as Play generating and serving optimised APKs for each device
configuration. A universal APK, like the ones in section 04's list, carries all four libraries to
every phone.

## Seeing what a phone would receive

**Not run.** Google's `bundletool`, a separate download, builds from a bundle the same split APKs
Play would, for a given device or for a description of one, and can install them on a connected
phone. It was not downloaded for this course, so the sizes per device it would report are not shown
here. The Play Console shows the same figures for every uploaded bundle, per device model.

## Who signs the APKs Play builds

The APKs that reach phones are built by Google, so Google signs them, with the **app signing key**,
which it keeps. That is the subject of the next section, and the reason the key you made is called
the upload key.
