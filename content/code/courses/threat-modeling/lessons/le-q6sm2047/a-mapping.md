---
title: A mapping in the repository
version: 1
---

The mapping lives where the model lives, as one more file joined by id. ana added it to the
repository on 5 October:

```
(.venv) ana@vm:~/tm/portal-model$ cat mapping.csv
control,plan,iso27001,csf
C1,phase 1,8.5,PR.AA-03
C2,phase 2,8.22,PR.IR-01
C3,phase 2,8.26,PR.DS-02
C4,phase 1,8.3,PR.AA-05
C5,phase 1,8.2,PR.AA-05
C6,not bought,8.7,PR.PS-05
C7,phase 2,5.17 8.5,PR.AA-03
C8,phase 1,5.34,PR.DS-02
C9,phase 2,8.26,PR.IR-04
C10,phase 2,8.6,PR.IR-04
C11,law,5.15 5.34,PR.AA-05
```

Four columns. The control, by its id from `controls.csv`. **Where it is in the plan** of lesson 11:
phase 1, phase 2, done because the law requires it, or not bought. Then one reference in each
framework, or two separated by a space when a control answers two.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l13-files\" aria-label=\"The four files the lab joins, and the column each join uses. threats.csv holds T01 to T17. requirements.csv names its threats in a column called threats. controls.csv names the threat it reduces in a column called risk. mapping.csv names a control in a column called control and adds an ISO 27001 reference and a NIST CSF reference. Every join is by id.\"><defs><marker id=\"l13-files-tm-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">threats.csv</text><text x=\"105.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">T01 … T17</text><rect x=\"30.0\" y=\"15.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"105.0\" y=\"31.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">requirements.csv</text><text x=\"105.0\" y=\"61.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">R01 … R19</text><rect x=\"290.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></rect><text x=\"365.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">controls.csv</text><text x=\"365.0\" y=\"166.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C1 … C11</text><rect x=\"540.0\" y=\"120.0\" width=\"150.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"615.0\" y=\"136.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">mapping.csv</text><text x=\"615.0\" y=\"159.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">ISO 27001 and</text><text x=\"615.0\" y=\"172.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">NIST CSF</text><path d=\"M105.0 85.0 L105.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"115.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">column threats</text><path d=\"M290.0 155.0 L180.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"235.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">risk</text><path d=\"M540.0 155.0 L440.0 155.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-files-tm-ah-paper-dim)\"></path><text x=\"490.0\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">control</text><text x=\"360.0\" y=\"215.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">each arrow points at the file whose id it names</text></svg>", "caption": "No file repeats another’s words. A threat renamed in threats.csv changes nothing in the other three, because they hold its id."}
```

The file says nothing a reader could also find elsewhere. It does not repeat the control's name, its
cost or its threat, because those are in `controls.csv` and a copy would drift the first time one of
them changed. It holds the one new fact, the references, and the id that joins it to everything
else.

### Reading it back

`crosswalk.py` joins the two files and prints the mapping in three shapes:

```schooling-example
{"language": "python", "file": "crosswalk.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"Read the controls through a framework: ISO/IEC 27001:2022 Annex A, or the NIST CSF 2.0.\n\n    python3 crosswalk.py            every control, its threat and both references\n    python3 crosswalk.py iso27001   grouped by the four themes of Annex A\n    python3 crosswalk.py csf        grouped by the six functions of the CSF\n\"\"\"\nimport collections\nimport csv\nimport re\nimport sys\n", "note": "What it reads and the three shapes it prints. The docstring names the editions, because a reference means nothing without one."}, {"code": "GROUPS = {\n    \"iso27001\": {\"5\": \"organisational\", \"6\": \"people\", \"7\": \"physical\", \"8\": \"technological\"},\n    \"csf\": {\"GV\": \"Govern\", \"ID\": \"Identify\", \"PR\": \"Protect\",\n            \"DE\": \"Detect\", \"RS\": \"Respond\", \"RC\": \"Recover\"},\n}\n\ncontrols = {row[\"control\"]: row for row in csv.DictReader(open(\"controls.csv\"))}\nmapping = list(csv.DictReader(open(\"mapping.csv\")))\n", "note": "How each framework's references group: Annex A by the number before the dot, the CSF by the two letters of its function. Both files are read whole and joined by the control's id."}, {"code": "if len(sys.argv) == 1:\n    for m in mapping:\n        c = controls[m[\"control\"]]\n        print(f\"{m['control']:4} {c['risk']:4} {m['iso27001']:9} {m['csf']:9} {m['plan']:10}  {c['name']}\")\n    sys.exit()\n", "note": "With no argument, one line per control: its id, its threat, both references and where it is in the plan. The name comes from controls.csv, never from the mapping."}, {"code": "framework = sys.argv[1]\nrefs = collections.defaultdict(list)\nfor m in mapping:\n    for ref in m[framework].split():\n        refs[ref].append(m)\n", "note": "Turn the mapping round: for each reference, the controls that answer it. A control with two references lands under both."}, {"code": "def order(ref):\n    return [int(p) if p.isdigit() else p for p in re.split(r\"[.-]\", ref)]\n", "note": "Sort 8.22 after 8.5, which a plain string sort gets wrong."}, {"code": "for prefix, name in GROUPS[framework].items():\n    mine = sorted((r for r in refs if r.split(\".\")[0] == prefix), key=order)\n    print(f\"{name:14} {len(mine)}\")\n    for ref in mine:\n        names = [m[\"control\"] + (\" (not bought)\" if m[\"plan\"] == \"not bought\" else \"\") for m in refs[ref]]\n        print(f\"  {ref:9} {'  '.join(names)}\")", "note": "Every group is printed, the empty ones too, because an empty function is the finding. A control that was not bought says so wherever it appears."}]}
```

With no argument, every control, the threat it was chosen for, both references, and where it is in
the plan:

```
(.venv) ana@vm:~/tm/portal-model$ python3 crosswalk.py
C1   T03  8.5       PR.AA-03  phase 1     second factor for staff
C2   T03  8.22      PR.IR-01  phase 2     console on the clinic network only
C3   T01  8.26      PR.DS-02  phase 2     webhook signature and amount check
C4   T07  8.3       PR.AA-05  phase 1     ownership check on exam downloads
C5   T13  8.2       PR.AA-05  phase 1     least-privilege account for the worker
C6   T14  8.7       PR.PS-05  not bought  isolated viewer for exam PDFs
C7   T02  5.17 8.5  PR.AA-03  phase 2     sign-in rate limit and breached passwords
C8   T08  5.34      PR.DS-02  phase 1     reminder text without the clinic
C9   T10  8.26      PR.IR-04  phase 2     upload size and type limit
C10  T11  8.6       PR.IR-04  phase 2     daily cap on reminder messages
C11  T03  5.15 5.34 PR.AA-05  law         receptionist role without clinical notes
```

Read across, each line is the whole chain this course has built: a threat, a control, what each
framework calls it, and whether it exists yet. **That last column is the one a questionnaire most
often loses.** "Do you protect exam files against overwriting?" has an honest answer that is not yes
or no: C4 is planned for phase 1, and until then T07 is open.

### One mapping, kept honestly

Three rules keep the file worth reading:

- **A control with no reference keeps its row.** The empty cell says that nobody found where it
  belongs, which is different from the control not existing.
- **A reference with no control is not written here.** This file maps controls outward. The question
  "which Annex A controls do we not have?" belongs to the statement of applicability, in the next
  section, where every one of the 93 is answered.
- **The edition is written down.** `iso27001` here means the 2022 edition and `csf` means 2.0, and
  the docstring of `crosswalk.py` says so. When either is revised, the column gets the edition in
  its name, so an old mapping cannot be read as a new one.
