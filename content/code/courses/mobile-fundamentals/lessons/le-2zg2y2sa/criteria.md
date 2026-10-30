---
title: The questions that decide it
version: 1
---

**No approach is the best one; there is only the best one for a team, an app and a date.** The
common way to choose is to ask which tool is fastest, newest or most popular, and every answer to
that question starts an argument nobody can win, because each side is right about a different app.
The useful way is to ask a fixed set of questions about your own situation, and let the answers
point. Seven questions cover nearly every decision of this kind.

| criterion | the question it asks |
|---|---|
| languages | What does the team already write well, today? |
| device features | Which features does the app need, and how new are they? |
| performance | Does anything have to move smoothly under load: animation, long lists, the camera? |
| time to market | How soon must the first version be in the stores? |
| platforms | Android, iOS, or both, and in what order? |
| long-term cost | Who keeps the app working for the next five years, and with how many codebases? |
| hiring | Can the team find more people who write this, where it hires? |

## What each one weighs

**The team's languages weigh more than any benchmark.** A team of web developers who write
TypeScript every day start React Native or a wrapper already knowing the language, and start
Kotlin and Swift knowing neither. A team that writes Kotlin for Android has the opposite starting point, and Kotlin
Multiplatform lets it keep that language for iOS logic.

**Device features are a question about the border from lesson 2.** An app that needs the camera,
notifications and storage finds libraries for them in every approach. An app built around a feature
Apple or Google released this year waits for someone to write the bridge, or writes it itself in
Kotlin and Swift. The newer and rarer the feature, the stronger the case for native.

**Performance matters where something moves.** Android's documentation on frame rate, as read on 30
October 2026, says devices traditionally refreshed the screen at a single rate, typically 60 Hz, and
that many now also support 90 or 120 Hz.
An app that is lists and forms is smooth in any approach done well. An app that animates under the
user's finger, scrolls thousands of photos or processes the camera's frames feels each layer
between its code and the screen. Lesson 6 measures what a frame costs.

**Time to market counts what already exists.** A team with a working web app is in the stores
soonest with a wrapper, because the screens are already written. A team starting from nothing is not
saved much time by one, and gets the WebView's limits in exchange.

**The number of platforms changes the arithmetic of native.** For one platform, native costs nothing
extra: there is only one app. For two, native means two codebases, and every feature, fix and test
is done twice.

**Long-term cost is paid for years after the decision.** Two native codebases need two sets of
skills for as long as the app lives. One multiplatform codebase needs one, plus whoever maintains the
bridges at the border, plus the work of following the tool's own upgrades.

**Hiring is the criterion teams forget until someone leaves.** The question is not which language
is popular in general, but whether the team can replace a person in the city or market where it
hires, in the language it chose.

## Two things the criteria are not

**They are not a score of the tools.** "Flutter is fast" says nothing until you know what the app
draws. Each criterion is a property of your situation, and the same tool answers it differently for
two teams.

**And they are not equally important.** For a bank, device features and long-term cost may dominate;
for a startup with three months of money, time to market does. How much each question weighs is the
part only the team can decide, and the section after next makes that visible.
