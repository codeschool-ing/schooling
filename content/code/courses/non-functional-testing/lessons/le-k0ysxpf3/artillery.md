---
title: Node.js, then Artillery
version: 1
---

The last two load generators of this course are smaller than the four before them, and each is
worth knowing for one thing it does well. **Artillery writes the test as YAML**, a configuration
file rather than a program, with JavaScript available when the YAML runs out. **Vegeta does one
thing, a constant rate of requests**, from the command line, and does it in a way the others do
not. This lesson is an overview of both, not a full course in either.

## Node.js

Artillery is a Node.js program, and Node.js is not in Ubuntu's base at the version Artillery
wants, so it comes from nodejs.org as an archive and is unpacked over `/usr/local`:

```sh
cd ~
curl -fsSLO https://nodejs.org/dist/v24.21.0/node-v24.21.0-linux-x64.tar.xz
sudo tar -xJf node-v24.21.0-linux-x64.tar.xz -C /usr/local --strip-components=1
```

On a Mac with Apple silicon the archive is `node-v24.21.0-linux-arm64.tar.xz`, in both lines
that name it. `--strip-components=1` drops the archive's top directory, so `bin/node` lands in
`/usr/local/bin`, which is already on the `PATH`. Lessons 10 and 13 use the same Node.js.

## Artillery

```sh
sudo npm install -g artillery@2.0.34
```

**Installing Artillery also downloads a Chromium**, for an engine of Artillery's that drives real
pages through Playwright. This course never uses it, and the machine in the transcripts was built
with that download skipped. Otherwise the lines above were run as printed when the machine was built.
Check all three:

```
ana@nft:~$ node --version; npm --version; artillery --version
v24.21.0
11.19.0

        ___         __  _ ____
  _____/   |  _____/ /_(_) / /__  _______  __ ___
 /____/ /| | / ___/ __/ / / / _ \/ ___/ / / /____/
/____/ ___ |/ /  / /_/ / / /  __/ /  / /_/ /____/
    /_/  |_/_/   \__/_/_/_/\___/_/   \__  /
                                    /____/


VERSION INFO:

Artillery: 2.0.34
Node.js:   v24.21.0
OS:        linux
```

## A scenario

Make a directory for it and open the file with `mkdir -p ~/artillery && nano ~/artillery/boxoffice.yml`.
It is the journey of lessons 5 and 6 once more, in Artillery's words:

```schooling-example
{"language": "yaml", "file": "artillery/boxoffice.yml", "parts": [{"code": "# artillery/boxoffice.yml\nconfig:\n  target: http://127.0.0.1:8000", "note": "A test is a YAML file in two halves: `config`, which says where and how much, and `scenarios`, which says what a visitor does. `target` is the base address every request in the flow is relative to."}, {"code": "  phases:\n    - name: warm up\n      duration: 5\n      arrivalRate: 1\n      rampTo: 3\n    - name: steady\n      duration: 15\n      arrivalRate: 3", "note": "The phases are an open model, written as arrivals: `arrivalRate` is how many new virtual users arrive each second, and `rampTo` moves that rate from 1 to 3 over the 5 seconds of the first phase. The second holds 3 a second for 15 seconds. Like a Gatling user, an Artillery virtual user runs the scenario once and leaves."}, {"code": "  plugins:\n    ensure: {}\n  ensure:\n    thresholds:\n      - http.response_time.p95: 200\n    maxErrorRate: 1\n", "note": "`ensure` is Artillery's thresholds. `http.response_time.p95: 200` fails the run if the 95th percentile of all responses goes past 200 ms, and `maxErrorRate: 1` if more than 1% of virtual users fail. An error here is a request that got no answer, such as a refused connection or a timeout; a 409 is an answer, and counts as one."}, {"code": "scenarios:\n  - name: look and book\n    flow:\n      - get:\n          url: \"/shows/{{ $randomNumber(981, 1000) }}\"\n          capture:\n            json: \"$.id\"\n            as: show\n      - think: 2", "note": "The flow is one visitor's journey. `$randomNumber(981, 1000)` picks one of the twenty shows on sale, and `capture` reads the `id` out of the JSON answer into a variable called `show`, so the booking asks for the show the visitor looked at. `think: 2` is the think time, two seconds every time."}, {"code": "      - post:\n          url: /bookings\n          json:\n            show_id: \"{{ show }}\"\n            seat: \"{{ $randomNumber(1, 300) }}\"\n            customer: artillery", "note": "The booking sends a JSON body built from the captured show and a random seat. The template makes both values strings, which the box office accepts, because it converts them with `int()`. A seat already taken answers 409 and shows up under `http.codes.409` in the report."}]}
```

**YAML is the reason to pick Artillery, and also its limit.** A scenario like this one is read by
anybody who can read a configuration file, including people who would never open a Java class.
When the journey needs logic YAML cannot hold, such as a loop over a list or a body built from a
calculation, Artillery calls functions from a JavaScript file named in `config.processor`, and the
test becomes two files in two languages.
