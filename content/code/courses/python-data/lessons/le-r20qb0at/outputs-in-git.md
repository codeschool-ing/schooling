---
title: A notebook in version control
version: 1
---

**A notebook is a fine thing to keep in git, as long as you know that git sees the JSON and not the
page.** Ana puts the fixed notebook under version control, with the environment kept out of it:

```
(.venv) ana@lab:~/pydata$ git init -q
(.venv) ana@lab:~/pydata$ printf '.venv/\n' > .gitignore
(.venv) ana@lab:~/pydata$ git add .gitignore fixed.ipynb
(.venv) ana@lab:~/pydata$ git commit -qm "Wet days in 2025"
```

The `.gitignore` line matters: `.venv` is hundreds of megabytes of installed libraries that the
lab section's commands rebuild in minutes, and it has no place in a history that never forgets.

The next day she opens the notebook, runs its three cells, runs the last one twice more to look
at the number again, and saves. She changed no code. This is what git now reports:

```
(.venv) ana@lab:~/pydata$ git diff --stat
 fixed.ipynb | 4 ++--
 1 file changed, 2 insertions(+), 2 deletions(-)
(.venv) ana@lab:~/pydata$ git diff
diff --git a/fixed.ipynb b/fixed.ipynb
index 3c7af00..0b0d677 100644
--- a/fixed.ipynb
+++ b/fixed.ipynb
@@ -24,7 +24,7 @@
   },
   {
    "cell_type": "code",
-   "execution_count": 3,
+   "execution_count": 5,
    "id": "d83302b2",
    "metadata": {},
    "outputs": [
@@ -34,7 +34,7 @@
        "63"
       ]
      },
-     "execution_count": 3,
+     "execution_count": 5,
      "metadata": {},
      "output_type": "execute_result"
     }
```

Two lines changed and both are execution counts, `3` becoming `5`. **Nothing about the analysis
changed, and the history has a change in it.** Multiply that by a notebook with twenty cells, a
DataFrame or two and a chart, which is stored as a long string of encoded image that changes on
every run, and a diff of real work becomes a page of noise with one meaningful line somewhere in
it.

## Clearing outputs before a commit

The plainest remedy is to commit notebooks without their outputs, so that the history holds only
what people wrote:

```
(.venv) ana@lab:~/pydata$ jupyter nbconvert --clear-output --inplace fixed.ipynb
[NbConvertApp] Converting notebook fixed.ipynb to notebook
[NbConvertApp] Writing 1077 bytes to fixed.ipynb
(.venv) ana@lab:~/pydata$ git diff --stat
 fixed.ipynb | 19 ++++---------------
 1 file changed, 4 insertions(+), 15 deletions(-)
```

`--clear-output` empties every cell's `outputs` and sets its count back to `null`; the file
shrinks, and what is left to compare is the source. The cost is that somebody opening the
notebook from the repository sees code and no results until they run it, which, after this
lesson, is what they should do anyway. A separate package, `nbstripout`, does the same thing
automatically each time you commit; it is not installed in this course's lab, and the command
above is enough to see what it saves you.

Two other habits make notebooks behave in a repository:

- **Keep the code that has to last in `.py` files**, imported by the notebook, as the `bikes.py` of
  two sections ago was. Those diff like code because they are code. Lesson 21 takes that to its
  end.
- **Restart and run all before every commit.** A committed notebook is a claim that its outputs
  came from its code, and the counts `1` to `n` are the evidence.
