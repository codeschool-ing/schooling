---
title: Templates take variables, not text
version: 1
---

The reminder preview builds its template by joining the receptionist's note into the template's own
text:

```python
    page = render_template_string(
        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>" + note + "</p>",
```

The console's reminders use `{{ name }}` for the patient's name, so receptionists are used to typing
braces. One writes a note with a pair of them in it:

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q --tb=short -k note 2>&1 | grep -E '^E |^jinja2|passed|failed'
E   AssertionError: assert 'Hello lucia' in '<!doctype html>\n<html lang=en>\n<title>500 Internal Server Error</title>\n<h1>Internal Server Error</h1>\n<p>The ser...nd was unable to complete your request. Either the server is overloaded or there is an error in the application.</p>\n'
jinja2.exceptions.TemplateSyntaxError: expected token 'end of print statement', got 'referral'
1 failed, 5 deselected in 0.16s
```

The `grep` keeps the assertion and the template engine's own error out of a long traceback.
`expected token 'end of print statement', got 'referral'`. **Jinja parsed the note as part of the
template**, found `{{ the referral }}`, and tried to read `the referral` as an expression. Here the
expression was not valid and the page failed with a `500`. A note whose braces happened to hold a valid
expression would have been **evaluated**, on the server, with whatever the template engine can reach.
This is **server-side template injection**, and in the engines of most languages that reach extends
to running code on the server.

There is a second loss hidden in the same line. A value written into the template's text is not
escaped either, because it is not a value any more: the autoescaping of lesson 4 applies to
**variables**, and the note had stopped being one.

### The separate channel: a variable

The template's text is fixed and the note is passed as `note=note`, exactly as `patient` and `day`
already were:

```
(.venv) ana@vm:~/sc/exams-convert$ git diff
diff --git a/app.py b/app.py
index fecbd07..9a3bc57 100644
--- a/app.py
+++ b/app.py
@@ -50,8 +50,9 @@ def find_staff():
 def preview():
     note = request.form.get("note", "")
     page = render_template_string(
-        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>" + note + "</p>",
+        "<p>Hello {{ patient }}, see you on {{ day }}.</p><p>{{ note }}</p>",
         patient="lucia",
         day="Monday 16 November",
+        note=note,
     )
     return page
```

```
(.venv) ana@vm:~/sc/exams-convert$ pytest -q
......                                                                   [100%]
6 passed in 0.17s
```

Six of six. The braces are shown as written, and anything else the note contains is escaped like
every other value. Commit, and look at the history:

```
(.venv) ana@vm:~/sc/exams-convert$ git commit -qam "Pass the note to the template as a variable"
(.venv) ana@vm:~/sc/exams-convert$ git log --oneline
863e513 Pass the note to the template as a variable
5192718 Escape the name in the LDAP filter
9e253dd Run file with a list of arguments, without a shell
6196450 Exam types, staff lookup and reminder preview
```

### The rule for templates

**A template is code, written by the developers and kept in the repository; data reaches it only as
variables.** `render_template_string` is not wrong in itself, and this lesson uses it so every
program fits on the page; it is wrong the moment its first argument is built from anything a request
carried. The same goes for any feature that lets users write their own templates, such as the
console's reminder templates: those need a deliberately limited engine, such as Jinja's sandboxed
environment, and a review of their own.
