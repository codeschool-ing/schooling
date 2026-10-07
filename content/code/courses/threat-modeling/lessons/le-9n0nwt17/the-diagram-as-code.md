---
title: The diagram as code
version: 1
---

A diagram drawn in a drawing tool is a picture: it cannot be compared with last month's version
line by line, it cannot be checked by a program, and it drifts from the system without anybody
noticing. **Writing the same diagram as code** fixes the first two and makes the third visible,
because a change to the system can arrive in the same pull request as a change to its model.
Lesson 15 builds on that. This section writes the portal's level 1 diagram with **pytm**, the
OWASP library installed in lesson 1.

### The model

Create `model.py` in `~/tm/portal-model`. It is the drawing of the previous sections, element by
element:

```schooling-example
{"language": "python", "file": "model.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"The data flow diagram of Vereda's patient portal, written as code.\"\"\"\nfrom pytm import TM, Actor, Boundary, Dataflow, Datastore, ExternalEntity, Process, Server\n\ntm = TM(\"Vereda patient portal\")\ntm.description = \"Booking, records and reminders for a chain of physiotherapy clinics.\"\ntm.isOrdered = True\n", "note": "The model is an ordinary Python file. `TM` is the model itself; its name and description are what a report would print at the top."}, {"code": "# Trust boundaries: where the level of trust changes.\ninternet = Boundary(\"Internet\")\ncloud = Boundary(\"Vereda cloud\")\nprivate = Boundary(\"Private network\")\nprivate.inBoundary = cloud\nclinic = Boundary(\"Clinic network\")\nvendors = Boundary(\"Vendors\")\n", "note": "One `Boundary` per zone of trust. The private network sits inside the cloud, which pytm says with `inBoundary`, the same way it places every element."}, {"code": "# External entities: people and systems outside Vereda's control.\npatient = Actor(\"Patient\")\npatient.inBoundary = internet\npatient.protocol = \"HTTPS\"\nstaff = Actor(\"Clinic staff\")\nstaff.inBoundary = clinic\nsms = ExternalEntity(\"SMS provider\")\nsms.inBoundary = vendors\nsms.protocol = \"HTTPS\"\npayments = ExternalEntity(\"Payment gateway\")\npayments.inBoundary = vendors\npayments.protocol = \"HTTPS\"\n", "note": "The four external entities. People are `Actor`s, other companies' systems are `ExternalEntity`s. `protocol` is what flows arriving at the element use."}, {"code": "# Processes: code Vereda runs.\nportal = Server(\"Portal\")\nportal.inBoundary = cloud\nportal.protocol = \"HTTPS\"\nportal.usesSessionTokens = True\nconsole = Server(\"Staff console\")\nconsole.inBoundary = cloud\nconsole.protocol = \"HTTPS\"\nconsole.usesSessionTokens = True\nworker = Process(\"Reminder worker\")\nworker.inBoundary = private\n", "note": "The three processes. The portal and the console answer requests and keep sessions, so they are `Server`s; the worker only runs on a schedule."}, {"code": "# Data stores.\ndb = Datastore(\"Records database\")\ndb.inBoundary = private\ndb.storesPII = True\ndb.storesSensitiveData = True\ndb.isSQL = True\ndb.protocol = \"PostgreSQL\"\nfiles = Datastore(\"Exam files\")\nfiles.inBoundary = private\nfiles.storesPII = True\nfiles.storesSensitiveData = True\nfiles.protocol = \"HTTPS\"\n", "note": "The two data stores, both in the private network, both holding personal and sensitive data. Those flags are facts pytm will reason with in lesson 3."}, {"code": "# Data flows, in the order a booking happens. A flow takes its protocol\n# from the element it arrives at.\nDataflow(patient, portal, \"Sign in and book\")\nDataflow(portal, patient, \"Pages and booking status\")\nDataflow(patient, portal, \"Upload exam PDF\")\nDataflow(portal, files, \"Store exam PDF\")\nDataflow(portal, db, \"Read and write bookings\")\nDataflow(portal, payments, \"Charge for a session\")\nDataflow(payments, portal, \"Payment webhook\")\nDataflow(staff, console, \"Manage the agenda\")\nDataflow(console, db, \"Read and write records\")\nDataflow(console, files, \"Open exam PDF\")\nDataflow(worker, db, \"Read tomorrow's bookings\")\nDataflow(worker, sms, \"Send reminder\")\n", "note": "The twelve flows of the figure, in its order: source, destination, and the label naming the data."}, {"code": "if __name__ == \"__main__\":\n    tm.process()", "note": "`process()` reads the command line: `--json`, `--dfd`, `--report` and the rest."}]}
```

