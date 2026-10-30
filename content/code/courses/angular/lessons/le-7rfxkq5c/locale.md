---
title: Whose dates, whose numbers
version: 1
---

**`date`, `number`, `currency` and `percent` format for a locale, and Angular's default is
`en-US`.** That is why the week read "October 19, 2026": American English writes the month first.
This course is written in British English, and the planner should say what its readers would write.
A Portuguese one would want `19 de outubro de 2026`, and decimal commas.

The locale an application is written in is its **source locale**, set in `angular.json`. `ng config`
writes it:

```
ana@dev:~/planner$ npx ng config projects.planner.i18n.sourceLocale en-GB
```

The build then includes the locale's data, the month names, the date patterns, the separators, and
makes it the default for every pipe. The dev server reads `angular.json` when it starts, so stop it
with `Ctrl-C` and start `npx ng serve` again:

```
ana@dev:~/planner$ look http://localhost:4200/ --today 2026-10-23 --text 'app-week p'
[vite] connecting...
[vite] connected.
Angular is running in development mode.
19 October to 25 October 2026
```

Day before month, no comma, and nothing in the template changed.

**One application, one locale per build.** A planner that served English and Portuguese readers
would build twice, once per locale, with Angular's `@angular/localize` translating the template text
as well; that is a project of its own and outside this course. A locale chosen at run time, by the reader, is possible with `LOCALE_ID` and a pipe argument, `{{ day | date: 'longDate' : undefined : 'pt' }}`, after registering that locale's data by hand. Most applications that need it use the build-per-locale approach instead, because it translates everything, not only the dates.
