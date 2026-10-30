---
title: A release build, and whose key it carries
version: 1
---

Lesson 3 built a debug APK. A release build is the same command with `Release` in it, and it differs in what
lesson 18 described: Hermes bytecode inside, no Metro, no development checks. Generate the native project
and build one, with nothing else said:

```
ana@dev:~/planner$ npx expo prebuild --platform android --clean --no-install > /dev/null 2>&1
ana@dev:~/planner/android$ ./gradlew :app:assembleRelease -PreactNativeArchitectures=arm64-v8a -q > /dev/null 2>&1
ana@dev:~/planner/android$ $ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2
V2 Signer: certificate DN: CN=Android Debug, OU=Android, O=Unknown, L=Unknown, ST=Unknown, C=US
V2 Signer: certificate SHA-256 digest: fac61745dc0903786fb9ede62a962b399f7348f0bb6f899b8332667591033b9c
```

**`CN=Android Debug`: the release is signed with the debug key.** Expo's template does that on purpose, so
that a release builds on any machine without a keystore; it is fine for trying a release on your own phone,
and Google Play refuses it. Every developer's debug key is different and generated on their machine, so an
app signed with one could never be updated by anybody else either.

## Your key, without editing a generated file

The usual instructions say to edit `android/app/build.gradle` and add a `signingConfig`. Here that file is
generated, and lesson 2's rule holds: the next `prebuild --clean` would remove the edit. The Android Gradle
plugin accepts the signing details as properties on the command line, the same ones Android Studio passes
when it builds a signed app, so nothing generated has to change:

```
ana@dev:~/planner/android$ ./gradlew :app:assembleRelease :app:bundleRelease -PreactNativeArchitectures=arm64-v8a -Pandroid.injected.signing.store.file=$HOME/planner-upload.p12 -Pandroid.injected.signing.store.password="$PLANNER_KEY_PASSWORD" -Pandroid.injected.signing.key.alias=upload -Pandroid.injected.signing.key.password="$PLANNER_KEY_PASSWORD" -q > /dev/null 2>&1
ana@dev:~/planner/android$ $ANDROID_HOME/build-tools/37.0.0/apksigner verify --print-certs app/build/outputs/apk/release/app-release.apk | head -2
V2 Signer: certificate DN: CN=Ana, O=Study planner, C=BR
V2 Signer: certificate SHA-256 digest: fed628dbaf749965c2d49a53619fe9bd9e460fe49bf6bf61e9a2a13d654f641f
ana@dev:~/planner/android$ keytool -printcert -jarfile app/build/outputs/bundle/release/app-release.aab | grep -E "Owner|SHA256:"
Owner: CN=Ana, O=Study planner, C=BR
	 SHA256: FE:D6:28:DB:AF:74:99:65:C2:D4:9A:53:61:9F:E9:BD:9E:46:0F:E4:9B:F6:BF:61:E9:A2:A1:3D:65:4F:64:1F
ana@dev:~/planner/android$ du -h app/build/outputs/apk/release/app-release.apk app/build/outputs/bundle/release/app-release.aab
33M	app/build/outputs/apk/release/app-release.apk
25M	app/build/outputs/bundle/release/app-release.aab
ana@dev:~/planner/android$ unzip -p app/build/outputs/apk/release/app-release.apk assets/index.android.bundle | head -c 64 | file -
/dev/stdin: Hermes JavaScript bytecode, version 99
```

- **Both artifacts carry the upload key**: the APK, which `apksigner` checks, and the **AAB**, the *Android
  App Bundle*, which `keytool` reads. The fingerprints are the ones the keystore listed.
- **The AAB is what Google Play takes.** It holds every architecture and every screen density, and Play
  builds from it the APK each phone needs. The APK is for installing directly, on your phone or a tester's.
- **The JavaScript inside is Hermes bytecode**, `assets/index.android.bundle`, compiled at build time.
- **33 megabytes, against the debug build's 91** in lesson 17: no debugging support, and native libraries
  stripped of what a debugger would need.

`$PLANNER_KEY_PASSWORD` is in double quotes so the shell expands it; the password never appears in the
command. On a build server the same variables come from the server's secrets.
