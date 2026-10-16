---
title: Response time, and many people at once
version: 1
---

The first number in any performance conversation is how long one request takes. curl measures it
with `-w`, which prints variables after the transfer: here the status code and the total time in
seconds. `-o /dev/null` throws the page away, because the time is the point:

```
ana@laptop:~$ curl -s -o /dev/null -w '%{http_code} %{time_total}s\n' http://127.0.0.1:8000/
200 0.002166s
```

**A page in about two milliseconds.** On Windows, type the same command with `NUL` in place of
`/dev/null`; in a browser, the developer tools' Network tab shows a time for every request.

That number is true and nearly useless, and seeing why is the first lesson of performance testing.
The client and the server are on the same machine, so the request crossed no network. One person
asked for one page, with nobody else using the application. And it is a test build on a laptop,
not the theatre's server. **A measurement says something only about the conditions it was taken
in**, so a performance result is never reported without them: which build, which machine, which
network, how many users, which page.

## Twenty at once

The next question is what happens when people arrive together. A loop can start twenty curls
without waiting for each to finish, which is roughly twenty people pressing Enter in the same
instant. Each prints its own time, and `sort` with `tail` keeps the three slowest:

```
ana@laptop:~$ for i in $(seq 20); do curl -s -o /dev/null -w '%{time_total}\n' http://127.0.0.1:8000/ & done | sort -n | tail -n 3
0.029441
0.032561
0.036099
```

The slowest of the twenty took about 36 milliseconds, against about two for the request on its own.
Still fast, and still a laptop talking to itself. Your numbers will differ on every run, which is
another thing performance testers plan for: one measurement is an anecdote, and a load test reports
**percentiles** over thousands of requests, such as the time 95% of them came in under.

