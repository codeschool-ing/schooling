---
title: The upload key, and the password that is in no file
version: 1
---

**An app is identified by its package name and by the key that signs it**, and a phone installs an
update only if it is signed by the same key as the version already installed. Lesson 1 section 08
said the debug key is the same on every machine and never what you publish with. This section makes
the key you would publish with, and the next sections explain why on Google Play it is an *upload*
key rather than the app's final signature.

## Making the key

`keytool`, which comes with the JDK, makes a key pair and a self-signed certificate inside a
**keystore**, a file protected by a password. The password is the one secret in this section, so it
should never be typed as part of a command, where the shell's history would keep it. Read it into a
variable that is exported for this terminal only, and that `read -rs` does not echo:

```sh
read -rs -p 'Upload key password: ' PLANNER_UPLOAD_PASSWORD && export PLANNER_UPLOAD_PASSWORD
```

Then make a directory outside any project, and the key in it:

```
ana@vm:~/planner$ mkdir -p ~/keys && chmod 700 ~/keys
ana@vm:~/planner$ keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 9125 -dname 'CN=Ana Example, O=Example, C=BR' -storepass:env PLANNER_UPLOAD_PASSWORD -keypass:env PLANNER_UPLOAD_PASSWORD
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 9,125 days
	for: CN=Ana Example, O=Example, C=BR
ana@vm:~/planner$ keytool -list -v -keystore ~/keys/planner-upload.jks -storepass:env PLANNER_UPLOAD_PASSWORD | grep -E 'Alias name|Keystore type|Owner|Valid from|SHA256:|Key Algorithm'
Keystore type: PKCS12
Alias name: upload
Owner: CN=Ana Example, O=Example, C=BR
Valid from: Fri Oct 30 17:41:09 BRT 2026 until: Tue Oct 24 17:41:09 BRT 2051
	 SHA256: 40:8B:D0:9B:F6:37:4A:DC:56:58:1B:D5:3B:9B:A8:B1:55:DA:DA:E1:E4:01:FE:9F:CB:35:2C:D5:20:CF:41:B1
Subject Public Key Algorithm: 4096-bit RSA key
```

`-storepass:env` tells `keytool` to read the password from the environment variable rather than the
command line. The key is RSA, 4,096 bits, and valid for 9,125 days, which is 25 years: **Google's
documentation on app signing recommends a validity of at least 25 years**, because an app signed by a
key that has expired cannot be updated. The `SHA256` line is the certificate's fingerprint, the short
form of the key that Google Play and an API key restriction would ask you for.

**This file and its password are the app's identity.** Keep a copy of both somewhere that is not this
computer, and never commit either: the build file of section 02 names a path under your home
directory precisely so that the keystore is never inside the project.

## The build reads the password from the environment

The `upload` signing configuration in section 02 reads `PLANNER_UPLOAD_PASSWORD` with
`providers.environmentVariable`. In a terminal where the variable was never set, a release build
stops before it signs anything:

```
ana@vm:~/planner$ ./gradlew --console=plain assemblePlayRelease 2>&1 | grep -E -A2 'What went wrong'
* What went wrong:
Execution failed for task ':app:validateSigningPlayRelease' (registered by plugin 'com.android.internal.application').
> Keystore file not set for signing config upload
```

**The message blames the keystore file, and the file is there**: what is missing is the password, and
the plugin's validation reports it under the file's name. When a release build fails at
`validateSigning`, check the environment first.

In the terminal where `read` set the variable, the release builds:

```
ana@vm:~/planner$ ./gradlew --console=plain assembleRelease bundlePlayRelease 2>&1 | grep -E '^BUILD|actionable'
BUILD SUCCESSFUL in 1m 16s
110 actionable tasks: 79 executed, 31 up-to-date
ana@vm:~/planner$ find app/build/outputs -name "*release*.apk" -o -name "*.aab" | sort | xargs ls -l
-rw-r--r-- 1 ana ana  757890 Oct 30 17:42 app/build/outputs/apk/direct/release/app-direct-release.apk
-rw-r--r-- 1 ana ana  757882 Oct 30 17:42 app/build/outputs/apk/play/release/app-play-release.apk
-rw-r--r-- 1 ana ana 1775458 Oct 30 17:42 app/build/outputs/bundle/playRelease/app-play-release.aab
```

## Who signed what

`apksigner`, from the build tools, reads the signature of an APK:

```
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/apksigner verify --print-certs app/build/outputs/apk/play/release/app-play-release.apk | grep -E 'DN|SHA-256'
Signer #1 certificate DN: CN=Ana Example, O=Example, C=BR
Signer #1 certificate SHA-256 digest: 408bd09bf6374adc56581bd53b9ba8b155dadae1e401fe9fcb352cd520cf41b1
ana@vm:~/planner$ $ANDROID_HOME/build-tools/36.1.0/apksigner verify --print-certs app/build/outputs/apk/play/debug/app-play-debug.apk | grep -E 'DN|SHA-256'
Signer #1 certificate DN: C=US, O=Android, CN=Android Debug
Signer #1 certificate SHA-256 digest: 4ad6a4e45969a0273254430560e6575336e34abc4d8256a826af6301f38c250d
```

The release APK is signed by Ana's key, with the fingerprint `keytool` printed. The debug APK is
signed by `CN=Android Debug`, the debug key of lesson 1. **Without section 02's suffix, a phone holding the debug build would refuse the release build as an
update**, because the certificates differ, and the debug build would have to be uninstalled first,
its data with it. With the suffix they are two apps with two package names, and the question never
arises.
