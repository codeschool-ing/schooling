# Video

What the video layer is made of, and why each part is the way it is.

`C-08` puts video last on purpose and phase 6 is where it lands, so this file is written
**before** the thing it describes exists. That is deliberate: the decisions below are cheap now
and expensive once there is a stored hour of anything. It is also the answer to the **video
provider** question `PLAN.md` carried open — "managed service or own transcoding, behind an
interface" — which is settled here and struck there.

Nothing in this file is built yet. The state column says what is decided and what is only
proposed, and the difference is not decoration: a proposal recorded as a decision is how a
document starts lying.

---

## Two requirements pulling opposite ways

The videos **must not be reachable from outside the system**, and the **recurring cost must be as
close to zero as it can be** while there are no students yet.

The first requirement removes YouTube and the generator's own player: both hand out an address
that plays without asking this system anything. The second removes everything billed monthly
before there is anyone watching.

What is left is hosting it ourselves, with authorisation decided at the moment of the click.

The threat is bounded as well, and the bound is a decision rather than an oversight: what is
being defended against is **one person watching and passing the material on**. A camera pointed
at a screen is out of scope. That single line is what makes DRM the wrong purchase — it is
expensive, it is a recurring licence, it needs a licence server, and it does not close the hole
that was declared out of scope in the first place.

**Nothing here protects against somebody determined. It protects against the one-click path,
which is the path nearly everybody would take.**

---

## The register

`Decided` was chosen. `Proposed` is a recommendation nobody has ratified. `Deferred` is reopened
by a named trigger, not by a date. `Refused` was considered and dropped, and the reason is kept
so the next person can disagree with it rather than rediscover it.

### Scope

| Decision | Why | State |
|---|---|---|
| One course first: `web-fundamentals` | Code-level adjustments will surface as the material grows. One course keeps each adjustment cheap. | Decided |
| Material in English only, for now | It is the source language everywhere (`N-06`). Translations divide storage by five the day they arrive, and the material is still changing shape. | Decided |
| Structure frozen | Tracks, courses, `requires` and `links` do not change. Phase 5 is prose, exercises and script. Held by `validate-catalog`. | Decided |
| The spoken script is authored source | Written beside the prose, versioned in git under `content/`. The generator reads it; the student reads it back as the transcript. | Decided |

### Delivery

| Decision | Why | State |
|---|---|---|
| We host it | Any provider that serves the file directly hands out an address that works without us, which is the requirement that started this. | Decided |
| Signed URL per object, short expiry, issued against the active subscription | Phase 6 already says this. An address that expires makes sharing it hand over a dead link. | Decided |
| Progressive MP4 with `faststart` | One file, one object, one signature. Without `faststart` the index sits at the end and playback waits for the whole download. | Decided |
| 1080p, ~5 Mbps | 4K is five times the storage — about US$1,400 a month more at 50,000 renditions — for a screen showing an editor and a slide. | Decided |
| H.264 | H.265 support in browsers is uneven; AV1 saves bandwidth but still has a hardware-decode gap, which spends the student's battery to save our egress. | Decided |
| No CDN while the volume is low | A fixed monthly bill and a second cache layer to authorise, for traffic the bucket serves on its own. | Refused |
| Segmented HLS | Costs more than it saves at this size, and replaces a per-object signature with a signed cookie over a prefix, which authorises a folder instead of a file. Revisit when **paid egress passes US$50 a month** (~200 active students). | Deferred |

### Protection

| Decision | Why | State |
|---|---|---|
| `controlsList="nodownload"` and the context menu suppressed | Removes the button and the right-click — the one-step path. Anyone who opens the network tab finds the file; that person was never the target. | Decided |
| A watermark composited in the DOM, carrying the student, from the first video | Catches a screen recording and a camera. Does not catch a download, because it is not in the file — so its **absence is never evidence of anything**. | Decided |
| DRM | A monthly licence and a licence server, and the analogue hole stays open either way. | Refused |

### Infrastructure

