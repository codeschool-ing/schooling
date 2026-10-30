---
title: The first lanes, run on your computer
version: 1
---

**A Fastfile is Ruby, but it reads like a list**: lanes, and inside each lane the actions in the
order they run. Fastlane looks for it in a folder named `fastlane` in the project, and runs each
lane **from inside that folder**, which is the one detail that catches everybody once: a path in a
lane is relative to `fastlane/`, not to the project.

## The planner's Fastfile

Save this as `Fastfile` in `~/planner/fastlane`:

```
# Fastfile: the planner's lanes. Fastlane runs each lane from inside the fastlane folder.
default_platform(:android)

desc "Every check that runs without a store: lessons 2, 4, 5 and 6"
lane :checks do
  sh("cd .. && node preflight.ts")
end

platform :android do
  desc "Check, then upload the signed bundle and the listing to the internal track"
  lane :internal do
    checks
    upload_to_play_store(
      track: "internal",
      aab: ENV.fetch("AAB"),
      json_key: ENV.fetch("PLAY_JSON_KEY"),
      metadata_path: "../listing/android",
      skip_upload_screenshots: true
    )
  end
end

platform :ios do
  desc "Check, then build, sign and send to TestFlight"
  lane :beta do
    checks
    match(type: "appstore", readonly: true)
    build_app(scheme: "Planner", export_method: "app-store")
    upload_to_testflight(skip_waiting_for_build_processing: true)
  end
end
```

`lanes` lists what the file defines, with each `desc` beside its lane. It reads the file and runs
nothing, so it works on Linux for the iOS lanes too:

```
ana@dev:~/planner$ bundle exec fastlane lanes
------------------------------
--- Step: default_platform ---
------------------------------

--------- general---------
----- fastlane checks
Every check that runs without a store: lessons 2, 4, 5 and 6


--------- android---------
----- fastlane android internal
Check, then upload the signed bundle and the listing to the internal track


--------- ios---------
----- fastlane ios beta
Check, then build, sign and send to TestFlight

Execute using `fastlane [lane_name]`
```

## Running the checks

`checks` runs the gate of lesson 6. The planner still has the two problems that lesson left, so the
lane should stop. The output of a failing lane is long, with a summary table and a stack trace; the
command below prints the part from the step to its result, and then the exit status of Fastlane
itself:

```
ana@dev:~/planner$ bundle exec fastlane checks 2>&1 | sed -n '/Step: cd/,/reason(s)/p'; echo "exit status ${PIPESTATUS[0]}"
--- Step: cd .. && node preflight.ts ---
----------------------------------------
$ cd .. && node preflight.ts
STOP  store listing within limits
go    privacy inventory complete
STOP  no certificate expiring within 30 days
go    api https://api.planner.example is production
go    debug menu is off
go    review notes carry a demo account
2 reason(s) to stop before submitting 1.4.0 (42)
exit status 1
```

**The lane stopped on the gate, and its exit status is 1**, which is what lesson 10's pipeline reads.
A lane that calls `checks` first, as `internal` and `beta` do, never reaches the upload while the
gate says stop, which is the whole reason the gate was written as a script with an exit status.

## Running a lane for one platform

A lane inside `platform :android` is run as `bundle exec fastlane android internal`. It would stop at
`checks` here for the same reason, and past it, it needs two things this course does not have: a
signed bundle in `AAB` and a Google Play service account key in `PLAY_JSON_KEY`. `ENV.fetch` makes
the lane refuse to start without them, with an error naming the missing variable, rather than
uploading nothing in silence.
