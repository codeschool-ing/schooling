#!/usr/bin/env python3
"""Every `schooling-example` in the course, written once. THE AUTHOR'S.

An annotated program is code (the same in both languages, byte for byte) and
notes (prose, translated). Writing the block twice by hand is how the two
drift, so each one is written here with its notes as (English, Portuguese)
pairs, and

    python3 lab/examples.py

replaces each line `@@ex:NAME@@` in the lessons with the block in that file's
language, and, on later runs, each block already there whose "file" names the
same example in the same lesson. lab/extract.py then reads the program back out
of the lesson, so the capture runs exactly what the page shows.
"""
import glob
import json
import os
import re
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
COURSE = os.path.dirname(HERE)
sys.path.insert(0, HERE)
sys.dont_write_bytecode = True

EXAMPLES = {}


def example(name, file, parts, output=None, language='python'):
    EXAMPLES[name] = dict(file=file, parts=parts, output=output, language=language)


def block(name, lang):
    e = EXAMPLES[name]
    b = {'language': e['language'], 'file': e['file'], 'parts': []}
    for code, en, pt in e['parts']:
        p = {'code': code}
        note = en if lang == 'en' else pt
        if note:
            p['note'] = note
        b['parts'].append(p)
    if e['output']:
        b['output'] = e['output']
    return '```schooling-example\n' + json.dumps(b, ensure_ascii=False) + '\n```'


for p in sorted(glob.glob(os.path.join(HERE, 'examples', '*.py'))):
    exec(compile(open(p, encoding='utf-8').read(), p, 'exec'), globals())


def main():
    changed = 0
    for path in sorted(glob.glob(os.path.join(COURSE, 'lessons', '*', '*.md'))):
        lang = 'pt' if path.endswith('.pt.md') else 'en'
        t = open(path, encoding='utf-8').read()
        n = re.sub(r'^@@ex:([\w-]+)@@$', lambda m: block(m.group(1), lang), t, flags=re.M)

        def again(m):
            b = json.loads(m.group(1))
            for k, e in EXAMPLES.items():
                if e['file'] == b.get('file') and [p[0] for p in e['parts']] == [p['code'] for p in b['parts']]:
                    return block(k, lang)
            return m.group(0)
        n = re.sub(r'```schooling-example\n(\{.*?\})\n```', again, n, flags=re.S)
        if n != t:
            open(path, 'w', encoding='utf-8').write(n)
            changed += 1
    print(f'{len(EXAMPLES)} examples, {changed} file(s) rewritten')


if __name__ == '__main__':
    main()
