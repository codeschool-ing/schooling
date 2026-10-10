---
title: Installing k6 and a first run
version: 1
---

JMeter, in lesson 4, keeps a test plan as an XML file that a window edits for you. **k6 keeps a
test as a JavaScript file you write yourself**, and that one difference decides most of what
follows: the test lives in the repository beside the code, it goes through code review like any
other change, and a diff of it says what changed in words. k6 is a single program written in Go,
from Grafana Labs. The JavaScript runs inside k6 on an engine of its own, so there is no Node.js
here and no `npm install`.

## One program

k6 is published as an archive on GitHub, with one file inside. In the VM's shell:

```sh
cd ~
curl -fsSLO https://github.com/grafana/k6/releases/download/v1.8.1/k6-v1.8.1-linux-amd64.tar.gz
tar -xzf k6-v1.8.1-linux-amd64.tar.gz
sudo install k6-v1.8.1-linux-amd64/k6 /usr/local/bin/
```

On a Mac with Apple silicon the VM is ARM, and the archive is
`k6-v1.8.1-linux-arm64.tar.gz`, in both lines that name it. **These four lines were not run for
this course**, because the computer it was recorded on cannot reach GitHub. The k6 in the
transcripts was built from the same v1.8.1 source, which is why the version line names the Go
compiler of that build:

```
ana@nft:~$ k6 version
k6 v1.8.1 (go1.25.1, linux/amd64)
```

A release you download names the Go version it was built with instead, and the rest is the same.

## The smallest test

Make a directory for the scripts of this lesson and open the first one:

```sh
mkdir -p ~/k6 && nano ~/k6/first.js
```

```javascript
// k6/first.js
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 5,
  duration: '10s',
};

export default function () {
  http.get('http://127.0.0.1:8000/shows/990');
  sleep(1);
}
```

That is a whole test. `options` says five virtual users for ten seconds, and the default function
is what each of them does over and over: ask for show 990, then wait a second. Start the box office
in one terminal, as in lesson 1 (`cd ~/boxoffice && python3 app.py`), and run the test from a
second one, in your home directory:

```
ana@nft:~$ k6 run -q k6/first.js


  █ TOTAL RESULTS 

    HTTP
    http_req_duration..............: avg=29.91ms min=16.02ms med=27.68ms max=69.25ms p(90)=51.79ms p(95)=62.09ms
      { expected_response:true }...: avg=29.91ms min=16.02ms med=27.68ms max=69.25ms p(90)=51.79ms p(95)=62.09ms
    http_req_failed................: 0.00%  0 out of 50
    http_reqs......................: 50     4.820475/s

    EXECUTION
    iteration_duration.............: avg=1.03s   min=1.01s   med=1.02s   max=1.07s   p(90)=1.05s   p(95)=1.06s  
    iterations.....................: 50     4.820475/s
    vus............................: 5      min=5       max=5
    vus_max........................: 5      min=5       max=5

    NETWORK
    data_received..................: 16 kB  1.6 kB/s
    data_sent......................: 4.0 kB 381 B/s
```

**The `-q` flag hides the progress bar**, which k6 redraws on the same line every second while
it runs; without it you also get a logo and a line per second, and the summary at the end is the
same. Every run in this lesson uses `-q` so that the transcripts hold only the result.

Look at `http_reqs` before anything else. Five users, each sending one request and then sleeping
a second, should send a little under five a second, and the summary says `4.820475/s`. **Each
virtual user waits for its answer before it sleeps and asks again**, which is lesson 3's virtual
user with its think time. So a server that slowed down would receive fewer requests, and the test
would ease off at the moment it should be pressing hardest. The next section writes the same kind
of test the other way round.
