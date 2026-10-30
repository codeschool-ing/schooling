---
title: Play App Signing, and the two keys
version: 1
---

**Google Play signs your app for you, with a key it keeps, and you sign only what you upload.**
That is **Play App Signing**, and for every app created since August 2021 it is not optional:
Google Play accepts a new app only as an **Android App Bundle**, an `.aab`, and builds the APKs
phones install from it. Building them means signing them, so Google needs the key that signs them.

So there are two keys, and they do different jobs.

| | the **app signing key** | the **upload key** |
|---|---|---|
| who holds it | Google, in its own key store | you |
| what it signs | every APK a phone installs | the bundle you upload |
| who checks it | every phone, on every update | Google Play, on every upload |
| if it is lost | Google cannot give you a copy; the app can never be updated again | you ask Google for a reset |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l01-two-keys\" aria-label=\"Three stations from left to right. You sign the app bundle with the upload key and upload it. Google Play checks the upload signature against the upload certificate it holds, builds the APKs, and signs them with the app signing key, which it keeps. The phone checks the app signing key, on the first install and on every update. A lost upload key can be reset; a lost app signing key cannot.\"><defs><marker id=\"l01-two-keys-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"115\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">you</text><rect x=\"265\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"360\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">Google Play</text><rect x=\"510\" y=\"20\" width=\"190\" height=\"120\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"605\" y=\"40\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">the phone</text><rect x=\"40\" y=\"56\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">upload key</text><text x=\"115\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signs the .aab</text><rect x=\"285\" y=\"56\" width=\"150\" height=\"30\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"360.0\" y=\"71.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">app signing key</text><text x=\"360\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">checks the upload</text><text x=\"360\" y=\"113\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">signature, then builds</text><text x=\"360\" y=\"126\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">and signs the APKs</text><text x=\"605\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">checks the</text><text x=\"605\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--phosphor)\">app signing key</text><text x=\"605\" y=\"106\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">checks it on every</text><text x=\"605\" y=\"119\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">install and update</text><path d=\"M210 80 L263 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-keys-ah-paper-dim)\"></path><path d=\"M455 80 L508 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-two-keys-ah-paper-dim)\"></path><text x=\"237\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">.aab</text><text x=\"482\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">.apk</text><rect x=\"20\" y=\"160\" width=\"680\" height=\"70\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.4\" stroke-dasharray=\"5 4\"></rect><text x=\"115\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">lost: Google resets it</text><text x=\"360\" y=\"195\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">lost: never recovered</text></svg>", "caption": "The upload key only ever meets Google. The key phones see is the one Google holds, which is why it can survive your laptop and why nobody can hand it back."}
```

**The upload key is the one you can lose and survive.** If it leaks or disappears, the account owner
asks for an **upload key reset** in the Play Console, registers a new upload certificate, and
carries on. The phones never knew the upload key existed: they only ever saw Google's. *The
console steps are in Google's Play Console Help and were not run for this course.*

## Doing what Play does, on your desk

The tools Google runs are the ones you installed. `bundletool build-bundle` makes an app bundle out
of a module, `jarsigner` signs it with your upload key, and `bundletool build-apks` does what
Google Play does after the upload: it cuts the bundle into the APKs a phone downloads and signs
them. Here the module comes from the same manifest, compiled by `aapt2` into the bundle's own
format; that step is one long command and changes nothing about signing, so it is left out of the
transcript. Then the bundle, and your upload signature on it:

```
ana@dev:~/signing$ java -jar ~/android/bundletool.jar build-bundle --modules=base.zip --output=planner.aab
ana@dev:~/signing$ jarsigner -keystore upload.jks -storepass:env UPLOAD_PASS planner.aab upload
jar signed.

Warning: 
The signer's certificate is self-signed.
ana@dev:~/signing$ jarsigner -verify planner.aab

jar verified.

Warning: 
This jar contains entries whose certificate chain is invalid. Reason: PKIX path building failed: sun.security.provider.certpath.SunCertPathBuilderException: unable to find valid certification path to requested target
This jar contains entries whose signer certificate is self-signed.
This jar contains signatures that do not include a timestamp. Without a timestamp, users may not be able to validate this jar after any of the signer certificates expire (as early as 2054-03-17).

Re-run with the -verbose and -certs options for more details.
```

**The warnings are expected, and they are not about your app.** `jarsigner` was built for Java
libraries, where a certificate is meant to be issued by an authority and the signature stamped
with a time. An upload key is self-signed on purpose, and Google Play reads the signature only to
match it against the upload certificate it holds for you, so none of the three warnings matters
here.

The second key stands in for Google's. **It is not Google's key, and nothing on your computer ever
will be**; it is made here so the re-signing can be watched:

```
ana@dev:~/signing$ keytool -genkeypair -keystore play-stand-in.jks -storetype PKCS12 -alias app -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Play stand-in, C=US" -storepass:env PLAY_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Play stand-in, C=US
ana@dev:~/signing$ java -jar ~/android/bundletool.jar build-apks --bundle=planner.aab --output=planner.apks --ks=play-stand-in.jks --ks-key-alias=app --ks-pass=pass:$PLAY_PASS
ana@dev:~/signing$ unzip -o -q planner.apks -d from-play && ls from-play/splits
base-master.apk
base-master_2.apk
ana@dev:~/signing$ apksigner verify --print-certs from-play/splits/base-master.apk | grep DN
Signer #1 certificate DN: CN=Play stand-in, C=US
ana@dev:~/signing$ apksigner verify --print-certs planner.apk | grep DN
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
```

`bundletool` made two variants of the same base, one signed for older Android versions and one for
newer ones; a phone downloads only the one that fits it. Its `--ks-pass` takes the password as
`pass:` followed by the text, so the variable is expanded by the shell and your history keeps
`$PLAY_PASS` rather than the password.

The last two lines are the point of the lesson. The APK you signed yourself names your
certificate. The APK built from your bundle names the other one, because whoever builds the APKs
signs them. **Phones check the bottom line's key, and you never held it.**

## What to keep, and where

- **The upload keystore and its password, in two places that cannot fail together**: a password
  manager for the password, and an encrypted backup of the `.jks` file away from the computer that
  made it. A laptop that is stolen should cost you a reset, not a week.
- **Never in the repository.** A keystore committed to git is in every clone forever, including
  the ones made before you noticed. Lesson 10 puts it into a pipeline as an encrypted secret.
- **The SHA-256 fingerprints of both certificates.** The Play Console shows the app signing
  certificate's; services such as Firebase need that one, not yours, for the release build.

## The other two platforms

**iOS has no equivalent of the upload key.** Apple re-signs every app it distributes, and your own
distribution certificate is a yearly credential Apple can reissue. Lesson 2 takes it apart.
**React Native** produces a normal Android project, so the same two keys apply: the release
configuration in `android/app/build.gradle` names the upload keystore, and Expo's build service,
EAS Build, can generate and hold the upload key for you if you let it.
