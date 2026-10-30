---
title: VoiceOver, tested by using it
version: 1
---

**The only way to know what VoiceOver says is to turn it on and listen.** Every rule in this lesson
helps, and none of them replaces ten minutes with the screen read aloud and your eyes closed. This
section was not run for the course: it needs a simulator or an iPhone, and it is written from
Apple's VoiceOver user guide and the documentation for Xcode's Accessibility Inspector, read on 30
October 2026.

## The minimum a person needs to know

On an iPhone, VoiceOver is in *Settings*, *Accessibility*, *VoiceOver*, and the accessibility
shortcut, a triple-click of the side button, turns it on and off once it is set up. **Set up the
shortcut before turning VoiceOver on**, because the gestures change completely while it is on:

| gesture | what it does |
|---|---|
| touch, or drag a finger | reads whatever is under the finger |
| swipe right or left with one finger | moves to the next or the previous element |
| double-tap | activates the element that was last read |
| swipe up or down | the rotor's current option, such as the custom actions of section 03 |
| two-finger swipe up | reads the whole screen from the top |

## What to listen for in the planner

Go through the four screens, `CourseListView`, `CourseDetailView`, `SessionForm` and `WeekView`,
with the screen covered, and write down every place where you had to look:

- **an element read as something that is not a sentence**, such as an image's file name or `50 min`;
- **a control you could not find or could not tell was a control**, the `onTapGesture` of section 03;
- **too many stops** in a row that is one thing, or **one stop** where there should be two;
- **a change nobody announced**: marking a session done should change the value VoiceOver reads, and
  an error under a field in `SessionForm` should be read when it appears;
- **the order**: the week's total should come before the list it sums, not after it.

## Without a phone: the Accessibility Inspector

Xcode ships the **Accessibility Inspector**, in *Xcode*, *Open Developer Tool*. Pointed at the
simulator, it shows the label, value, traits and hint of the element under the pointer, can step
through the elements in VoiceOver's order, and runs an **audit** that reports elements with no label,
text that does not scale and contrast below its thresholds. It catches the mechanical half. Whether
a label makes sense is still a question only listening answers.
