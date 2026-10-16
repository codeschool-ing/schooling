---
title: Distributed execution
version: 1
---

One load generator has a ceiling: its processors, its memory, its network card. **Past that
ceiling, the generator is what is being measured**, which lesson 2 warned about with a much
smaller program. JMeter's answer is to run one plan on several machines at once, directed from one
of them.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-distributed\" aria-label=\"Distributed execution. On the left, the controller, which runs jmeter with -R. It sends the test plan and the -G properties to two workers, each running jmeter-server and each with its own copy of shows.csv. Both workers run the whole plan and send their requests to the system under test on the right. The samples travel back from each worker to the controller, which writes one results file. Ten users a worker on two workers is twenty users in all.\"><defs><marker id=\"l04-distributed-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-distributed-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l04-distributed-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"105.0\" width=\"150.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">controller</text><text x=\"95.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter -n -R …</text><text x=\"95.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dist.jtl</text><rect x=\"285.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"365.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker 1</text><text x=\"365.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter-server :1099</text><text x=\"365.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shows.csv</text><path d=\"M172.0 140.0 L283.0 65.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-paper)\"></path><path d=\"M283.0 87.0 L172.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-distributed-nf-ah-phosphor)\"></path><path d=\"M447.0 75.0 L553.0 138.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-amber)\"></path><rect x=\"285.0\" y=\"200.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"365.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker 2</text><text x=\"365.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter-server :1100</text><text x=\"365.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shows.csv</text><path d=\"M172.0 160.0 L283.0 225.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-paper)\"></path><path d=\"M283.0 247.0 L172.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-distributed-nf-ah-phosphor)\"></path><path d=\"M447.0 235.0 L553.0 162.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-amber)\"></path><text x=\"95.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">sends the plan, -G</text><text x=\"95.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">samples come back</text><rect x=\"555.0\" y=\"115.0\" width=\"145.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"627.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">system under test</text><text x=\"627.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">127.0.0.1:8000</text><text x=\"500.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">each worker runs the whole plan: 10 users each, 20 in all</text></svg>", "caption": "One controller, several workers. The plan travels to the workers; the files it reads do not."}
```

- The **workers** run `jmeter-server`, which waits to be told what to do. Each one runs the whole
  test plan with all of its threads, so ten users on each of two workers is twenty users against
  the system under test.
- The **controller** runs `jmeter -n -t plan.jmx -R host1,host2`. It sends the plan to every
  worker named after `-R` (or to every worker listed in `remote_hosts` in `jmeter.properties`, with
  `-r`), starts them together, and collects the samples they send back into one `.jtl`.
- **Properties go with `-G`, not `-J`.** `-J` sets a property on the machine where it is typed, the
  controller, which runs no threads; `-G` sends it to the workers as well.
- **The plan travels and its files do not.** Each worker reads `shows.csv` from its own disk, from
  the directory `jmeter-server` was started in. A worker started where there was none, tried while
  writing this lesson, recorded no samples at all.

The controller and the workers talk over Java RMI. That traffic is encrypted by default and needs a
keystore made with the `create-rmi-keystore.sh` script in JMeter's `bin`. On a private network of
your own, `server.rmi.ssl.disable=true` switches the encryption off, and every command here sets
it, on the workers and on the controller alike.

## One machine standing in for three

A real distributed test runs each worker on a machine of its own. **What follows runs both workers
and the controller on the one VM**, on different ports, because the point is to see the mechanism
and the VM is the only machine you have. It measures nothing a single JMeter could not, and a test
that needed more generators would get none from this.

The first attempt at starting a worker fails, and the failure is worth knowing, because it happens
on most Linux machines:

```
ana@nft:~/loadtest$ timeout 60 jmeter-server -Dserver_port=1099 -Jserver.rmi.ssl.disable=true
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Created remote object: UnicastServerRef2 [liveRef: [endpoint:[127.0.1.1:34937](local),objID:[fef7d06:1a1276024f1:-7fff, 3849172207519650938]]]
Server failed to start: java.rmi.RemoteException: Cannot start. nft is a loopback address.
An error occurred: Cannot start. nft is a loopback address.
```

The worker looked up its own hostname to tell the controller where to reach it, and Ubuntu maps
`nft` to `127.0.1.1` in `/etc/hosts`, a loopback address no other machine could use. JMeter
refuses to start rather than hand out an address that would not work. **`-Djava.rmi.server.hostname`
names the address to advertise**: on real machines, the worker's own IP on the network the
controller is on; here, `127.0.0.1`.

Each worker gets a directory with its own copy of the data file:

```
ana@nft:~/loadtest$ mkdir -p ~/worker1 ~/worker2 && cp shows.csv ~/worker1/ && cp shows.csv ~/worker2/
```

Then two more terminals (`multipass shell nft` again), one per worker. In the first, from
`~/worker1`:

```sh
jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
```

And in the second, from `~/worker2`, the same with its own two ports:

```sh
jmeter-server -Dserver_port=1100 -Jserver.rmi.localport=50002 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
```

`server_port` is where the worker listens for the controller, 1099 by default, and
`server.rmi.localport` fixes the second port RMI would otherwise pick at random, which matters on a
real network where a firewall has to let both through. With both waiting, the controller runs the
plan from `~/loadtest`, with ten users on each worker, for twenty seconds:

```
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -R 127.0.0.1:1099,127.0.0.1:1100 -Jserver.rmi.ssl.disable=true -Gusers=10 -Gseconds=20 -l dist.jtl
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Configuring remote engine: 127.0.0.1:1099
Configuring remote engine: 127.0.0.1:1100
Starting distributed test with remote engines: [127.0.0.1:1100, 127.0.0.1:1099] @ 2026 Oct 10 16:53:04 BRT (1791661984280)
Remote engines have been started:[127.0.0.1:1100, 127.0.0.1:1099]
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =    229 in 00:00:20 =   11.2/s Avg:    12 Min:     1 Max:    69 Err:     0 (0.00%)
Tidying up remote @ 2026 Oct 10 16:53:25 BRT (1791662005416)
... end of run
ana@nft:~/loadtest$ cut -d, -f6 dist.jtl | cut -d- -f1 | sort | uniq -c
    112 127.0.0.1:1099
    117 127.0.0.1:1100
      1 threadName
```

The controller configured both engines, started them, and printed one summary for both: 229 samples
in 20 seconds, no errors. The `threadName` column of `dist.jtl` now begins with the worker's
address, and counting by it shows the samples split between the two, 112 from the worker on 1099
and 117 from the one on 1100. Meanwhile, the first worker's terminal showed this:

```
ana@nft:~/worker1$ jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Using local port: 50001
Created remote object: UnicastServerRef2 [liveRef: [endpoint:[127.0.0.1:50001](local),objID:[-3a01a255:1a12760311f:-7fff, -3003621217474519746]]]
Starting the test on host 127.0.0.1:1099 @ 2026 Oct 10 16:53:05 BRT (1791661985157)
Finished the test on host 127.0.0.1:1099 @ 2026 Oct 10 16:53:25 BRT (1791662005416)
```

`Ctrl+C` stops each worker when you are done. On real machines the same commands apply with real
addresses, plus two practical rules. The workers should be identical, so that one slow machine does
not skew the total. And the controller collects every sample over the network, so at very high
rates JMeter's *sample sender* settings batch or summarise them on the workers first.
