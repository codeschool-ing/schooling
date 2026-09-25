---
title: Sending a file by FTP
version: 1
---

The company website lives on `www`, at a hosting provider, and the account that owns its files is
`example`. The provider offers FTP, the File Transfer Protocol, which is how the site has been updated
for years. Ana has a new home page to put up:

```
ana@laptop:~$ ftp www.example.com
Trying 192.0.2.80:21 ...
Connected to www.example.com.
220 (vsFTPd 3.0.5)
Name (www.example.com:ana): example
331 Please specify the password.
Password: 
230 Login successful.
Remote system type is UNIX.
Using binary mode to transfer files.
ftp> pwd
Remote directory: /
ftp> ls
229 Entering Extended Passive Mode (|||40007|)
150 Here comes the directory listing.
-rw-r--r--    1 1001     1001          173 Sep 25 18:25 index.html
226 Directory send OK.
ftp> put index.html
local: index.html remote: index.html
229 Entering Extended Passive Mode (|||40001|)
150 Ok to send data.
100% |***********************************|   109      686.74 KiB/s    00:00 ETA
226 Transfer complete.
109 bytes sent in 00:00 (246.40 KiB/s)
ftp> bye
221 Goodbye.
ana@laptop:~$ curl -s https://www.example.com/ | grep Closed
<p>Closed on 12 October for the holiday.</p>
```

Like HTTP in lesson 5, **FTP is text**: the client sends a command and the server answers with a
three-digit code and a sentence. `220` is the greeting, `331` asks for the password, `230` accepts it,
`226` says a transfer finished. The first digit says what kind of answer it is: 2 done, 3 go on,
4 and 5 failed.

`pwd` answered `/`, and that `/` is the site's own folder, not the server's root. The server locks the
account inside it, so `example` reaches the site's files and nothing else on the machine. `put` sent
the new `index.html`, and `curl` shows the website serving it straight away.
