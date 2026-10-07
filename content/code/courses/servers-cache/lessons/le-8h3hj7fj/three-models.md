---
title: Three servers side by side
version: 1
---

The three servers now run together on one machine, each on its own port:

```
ana@web:~$ sudo ss -ltnp | grep -E ':(80|8080|8081) '
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=287,fd=5),("nginx",pid=285,fd=5),("nginx",pid=284,fd=5),("nginx",pid=283,fd=5),("nginx",pid=227,fd=5))
LISTEN 0      511          0.0.0.0:8080      0.0.0.0:*    users:(("apache2",pid=399,fd=3),("apache2",pid=398,fd=3),("apache2",pid=396,fd=3))                                        
LISTEN 0      4096         0.0.0.0:8081      0.0.0.0:*    users:(("caddy",pid=498,fd=7))                                                                                            
```

The quickest way to see how they differ is to look at their processes. `NLWP` is the number of
threads in each process, and `RSS` its resident memory in kilobytes:

```
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C nginx
    PID    PPID USER     NLWP   RSS CMD
    227       1 root        1  3572 nginx: master process /usr/sbin/nginx -g daemon on; master_proce
    283     227 www-data    1  5120 nginx: worker process
    284     227 www-data    1  5032 nginx: worker process
    285     227 www-data    1  5120 nginx: worker process
    287     227 www-data    1  5032 nginx: worker process
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C apache2
    PID    PPID USER     NLWP   RSS CMD
    396       1 root        1  5380 /usr/sbin/apache2 -k start
    398     396 www-data   27  5880 /usr/sbin/apache2 -k start
    399     396 www-data   27  6824 /usr/sbin/apache2 -k start
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C caddy
    PID    PPID USER     NLWP   RSS CMD
    498       1 caddy       9 35964 /usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Three columns. Nginx: one master process run as root and four single-threaded worker processes, each holding many connections. Apache with the event MPM: one parent process and two children with 27 threads each. Caddy: a single process with nine threads running many goroutines.\"><defs><marker id=\"fpm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nginx</text><rect x=\"40\" y=\"32\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">master (root)</text><rect x=\"20\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"41.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"41\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"26\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"37\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"48\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"68\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"89.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"89\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"74\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"85\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"96\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"116\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"137.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"137\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"122\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"133\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"144\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"164\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"185.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"185\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"170\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"181\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"192\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"115\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1 thread per worker</text><text x=\"115\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">many connections each</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">apache2 (event)</text><rect x=\"275\" y=\"32\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">parent (root)</text><rect x=\"270\" y=\"110\" width=\"75\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"307.5\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">child</text><line x1=\"350\" y1=\"68\" x2=\"307\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"274\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"286\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"298\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"310\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"322\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"334\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"355\" y=\"110\" width=\"75\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392.5\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">child</text><line x1=\"350\" y1=\"68\" x2=\"392\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"359\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"371\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"383\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"395\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"407\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"419\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"350\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">27 threads per child</text><text x=\"350\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">one request per thread</text><text x=\"585\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">caddy</text><rect x=\"505\" y=\"32\" width=\"160\" height=\"114\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">one process</text><rect x=\"517\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"532\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"547\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"562\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"577\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"592\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"607\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"622\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"637\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"517\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"532\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"547\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"562\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"577\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"592\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"607\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"622\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"637\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"585\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9 threads, Go runtime</text><text x=\"585\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a goroutine per connection</text><rect x=\"220\" y=\"228\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"234\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a connection being served</text><rect x=\"420\" y=\"223\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"430\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a thread</text></svg>", "caption": "The processes ps listed on the lab's server. The three designs answer the same question differently: what does a slow client cost?"}
```

**Nginx: a few single-threaded workers, each running an event loop.** A worker never waits for one
client. It asks the kernel which of its thousands of connections have something to read or room to
write, does that bit of work, and asks again. A slow client costs a few kilobytes of memory and no
thread. That design is the reason Nginx became the default thing in front of other software, where
most connections are idle most of the time.

**Apache with `event`: a few processes, each with a pool of threads.** Here two children with 27
threads each. A thread handles a request from start to finish and may block while doing it, which
is simpler to program against (it is why so many modules exist), and the separate listener thread
keeps idle keep-alive connections from tying threads up. Under `prefork`, each connection is a whole
process.

**Caddy: one process, and Go's runtime underneath.** Each connection is a goroutine, a lightweight
thread Go schedules over a handful of real ones, the nine in `NLWP`. It is the event loop again,
written for you by the language runtime rather than by hand. Its 35 MB of memory is mostly the Go
runtime and the code for features this site does not use, such as certificate management.

## And the speed

People choose web servers on benchmarks, so here is one, with `ab`, ApacheBench, from the
`apache2-utils` package: two thousand requests for the stylesheet, fifty at a time, against each
server in turn.

```
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    19176.37 [#/sec] (mean)
Time per request:       2.607 [ms] (mean)
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example:8080/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    15546.42 [#/sec] (mean)
Time per request:       3.216 [ms] (mean)
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example:8081/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    11853.19 [#/sec] (mean)
Time per request:       4.218 [ms] (mean)
```

Read that for what it is. **All three served a small file at between 11,853 and 19,176 requests a
second, on the same machine that was sending the requests**, and the ranking between them changed
from one run of this capture to the next. For a static file, none of them is your bottleneck, and the
numbers above say more about `ab` and the machine than about the servers. What separates them in
production is how they behave with ten thousand slow clients at once, how they are configured and
by whom, and what they do besides serving files. That is the comparison the table makes.

| | Nginx | Apache | Caddy |
|---|---|---|---|
| connections | event loop per worker | threads per process (`event` MPM) | goroutines in one process |
| configuration | nested blocks, `nginx -t` | directives and `<VirtualHost>`, `apachectl configtest` | Caddyfile or JSON, `caddy validate` |
| per-directory config | no | `.htaccess` | no |
| HTTPS | you configure it (lesson 3) | you configure it | automatic by default |
| where you meet it | in front of almost everything | shared hosting, older stacks, PHP | small sites, internal tools |

This course uses Nginx from here on, for the reason in the last row of that table. Lesson 3 comes
back to Caddy, because automatic certificates are its strongest argument.
