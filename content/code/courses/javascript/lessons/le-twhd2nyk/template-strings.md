---
title: Template strings
version: 1
---

Text in JavaScript is a **string**, written between quotes. Single and double quotes are the same
thing. A third kind, the **backtick**, makes a template string, and it does two things the others
cannot: it puts values inside the text, and it spans lines.

## Values inside text

```javascript
const title = "Dom Casmurro";
const year = 1899;

console.log("'" + title + "' came out in " + year + ", " + (2026 - year) + " years ago.");
console.log(`'${title}' came out in ${year}, ${2026 - year} years ago.`);
console.log(`${title.toUpperCase()} has ${title.length} characters`);
console.log(`Is it old? ${year < 1950 ? "yes" : "no"}`);
```

```
'Dom Casmurro' came out in 1899, 127 years ago.
'Dom Casmurro' came out in 1899, 127 years ago.
DOM CASMURRO has 12 characters
Is it old? yes
```

The first line builds the sentence with `+`, and the second with a template. The output is the
same; **the template is the one you can read**, because the sentence is written as a sentence.
Inside `${ }` goes any expression: a name, arithmetic, a method call, a condition. The value is
turned into text and dropped in place.

## Text that spans lines

A quoted string must end on the line it starts. A template keeps the line breaks you type:

```javascript
const card = `Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899`;

console.log(card);
console.log(card.split("\n").length, "lines");
```

```
ana@dev:~/js$ node multiline.js
Title:  Dom Casmurro
Author: Machado de Assis
Year:   1899
3 lines
```

The indentation is kept too, which is why `card` starts its continuation lines at the margin. A
template indented to match the code around it carries those spaces into the text.

## Tagged templates

A name written straight before the backtick is a **tag**: a function that receives the template's
fixed pieces and its values separately, and decides what to make of them.

```javascript
console.log(`C:\notes\today`);
console.log(String.raw`C:\notes\today`);

function shout(strings, ...values) {
  console.log(strings);
  console.log(values);
  return strings.reduce((out, s, i) => out + s + (i < values.length ? String(values[i]).toUpperCase() : ""), "");
}

const who = "ana";
console.log(shout`hello ${who}, it is ${2026}`);
```

```
ana@dev:~/js$ node tagged.js
C:
otes	oday
C:\notes\today
[ 'hello ', ', it is ', '' ]
[ 'ana', 2026 ]
hello ANA, it is 2026
```

The first line went wrong on purpose. In any string, `\n` is a line break and `\t` a tab, so the
path was printed in pieces. `String.raw` is a tag built into the language that **keeps the
backslashes as they were typed**. `shout` is a tag ana wrote: it was handed the three fixed pieces
and the two values, and joined them with the values in capitals.

**A template does not make text safe to put into a web page.** It joins strings and nothing else,
so a value that contains HTML stays HTML. Lesson 11 shows what that costs and the one property to
use instead.
