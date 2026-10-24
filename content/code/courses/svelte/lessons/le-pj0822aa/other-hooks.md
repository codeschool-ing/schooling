---
title: The other hooks
version: 1
---

**SvelteKit has three hooks files, and the planner has used one.** `src/hooks.server.js` runs on the
server; `src/hooks.client.js` runs in the browser; `src/hooks.js` runs in both. The hooks the planner has
no use for are worth knowing by name, so that the problem each one solves is recognised when it turns
up. None of the code below is part of the planner, and none of it is run in this lesson.

**`handleError` in `hooks.client.js`** is the browser's half of the previous section: an error thrown
while the browser loads or renders a page reaches it instead. It is where an
application reports browser errors to a monitoring service, since they never reach the server's log on
their own.

**`handleFetch`**, in `hooks.server.js`, sits in front of every `fetch` a load function or action makes
on the server. The usual use is to send a request meant for the public address of an API to a faster
internal one, when the server and the API are on the same network:

```javascript
// src/hooks.server.js: an example of handleFetch, not part of the planner.
export async function handleFetch({ request, fetch }) {
	if (request.url.startsWith('https://api.example.com/')) {
		request = new Request(request.url.replace('https://api.example.com/', 'http://localhost:9999/'), request);
	}
	return fetch(request);
}
```

**`reroute`**, in `hooks.js`, changes which route an address is matched to, before anything else runs,
without changing the address. It is how one route can answer under several names, an English address
and a Portuguese one for the same page, say:

```javascript
// src/hooks.js: an example of reroute, not part of the planner.
const aliases = { '/sobre': '/about' };

export function reroute({ url }) {
	return aliases[url.pathname];
}
```

Returning nothing keeps the address's own route.

**`transport`**, in `hooks.js`, teaches SvelteKit to carry a class of your own from a server load
function to the browser, with a function that turns it into data and another that rebuilds it. It is the
way out that lesson 13's `load_not_serializable` message pointed to. It does not make functions
travel; it makes a class whose state is data travel, by sending the data and calling the constructor
again on the other side.

**`init`** runs once, when the server starts or the app starts in the browser, for work such as
connecting to a database before the first request arrives.
