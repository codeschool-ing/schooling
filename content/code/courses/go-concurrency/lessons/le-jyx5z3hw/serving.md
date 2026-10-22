---
title: Serving a website from the binary
version: 1
---

The commonest use of an `embed.FS` is the one this platform itself makes: a web server that carries
its own pages, scripts and stylesheets, so that deploying it is copying one file. **`http.FileServerFS`
serves any `fs.FS`, and `fs.Sub` makes a sub-directory of one into a file system of its own.** Saved
as `serve/main.go`:

```go
// Command serve answers HTTP requests from files built into it.
package main

import (
	"embed"
	"io/fs"
	"log"
	"net/http"
)

//go:embed static
var files embed.FS

func main() {
	root, err := fs.Sub(files, "static")
	if err != nil {
		log.Fatal(err)
	}
	http.Handle("/", http.FileServerFS(root))
	log.Fatal(http.ListenAndServe("127.0.0.1:8024", nil))
}
```

`fs.Sub(files, "static")` is why the request for `/` finds `index.html` rather than needing
`/static/index.html`. The server listens on `127.0.0.1` only, so nothing outside this machine can
reach it. The same `static` directory is copied beside it and the program built:

```
ana@vm:~/embedding$ cp -r site/static serve/
ana@vm:~/embedding$ go build -o bin/serve ./serve
ana@vm:~/embedding$ ls -l bin/serve
-rwxr-xr-x 1 ana ana 8844359 Oct 16 19:54 bin/serve
```

Almost nine million bytes: the HTTP server is most of it, and the four files a few dozen bytes.
Started in the background, it answers from what was built in:

```
ana@vm:~/embedding$ curl -s http://127.0.0.1:8024/
<h1>Orders</h1>
ana@vm:~/embedding$ curl -s -o /dev/null -w "%{http_code} %{content_type}\n" http://127.0.0.1:8024/style.css
200 text/css; charset=utf-8
ana@vm:~/embedding$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8024/_notes.txt
404
ana@vm:~/embedding$ rm -r serve/static
ana@vm:~/embedding$ curl -s http://127.0.0.1:8024/
<h1>Orders</h1>
```

The page came back, the stylesheet arrived with the right content type, which `FileServerFS`
worked out from the extension, and `_notes.txt` was a 404, because the plain pattern never embedded
it. **Then the `static` directory was deleted, and the server went on serving the page**, because
it never reads that directory: the directory existed for the build and for nothing after it.

## What embedding is not for

The files are fixed at build time, which is the point and also the limit. Content that changes
without a release, a user's upload, a configuration that differs between environments, belongs on
disk or in a database, read at run time. And an embedded file costs its size in the binary and in
memory: a few stylesheets cost nothing, while a gigabyte of video would be a gigabyte in every copy
of the program.
