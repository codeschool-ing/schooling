---
title: Flutter, which paints its own pixels
version: 1
---

**Flutter is Google's toolkit for apps on phones, desktops and the web, from one codebase in Dart**, a
language Google makes for it. It is the most different of the tools in this course, and the planner
shows that in two ways: the rules have to be written again, because nothing of TypeScript runs in it,
and the screen is pixels, not elements.

## Installing it

Flutter is one folder, like Node. The lines that installed it where this course was recorded, at the
version current on the day:

```sh
curl -fsSLO https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.47.8-stable.tar.xz
tar -xJf flutter_linux_3.47.8-stable.tar.xz -C ~/.local
```

and then `~/.local/flutter/bin` on the `PATH`, added in `~/.profile` like this:
`export PATH="$HOME/.local/flutter/bin:$PATH"`. The download is about 1.6 GB and the unpacked folder
2.5 GB. **On Windows and macOS, flutter.dev has an installer**; building for Android needs the Android
SDK of lesson 3, and for iOS a Mac with Xcode, so this course builds for the web only.

```
ana@dev:~$ flutter --version
Flutter 3.47.8 • channel stable • https://github.com/flutter/flutter.git
Framework • revision 737ba8f885 (19 hours ago) • 2026-10-22 21:37:31 -0700
Engine • hash dfd2e6cb7d319db05e3bf1503f3e2ac60f6288a2 (revision cf636b1dfb) (24 hours ago) • 2026-10-23 02:13:38.000Z
Tools • Dart 3.13.7 • DevTools 2.60.0
```

## The planner in Dart

```
ana@dev:~$ flutter create --platforms web --empty --project-name planner_flutter planner_flutter
Creating project planner_flutter...
Resolving dependencies in `planner_flutter`...
Downloading packages...
Got dependencies in `planner_flutter`.
Wrote 18 files.

All done!
You can find general documentation for Flutter at: https://docs.flutter.dev/
Detailed API documentation is available at: https://api.flutter.dev/
If you prefer video documentation, consider: https://www.youtube.com/c/flutterdev

In order to run your empty application, type:

  $ cd planner_flutter
  $ flutter run

Your empty application code is in planner_flutter/lib/main.dart.
```

Replace `lib/main.dart` with the planner's screen. **The first half is `planner.ts` written again in
Dart**, by hand, because there is no way to import TypeScript; the second half is the screen, made of
Flutter's *widgets*, its word for components:

```
// lib/main.dart: the planner's screen in Flutter, its rules written again in Dart.
import 'package:flutter/material.dart';

class Session {
  Session(this.id, this.course, this.date, this.minutes, this.done);
  final String id, course, date;
  final int minutes;
  bool done;
}

const courses = {'spanish': 'Spanish A2', 'statistics': 'Statistics', 'guitar': 'Guitar'};
final sessions = [
  Session('s1', 'spanish', '2026-10-19', 30, true),
  Session('s2', 'statistics', '2026-10-20', 45, true),
  Session('s3', 'guitar', '2026-10-21', 20, false),
  Session('s4', 'spanish', '2026-10-22', 30, false),
  Session('s5', 'statistics', '2026-10-26', 60, false),
  Session('s6', 'guitar', '2026-10-28', 20, false),
];

String mondayOf(String date) {
  final d = DateTime.parse('${date}T12:00:00Z');
  return d.subtract(Duration(days: d.weekday - 1)).toIso8601String().substring(0, 10);
}

(int, int) weekTotal(List<Session> all, String monday) {
  final end = DateTime.parse('${monday}T12:00:00Z').add(const Duration(days: 7));
  final last = end.toIso8601String().substring(0, 10);
  final week = all.where((s) => s.date.compareTo(monday) >= 0 && s.date.compareTo(last) < 0);
  final done = week.where((s) => s.done).fold(0, (n, s) => n + s.minutes);
  return (done, week.fold(0, (n, s) => n + s.minutes));
}

// The transcripts open the web build with ?today=2026-10-21, as lesson 1 does.
final today = Uri.base.queryParameters['today'] ?? DateTime.now().toIso8601String().substring(0, 10);

void main() => runApp(const MaterialApp(title: 'Study planner', home: Planner()));

class Planner extends StatefulWidget {
  const Planner({super.key});
  @override
  State<Planner> createState() => _PlannerState();
}

class _PlannerState extends State<Planner> {
  String? open;

  @override
  Widget build(BuildContext context) {
    final (done, planned) = weekTotal(sessions, mondayOf(today));
    return Scaffold(
      appBar: AppBar(title: const Text('Study planner')),
      body: ListView(children: [
        ListTile(title: Text('This week: $done of $planned minutes done')),
        for (final MapEntry(key: id, value: name) in courses.entries) ...[
          ListTile(title: Text(name), onTap: () => setState(() => open = open == id ? null : id)),
          if (open == id)
            for (final s in sessions.where((s) => s.course == id))
              ListTile(
                title: Text('${s.date}, ${s.minutes} min'),
                trailing: s.done
                    ? const Text('done')
                    : TextButton(onPressed: () => setState(() => s.done = true), child: const Text('Mark done')),
              ),
        ],
      ]),
    );
  }
}
```

