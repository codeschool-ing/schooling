---
title: Lighthouse on both pages
version: 1
---

**Lighthouse** is Google's page auditor: it opens a page in Chrome, records everything the browser
did while loading it, and turns that recording into the metrics of the previous sections, a score
and a list of what to fix. It runs from the command line, which is what makes it usable in a
pipeline, and the same engine sits in the Lighthouse panel of Chrome's developer tools and behind
PageSpeed Insights.

## Installing it, and a browser for it

Lighthouse is a Node.js program, and Node has been on the machine since lesson 7. It needs a Chrome or
Chromium to drive, and the VM has no browser. The simplest one to get is the Chromium that
Playwright downloads, the same browser `web-automation` lesson 10 used. Three lines, in your second
terminal (the box office runs in the first):

```sh
sudo npm install -g lighthouse@13.5.0
mkdir -p ~/browser && cd ~/browser && npm init -y && npm install playwright@1.56.0 && npx playwright install --with-deps chromium
cd ~/boxoffice
```

The first installs Lighthouse for every user. The second makes a small project whose only job is
to hold Playwright, then asks Playwright for its Chromium and for the system libraries the browser
needs. **These lines were run on the recording machine with one exception**: the browser itself
could not be downloaded there, so the same build was copied from another Playwright 1.56.0
installation. The libraries were installed by the same command. Check both:

```
ana@nft:~/boxoffice$ lighthouse --version
13.5.0
ana@nft:~/boxoffice$ ~/.cache/ms-playwright/chromium-1194/chrome-linux/chrome --version
Chromium 141.0.7390.37 
```

Lighthouse looks for Chrome in the usual places, and a browser inside Playwright's cache is not in
any of them. Asked to run without being told where it is, it stops at once:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet 2>&1 | head -1
Runtime error encountered: The CHROME_PATH environment variable must be set to a Chrome/Chromium executable no older than Chrome stable.
```

The variable it names takes the path of the browser. Put it in `~/.profile`, so every new terminal
has it, and read it back:

```
ana@nft:~/boxoffice$ echo 'export CHROME_PATH=$HOME/.cache/ms-playwright/chromium-1194/chrome-linux/chrome' >> ~/.profile
ana@nft:~/boxoffice$ source ~/.profile && echo $CHROME_PATH
/home/ana/.cache/ms-playwright/chromium-1194/chrome-linux/chrome
```

**One more flag is needed on Ubuntu 24.04, and it is worth understanding before you type it.**
Chromium isolates the code of every web page in a sandbox, and building that sandbox needs
unprivileged user namespaces, which Ubuntu 24.04 restricts through AppArmor for programs it did not
install itself. A downloaded Chromium therefore refuses to start unless it is told to do without:
`--no-sandbox`. That is acceptable for a test browser that opens only your own page on
`127.0.0.1`, and it is not how anyone should browse the web. Playwright launches its Chromium
without the sandbox by default for the same reason. `--headless=new` runs the full browser with no
window, since the VM has no screen.

## The slow page

The command is long because each flag removes something this lesson does not need: `--quiet`
silences the progress log, `--only-categories=performance` skips the accessibility, SEO and
best-practice audits, and `--output=json` with `--output-path` writes the report as JSON to a file.
The HTML report Lighthouse writes by default is meant for a person with a browser, and a JSON
report is meant for a program, which is what `jq` is.

`jq` can read the numbers out with a filter kept in a file. Create `~/boxoffice/metrics.jq`:

```
# boxoffice/metrics.jq
# The score and the five timings this lesson reads out of a Lighthouse report.
{
  score: .categories.performance.score,
  FCP: .audits["first-contentful-paint"].displayValue,
  LCP: .audits["largest-contentful-paint"].displayValue,
  TBT: .audits["total-blocking-time"].displayValue,
  CLS: .audits["cumulative-layout-shift"].displayValue,
  "Speed Index": .audits["speed-index"].displayValue
}
```

Every audit in the report has a `displayValue`, the number as the HTML report prints it, and a
`numericValue` in milliseconds (or with no unit, for CLS), which is the one to compare in a
program. Run Lighthouse on the slow page, then read it:

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/ --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=slow.json
ana@nft:~/boxoffice$ jq -f metrics.jq slow.json
{
  "score": 0.37,
  "FCP": "2.8 s",
  "LCP": "13.1 s",
  "TBT": "1,430 ms",
  "CLS": "0.139",
  "Speed Index": "4.6 s"
}
```

