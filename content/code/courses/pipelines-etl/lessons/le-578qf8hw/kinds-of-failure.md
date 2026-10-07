---
title: Three kinds of failure
version: 1
---

Every pipeline in this course has so far failed in front of Ana, who read the error and did
something about it. A scheduled pipeline fails at three in the morning, when nobody is reading,
and **what happens next has to have been decided in the afternoon**. Airflow can try again, give
up, or tell somebody, and which of those is right depends on why the task failed.

The new DAG of this lesson fetches the publishers' prices every night at 03:00, from the API of
lesson 3. Its failures fall into three kinds:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l10-failures\" aria-label=\"Three kinds of failure and what each asks for. A passing failure, such as a 503, a 429 or a timeout, is retried later and alerts nobody unless the tries run out. A permanent one, such as a 401, a 400 or a file in the wrong shape, fails at once and alerts. A failure in the code itself, such as an import error, stops the DAG from being scheduled at all and is fixed by changing the code.\"><text x=\"30.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">the failure</text><text x=\"200.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">for example</text><text x=\"410.0\" y=\"28.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper-dim)\">what Airflow should do</text><path d=\"M30.0 44.0 L690.0 44.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"30.0\" y=\"61.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">passing</text><text x=\"200.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">503 · 429 · timeout</text><text x=\"410.0\" y=\"78.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">try again, later each time</text><rect x=\"30.0\" y=\"113.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"130.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">permanent</text><text x=\"200.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">401 · 400 · a bad file</text><text x=\"410.0\" y=\"130.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fail now, and say so</text><rect x=\"30.0\" y=\"165.0\" width=\"150.0\" height=\"34.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">in the code</text><text x=\"200.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an import error</text><text x=\"410.0\" y=\"182.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nothing runs: fix the code</text></svg>", "caption": "Asking again only helps when the cause can go away by itself."}
```

- **A passing failure** is one the world will fix without anybody's help. The API answers `503`
  because it is being redeployed, or `429` because the request came too fast, or a connection
  times out on a busy network. The same request a minute later succeeds. **These are what retries
  are for**, and a person woken for one would find nothing to do.
- **A permanent failure** is one asking again will not change. A `401` means the key is wrong, and
  it will still be wrong in a minute and in an hour; a `400` means the request itself is malformed;
  a file in the wrong shape will be in the wrong shape on every read. Retrying these wastes the
  night and delays the alert. **The task should fail at once and say so.**
- **A failure in the code** stops the task before it starts. A DAG file that does not import is not
  a failing task: it is a DAG Airflow cannot see, and nothing in it is scheduled at all.

The third kind turned up first, while Ana was writing the DAG, so it comes first. The rest of the
lesson takes the other two in turn: retries, failing fast, timeouts, and then what tells a person
when none of that was enough.
