---
title: Two documentation pages, and what they load
version: 1
---

FastAPI serves two pages that render the schema for people: **`/docs`**, Swagger UI, where each
operation has a *Try it out* button that sends a real request, and **`/redoc`**, ReDoc, a reference
page laid out for reading. Open them in a browser through the tunnel of lesson 5, on port 8001.

Neither page is in FastAPI's package. Each is a small HTML file that loads the real program from
elsewhere:

```
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/docs | grep -oE "https://[^\"]+"
https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui.css
https://fastapi.tiangolo.com/img/favicon.png
https://cdn.jsdelivr.net/npm/swagger-ui-dist@5/swagger-ui-bundle.js
ana@vm:~/agenda-api$ curl -s http://127.0.0.1:8001/redoc | grep -oE "https://[^\"]+"
https://fonts.googleapis.com/css?family=Montserrat:300,400,700|Roboto:300,400,700
https://fastapi.tiangolo.com/img/favicon.png
https://cdn.jsdelivr.net/npm/redoc@2/bundles/redoc.standalone.js
```

**Both load JavaScript from `cdn.jsdelivr.net`, and ReDoc loads fonts from Google**, every time
somebody opens the page. That has three consequences worth knowing before deciding where the pages
are served:

- a machine without internet access shows a blank page, though the API works;
- the browser of whoever reads the documentation contacts those companies, which a privacy policy
  may have to say;
- the version is `swagger-ui-dist@5` and `redoc@2`, which is whatever those major versions are on the
  day, rather than a file you chose and reviewed.

FastAPI's documentation shows how to serve both pages from files of your own, with `docs_url=None`
and a route that returns the HTML pointing at your copies. And an API that is not public can switch
everything off, `FastAPI(docs_url=None, redoc_url=None, openapi_url=None)`, which removes the pages
and the schema with one line, as long as nothing else needs the schema.
