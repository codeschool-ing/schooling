---
title: Lanes that reach the stores
version: 1
---

**Fastlane's store actions talk to the stores' own APIs, and each needs a credential that is not a
person's password.** None of this section was run for this course: it needs a Play Console account,
an Apple developer account, or both. It is read from Fastlane's documentation and the stores' API
pages, October 2026.

## The credentials

| store | what Fastlane uses | where it comes from |
|---|---|---|
| Google Play | a **service account key**, a JSON file | created in Google Cloud and given access to the app in the Play Console, with the permissions of lesson 3 |
| App Store Connect | an **API key**, a `.p8` file with a key ID and an issuer ID | created by the Account Holder or an Admin in App Store Connect, with a role of its own |

Both are secrets of the pipeline, exactly like the keystore in lesson 10, and both deserve the
**least role that does the job**: a key that uploads to testing tracks does not need to release to
production.

## The listing, sent from files

`upload_to_play_store` reads a folder per language with `title.txt`, `short_description.txt`,
`full_description.txt` and a `changelogs` folder of release notes named by version code. That is
lesson 4's `listing/android/en-US` with one folder added. `upload_to_app_store` reads `name.txt`,
`subtitle.txt`, `keywords.txt`, `description.txt`, `release_notes.txt` and the rest, per language:
lesson 4's `listing/ios/en-US`. **The files written and checked in lesson 4 are the files Fastlane
sends**, which is why that lesson kept them in Fastlane's layout.

## Screenshots from tests

`capture_ios_screenshots`, known as **snapshot**, runs Xcode UI tests on a list of simulators and
languages and saves a screenshot wherever the test calls `snapshot("01-week")`.
`capture_android_screenshots`, known as **screengrab**, does the same with instrumented tests on an
emulator. Both write the pictures into the folders the upload actions read. *They need a simulator or
an emulator and were not run here; lesson 4's script checks the sizes of whatever they produce.*

## Promoting, not rebuilding

Lesson 7's rule has an action:

```
lane :promote do
  upload_to_play_store(track: "internal", track_promote_to: "alpha",
                       json_key: ENV.fetch("PLAY_JSON_KEY"), skip_upload_aab: true)
end
```

It uploads nothing and moves the release a person chose from one track to the next. Google's API
names the default closed track `alpha` and the open track `beta`, which is why the lane says
`alpha` where the console says closed testing. On iOS, the build
already in TestFlight is the one `upload_to_app_store` submits for review when it is given the build
number instead of a new archive.
