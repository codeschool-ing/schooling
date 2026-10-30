---
title: Where a class hierarchy goes wrong
version: 1
---

The first design most people reach for is a tree of classes: a base class with what everything
shares, and a subclass for each kind of thing. It works until something belongs to two branches at
once. **A class has one superclass, so a type that is two things at once has to pick one of them and
copy the other.**

The planner has study sessions, which take time, and exams, which have a grade. Then a student asks
for a mock exam, which is timed and graded both:

```swift
// Hierarchy.swift
class StudyItem {
    let title: String
    init(title: String) { self.title = title }
    var minutes: Int { 0 }
    var grade: Int? { nil }
}

class StudySession: StudyItem {
    let length: Int
    init(title: String, length: Int) {
        self.length = length
        super.init(title: title)
    }
    override var minutes: Int { length }
}

class Exam: StudyItem {
    let score: Int
    init(title: String, score: Int) {
        self.score = score
        super.init(title: title)
    }
    override var grade: Int? { score }
}

// timed and graded, and a class can have only one superclass
class MockExam: Exam {
    let length: Int
    init(title: String, score: Int, length: Int) {
        self.length = length
        super.init(title: title, score: score)
    }
}

let week: [StudyItem] = [
    StudySession(title: "Optionals", length: 45),
    Exam(title: "Swift basics", score: 80),
    MockExam(title: "Generics", score: 70, length: 60),
]
print("minutes this week:", week.map(\.minutes).reduce(0, +))
```

```
ana@vm:~/sw/l10$ swift Hierarchy.swift
minutes this week: 45
```

The week had 45 minutes of study and a 60-minute mock exam, and the total says 45. Nothing failed to
compile and nothing crashed. `MockExam` inherited `minutes` from `StudyItem`, where it is `0`,
because it sits under `Exam` and not under `StudySession`, and nobody remembered to override it.

## Three things went wrong at once

- **The base class answers for everyone.** `StudyItem` had to declare `minutes` and `grade` so that
  the array could ask every item, and it had to give them a value, so it gave a wrong one: `0` minutes
  for an exam is a guess dressed as a fact. Every subclass inherits the guess.
- **The second parent is copied.** `MockExam` declares `length` again, because the code that handles
  length lives in `StudySession` and a class cannot inherit from two classes.
- **The compiler cannot help.** Overriding is optional, so a subclass that forgets is a correct
  program with a wrong number in it, which is the worst kind of defect: lesson 1's overflow at least
  stopped the program.

Hierarchies also only grow downwards. A reading assignment with no minutes and no grade still gets
both, and the day the planner needs a "has a due date" property, it goes into the base class, where
every item answers it whether it has a due date or not.

## The question to ask instead

The tree asked "what **is** a mock exam?", and that question has one answer per class. The
alternative asks "what **can** it do?": it takes time, and it has a grade. Those are two
capabilities, independent of each other, and lesson 8 already has the tool for a capability. Section
03 rebuilds the planner with it.
