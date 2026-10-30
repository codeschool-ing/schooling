#!/usr/bin/env python3
"""add-lesson.py LESSON_ID: put the lesson in course.json's `lessons`, in topic order (locked)."""
import fcntl, json, re, sys
P = "/home/user/schooling/content/code/courses/mobile-fundamentals/course.json"
with open("/tmp/mobile-fundamentals-course.lock", "w") as lock:
    fcntl.flock(lock, fcntl.LOCK_EX)
    text = open(P).read()
    c = json.loads(text)
    order = [t["id"] for t in c["topics"]]
    want = sys.argv[1]
    assert want in order, want
    have = set(c["lessons"]) | {want}
    lessons = [i for i in order if i in have]
    new = re.sub(r'"lessons": \[[^\]]*\]', '"lessons": ' + json.dumps(lessons), text, count=1)
    open(P, "w").write(new)
    print(lessons)