Three details are pytm's rather than the notation's. An external entity that is a person is an
`Actor`; one that is a system is an `ExternalEntity`. A process that answers requests is a
`Server`, which lets pytm ask questions about sessions; one that does not is a `Process`. And
`tm.isOrdered = True` keeps the flows numbered in the order they are written, which is why the
numbers in the figure and in the output below are the same.

### Which flows cross a boundary

pytm can write everything it knows about the model as JSON. A short program beside it, `flows.py`,
reads that file and marks each flow whose two ends sit in different boundaries:

```schooling-example
{"language": "python", "file": "flows.py", "parts": [{"code": "#!/usr/bin/env python3\n\"\"\"List the data flows of a pytm model, and mark the ones that cross a trust boundary.\"\"\"\nimport json\nimport sys\n\nmodel = json.load(open(sys.argv[1]))", "note": "pytm's JSON lists every element with the boundary it sits in, and every flow with the names of its two ends."}, {"code": "where = {e[\"name\"]: e[\"inBoundary\"] or \"(none)\" for e in model[\"elements\"]}\n", "note": "A dictionary from an element's name to its boundary. An element outside every boundary gets `(none)`."}, {"code": "crossing = 0\nfor f in model[\"flows\"]:\n    a, b = where[f[\"source\"]], where[f[\"sink\"]]\n    mark = \"x\" if a != b else \" \"\n    crossing += a != b\n    print(f\"{f['order']:2} {mark} {f['name']:26} {a} -> {b}\")\nprint(f\"\\n{crossing} of {len(model['flows'])} flows cross a trust boundary\")", "note": "A flow crosses when its ends sit in different boundaries. Nested boundaries count as different: the cloud and the private network inside it are two zones."}]}
```

Run the model with `--json`, which prints nothing and writes the file, and then the program:

```
(.venv) ana@vm:~/tm/portal-model$ ls -A
.git
.gitignore
flows.py
model.py
(.venv) ana@vm:~/tm/portal-model$ python3 model.py --json model.json
(.venv) ana@vm:~/tm/portal-model$ python3 flows.py model.json
 1 x Sign in and book           Internet -> Vereda cloud
 2 x Pages and booking status   Vereda cloud -> Internet
 3 x Upload exam PDF            Internet -> Vereda cloud
 4 x Store exam PDF             Vereda cloud -> Private network
 5 x Read and write bookings    Vereda cloud -> Private network
 6 x Charge for a session       Vereda cloud -> Vendors
 7 x Payment webhook            Vendors -> Vereda cloud
 8 x Manage the agenda          Clinic network -> Vereda cloud
 9 x Read and write records     Vereda cloud -> Private network
10 x Open exam PDF              Vereda cloud -> Private network
11   Read tomorrow's bookings   Private network -> Private network
12 x Send reminder              Private network -> Vendors

11 of 12 flows cross a trust boundary
```

That is the count the figure two sections back showed by eye, now computed from the model. The
next time somebody adds a flow, the program counts it too, and nobody has to remember to redraw a
picture first.

pytm can also print the diagram in Graphviz's language, with `python3 model.py --dfd`, for
turning into an image. Making the image needs Graphviz itself, which this workspace does not
install, so that step was not run here.

### Commit it

The `.gitignore` keeps `model.json` and Python's cache out of the repository, since both are
produced from the files that are in it:

```
(.venv) ana@vm:~/tm/portal-model$ git status --short
?? .gitignore
?? flows.py
?? model.py
(.venv) ana@vm:~/tm/portal-model$ git add .gitignore model.py flows.py
(.venv) ana@vm:~/tm/portal-model$ git commit -m 'Draw the portal as a data flow diagram'
[main (root-commit) 0cc253e] Draw the portal as a data flow diagram
 3 files changed, 88 insertions(+)
 create mode 100644 .gitignore
 create mode 100644 flows.py
 create mode 100644 model.py
```

The `.gitignore` holds two lines, `__pycache__/` and `model.json`. If your commit shows a
different hash, that is expected: a hash covers the author and the time, and yours are not ana's.

### Code is not the model either

The file is a model only while it matches the system. pytm cannot know that the console answers
from the internet unless somebody writes it down; it believes the boundary it was given, exactly
as the drawing did. The advantage of code is not that it is truer. It is that a difference between
the model and the system can be shown in a diff, reviewed and argued about, which is the habit
lesson 15 sets up.
