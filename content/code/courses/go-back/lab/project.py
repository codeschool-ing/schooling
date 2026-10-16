#!/usr/bin/env python3
"""Print, as JSON, the boxoffice project as lesson N of go-back leaves it.

    python3 project.py COURSE_DIR N

The project is built across the lessons, and every file of it is shown whole
in the lesson that writes or changes it. This walks lessons 1 to N in the
course's order and their sections in each lesson's order, and takes every block
that names a project file:

  - an ordinary fence whose first line is `// boxoffice/PATH`,
    `-- boxoffice/PATH` or `# boxoffice/PATH`;
  - a schooling-example whose "file" is `boxoffice/PATH`, its parts joined.

A later block for the same PATH replaces the earlier one, as a student's edit
replaces the file. The result maps PATH (relative to the project) to the text,
so the file the capture builds is the file the student copied.
"""
import json, os, re, sys

course, upto = sys.argv[1], int(sys.argv[2])
topics = json.load(open(os.path.join(course, 'course.json')))['topics']
FIRST = re.compile(r'^(?://|--|#) boxoffice/(\S+)$')
files = {}


def blocks(text):
    lang, cur = None, None
    for line in text.split('\n'):
        if line.startswith('```'):
            if cur is None:
                lang, cur = line[3:].strip(), []
            else:
                yield lang, cur
                cur = None
        elif cur is not None:
            cur.append(line)


for topic in topics[:upto]:
    d = os.path.join(course, 'lessons', topic['id'])
    if not os.path.isdir(d):
        continue
    for sec in json.load(open(os.path.join(d, 'lesson.json')))['sections']:
        md = os.path.join(d, sec['slug'] + '.md')
        if not os.path.exists(md):
            continue
        for lang, lines in blocks(open(md, encoding='utf-8').read()):
            if lang == 'schooling-example':
                ex = json.loads('\n'.join(lines))
                f = ex.get('file', '')
                if f.startswith('boxoffice/'):
                    files[f[len('boxoffice/'):]] = ''.join(p['code'] for p in ex['parts'])
            elif lines:
                m = FIRST.match(lines[0])
                if m:
                    files[m.group(1)] = '\n'.join(lines) + '\n'

json.dump(files, sys.stdout)