Score 0.37, which the HTML report would draw as 37 out of 100,
in red. LCP 13.1 s against a threshold of 2.5, CLS 0.139 against 0.1, and TBT 1,430 ms on a page
whose only script is a loop.

## The fixed page

```
ana@nft:~/boxoffice$ lighthouse http://127.0.0.1:8000/fast.html --quiet --only-categories=performance --output=json --chrome-flags="--headless=new --no-sandbox" --output-path=fast.json
ana@nft:~/boxoffice$ jq -f metrics.jq fast.json
{
  "score": 1,
  "FCP": "0.7 s",
  "LCP": "0.9 s",
  "TBT": "0 ms",
  "CLS": "0",
  "Speed Index": "0.7 s"
}
```

**Every number is in the good band, and the score is 1.** LCP fell from 13.1 s to 0.9 s, TBT to
0 ms, CLS to 0. The content of the two pages is the same; the difference is the four defects.

## Reading why

The score says how bad and the audits say why. Each audit in the JSON carries a `details` field
with the evidence, and four of them point straight at the defects:

```
ana@nft:~/boxoffice$ jq -c '.audits["long-tasks"].details.items[] | [.url, .duration]' slow.json
["http://127.0.0.1:8000/slow.js",2000]
["http://127.0.0.1:8000/",1606.0000000000005]
["Unattributable",50]
ana@nft:~/boxoffice$ jq -r '.audits["layout-shifts"].details.items[].subItems.items[].cause' slow.json
Media element lacking an explicit size
ana@nft:~/boxoffice$ jq -r '.audits["lcp-breakdown-insight"].details.items[1].snippet' slow.json
<img src="hero.png" alt="The stage, lit for tonight's show">
ana@nft:~/boxoffice$ jq -c '.audits["resource-summary"].details.items[] | select(.requestCount > 0) | [.resourceType, .requestCount, .transferSize]' slow.json
["total",4,2435280]
["image",1,2431680]
["other",1,1747]
["document",1,1448]
["script",1,405]
```

- **`long-tasks`** lists the main thread's long tasks. `slow.js` took 2,000 ms and the page's own
  script 1,606, though one loops for 500 ms and the other for 400. The phone Lighthouse pretends to
  be has a processor four times slower than the machine it runs on, and the next section shows
  where that number lives. The page's 1,606 ms come after the first paint, and that is most of
  the TBT; `slow.js` runs before anything is painted, so it delays FCP and LCP instead.
- **`layout-shifts`** names the cause of the movement it found: an image with no explicit size.
  Read it as a suspect rather than a verdict. The cause is Lighthouse's guess, and this page has
  two defects that move content, the unsized picture and the late banner. `fast.html` fixed both,
  which is why its CLS is 0.
- **`lcp-breakdown-insight`** says which element was the largest contentful paint: the heavy
  picture.
- **`resource-summary`** counts requests and bytes by type. Four requests, 2,435,280 bytes, of which
  2,431,680 are the picture. Lesson 11 sets a budget on exactly these numbers.

## Where the score comes from

The score is not a fifth metric. It is a weighted mean of the five, each first converted into a
score between 0 and 1 against a curve built from how real sites perform. The weights are in the
report:

```
ana@nft:~/boxoffice$ jq -c '.categories.performance.auditRefs[] | select(.weight > 0) | [.id, .weight]' slow.json
["first-contentful-paint",10]
["largest-contentful-paint",25]
["total-blocking-time",30]
["cumulative-layout-shift",25]
["speed-index",10]
```

TBT carries 30%, and LCP and CLS 25% each, so those three decide most of the score. **Treat the
score as a summary for people and the metrics as the requirement.** A score of 0.9 does not say whether LCP is under 2.5 s,
and the requirement from lesson 1 names LCP, not a score.