| Decision | Why | State |
|---|---|---|
| United States region | The free 100 GiB/month egress tier is North America. São Paulo costs more per GiB *and* forfeits the tier. | Decided |
| Standard for what is watched, Autoclass on from day one | US$0.125/month for 50,000 objects. What nobody watches demotes itself, with nobody remembering to do it. | Decided |
| Masters in Archive, separate from the served renditions | The original render is never read by a student, which is the one case where Archive's retrieval price does not matter. | Decided |
| Video language decoupled from the interface: a selector on the player, defaulting to the interface language, falling back to English **spoken aloud** | A video is not a string — a missing translation is not a key showing through, it is somebody hearing the wrong language. Remembering the choice is a separate decision: it would be the third key stored in a browser, and every stored key needs a migration and a test that seeds a real browser. | Deferred |

### Telemetry

| Decision | Why | State |
|---|---|---|
| `internal/event/` takes the rows, a fold in `internal/analysis/` aggregates, the console reads the aggregate | `K-03`, applied. Not a new decision — the existing one, arriving somewhere new. | Decided |
| Nothing below the minimum sample | `C-17`. A completion rate over three views is noise, and the questions screen already knows how to say how many were left out. | Decided |
| Milestones at 25%, 50%, 75%, 95% — not a periodic heartbeat | Four rows per view instead of about forty. The stream is permanent by decision, and the heartbeat stores a detail nobody will ask for. | Proposed |
| The milestone is **earned**: emitted from media time actually played, never from the playhead | Dragging the scrubber to the end fires 95% in two seconds. Read from position, the metric measures who touched the control. | Proposed |
| Media seconds, not wall-clock seconds | At 1.5×, two thirds of a video takes the running time of all of it and passes for finished. | Proposed |
| The row stores the milestone reached, not a count of seconds | Replace a video with a shorter one and stored seconds become more than 100% with nobody noticing. "Reached 75%" stays true without consulting current state, which is the whole reason `K-03` exists. | Proposed |
| The rendition's language is on the event | Turns "when do the translations land" from a guess into an observation, using a row that was going to be written anyway. | Proposed |

---

## What it costs

Google Cloud Storage, US regions, **priced September 2026**. A price in a document goes stale
quietly, so the date is part of the claim.

A ten-minute 1080p video at 5 Mbps is **0.35 GiB**. Everything below is a multiple of that.

### Storing 50,000 renditions — 17.5 TiB

| Class | Per GiB-month | Monthly | Retrieval | Minimum duration | Reads/month before it stops paying |
|---|---|---|---|---|---|
| Standard | $0.0200 | **$350** | — | — | — |
| Nearline | $0.0100 | $175 | $0.01/GiB | 30 days | ~1.0 |
| Coldline | $0.0040 | $70 | $0.02/GiB | 90 days | ~0.8 |
| Archive | $0.0012 | **$21** | $0.05/GiB | 365 days | ~0.4 |

The last column is the point, and it runs the opposite way to intuition: **the colder the class,
the fewer reads it tolerates**, because retrieval rises faster than storage falls. Archive is a
seventeenth of Standard and allows roughly one read a quarter — which is a master, not a lesson.
That is the whole argument for keeping the two apart.

### Traffic, by scale

Ten videos per student per month, at $0.08/GiB, after the free 100 GiB.

| Active students | Views/month | Traffic | Paid egress |
|---|---|---|---|
| 20 | 200 | 70 GiB | **$0** |
| 100 | 1,000 | 350 GiB | $20 |
| 1,000 | 10,000 | 3.5 TiB | $272 |

The free tier covers about **285 views a month**, which is more than the first year is likely to
produce. So at the start **storage dominates and egress is free** — the reverse of the intuition
that serving is what costs.

---

## MP4 now, HLS at a number

HLS saves roughly **40% of egress**: the student fetches only what is watched, and a smaller rung
on a small screen. Forty per cent of $0 is $0.

At 100 active students it saves about $11 a month and gives back about $2.50, because a
three-rung ladder is about 1.7× the single file. What actually weighs is not on the monthly bill:

- **Transcoding.** About $200 one-off through the Transcoder API for 500 renditions — or, done
  with local `ffmpeg`, a manual step forever.
- **A build step.** This repository has none, and hls.js would be its first JavaScript
  dependency.
- **Looser authorisation.** Per-object signed URLs do not survive segmentation; the practical
  answer is a signed cookie over a prefix, which authorises a folder.