What the twenty show is the shape. **Requests that arrive together wait for each other**, so the
time each one takes grows with the number arriving. Up to some load the growth is small; past it,
the queue builds faster than it drains and response times climb steeply, and then requests start to
fail. That bend is what load and stress testing exist to find:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 330\" role=\"img\" data-fig=\"l14-load-curve\" aria-label=\"A line graph with people using it at once along the bottom and response time up the side, with no numbers on either axis. The line runs almost flat, bends, then climbs steeply, and past the climb crosses mark requests that fail. A dashed vertical line marks the expected peak on the flat part. A bracket over the flat part up to the peak is labelled load test: still flat at the peak? A bracket over the bend and the climb is labelled stress test: where does it bend, and how does it fail?\"><path d=\"M70.0 280.0 L640.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M70.0 70.0 L70.0 280.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"355.0\" y=\"300.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">people using it at once</text><text x=\"70.0\" y=\"58.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">response time</text><path d=\"M70.0 264.0 L72.9 264.0 L75.8 263.9 L78.8 263.9 L81.7 263.8 L84.6 263.8 L87.5 263.8 L90.4 263.7 L93.4 263.7 L96.3 263.6 L99.2 263.6 L102.1 263.5 L105.1 263.5 L108.0 263.5 L110.9 263.4 L113.8 263.4 L116.7 263.3 L119.7 263.3 L122.6 263.3 L125.5 263.2 L128.4 263.2 L131.3 263.1 L134.3 263.1 L137.2 263.1 L140.1 263.0 L143.0 263.0 L146.0 262.9 L148.9 262.9 L151.8 262.9 L154.7 262.8 L157.6 262.8 L160.6 262.7 L163.5 262.7 L166.4 262.6 L169.3 262.6 L172.2 262.6 L175.2 262.5 L178.1 262.5 L181.0 262.4 L183.9 262.4 L186.8 262.4 L189.8 262.3 L192.7 262.3 L195.6 262.2 L198.5 262.2 L201.5 262.2 L204.4 262.1 L207.3 262.1 L210.2 262.0 L213.1 262.0 L216.1 261.9 L219.0 261.9 L221.9 261.9 L224.8 261.8 L227.7 261.8 L230.7 261.7 L233.6 261.7 L236.5 261.7 L239.4 261.6 L242.4 261.6 L245.3 261.5 L248.2 261.5 L251.1 261.5 L254.0 261.4 L257.0 261.4 L259.9 261.3 L262.8 261.3 L265.7 261.3 L268.6 261.2 L271.6 261.2 L274.5 261.1 L277.4 261.1 L280.3 261.0 L283.3 261.0 L286.2 261.0 L289.1 260.9 L292.0 260.9 L294.9 260.8 L297.9 260.8 L300.8 260.8 L303.7 260.7 L306.6 260.7 L309.5 260.6 L312.5 260.6 L315.4 260.6 L318.3 260.5 L321.2 260.5 L324.1 260.4 L327.1 260.4 L330.0 260.4 L332.9 260.3 L335.8 260.3 L338.8 260.2 L341.7 260.2 L344.6 260.1 L347.5 260.1 L350.4 260.1 L353.4 260.0 L356.3 260.0 L359.2 259.9 L362.1 259.9 L365.0 259.9 L368.0 259.8 L370.9 259.8 L373.8 259.7 L376.7 259.7 L379.7 259.7 L382.6 259.6 L385.5 259.6 L388.4 259.5 L391.3 259.5 L394.3 259.4 L397.2 259.4 L400.1 259.4 L403.0 259.3 L405.9 259.2 L408.9 259.1 L411.8 258.9 L414.7 258.6 L417.6 258.2 L420.6 257.7 L423.5 257.1 L426.4 256.4 L429.3 255.6 L432.2 254.7 L435.2 253.7 L438.1 252.6 L441.0 251.3 L443.9 249.9 L446.8 248.3 L449.8 246.6 L452.7 244.8 L455.6 242.8 L458.5 240.7 L461.4 238.4 L464.4 236.0 L467.3 233.4 L470.2 230.6 L473.1 227.7 L476.1 224.6 L479.0 221.4 L481.9 217.9 L484.8 214.3 L487.7 210.5 L490.7 206.6 L493.6 202.4 L496.5 198.1 L499.4 193.6 L502.3 188.9 L505.3 184.0 L508.2 178.9 L511.1 173.6 L514.0 168.2 L517.0 162.5 L519.9 156.6 L522.8 150.5 L525.7 144.2 L528.6 137.7 L531.6 131.0 L534.5 124.1 L537.4 117.0\" stroke=\"var(--phosphor)\" stroke-width=\"2.2\" fill=\"none\"></path><path d=\"M549.5 104.8 L559.5 114.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M549.5 114.8 L559.5 104.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M578.0 92.8 L588.0 102.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M578.0 102.8 L588.0 92.8\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M606.5 83.0 L616.5 93.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M606.5 93.0 L616.5 83.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"583.0\" y=\"72.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">requests fail</text><path d=\"M298.0 280.0 L298.0 150.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.6\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"298.0\" y=\"138.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">expected peak</text><text x=\"454.2\" y=\"250.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the bend</text><path d=\"M70.0 233.0 L70.0 225.0 L298.0 225.0 L298.0 233.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"70.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">load test: still flat at the peak?</text><path d=\"M383.5 50.0 L383.5 42.0 L537.4 42.0 L537.4 50.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\"></path><text x=\"537.4\" y=\"31.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">stress test: where does it bend, and how does it fail?</text></svg>", "caption": "The typical shape of response time against load, not a measurement of boxoffice. A load test checks the expected peak; a stress test goes looking for the bend."}
```

Where the bend sits for boxoffice is the question, and it can only be answered by measuring: a load test checks the system stays on the flat
part at the expected peak, and a stress test pushes on until it finds the steep part and the
failures.

## The tools that do this for real

A shell loop is enough to show the idea and nowhere near enough to test with. Real load tests
simulate hundreds or thousands of **virtual users**, each following a script, pausing between
pages the way a person does, arriving gradually rather than all at once, and the tool records every
response time and every error. Three tools are common:

- **k6**, where the user's script is written in JavaScript;
- **JMeter**, an older Java tool whose test plans are built in a graphical editor;
- **Locust**, where the script is written in Python.

Gatling is a fourth you will see named. This course installs none of them and ran none of them;
`non-functional-testing` teaches them, along with how to model a realistic load before running one.

## Two rules worth knowing now

**Never load-test a system you were not given permission to load-test.** A load test is
indistinguishable from an attack to the people running the servers, and pointing one at a
production site, or at somebody else's, can take it down for real customers. Load tests run
against an environment set aside for them, with the owners told in advance.

**Report slowness with a number, not an adjective.** "Booking is slow" is a feeling. "Posting the
booking form for Hamlet took 4.2 seconds three times out of five, on build 1.1 in the test
environment, at 10:15, while nothing else was running" can be checked, compared with the next build,
and argued with. When no requirement gives a number to compare against, say so in the report;
section 02 of this lesson is about why that gap matters.