Widgets nest like React's components, and `setState` asks Flutter to draw again, as `useState` does in
React. `ListTile`, `TextButton` and `AppBar` are Material Design widgets, Google's look, drawn by Flutter
on every platform; Flutter's `Cupertino` widgets draw the iOS look instead.

```
ana@dev:~$ cd planner_flutter
ana@dev:~/planner_flutter$ flutter analyze
Analyzing planner_flutter...                                    
No issues found! (ran in 7.4s)
ana@dev:~/planner_flutter$ flutter build web --no-web-resources-cdn
Compiling lib/main.dart for the Web...                          
Wasm dry run succeeded. Consider building and testing your application with the `--wasm` flag. See docs for more info: https://docs.flutter.dev/platform-integration/web/wasm
Use --no-wasm-dry-run to disable these warnings.
Expected to find fonts for (MaterialIcons, packages/cupertino_icons/CupertinoIcons), but found (MaterialIcons). This usually means you are referring to font families in an IconData class but not including them in the assets section of your pubspec.yaml, are missing the package that would include them, or are missing "uses-material-design: true".
Font asset "MaterialIcons-Regular.otf" was tree-shaken, reducing it from 1645184 to 7736 bytes (99.5% reduction). Tree-shaking can be disabled by providing the --no-tree-shake-icons flag when building your app.
Compiling lib/main.dart for the Web...                             32.1s
✓ Built build/web
ana@dev:~/planner_flutter$ du -sh build/web
40M	build/web
```

`--no-web-resources-cdn` makes the build carry its own copy of the rendering engine, CanvasKit, instead
of loading it from Google's servers when the page opens; the recording machine could not reach those
servers, and an app that should work offline needs the same flag. **The build is 40 MB**, which is the
engine, against the planner's few kilobytes.

## What a screen reader sees

```
ana@dev:~/planner$ node look.mjs 'http://localhost:4174/?today=2026-10-21' --wait 4000 2>&1 | grep -v '^console'
- button "Enable accessibility"
ana@dev:~/planner$ node look.mjs 'http://localhost:4174/?today=2026-10-21' --wait 4000 --eval 'document.querySelector("flt-semantics-placeholder").click()' --wait 1500 --click 'Spanish A2' --wait 500 --click 'Mark done' --wait 500 2>&1 | grep -v '^console'
document.querySelector("flt-semantics-placeholder").click() = undefined
- heading "Study planner" [level=2]
- group:
  - text: "This week: 105 of 125 minutes done"
  - button "Spanish A2"
  - text: 2026-10-19, 30 min done 2026-10-22, 30 min done
  - button "Statistics"
  - button "Guitar"
```

**The first run shows one element, a button called "Enable accessibility", and nothing else**: not the
week, not the courses. Flutter painted them on a canvas, and a canvas is one picture to the browser. The
button is Flutter's way in: activating it, as a screen reader user would, turns on Flutter's
**semantics tree**, a hidden structure it builds beside the pixels to tell assistive technology what is
there. With it on, the second run reads the planner, opens Spanish A2 and marks a session done, and the
week reads 105 of 125, the same number as every other version of the planner, from rules written twice.

On a phone, Flutter gives its semantics tree to TalkBack and VoiceOver without that button, so a Flutter
app can be as accessible as a native one; it is a promise Flutter keeps by work of its own, where React
Native gets it from the platform's controls.
