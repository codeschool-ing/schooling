---
title: What to leave out of the count
version: 1
---

Some code is not worth testing in the suite, and counting it as missed only adds noise to the list
a reader has to check. Coverage tools let you exclude it. Used narrowly, that keeps the report
honest; used broadly, it is the threshold game of section 06 played with configuration.

`app.py` is at 76%, and part of what it misses is the program's entry point:

```
ana@laptop:~/shipquote$ coverage run -m pytest -q > /dev/null; coverage report -m --include=shipquote/app.py
Name               Stmts   Miss Branch BrPart  Cover   Missing
--------------------------------------------------------------
shipquote/app.py      54     12      8      3    76%   20-21, 23, 31, 36-38, 60-63, 67
--------------------------------------------------------------
TOTAL                 54     12      8      3    76%
ana@laptop:~/shipquote$ sed -n 58,67p shipquote/app.py

def main():
    port = int(os.environ.get("SHIPQUOTE_PORT", "8080"))
    server = ThreadingHTTPServer(("127.0.0.1", port), Handler)
    print(f"shipquote {VERSION} listening on 127.0.0.1:{port}", file=sys.stderr)
    server.serve_forever()


if __name__ == "__main__":
    main()
ana@laptop:~/shipquote$ git diff pyproject.toml | tail -4
 
 [tool.coverage.report]
 show_missing = true
+exclude_also = ["if __name__ == .__main__.:"]
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/app.py
Name               Stmts   Miss Branch BrPart  Cover   Missing
--------------------------------------------------------------
shipquote/app.py      52     11      6      2    78%   20-21, 23, 31, 36-38, 60-63
--------------------------------------------------------------
TOTAL                 52     11      6      2    78%
```

Lines 60 to 63 are `main()`, which reads the port and starts a server forever, and line 67 is the
`if __name__ == "__main__":` guard that calls it when the file is run as a program. The tests start
the server their own way, in a thread, so these lines never run in the suite.

The project adds one line of configuration, `exclude_also`, a list of patterns whose matching lines
and blocks are left out of the count. The pattern here matches the guard, so line 67 disappears
from the report and the file goes to 78%. **`main()` itself stays counted**, and that is a decision
worth explaining.

## What earns an exclusion

| exclude | do not exclude |
|---|---|
| the `if __name__ == "__main__":` guard | the function it calls |
| code for type checkers only, under `if TYPE_CHECKING:` | error handling you have not tested yet |
| an `assert False` marking a branch that cannot happen | a branch you believe cannot happen |
| debugging helpers that never run in production | a whole module "because it is hard to test" |

`main()` reads `SHIPQUOTE_PORT` from the environment and builds the server, and both can be wrong:
a typo in the variable name, a server bound to the wrong address. Those are worth checking, and the
check that will cover them is the smoke test of lesson 7, which starts the deployed program and asks
it `/health`. Excluding `main()` would hide it from the one report that shows it is not yet checked
anywhere.

The marker `# pragma: no cover` on a line excludes that line, or the block it opens, the same way.
**Every exclusion should say why**, in a comment beside it, because a reader of the report cannot
see what is no longer in it.
