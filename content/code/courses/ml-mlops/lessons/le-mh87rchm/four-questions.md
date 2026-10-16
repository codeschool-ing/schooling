---
title: Four questions, answered at four speeds
version: 1
---

"Is the model working?" sounds like one question. **It is four, and what separates them is how
long you wait for the answer.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" data-fig=\"l09-four-signals\" aria-label=\"A time axis from the moment of a request to ninety days later. Is it answering and how fast are known within seconds; what it is saying is known the next morning; whether it was right is known ninety days later, when the outcomes are in.\"><path d=\"M250.0 220.0 L700.0 220.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M300.0 216.0 L300.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"300.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">seconds</text><path d=\"M470.0 216.0 L470.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"470.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a night</text><path d=\"M650.0 216.0 L650.0 224.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">90 days</text><text x=\"20.0\" y=\"23.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">is it answering?</text><text x=\"20.0\" y=\"39.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">status of every request</text><path d=\"M255.0 30.0 L294.0 30.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"300.0\" cy=\"30.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20.0\" y=\"69.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">how fast?</text><text x=\"20.0\" y=\"85.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">milliseconds per request</text><path d=\"M255.0 76.0 L294.0 76.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"300.0\" cy=\"76.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"20.0\" y=\"115.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">what is it saying?</text><text x=\"20.0\" y=\"131.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tonight against the weeks before</text><path d=\"M255.0 122.0 L464.0 122.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"470.0\" cy=\"122.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"20.0\" y=\"161.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">was it right?</text><text x=\"20.0\" y=\"177.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">scores against outcomes</text><path d=\"M255.0 168.0 L644.0 168.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><circle cx=\"650.0\" cy=\"168.0\" r=\"5\" fill=\"var(--amber)\"></circle><text x=\"314.0\" y=\"53.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">the service</text><text x=\"484.0\" y=\"145.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">the model</text></svg>", "caption": "The two questions a model shares with any service are answered at once; its own two wait, and the one that matters most waits longest."}
```

| question | what answers it | how soon |
| --- | --- | --- |
| is it answering? | the status of every request, a run that finished | seconds |
| how fast? | the time every request took | seconds |
| what is it saying? | tonight's scores and inputs against the nights before | a night |
| was it right? | the scores of a past night against what the members then did | 90 days, for this model |

**The first two are the questions of any web service**, and nothing about them is specific to
machine learning: a service that is down or slow fails whatever model sits inside it.

**The last two are the model's own.** A service can answer every request in five milliseconds with
a status of 200 and be wrong about every member, and no check of speed or status will notice. The
third question can be asked the next morning, because it compares the model with itself. The fourth
is the real one, and for the lapse model it waits for the label: whether a member came back takes
90 days to be known, the delay lesson 3 drew as the label's maturity.

**So the checks that can run early stand in for the one that cannot.** If tonight's scores look
nothing like last week's, something changed, and you find out three months before the report card
would have told you. This lesson builds one check for each row, and then asks what keeping each kind
of deployment running costs.
