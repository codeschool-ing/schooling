---
title: What non-functional means
version: 1
---

Every test so far in this course has asked whether boxoffice does what it should: whether six
tickets are accepted, whether a student pays half, whether a used order can be refunded. Those are
**functional** questions, about what the system does. A **non-functional** question is about how
well it does it: how fast, for how many people at once, how safely, and for whom. A ticket office
that charges the right price and takes twenty seconds to show a page has no functional defect and
loses its customers anyway.

The name suggests something optional, a layer of polish after the real work. It is the reverse in
practice. **A non-functional failure is often the one that makes the news**: the site that falls
over when tickets for a popular show go on sale, the error page that shows a stranger the inside of
the program, the form a blind customer cannot fill in. None of those breaks a requirement about
what the system does.

## The families

The standard most teams borrow their vocabulary from is ISO/IEC 25010, which lists the qualities
of a product. You do not need the list by heart; you need to recognise the families of testing
that grew around it, because each has its own tools, specialists and courses.

**Performance testing** measures how quickly the system answers under an ordinary amount of use.
The usual measure is **response time**: from the moment a request is sent to the moment the answer
has arrived.

**Load testing** asks the same question under the load the system is expected to carry at its
busiest. For the theatre that is the morning a popular show goes on sale, and the question is
whether pages still answer in time when hundreds of people book at once.

**Stress testing** pushes past that peak on purpose, until something gives, to learn where the
limit is and how the system fails when it reaches it. A system that slows down and recovers is in a
different position from one that loses orders. Two neighbours are named often enough to recognise:
**spike testing**, a sudden jump in load, and **soak** or **endurance testing**, ordinary load held
for hours to find what only shows over time, such as memory that is never given back.

**Security testing** looks for the ways the system could expose data, accept what it should refuse
or be misused. Section 04 of this lesson takes the defender's side of it.

**Accessibility testing** checks that people with disabilities can use the system: with the keyboard
alone, with a screen reader, with enlarged text. Section 05 does this on boxoffice.

**Compatibility testing**, browsers, systems and screens, is non-functional too, and lesson 7 has
already done it. Usability, reliability and the rest of the standard's list are tested as well, by
people who specialise in them.

## A requirement needs a number

Look at boxoffice's requirements in lesson 1 again. Two of them are non-functional: R8 names
browsers and a screen width, and R9 names WCAG 2.2 level AA. Both can be tested because both name
something measurable. **There is nothing at all about speed or load.**

That gap is itself a finding, and raising it is part of the job. "The site must be fast" cannot be
tested, because nobody can say when it has failed. A tester's question turns it into something that
can be: how fast, for how many people, measured where? A testable version for the theatre might
read: *with 200 people booking at once, 95% of pages answer within one second, and none fail*. Each
number in that sentence came from somebody's decision, the way the risks of lesson 1 did, and each
can be disagreed with before anything is measured.

## Where a manual tester stands

Most of this lesson is an overview, and the depth belongs elsewhere. Load tests are written in tools
built for them, security testing is a specialism with its own ethics and law, and accessibility
audits are done by people trained in assistive technology. The course in this track that goes deep
on all three is `non-functional-testing`, and `security-fundamentals` takes security further.

What remains for a manual tester is more than it sounds. **You are the first person to use each
build**, and you notice the page that took four seconds, the error that showed a file path, the
field you could not reach with Tab. A number, a screenshot and a sentence in a defect report are
how most non-functional defects are first found, long before anybody runs a tool. The next three
sections show what that looks like on boxoffice.
