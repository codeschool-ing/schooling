---
title: Elements, tags and attributes
version: 2
---

An HTML file is text, and the text is of two kinds: **content**, which is what the reader reads, and **markup**, which says what the content is. Markup is written in tags, and the vocabulary for talking about them is worth getting exactly right, because the rest of the course uses it constantly.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 206\" role=\"img\" aria-label=\"One link element, &lt;a href=&quot;events.html&quot; class=&quot;nav&quot;&gt;Events&lt;/a&gt;, taken apart. The opening tag holds the element name and two attributes, each a name, an equals sign and a quoted value. The word Events is the content. The closing tag repeats the name after a slash. All of it together is the element.\"><rect x=\"20\" y=\"42\" width=\"680\" height=\"40\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"60\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&lt;a</text><text x=\"96\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">href</text><text x=\"144\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">=</text><text x=\"156\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">&quot;events.html&quot;</text><text x=\"324\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--amber)\">class</text><text x=\"384\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">=</text><text x=\"396\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">&quot;nav&quot;</text><text x=\"456\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&gt;</text><text x=\"468\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--paper)\">Events</text><text x=\"540\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"20\" fill=\"var(--phosphor)\">&lt;/a&gt;</text><path d=\"M60 100 v8 H468 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"264\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">opening tag</text><text x=\"264\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">name and attributes</text><path d=\"M468 100 v8 H540 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><text x=\"504\" y=\"122\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">content</text><path d=\"M540 100 v8 H588 v-8\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></path><line x1=\"564\" y1=\"110\" x2=\"564\" y2=\"136\" stroke=\"var(--paper-dim)\" stroke-width=\"1\"></line><text x=\"564\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">closing tag</text><path d=\"M96 40 v-6 H312 v6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"204\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">attribute: name=&quot;value&quot;</text><path d=\"M324 40 v-6 H456 v6\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><text x=\"390\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">attribute</text><path d=\"M60 166 v8 H588 v-8\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></path><text x=\"324\" y=\"190\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\" font-weight=\"600\">the element: everything from the first &lt; to the last &gt;</text></svg>", "caption": "An element is the whole thing; a tag is only its two ends."}
```

**A tag** is what is written between angle brackets. `<a href="events.html">` is an opening tag and `</a>` is its closing tag, the same name after a slash.

**An element** is the whole thing: the opening tag, the closing tag and everything between them. "The link element" means all of `<a href="events.html" class="nav">Events</a>`, including the word *Events*. People say "the `a` tag" when they mean the element all the time, and in conversation nobody minds; when the difference matters, which it does in this lesson, the element is the thing in the tree and the tags are how it was written.

**An attribute** is extra information written inside the opening tag, as a name, an equals sign and a value in quotes: `href="events.html"` tells the link where it goes, `class="nav"` gives it a name CSS can find it by. An element can carry several, in any order, separated by spaces. Some attributes need no value at all, because being there is the information: `<input required>` is a required field, and writing `required="false"` would still make it required, since the browser only checks whether the attribute is present.

## Elements inside elements

Elements nest, and the rule for nesting is strict: **an element closes before its parent closes**. This is right, because `<em>` opens and closes inside `<p>`:

```html
<p>Open <em>every</em> day.</p>
```

This is wrong, because `<em>` is still open when `<p>` closes:

```html
<p>Open <em>every day.</p></em>
```

The browser will show the second one without complaint, and section 09 shows what it builds from markup like it. That forgiveness is the reason a mistake like this survives for years in a real site.

## Elements with nothing inside

Some elements cannot have content, so they have no closing tag. They are called **void elements**, and there are only a few you will meet often: `<img>` for an image, `<input>` for a form field, `<br>` for a line break, `<hr>` for a thematic break, and `<meta>` and `<link>` in the head. You may see them written `<img />` with a slash before the bracket; that is a habit from XHTML that HTML tolerates and ignores, and this course leaves it out.

## Characters that mean something

Because `<` starts a tag, a page that needs to show a literal less-than sign has to write it differently: `&lt;`. These are **character references**, and four are worth knowing: `&lt;` for `<`, `&gt;` for `>`, `&amp;` for `&` and `&quot;` for a double quote inside an attribute value. A page listing *Pride & Prejudice* writes the ampersand as `&amp;` in its HTML, and the reader sees `&`. Any other character, an `ã` or a `€`, is simply typed, provided the file declares that it is UTF-8, which is section 10.

HTML does not care about case in element names, so `<P>` and `<p>` are the same element. Write them in lower case: every style guide does, and so does the rest of this course.
