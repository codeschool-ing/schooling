---
title: Commands without a shell
version: 1
---

The exam-type feature builds a command line and gives it to the shell:

```python
    result = subprocess.run(
        f"file --brief --mime-type exams/{name}", shell=True, capture_output=True, text=True
    )
```

Ask it for an exam whose name has a space, and read what `file` answered:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k spaces
F                                                                        [100%]
=================================== FAILURES ===================================
_____________________ test_a_name_with_spaces_is_one_file ______________________
/home/ana/sc/exams-convert/test_app.py:21: in test_a_name_with_spaces_is_one_file
    assert client.get("/exams/knee scan.pdf/type").json["type"] == "application/pdf"
E   AssertionError: assert 'cannot open ...or directory)' == 'application/pdf'
E     
E     - application/pdf
E     + cannot open `exams/knee' (No such file or directory)
E     + cannot open `scan.pdf' (No such file or directory)
=========================== short test summary info ============================
FAILED test_app.py::test_a_name_with_spaces_is_one_file - AssertionError: ass...
1 failed, 5 deselected in 0.22s
```

``cannot open `exams/knee'`` and ``cannot open `scan.pdf'``. **The shell split the name at the space**,
because splitting at spaces is what a shell does with a command line, and ran `file` on two files that
do not exist. The name was meant to be one argument; the shell read it as part of the program. Every
other character the shell gives a meaning to, `;`, `|`, `$( )`, quotes, is in the same position as that
space, and the same line would act on each of them.

### The separate channel: no shell

`subprocess.run` does not need a shell. Given a **list**, it starts the program directly and hands it
each element as one argument, exactly as written. No shell parses anything, so no character in
`name` has a meaning:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index 2060366..4dc7da8 100644
--- a/app.py
+++ b/app.py
@@ -29,7 +29,9 @@ def directory():
 @app.get("/exams/<path:name>/type")
 def exam_type(name):
     result = subprocess.run(
-        f"file --brief --mime-type exams/{name}", shell=True, capture_output=True, text=True
+        ["file", "--brief", "--mime-type", "--", str(EXAMS / name)],
+        capture_output=True,
+        text=True,
     )
     return jsonify(name=name, type=result.stdout.strip())
 
```

Two details in the new call matter. **`--`** tells `file` that everything after it is a file name,
even one that starts with `-`; without it, an exam named `-z.pdf` would be read as an option, by
`file` itself rather than by the shell. And `EXAMS / name` builds the path with `pathlib` rather than
by joining strings. Which names may reach this folder at all is the upload lesson's question,
lesson 14.

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=no
...FFF                                                                   [100%]
=========================== short test summary info ============================
FAILED test_app.py::test_a_star_is_a_character_not_everyone - AssertionError:...
FAILED test_app.py::test_parentheses_in_a_name_are_searched_for - AssertionEr...
FAILED test_app.py::test_a_note_is_shown_as_written - AssertionError: assert ...
3 failed, 3 passed in 0.19s
```

**One fewer failure.** Commit:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Run file with a list of arguments, without a shell"
```

### Better still: no command

The safest command line is the one the program does not need. Python can do much of what small
command-line tools are called for: `pathlib` and `shutil` copy and move files, `zipfile` makes
archives, libraries such as `python-magic` read file types through `libmagic` without a process. When a
program really must run another program, the rules are the ones above: **a list, no `shell=True`, `--`
before any name, and never `os.system`**, which always uses a shell.
