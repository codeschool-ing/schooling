---
title: Scan coverage, and the targets with no findings
version: 1
---

Every other number in this lesson is computed from findings. Coverage is the one that is not, and it
is the one that says how far to trust the others. **A target no scanner looks at produces no
findings, and a dashboard of findings shows it as clean.** Coverage is the number that tells clean
apart from unexamined.

### The report

```
ana@vm:~/metrics$ python3 measure.py coverage
sast      5 of  8 repos   62%
sca       6 of  8 repos   75%
secrets   7 of  8 repos   88%
image     4 of  6 images   67%
scanned by nothing: legacy-reports, refunds-worker
ana@vm:~/metrics$ cut -d, -f2,3 findings.csv | sort | uniq -c | sort -rn
     67 auth-gateway,repo
     60 billing-api,repo
     57 storefront,repo
     55 linkbox,repo
     54 link-stats,repo
     49 billing-api,image
     46 linkbox,image
     44 storefront,image
     39 auth-gateway,image
     35 invoices,repo
      3 web-assets,repo
      1 target,kind
```

Read the first four lines as fractions, each with its own denominator. Static analysis runs on 5 of
the 8 repositories, secret scanning on 7 of 8, and the image scanner on 4 of the 6 images. There is
no single coverage figure: a repository with secret scanning and nothing else is covered for leaked
credentials and blind to everything else, so averaging the four rows into one percentage would
hide exactly which kind of blindness it is.

The second command counts findings per target, straight from the findings file (the last line is
the header). `legacy-reports` and `refunds-worker` are not in it at all. That is what a dashboard
built from findings sees: eleven targets with findings, and the other three (two names between them)
nowhere. `web-assets` has three findings, all from the secret scanner, which is the only one pointed
at it, and three is not evidence that its code is better than `storefront`'s 57.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"sp-l20-coverage\" aria-label=\"The fourteen targets of the inventory, as boxes inside a boundary labelled what exists. Eleven of them have at least one scanner and appear in the findings; three, the repository and image of legacy-reports and the image of refunds-worker, have none. A smaller boundary labelled what a findings dashboard sees contains only the eleven.\"><defs></defs><rect x=\"10\" y=\"10\" width=\"700\" height=\"310\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">what exists: the inventory, 14 targets</text><rect x=\"24\" y=\"44\" width=\"480\" height=\"262\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"38\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">what a dashboard built from findings sees: 11 targets</text><rect x=\"38\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox</text><text x=\"110.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 55</text><rect x=\"193\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">linkbox</text><text x=\"265.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 46</text><rect x=\"348\" y=\"78\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link-stats</text><text x=\"420.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 54</text><rect x=\"38\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billing-api</text><text x=\"110.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 60</text><rect x=\"193\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">billing-api</text><text x=\"265.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 49</text><rect x=\"348\" y=\"134\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"149.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">invoices</text><text x=\"420.5\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 35</text><rect x=\"38\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"110.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 57</text><rect x=\"193\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">storefront</text><text x=\"265.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 44</text><rect x=\"348\" y=\"190\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"420.5\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">web-assets</text><text x=\"420.5\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 3</text><rect x=\"38\" y=\"246\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"110.5\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">auth-gateway</text><text x=\"110.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 67</text><rect x=\"193\" y=\"246\" width=\"145\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"265.5\" y=\"261.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">auth-gateway</text><text x=\"265.5\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 39</text><rect x=\"530\" y=\"78\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"93.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">refunds-worker</text><text x=\"612.5\" y=\"110.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 0</text><rect x=\"530\" y=\"142\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"157.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">legacy-reports</text><text x=\"612.5\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">repo · 0</text><rect x=\"530\" y=\"206\" width=\"165\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"612.5\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">legacy-reports</text><text x=\"612.5\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">image · 0</text><text x=\"612\" y=\"288\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">no scanner, no findings, not on the dashboard</text></svg>", "caption": "Findings come only from what is scanned. The three targets outside the inner line hold no findings, and a dashboard built from findings cannot tell them from clean."}
```

### The denominator is the hard part

Computing coverage is a division. Knowing what to divide by is the work, and it is why most
programmes report a coverage they cannot back up. The numerator comes for free: every pipeline that
runs a scanner knows it did. The denominator has to come from outside the pipelines, because the
targets that matter most are the ones that never had one:

- **Repositories**: the list of the organisation's repositories on the hosting platform, including
  the archived and the forgotten. A list kept by hand drifts.
- **Images**: what the registry holds, and above all what is running. The cluster knows which images
  its pods run; an image that runs without having come from a pipeline is the one most worth
  finding. Lesson 10's admission policy refuses images from anywhere but this project's registry,
  which is coverage enforced at the door rather than measured afterwards.
- **What is not code at all**: a server somebody set up by hand, a bucket, a SaaS account. These are
  outside what this course's scanners read, and lesson 11 described the scanners that look at them.

In the generated data the inventory is a list in the program, which is the easy case. On a real
platform, building it is a small project of its own, and it pays for itself the first time it turns
up a repository nobody remembered.

### Coverage is that a scanner ran, not that anybody read it

The report counts a scanner as covering a target when it is configured to run there. Lesson 1 began
with a scanner that ran on every push and had been red for a month. By this report, that target was
covered.

So coverage needs a second condition to mean anything: the scanner's result decides something. In
this course's pipeline that condition is built in, because every stage is a gate whose exit status
breaks the build, warns or passes (lesson 7). A scanner that runs as a job allowed to fail does not
meet it, and an honest coverage report counts it separately or not at all.

Two more ways coverage overstates itself are worth checking on real data:

- **A scanner that ran on an old commit.** A repository scanned once, a year ago, appears in the
  numerator forever unless the report asks when the last scan was.
- **A scanner with nothing to read.** Composition analysis on a repository with no lock file reports
  zero findings, every time, and looks exactly like a clean result.

### What to do with the number

Coverage below 100% is not a failure; it is a list of work. The two targets scanned by nothing are
the first items on it, ahead of any finding in the debt report, because whatever they hold is not
counted anywhere. A coverage number that never moves is the sign that the list is not being worked.
