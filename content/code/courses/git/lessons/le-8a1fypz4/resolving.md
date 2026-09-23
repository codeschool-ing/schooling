---
title: Resolving a conflict, or backing out of one
version: 1
---

Resolving is three steps, and only the first needs thought.

**1. Make the file say what it should.** Open it, delete the three markers, and leave the version you
want. That is often neither side exactly. Here both changes are right: winter hours from Bruno,
Sunday hours from Ana. So the resolution keeps both:

```
ana@vm:~/site$ cat index.html
<h1>Padaria Sol</h1>
<p>Bread from half past six; Sundays from seven.</p>
<p><a href="menu.html">See the menu</a></p>
ana@vm:~/site$ git add index.html
ana@vm:~/site$ git status
On branch main
All conflicts fixed but you are still merging.
  (use "git commit" to conclude merge)

Changes to be committed:
	modified:   index.html

ana@vm:~/site$ git commit --no-edit
[main 56eb01e] Merge branch 'sunday'
ana@vm:~/site$ git log --oneline --graph -5
*   56eb01e Merge branch 'sunday'
|\  
| * 9677eef Open on Sundays from seven
* | ee92834 Open at half past six in winter
|/  
* 6555c9b Link the menu from the home page
* eadf998 Take rye bread off until the flour arrives
```

**2. `git add` the file.** In the middle of a merge, adding a file means *this conflict is settled*.
`git status` changes its tune accordingly: *all conflicts fixed but you are still merging*.

**3. `git commit`.** Git already wrote the message, `Merge branch 'sunday'`, and `--no-edit` accepted
it. The graph shows an ordinary merge commit joining the two sides, exactly the shape lesson 5 drew;
the only difference is that a person decided what one line of it says.

## Things that go wrong in step 1

- **Leaving a marker behind.** Git does not check the content for you; a stray `=======` gets
  committed like any other text. Search the file for `<<<<<<<` before adding it.
- **Picking a side without reading the other.** Keeping *your* version is the fastest resolution and
  often the wrong one, because the other side was also somebody's deliberate change. Read both, then
  decide, and if you cannot decide, ask the person on the other side: `git log` of lesson 3 tells you
  who that is.
- **Fixing more than the conflict.** A resolution is not the place for unrelated improvements. They
  get buried inside a merge commit, where nobody reviewing the history thinks to look.

## Backing out

Sometimes a conflict is bigger than it looked, or it is the wrong moment. **`git merge --abort` puts
everything back as it was before the merge started**:

```
ana@vm:~/site$ git merge lunch
Auto-merging index.html
CONFLICT (content): Merge conflict in index.html
Automatic merge failed; fix conflicts and then commit the result.
ana@vm:~/site$ git merge --abort
ana@vm:~/site$ git status --short
```

Another conflicting branch, and this time Ana chose not to deal with it now. After `--abort` the
status is empty: no markers, no half-finished merge, the working tree clean. Nothing was lost; the
branch is still there to merge another day.

That is worth knowing before you ever need it, because a paused merge is the state beginners panic
in. **There is always a way back to the moment before you typed `git merge`**, and Git prints it in
`git status` for as long as the merge is open.
