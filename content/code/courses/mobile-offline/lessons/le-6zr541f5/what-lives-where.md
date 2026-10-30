---
title: The sandbox, and what lives in it
version: 1
---

**Every app on a phone gets a folder of its own, and nothing outside it is the app's to read or
write.** That folder is the **sandbox**. The operating system creates it when the app is installed,
gives it to one user ID, and deletes it when the app is removed. Everything this course stores, a
database, a preference, a downloaded picture, a file waiting to be sent, lives inside it.

A common picture is that the sandbox is one bucket. It is not. Each platform splits it into a few
places, and **the place a file goes decides three things about it**: whether the backup takes it,
whether the system may delete it to free space, and whether the person can see it.

## Android

An app's private storage sits under `/data/data/<package>/`, the same folder that newer releases
also reach as `/data/user/0/<package>/`. The app never types that path; it asks for each part by
name.

| folder | asked for with | what goes there |
|---|---|---|
| `files/` | `Context.getFilesDir()` | files the app made and needs again |
| `databases/` | `Context.getDatabasePath()` | SQLite files, which Room puts here |
| `shared_prefs/` | `SharedPreferences` | small settings, as XML |
| `cache/` | `Context.getCacheDir()` | anything that can be fetched again; the system may delete it when space runs low |
| `no_backup/` | `Context.getNoBackupFilesDir()` | files that must stay on this one device |

## iOS

An iOS app's container has its own shape, and the names say what each part is for.

| folder | what goes there |
|---|---|
| `Documents/` | what the person made, and may see in the Files app if the app allows it |
| `Library/Application Support/` | what the app needs and the person never handles, a database for one |
| `Library/Preferences/` | the property list `UserDefaults` writes |
| `Library/Caches/` | what can be fetched again; the system may purge it when the disk is nearly full |
| `tmp/` | scratch files, which the system may delete when the app is not running |

## React Native

A React Native app runs on one of the two systems above, so its files land in the same folders.
The libraries name them for you: Expo's `expo-file-system` gives a document directory and a cache
directory, which are `files/` and `cache/` on Android and `Documents/` and `Library/Caches/` on iOS,
and a database opened with `expo-sqlite` goes where the platform keeps its databases.

**The rule to carry out of this section is short: a file goes where its loss would hurt the
right amount.** A study session the person typed must survive a reinstall from backup, so it goes
in the database. A course's cover picture can be downloaded again, so it goes in the cache, and
losing it costs one request. The rest of this lesson measures what that choice does to a backup.