So HLS costs more *and* authorises less at this size. The trigger to reopen it is a number rather
than a date — **paid egress above US$50 a month**, roughly 200 active students — and deferring is
cheap because changing delivery later does not touch the content model, the scripts or the
authorisation.

---

## The precedent

In August 2018, a post showed that Vimeo's video ids are **sequential**, and that on a course site
the only barrier was the embed's domain restriction: increment the number and eventually a paid
video opens. Alura was one of the examples, `<iframe>` and id in plain view. One of its founders
answered in the comments, and that answer is the best public record of the reasoning of somebody
running this at scale.

> "Ha também soluções mais robustas como YouTube e Netflix fazem, onde os vídeos não estão em uma
> única fonte, quebrado em múltiplos chunks, fazendo o download parar se você tentar um algoritmo
> ingênuo de HTTP get no arquivo mp4. Mas também é relativamente simples entender o funcionamento
> e automatizá-lo."

> "No final ficamos com duas opções: investir mais tempo e dinheiro para dificultar um pouco a
> vida de pessoas pessimamente intencionadas ou investir isso em mais features, mais cursos,
> respondendo as dúvidas no fórum, mantendo textos atualizados e criando uma comunidade. Foi
> fácil optar pela segunda opção."

— Guilherme Silveira, replying to *"Vimeo uma bomba relógio para quem vende cursos on-line"* by
Jonathan Trancozo, August 2018. The reply also says that even after applying the article's
suggestions, "tudo continua muito fácil de baixar".

The first quote is the HLS question answered by somebody who paid to find out. The second is the
cost-against-protection trade, settled on the same side this file settles it.

But the part worth keeping is what the article proposed as defence: do not publish the id, space
the uploads so other people's videos land between yours, build the player through the API so the
id never reaches the HTML. All three hide the identifier and none of them expires anything — and
the reply takes all three apart in one sentence, saying a crawler finds the URLs whether or not
they are sequential.

**Hiding the identifier is not a control. Expiring the authorisation is.**

That failure class does not exist here, and not by degree:

- **The guard is a signature with an expiry**, not a `Referer` check that any `curl` forges.
- **The identifier is an object in our own bucket**, not a position in a global sequence shared
  with everyone else who uploads to the same platform. There is no run to walk.

None of which makes the material unextractable. The same reply lists people who got around every
scheme with a web driver, a screencast and a phone camera. What changes is that the failure which
leaks a whole catalogue *without anybody logging in* is not available.

---

## What the content model has to grow

A section today says it has *a* video, as a boolean. Twenty-six sections carry it, all of them
placeholder material:

```json
{ "id": "se-pm2stfcw", "slug": "shared", "kind": "video", "video": true, "duration": "08 min" }
```

With N videos to a section, each with its own id, script and duration, the boolean becomes a list:

```json
{ "id": "se-pm2stfcw", "slug": "shared", "kind": "video",
  "videos": [
    { "id": "vd-…", "script": "…", "duration": "08 min" },
    { "id": "vd-…", "script": "…", "duration": "03 min" }
  ] }
```

The id is what ties the video to its object, its script and its transcript — nothing joins by
prose or position (`C-09`). The script is authored source: it lives in `content/`, it is
versioned, and one rendition per language is generated from it.

**Calling the script a transcript is a claim about the video, not about the text.** While the
generator reads the script literally the two are the same string. The day a rendition drifts from
it, the transcript is lying to a student who cannot hear the difference — so the script is what
has to be corrected, not the label.

---

## Still open

**Does re-rendering a video mint a new id?** If the script is corrected and the id stays, the
drop-off curve mixes two versions and cannot say whether the correction worked. A new id breaks
the series on purpose, which is the honest behaviour and matches `C-16` for exercises. Cheap to
decide now, expensive once there is history.

**Does the player pause when the tab loses focus?** Pausing brings the milestone closer to real
attention and annoys the person listening in another window deliberately. Either way it has to be
chosen before the first events: changing it later leaves two halves of one series measuring
different things under the same name.

**When do the translations land?** Each language multiplies storage and renders. Starting with
one keeps the bill at a fifth while the material is still moving — and the telemetry above is
what turns this from a guess into a reading.

**What the watermark shows.** That it exists is decided; what it carries, how often it moves and
whether it fades on hover are not. Each of those trades a paying student's comfort for friction
against somebody recording the screen.
