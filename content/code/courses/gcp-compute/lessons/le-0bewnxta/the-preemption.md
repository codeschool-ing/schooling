---
title: The thirty seconds
version: 1
---

When Google needs a Spot machine back, it does not pull the plug. **It sends the machine the signal
a power button sends, waits about thirty seconds for it to shut down on its own, and then stops it
regardless.** What your software does with those thirty seconds decides whether a preemption costs
a few seconds of work or everything since the last save.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 240\" role=\"img\" aria-label=\"A timeline of a preemption. At the start, Compute Engine sends an ACPI soft power-off and sets instance/preempted to TRUE. Over the next thirty seconds, about, the services receive SIGTERM, the shutdown script runs and the operating system shuts down. At the end of the thirty seconds the machine is stopped regardless, and whatever was not saved is lost.\"><defs><marker id=\"l6p-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><path d=\"M60 120 L660 120\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M60 120 L60 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6p-ah)\"></path><path d=\"M660 120 L660 70\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l6p-ah)\"></path><rect x=\"20\" y=\"22\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">soft power-off</text><text x=\"120.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">ACPI, the notice</text><rect x=\"560\" y=\"22\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">hard stop</text><text x=\"635.0\" y=\"53.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no more notice</text><text x=\"360\" y=\"108\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">about 30 seconds</text><rect x=\"90\" y=\"140\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"170.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">SIGTERM</text><text x=\"170\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">to every service</text><rect x=\"270\" y=\"140\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">shutdown script</text><text x=\"350\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">lesson 7 sets it</text><rect x=\"450\" y=\"140\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">instance/preempted</text><text x=\"545\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">reads TRUE</text></svg>", "caption": "Everything that saves work has to fit in the thirty seconds between the notice and the hard stop."}
```

## What the machine sees

Inside the machine, the preemption arrives as an **ACPI soft power-off**, the same event as somebody
pressing the power button. The operating system starts an orderly shutdown: systemd stops services in
order, and each service is sent `SIGTERM` and given a moment to exit. Compute Engine also runs the
machine's **shutdown script**, if its metadata has one, a script lesson 7 sets up the same way as a
startup script. And the metadata server's value `instance/preempted` changes to `TRUE`, so a program
that polls it can tell a preemption from an ordinary shutdown.

The thirty seconds are a best effort, not a promise, and they cover everything: the services, the
shutdown script and the operating system's own shutdown. **A shutdown script that needs a minute
does not get one.** It is the place to flush a buffer or mark a job as interrupted, not to upload a
gigabyte.

## Thirty seconds on the laptop

None of that can be produced here: there is no Spot machine to take back. What can be shown is the
part that is yours, a program that hears `SIGTERM` and uses the time well, because `docker stop` sends
exactly that signal and then waits a number of seconds before killing the process. Save this as
`~/gcp/worker.py`:

```python
# worker.py
import signal
import time

done = 0
stopping = False


def stop(signum, frame):
    global stopping
    stopping = True


signal.signal(signal.SIGTERM, stop)
print('started', flush=True)
while not stopping:
    time.sleep(1)  # one unit of work
    done += 1
print(f'SIGTERM after {done} units: saving progress', flush=True)
time.sleep(2)  # writing a checkpoint
print('checkpoint written, exiting', flush=True)
```

The handler does nothing but set a flag, and the loop checks the flag between units of work, so a
unit is never cut in half. Put it in an image, with the second program of this section beside it,
using a `Dockerfile` in the same folder:

```dockerfile
# Dockerfile
FROM python:3.12.13-slim
COPY worker.py plain.py /
```

Then build the image, start the worker, let it work for a few seconds, and stop it with thirty
seconds' grace, the way Compute Engine would:

```
ana@laptop:~/gcp$ docker build -q -t spot-demo .
sha256:d3192edb3c6df57b69316fbf0d99faa87e839770c63957ab41aea9bc3c315cc8
ana@laptop:~/gcp$ docker run -d --name spot-worker spot-demo python3 /worker.py
2e865059cac39f03105bd1e2f93aa073b4a63250172bfc0715c80d406cd2e678
ana@laptop:~/gcp$ time docker stop -t 30 spot-worker
spot-worker

real	0m2.194s
user	0m0.014s
sys	0m0.015s
ana@laptop:~/gcp$ docker logs spot-worker
started
SIGTERM after 5 units: saving progress
checkpoint written, exiting
```

**The stop took about two seconds**, the time the checkpoint needed, and the log shows the work saved.
Now the same work with no handler at all, which is what most programs are. This is the second
program, `~/gcp/plain.py`, which the image already holds:

```python
# plain.py
import time

done = 0
print('started', flush=True)
while True:
    time.sleep(1)  # one unit of work
    done += 1
```

```
ana@laptop:~/gcp$ docker run -d --init --name plain-worker spot-demo python3 /plain.py
34fcd9fdb94426b946930ba2428fa8ee6a0eee35e7068b7db28c9fa893278f7f
ana@laptop:~/gcp$ time docker stop -t 30 plain-worker
plain-worker

real	0m0.141s
user	0m0.015s
sys	0m0.015s
ana@laptop:~/gcp$ docker logs plain-worker
started
ana@laptop:~/gcp$ docker inspect -f '{{.State.ExitCode}}' plain-worker
143
```

**Exit code 143 is 128 plus 15, the number of `SIGTERM`**: the program was killed by the signal the
moment it arrived, in the middle of whatever it was doing, and nothing was saved. `--init` is there
because a process running as the first one in a container ignores `SIGTERM` unless it handles it,
which would have hidden the difference. On a virtual machine your service is never the first
process, so this run is the honest picture of an unprepared service on a preempted Spot machine.

This is an imitation of the signal, not of a preemption. It shows what your program does with the
notice; how often notices come, and how much warning there really is, is Google's side and cannot be
tested from a laptop.
