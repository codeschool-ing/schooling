---
title: Flutter
version: 1
---

**Flutter is Google's framework, written in Dart.** A screen is a tree of **widgets**, which play the part
React components play here: immutable descriptions, rebuilt when state changes, with the framework working
out what to repaint. The planner's weekly total, as a Flutter widget, would read something like this:

```java
class WeekTotal extends StatelessWidget {
  const WeekTotal({super.key, required this.done, required this.planned});
  final int done;
  final int planned;

  @override
  Widget build(BuildContext context) {
    return Text(
      'This week: $done of $planned minutes done',
      style: Theme.of(context).textTheme.bodyLarge,
    );
  }
}
```

*This was written for comparison and not compiled; this course has no Flutter toolchain.* The resemblance to
a React component is not an accident: Flutter's model came from the same idea.

**What its own renderer buys.** Every pixel is Flutter's, so the app looks identical on every phone, and
custom design, animation and drawing are first-class: there is no bridge to a native view to slow them down.
It also runs on the web and on desktops from the same code.

**What it costs.** A Flutter app is not made of the platform's views, so whatever the platform adds to its
own controls, the newest text selection behaviour, a new system look, accessibility details, Flutter has to
reimplement, and it arrives later. The language is Dart, which few people know before Flutter. And the app
carries its engine, so the smallest app is larger than the smallest React Native one.

**Native code** is reached through *platform channels* or the newer *FFI* bindings, the counterpart of lesson
17's modules, with Kotlin and Swift on the other side as here.
