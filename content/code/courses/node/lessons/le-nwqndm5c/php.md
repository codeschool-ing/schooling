---
title: PHP
version: 1
---

**PHP runs a very large share of the web's sites**, WordPress first among them. Its model is the
oldest of the six and the most different: **a PHP program does not run a server.** A web server runs
the PHP file once per request, from the top, and everything it built is thrown away when the answer is
sent.

```sh
sudo apt install php8.3-cli        # Ubuntu and WSL
brew install php                   # a Mac, with Homebrew (not run for this course)
```

```
ana@dev:~/server/other/php$ php --version
PHP 8.3.6 (cli) (built: Oct 19 2026 15:16:58) (NTS)
Copyright (c) The PHP Group
Zend Engine v4.3.6, Copyright (c) Zend Technologies
    with Zend OPcache v8.3.6, Copyright (c), by Zend Technologies
```

```schooling-example
{"language": "php", "file": "hello.php", "parts": [
 {"code": "<?php\n// hello.php: the same server in PHP. Each request runs this file from the top.\n$path = parse_url($_SERVER['REQUEST_URI'], PHP_URL_PATH);\nheader('content-type: application/json');", "note": "**The file is the handler.** There is no `listen` and no routing function: the request is already in variables when the first line runs."},
 {"code": "if ($path === '/hello') {\n    echo json_encode(['hello' => $_GET['name'] ?? 'world']);\n} elseif ($path === '/slow') {\n    sleep(1);\n    echo json_encode(['slept' => 1000]);\n} else {\n    http_response_code(404);\n    echo json_encode(['error' => \"nothing at $path\"]);\n}", "note": "**`$_GET` is the query string, already parsed**, and `json_encode` is in the language. `echo` writes the body of the answer."}
]}
```

PHP has a small web server built in, for development, that runs one file for every request. The port
is on its command line rather than in `PORT`, because the program is the server, not the file:

```
ana@dev:~/server/other/php$ php -S 127.0.0.1:3000 hello.php
[Thu Oct 22 20:11:34 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Accepted
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Closed without sending a request; it was probably just an unused speculative preconnection
[Thu Oct 22 20:11:34 2026] 127.0.0.1:35538 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35540 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35540 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35542 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35542 Closing
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35558 Accepted
[Thu Oct 22 20:11:35 2026] 127.0.0.1:35572 Accepted
[Thu Oct 22 20:11:36 2026] 127.0.0.1:35572 Closing
[Thu Oct 22 20:11:36 2026] 127.0.0.1:35576 Accepted
[Thu Oct 22 20:11:37 2026] 127.0.0.1:35558 Closing
[Thu Oct 22 20:11:37 2026] 127.0.0.1:35592 Accepted
[Thu Oct 22 20:11:38 2026] 127.0.0.1:35576 Closing
[Thu Oct 22 20:11:38 2026] 127.0.0.1:35594 Accepted
[Thu Oct 22 20:11:39 2026] 127.0.0.1:35592 Closing
[Thu Oct 22 20:11:39 2026] 127.0.0.1:35604 Accepted
[Thu Oct 22 20:11:40 2026] 127.0.0.1:35594 Closing
[Thu Oct 22 20:11:40 2026] 127.0.0.1:35610 Accepted
[Thu Oct 22 20:11:41 2026] 127.0.0.1:35604 Closing
[Thu Oct 22 20:11:41 2026] 127.0.0.1:35626 Accepted
[Thu Oct 22 20:11:42 2026] 127.0.0.1:35610 Closing
[Thu Oct 22 20:11:42 2026] 127.0.0.1:35632 Accepted
[Thu Oct 22 20:11:43 2026] 127.0.0.1:35626 Closing
[Thu Oct 22 20:11:43 2026] 127.0.0.1:35636 Accepted
[Thu Oct 22 20:11:44 2026] 127.0.0.1:35632 Closing
[Thu Oct 22 20:11:45 2026] 127.0.0.1:35636 Closing
^C
```

```
ana@dev:~/server/other/php$ curl -s 'http://127.0.0.1:3000/hello?name=ana'
{"hello":"ana"}
ana@dev:~/server/other/php$ curl -s -w ' %{http_code}\n' http://127.0.0.1:3000/nope
{"error":"nothing at \/nope"} 404
ana@dev:~/server/other/php$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m10.017s
user	0m0.034s
sys	0m0.027s
```

**The answers agree, apart from `\/`**: `json_encode` escapes forward slashes, which JSON allows and
no reader minds. **And ten slow requests took ten seconds.** The built-in server runs one request at a
time, so each `sleep(1)` waited for the one before it. It can be told to start more processes:

```
ana@dev:~/server/other/php$ PHP_CLI_SERVER_WORKERS=10 php -S 127.0.0.1:3000 hello.php
[1186] [Thu Oct 22 20:11:47 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
[1187] [Thu Oct 22 20:11:47 2026] PHP 8.3.6 Development Server (http://127.0.0.1:3000) started
^C
```

```
ana@dev:~/server/other/php$ time (for i in $(seq 10); do curl -s -o /dev/null -w '%{http_code} ' http://127.0.0.1:3000/slow & done; wait)
200 200 200 200 200 200 200 200 200 200 
real	0m1.017s
user	0m0.025s
sys	0m0.032s
```

**Ten processes, one second.** That is PHP's answer to concurrency, and in production it is **PHP-FPM**,
a pool of PHP processes behind nginx or Apache, each taking one request at a time. The model has a
property this course spent a section on: **nothing survives between requests**, so the problem lesson
10 found in `cluster` cannot happen. Every piece of state is in a database, a cache or the session store
from the start, because there is nowhere else to put it.

| what | in Node terms |
|---|---|
| **Laravel** or **Symfony** | Express, with a database layer and more included |
| **Composer**, and `composer.json` | `npm` and `package.json` |
| PHP-FPM behind nginx | `node server.js` behind a proxy |
