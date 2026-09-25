---
title: The same tools on Windows and macOS
version: 1
---

`curl` is on every system now, which makes this lesson's commands portable:

```sh
curl.exe -sv -o NUL https://www.example.com/          # Windows 10 and later ship curl as curl.exe
Invoke-WebRequest https://www.example.com/ -Method Head   # Windows PowerShell: status and headers
curl -sv -o /dev/null https://www.example.com/        # macOS: curl is built in
```

**None of these were run for this lesson.** On Windows, type `curl.exe` rather than `curl`: in
Windows PowerShell 5.1, `curl` is an alias for `Invoke-WebRequest`, which takes different options and
prints differently (PowerShell 7 dropped the alias). Every `-w` timer of section 07 works in
`curl.exe` too, with Windows' quoting.

In a browser, the developer tools' *Network* tab, covered in the web-fundamentals course, shows the
same things per request: the status, the headers, the protocol (`h2`), and a timing bar split into
DNS, connection, TLS and waiting for the server.
