---
title: An upload key for Android
version: 1
---

**An Android key lives in a keystore, a file protected by a password, and `keytool` makes one.** `keytool`
comes with Java, which lesson 3 installed for Android's tools, so it is already on your computer. Keep the
keystore **outside every project**, in a folder only you can open, so that no `git add .` can reach it.

The password should not end up in your shell's history either. Type it once into a variable with `read`,
which shows nothing as you type, and hand `keytool` the variable's name:

```sh
read -rs KEY_PASS && export KEY_PASS
```

Then the key: RSA, 4096 bits, valid for 10,000 days, which is some 27 years; Android's documentation asks for
at least 25, so that the key outlives the app:

```
ana@dev:~$ mkdir -p ~/keys && chmod 700 ~/keys
ana@dev:~$ keytool -genkeypair -keystore ~/keys/planner-upload.jks -alias upload -keyalg RSA -keysize 4096 -validity 10000 -dname "CN=Ana, O=Study planner, C=BR" -storepass:env KEY_PASS
Generating 4,096 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana, O=Study planner, C=BR
```

**`-alias upload`** names the key inside the keystore, and `-dname` is the name written into its certificate:
a person or an organisation, and a country. Nobody checks these against a register; they are what the
certificate says about you. Listed, the keystore shows the one thing you will be asked to copy into Google
Play's console, the certificate's fingerprint:

```
ana@dev:~$ keytool -list -keystore ~/keys/planner-upload.jks -storepass:env KEY_PASS
Keystore type: PKCS12
Keystore provider: SUN

Your keystore contains 1 entry

upload, Oct 23, 2026, PrivateKeyEntry, 
Certificate fingerprint (SHA-256): EE:C1:FE:3C:9F:7E:6F:69:82:F6:38:D4:04:BF:F8:8C:42:C1:79:FB:2E:DF:80:BF:FD:E4:B1:7F:4D:69:D7:64
ana@dev:~$ ls -l ~/keys
total 8
-rw-r--r-- 1 ana ana 4296 Oct 23 22:47 planner-upload.jks
```

**The fingerprint identifies the key without revealing it**, so it can go into a support request, a
configuration screen or a document. The keystore file and its password are the two things that must not go
anywhere. The file is readable only by you because the folder is `700`; on a shared computer, `chmod 600` on
the file as well.

## Keep it, twice

**Back the keystore up in two places, and the password with it**, in a password manager, for instance, and
not in the same place as the file. With Play App Signing a lost upload key can be replaced; an APK you
distribute yourself has no such rescue, and the key is the app's identity for as long as it exists.

The planner's repository also refuses to carry one by accident. These three lines in `.gitignore` cover a
keystore copied into the project and the properties file Android projects often use to hold its path and
password, and `git check-ignore` proves which line catches each name:

```
ana@dev:~/planner$ printf "*.jks\n*.keystore\nkeystore.properties\n" >> .gitignore
ana@dev:~/planner$ git check-ignore -v android/app/planner-upload.jks android/keystore.properties
.gitignore:26:*.jks	android/app/planner-upload.jks
.gitignore:28:keystore.properties	android/keystore.properties
```

*The step that uses the key, signing a release, was not run: it needs the Android SDK and Gradle, which the
recording machine could not install.* Lesson 13 showed it: `npx cap build android` with `--keystorepath`
and `--keystorealias`, which asks for the passwords, or reads them from `--keystorepass` and
`--keystorealiaspass`, flags a CI job fills from its secrets.
