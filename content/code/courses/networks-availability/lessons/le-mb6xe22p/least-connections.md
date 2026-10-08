---
title: Least connections, for requests that are not equal
version: 1
---

The web servers `netlab.sh` built also hold `slow.txt`, 3000 bytes that `nginx` is told to send at 1000 bytes a second,
so a request for it keeps a server busy for about three seconds. The laptop starts downloading it in the background, waits 0.3 seconds, and
sends four ordinary requests. The weights of the last section are still in force:

```
ana@laptop:~$ curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait
served by web2
served by web1
served by web3
served by web1
```

The download's own answer went to `/dev/null`, so the transcript does not say which server took it. It
does not need to. **Round robin handed out the four requests in its fixed order, `web1` twice, whatever
any server was doing**, and one of the three was at that moment busy sending the file. With one slow
download that costs little. With a few hundred, a server that drew several of them keeps being given its
full share of new work on top.

**Least connections asks a different question: which server has the fewest connections open right
now?** The same test, with `balance leastconn`:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance leastconn
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ curl -s -o /dev/null http://www.example.com/slow.txt & sleep 0.3; for i in 1 2 3 4; do curl -s http://www.example.com/; done; wait
served by web2
served by web3
served by web2
served by web3
```

`web2`, `web3`, `web2`, `web3`. **`web1` got none of the four**, which is exactly what the rule says
should happen to the one server with a connection still open, the slow download. The other two were
idle between requests, so they alternated.

HAProxy will show its own counts. The laptop starts one more slow download in the background,
`curl -s -o /dev/null http://www.example.com/slow.txt &`, and half a second later `lb1`'s statistics are
read from its control socket:

```
ana@lb1:~$ echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,5 | grep -E "^web,web"
web,web1,0
web,web2,1
web,web3,0
```

`show stat` prints a long line of comma-separated fields per server, and `cut` keeps three: the backend,
the server and the fifth field, **`scur`, the connections open at that moment**. The header line that
names the fields was filtered away by the `grep`. `web2` has one, the download; the other two have none,
so the next request goes to one of them.

| | round robin | least connections |
|---|---|---|
| decides by | the next name in the list | the fewest connections open now |
| knows about the servers | nothing | their open connections |
| fits | many short requests of similar cost | long or uneven ones: downloads, WebSockets, database sessions |
| weights | turns per round | connections are compared in proportion to weight |

For a website of small pages the two behave almost identically, because every connection closes before
the next arrives and all the counts are zero. **The difference appears only when some requests last much
longer than others**, and then least connections is the one that notices.
