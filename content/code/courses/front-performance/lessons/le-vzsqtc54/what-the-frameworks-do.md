---
title: What the frameworks do
version: 1
---

**Everything in this lesson is a step each of the four frameworks of lesson 2 can take for you**, and
each takes a different set of them. Knowing the steps is what lets you tell which ones yours took. This
section was read from each framework's documentation and, where it says *checked*, from the package
installed in lesson 2's projects; none of it was run.

## Pictures

| | the component | what it does on its own | what you still decide |
|---|---|---|---|
| **Next.js** | `<Image>` from `next/image` | resizes on request on its own server, writes `srcset`, sends WebP by default (checked), lazy-loads unless told otherwise, insists on `width` and `height` or `fill` | `sizes`; and `preload` on the LCP picture, the prop that replaced `priority` in Next.js 16 (checked) |
| **Nuxt** | `<NuxtImg>` and `<NuxtPicture>`, from the `@nuxt/image` module, installed separately | resizes through a provider, by default IPX, a server built on sharp; `<NuxtPicture>` writes the `<source>` per format | `sizes`, the formats, and `preload` and `loading` on each picture |
| **SvelteKit** | `<enhanced:img>`, from the `@sveltejs/enhanced-img` package | at build time, with sharp: the copies, AVIF and WebP, the `srcset`, and `width` and `height` from the file | `sizes` and `fetchpriority`; it works only on pictures in the project, not ones from a server |
| **Angular** | the `NgOptimizedImage` directive, `ngSrc` on an `<img>` | insists on `width` and `height`, lazy-loads by default, and with `priority` sets `fetchpriority="high"` and, when rendered on the server, adds a preload (checked) | the copies themselves: it writes a `srcset` for an image service's loader and does not resize |

## Fonts

| | what it does |
|---|---|
| **Next.js** | `next/font` downloads the font at build time and serves it from the application, with `display: "swap"` and `adjustFontFallback` on by default (checked): it writes a fallback face for Arial or Times New Roman with the `size-adjust` of the section "A fallback that takes the same room", computed from the font files |
| **Nuxt** | `@nuxt/fonts` reads the font families your CSS names, downloads and serves them from the application, and computes fallback faces with the library fontaine |
| **SvelteKit** | nothing of its own; Fontsource and the CSS of this lesson are the usual way |
| **Angular** | the production build inlines the CSS of Google Fonts into the page, and inlines critical CSS with Beasties, as the section "The stylesheet, inside the page" said |

## Reading them

**None of them takes every step**, and the gaps differ: Next.js and Angular leave `sizes` to you,
SvelteKit leaves the font, Angular leaves the resizing to a service. And each default is a decision
somebody made for most pages: lazy loading by default is right for a page of thumbnails and wrong for its
first picture, which is why all four have a way to say "this one is the LCP" and none of them can know
which one it is. Lighthouse's LCP request discovery is the check that you said so.
