---
title: ssr = false, and the page that arrives empty
version: 1
---

**`export const ssr = false` makes the server send a page with nothing in it and leaves all of the
rendering to the browser.** That is how most single-page applications work, and SvelteKit can do it per
page. Try it on About. Save this as `src/routes/(info)/about/+page.js`:

```schooling-example
{"language": "javascript", "file": "src/routes/(info)/about/+page.js", "parts": [
 {"code": "// +page.js: page options for About. (A trial: the next section changes it.)\nexport const ssr = false;", "note": "The server sends the page without rendering it; the browser does all of it."}
]}
```

Build, restart the server, and read the body of what it sends for `/about`:

```
ana@dev:~/planner$ curl -s http://localhost:3000/about | sed -n '/<body/,/<\/body>/p'
	<body data-sveltekit-preload-data="hover">
		<div style="display: contents">
			<script>
				{
					__sveltekit_1il064a = {
						base: new URL(".", location).pathname.slice(0, -1),
						version: "1792803344039"
					};

					const element = document.currentScript.parentElement;

					import("./_app/immutable/entry/start.DB_ekTOL.js").then(async (kit) => {
						kit.init(__sveltekit_1il064a);
						const app = await import("./_app/immutable/entry/app.CM8src-9.js");
						kit.start(app, element);
					});
				}
			</script>
		</div>
	</body>
```

**No heading, no paragraph, no header with its links**: one script, which imports SvelteKit's code and
the app's and then renders the page in the browser. In a browser with JavaScript, the result is the same
page:

```
ana@dev:~/planner$ look http://localhost:3000/about
at /about
title: About · Study planner
- main:
  - heading "About the planner" [level=1]
  - paragraph: The study planner lists your courses, the sessions you plan for each, and the minutes in your week. It keeps everything on this computer, in one small file, and asks nobody for anything.
  - paragraph:
    - link "Back to the planner":
      - /url: /
```

and in one without, nothing:

```
ana@dev:~/planner$ look http://localhost:3000/about --no-js
at /about
```

It costs three things, and each is a reason to keep the default:

- **Nothing until the script has run.** The browser downloads the HTML, then the scripts, then runs
  them, and only then is there anything to see. With SSR the text is in the first response.
- **Nothing at all without JavaScript**, the dependence lesson 14 spent a whole lesson taking out of
  the planner.
- **Nothing for anything that reads HTML and does not run scripts**: some search engines, link
  previews in chat applications, and plenty of tools.

`ssr = false` earns its place for a page that cannot be rendered on the server at all, because it uses
`window` or `document` while it renders, or a library that does. For a page that can be rendered on the
server, it gives up all three for nothing.
