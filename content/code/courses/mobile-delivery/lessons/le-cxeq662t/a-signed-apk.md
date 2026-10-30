---
title: A key, and a package signed with it
version: 1
---

**A signed APK takes four steps, and Android Studio hides all of them behind one menu item.**
Doing them by hand once is what makes the Gradle configuration of your real app readable: you
make a key, build a package, align it, sign it, and then ask a second tool whether the signature
holds. Work in a folder of its own, `~/signing`, away from the planner's code.

## The key

The key lives in a **keystore**, a password-protected file that can hold several keys, each under
a name called an **alias**. `keytool` comes with the JDK. Do not type the password into the
command, where your shell history keeps it; read it into a variable instead, and keytool and
apksigner both know how to take it from there:

```sh
read -rs UPLOAD_PASS && export UPLOAD_PASS
```

Type the password and press Enter; nothing is echoed. Then make the key: RSA with 4096 bits, and
**10,000 days of validity**, which is a little over 27 years. The certificate has to outlive the
app. Google's documentation recommends 25 years or more, and Google Play refuses a key whose
validity ends before 22 October 2033. The `-dname` is the name written into the certificate;
nobody checks it, and it is only what a person reads:

```
ana@dev:~/signing$ keytool -genkeypair -keystore upload.jks -storetype PKCS12 -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana Souza, O=Study Planner, C=BR" -storepass:env UPLOAD_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana Souza, O=Study Planner, C=BR
ana@dev:~/signing$ keytool -list -keystore upload.jks -storepass:env UPLOAD_PASS
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 1 entry

upload, Oct 30, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): 65:88:A1:69:B6:81:48:9F:04:E1:90:EA:72:3E:9B:77:82:4A:06:B4:92:68:17:B8:F1:FD:24:65:AA:2F:47:95
```

The certificate's dates came from the clock of the computer that made it, so yours will say the
day you ran it.

## The package

A real app is built by Gradle. To see signing on its own, the package here is the smallest one
Android accepts: a manifest and nothing else. `android:hasCode="false"` tells the system there is
no compiled code to look for. The package name is the app's identity in the store and can never
change once published. Save this as `AndroidManifest.xml`:

```xml
<!-- AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.planner"
    android:versionCode="1"
    android:versionName="1.0.0">
  <application android:label="Study Planner" android:hasCode="false" />
</manifest>
```

`aapt2 link` compiles the manifest against the platform's `android.jar` into an APK. **`zipalign`
comes before signing**, because the signature covers the bytes of the file and moving them
afterwards would break it. Then `apksigner sign` signs, and the size of the result shows the
signature was added:

```
ana@dev:~/signing$ aapt2 link -o planner-unsigned.apk --manifest AndroidManifest.xml -I $ANDROID_HOME/platforms/android-36/android.jar --min-sdk-version 24 --target-sdk-version 36
ana@dev:~/signing$ zipalign -p -f 4 planner-unsigned.apk planner-aligned.apk
ana@dev:~/signing$ apksigner sign --ks upload.jks --ks-key-alias upload --ks-pass env:UPLOAD_PASS --out planner.apk planner-aligned.apk
ana@dev:~/signing$ ls -l *.apk
-rw-r--r-- 1 ana ana   763 Oct 30 14:46 planner-aligned.apk
-rw-r--r-- 1 ana ana   763 Oct 30 14:46 planner-unsigned.apk
-rw-r--r-- 1 ana ana 12630 Oct 30 14:46 planner.apk
```

## Asking whether it holds

`apksigner verify` is what an install does, on your desk. It names each **signature scheme** it
checked. Scheme v1 is the old JAR signing, kept for Android older than 7.0; v2 and v3 sign the
whole file, and v3 adds the record that lets a key be rotated. The package's minimum SDK is 24,
which is Android 7.0, so apksigner skipped v1:

```
ana@dev:~/signing$ apksigner verify --verbose --print-certs planner.apk
Verifies
Verified using v1 scheme (JAR signing): false
Verified using v2 scheme (APK Signature Scheme v2): true
Verified using v3 scheme (APK Signature Scheme v3): true
Verified using v3.1 scheme (APK Signature Scheme v3.1): false
Verified using v4 scheme (APK Signature Scheme v4): false
Verified for SourceStamp: false
Number of signers: 1
Signer #1 certificate DN: CN=Ana Souza, O=Study Planner, C=BR
Signer #1 certificate SHA-256 digest: 6588a169b681489f04e190ea723e9b77824a06b4926817b8f1fd2465aa2f4795
Signer #1 certificate SHA-1 digest: deec87bdddfa2baab2750129c3caf4b34c4e2c93
Signer #1 certificate MD5 digest: fd96abbb27fe11fa950843bc5d1272b3
Signer #1 key algorithm: RSA
Signer #1 key size (bits): 4096
Signer #1 public key SHA-256 digest: 2e415dea2c4a838e70da6c5561946ce8126dba93ce6a0938cdb7e5f209c7025e
Signer #1 public key SHA-1 digest: 60f03bf87a3d9f21c6ef41ac32f0a84992852bd0
Signer #1 public key MD5 digest: f378440bd8429c794699d9dc6c05955c
```

**Write down the SHA-256 digest of the certificate.** It is the fingerprint every Google service
asks for when it needs to know an app is yours: Firebase, Maps, sign-in with Google. Your digest differs from the one above, because your key does.

The same question asked of the package before signing gets a refusal, which is what a phone
says to an unsigned app. With no v2 or v3 block in the file, apksigner falls back to looking for
the old v1 signature, and reports the first file of it that is missing:

```
ana@dev:~/signing$ apksigner verify planner-aligned.apk
DOES NOT VERIFY
ERROR: Missing META-INF/MANIFEST.MF
```
