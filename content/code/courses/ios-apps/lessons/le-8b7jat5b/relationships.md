---
title: Relationships, and what deleting a course takes with it
version: 1
---

**A course has many sessions and a session belongs to one course, and SwiftData keeps that link as a
relationship rather than as an id you look up.** Section 02's records already declare it: a
`CourseRecord` has `sessions`, a `SessionRecord` has `course`, and the `@Relationship` macro on the
first says how the two sides belong together. This section is about what that one line decides.
Nothing here was run; it follows Apple's documentation for `Relationship(_:deleteRule:…)` and its
article on defining data relationships, read on 30 October 2026.

## Both sides, and which is the inverse

```swift
// Records.swift, the two sides of one relationship
@Relationship(deleteRule: .cascade, inverse: \SessionRecord.course)
var sessions: [SessionRecord] = []        // in CourseRecord

var course: CourseRecord?                 // in SessionRecord
```

`inverse` names the property on the other class that points back. Apple's article shows the same
pattern with animals and their category: the category declares its animals with `@Relationship` and
names `category` as the inverse. **With the inverse declared, the two sides are one fact**: set
`record.course = course` and the session appears in `course.sessions`, without an `append`.

`course` is optional on purpose. A session is created before it is attached, as section 03's `add`
does, and the documentation notes that when a relationship property is optional, SwiftData enforces its
minimum and maximum counts only when it is not `nil`.

## The delete rule

The rule says what happens to the other side when a record is deleted. Apple's documentation for
`Schema.Relationship.DeleteRule` lists four:

| rule | when a course is deleted |
|---|---|
| `.nullify`, the default | its sessions stay, with `course` set to `nil` |
| `.cascade` | its sessions are deleted with it |
| `.deny` | the course cannot be deleted while it has sessions |
| `.noAction` | nothing is done to the sessions, which still point at a course that is gone |

**The planner uses `.cascade`, and the reason is what the student sees.** A session without a course
is a session no screen shows: `CourseDetailView` lists a course's sessions, and section 02's `value`
returns `nil` for one with no course. Under the default, deleting a course would leave its sessions in
the store, invisible, still counted by anything that sums every record, and still sent by lesson 14's
sync. `.cascade` says that a course's sessions are part of the course.

The default is the one that loses nothing, and that is why it is the default. **The rule is a decision
about the data, not a setting**: an app where a course is a tag on independent sessions would want
`.nullify`, and an app where deleting a course with history should need a second step would want
`.deny`, and a screen that explains why.

## A relationship is not a foreign key you maintain

The planner's server and lesson 1's values join a session to its course by `courseID`, text. The
records join by reference. Both are right in their place: an id is what can cross a network and
survive on another phone; a reference is what the store keeps consistent for you, with the delete rule
above, so that no code of yours has to find and fix the sessions of a deleted course. Section 02's
`value` is where one becomes the other.
