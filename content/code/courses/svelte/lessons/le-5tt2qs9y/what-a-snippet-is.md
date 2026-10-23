---
title: What a snippet compiles to
version: 1
---

**A snippet is a function, and `{@render}` calls it.** Lesson 1's `compile.mjs` shows it directly. Run
it on `List.svelte`:

```
ana@dev:~/planner$ node compile.mjs src/lib/List.svelte
import 'svelte/internal/disclose-version';
import * as $ from 'svelte/internal/client';

var root = $.from_html(`<li><!></li>`);
var root_1 = $.from_html(`<ul></ul>`);

export default function List($$anchor, $$props) {
	$.push($$props, true);

	var fragment = $.comment();
	var node = $.first_child(fragment);

	{
		var consequent = ($$anchor) => {
			var ul = root_1();

			$.each(ul, 21, () => $$props.items, (item) => item.id, ($$anchor, item) => {
				var li = root();
				var node_1 = $.child(li);

				$.snippet(node_1, () => $$props.row, () => $.get(item));
				$.reset(li);
				$.append($$anchor, li);
			});

			$.reset(ul);
			$.append($$anchor, ul);
		};

		var alternate = ($$anchor) => {
			var fragment_1 = $.comment();
			var node_2 = $.first_child(fragment_1);

			$.snippet(node_2, () => $$props.empty ?? $.noop);
			$.append($$anchor, fragment_1);
		};

		$.if(node, ($$render) => {
			if ($$props.items.length) $$render(consequent); else $$render(alternate, -1);
		});
	}

	$.append($$anchor, fragment);
	$.pop();
}
```

The line to find is `$.snippet(node_1, () => $$props.row, () => $.get(item))`. It says three things:
render at `node_1`, the place in the `<li>` the template left for it; the snippet to render is whatever
`row` is **right now**, which is why the first argument is a function; and the argument to pass is
`item`, also behind a function. The `empty` branch is the same call with `?? $.noop`, the do-nothing
function that `?.()` asked for when no `empty` was given.

## Parameters are read when they are used

That last detail has a consequence worth knowing. **A snippet's parameter is not a copy of the value
passed; it is a way of reading it.** When `item` changes, a row that read `item.minutes` updates,
because every use of the parameter inside the snippet goes back through `() => $.get(item)`. So a
snippet behaves like the markup it replaced: it stays live.

The same goes for the snippet itself. If the page swapped in a different `row` snippet later, the list
would start rendering the new one, because `List` asks for `$$props.row` each time rather than
keeping the first one it saw.

## Three more forms

**A snippet can be passed explicitly**, like any prop, when it is declared somewhere else. A snippet
declared at the top level of the page's markup could be given to `List` as `<List items={ofCourse}
{row} />`. Declaring it between the tags is shorthand for exactly that.

**Parameters can be destructured, with defaults**: `{#snippet row({ date, minutes })}` reads the two
fields it needs, and `{#snippet badge(label = 'new')}` has a default. They cannot be reassigned
inside the snippet, which is consistent with what they are: a view of something owned elsewhere.

**A component whose `children` are optional** renders them as `{@render children?.()}`, the same
`?.()` as `empty`. A `Panel` used with no content between its tags would then render its heading alone
rather than fail.
