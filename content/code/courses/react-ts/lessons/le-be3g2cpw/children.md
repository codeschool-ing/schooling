---
title: Children and composition
version: 1
---

**A component can leave a hole for its parent to fill.** Whatever a parent writes between a
component's opening and closing tags arrives as one more prop, called `children`, and the component
puts it wherever it chooses. This is how React shares a layout between parts of an app: not by one
component extending another, but by one component wrapping whatever it is given.

The planner's `Card` is a frame with a heading. What goes under the heading is not its business.
Save it as `src/Card.tsx`:

```tsx
import type { ReactNode } from 'react'

type CardProps = {
  title: string
  children: ReactNode
}

export function Card({ title, children }: CardProps) {
  return (
    <article className="card">
      <h2>{title}</h2>
      {children}
    </article>
  )
}
```

`ReactNode` is the type of anything React can draw: an element, a string, a number, an array of
those, or nothing at all. `CourseCard` fills the hole with a paragraph:

```tsx
<Card title={course.name}>
  <p>
    {count} {count === 1 ? 'session' : 'sessions'} · {minutes(sessions)} min
  </p>
</Card>
```

```schooling-figure
{"svg": "<svg data-fig=\"slot\" viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Card drawn as a frame with a heading and an empty slot labelled children. On the right, CourseCard writes a paragraph between Card's tags, and an arrow shows the paragraph landing in the slot. Card decides where the slot is; the parent decides what fills it.\"><text x=\"150\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">Card: the frame</text><rect x=\"30\" y=\"36\" width=\"240\" height=\"150\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"46\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;article&gt;</text><text x=\"58\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;h2&gt;{title}&lt;/h2&gt;</text><rect x=\"58\" y=\"100\" width=\"190\" height=\"52\" rx=\"4\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"153.0\" y=\"126.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">{children}</text><text x=\"46\" y=\"172\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">&lt;/article&gt;</text><text x=\"520\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">CourseCard: what goes in</text><rect x=\"380\" y=\"36\" width=\"300\" height=\"150\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"396\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;Card title={course.name}&gt;</text><rect x=\"408\" y=\"84\" width=\"250\" height=\"54\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"420\" y=\"104\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">&lt;p&gt;2 sessions · 90 min&lt;/p&gt;</text><text x=\"396\" y=\"162\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">&lt;/Card&gt;</text><path d=\"M 408 111 C 330 111 330 126 250 126\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></path><polygon points=\"250.0,126.0 257.2,122.2 257.7,128.6\" fill=\"var(--amber)\"></polygon></svg>", "caption": "The child decides where; the parent decides what."}
```

`Card` never learns that it is showing a course. Next week it can frame a session, a form, an error
message, and none of them needs to know how the frame is drawn. **The parent decides what goes in,
and the child decides where.** That split is what React means by composition, and it is the answer
to every "how do I make a variation of this component" question that would be inheritance in a
language built around classes.

## The first screen

With `Card.tsx` saved, every import resolves and the screen draws itself:

```
ana@dev:~/planner$ look http://localhost:5173/
- main:
  - heading "Study planner" [level=1]
  - region "This week":
    - paragraph: Week of 19 Oct 2026
    - paragraph: 80 of 195 minutes done
  - region "Courses":
    - article:
      - heading "Statistics" [level=2]
      - paragraph: 2 sessions · 90 min
    - article:
      - heading "Spanish" [level=2]
      - paragraph: 2 sessions · 60 min
    - article:
      - heading "Organic chemistry" [level=2]
      - paragraph: 1 session · 45 min
```

**80 of 195 minutes, and 90, 60 and 45 for the three courses**: the numbers lesson 1 said every
version of this screen has to reach. The snapshot also shows the structure the components made.
The two `section` elements with an `aria-label` became regions with names, each `article` holds a
heading at level 2 from `Card`, and the singular "1 session" came from the ternary in `CourseCard`.
