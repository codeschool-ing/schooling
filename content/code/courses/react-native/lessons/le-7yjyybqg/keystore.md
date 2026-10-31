---
title: An upload key
version: 1
---

`keytool` comes with the JDK that lesson 3 installed. One command makes a keystore with one key in it:

```
ana@dev:~$ keytool -genkeypair -storetype PKCS12 -keystore planner-upload.p12 -alias upload -keyalg RSA -keysize 2048 -validity 10000 -storepass:env PLANNER_KEY_PASSWORD -dname "CN=Ana, O=Study planner, C=BR"
Generating 2,048 bit RSA key pair and self-signed certificate (SHA384withRSA) with a validity of 10,000 days
	for: CN=Ana, O=Study planner, C=BR
ana@dev:~$ keytool -list -v -keystore planner-upload.p12 -storepass:env PLANNER_KEY_PASSWORD | grep -E "Alias|Owner|Valid|SHA256:"
Alias name: upload
Owner: CN=Ana, O=Study planner, C=BR
Valid from: Fri Oct 30 19:34:31 BRT 2026 until: Tue Mar 17 19:34:31 BRT 2054
	 SHA256: FE:D6:28:DB:AF:74:99:65:C2:D4:9A:53:61:9F:E9:BD:9E:46:0F:E4:9B:F6:BF:61:E9:A2:A1:3D:65:4F:64:1F
ana@dev:~/planner$ grep -n "p12\|jks" .gitignore
15:*.jks
17:*.p12
```

- **`-storetype PKCS12`** is the standard format; Android also reads the older `JKS`. A PKCS12 store has
  one password, for the store and the key alike.
- **`-alias upload`** names the key inside the store; the build will ask for it by that name.
- **`-validity 10000`** is in days, about 27 years. Google Play requires a key that is valid until after
  2033, and a key cannot be extended later.
- **`-dname`** is what the certificate says about its owner. Nobody checks it; it is there for people
  reading it.
- **`-storepass:env PLANNER_KEY_PASSWORD`** reads the password from an environment variable instead of
  the command line, where it would land in the shell's history and in the list of running processes. Set
  the variable from your password manager before running these commands, for example with
  `read -s PLANNER_KEY_PASSWORD && export PLANNER_KEY_PASSWORD`, which reads it without showing it.

**The SHA-256 fingerprint is the key's name.** Google Play and every service that has to recognise your app,
a Google sign-in, a maps key restricted to your app, ask for it.

**The keystore is a secret, and it is irreplaceable without help.** Expo's template already keeps `*.p12` and
`*.jks` out of git, as the last command shows. It belongs in a password manager or an encrypted backup, with
its password, and in nobody's repository. This one was made in the home folder, outside the project, for
the same reason.
