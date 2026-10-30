---
title: Bicep, installed beside the command line
version: 1
---

**Bicep is a compiler, and it runs on your computer.** It reads a `.bicep` file and writes the ARM JSON
template that Resource Manager understands; deploying that template is a separate step, which needs a
subscription and is not part of this lab. Everything else Bicep does, compiling, decompiling and
checking, needs nothing but the program itself, so this lesson and the next are fully practised.

The Azure command line downloads it, at a version you name, into `~/.azure/bin`. The two lines after
it put that directory on your path, now and in every new terminal, so the program can be called as
`bicep` rather than through `az bicep`:

```sh
cd ~/azure && source venv/bin/activate
az bicep install --version v0.48.1
echo 'export PATH="$HOME/.azure/bin:$PATH"' >> ~/.bashrc
export PATH="$HOME/.azure/bin:$PATH"
```

```
ana@laptop:~/azure/bicep$ bicep --version
Bicep CLI version 0.48.1 (cec7951cf6)
ana@laptop:~/azure/bicep$ du -sh ~/.azure/bin/bicep
117M	/home/ana/.azure/bin/bicep
```

It is one self-contained program of about 117 MB. `az bicep build` and `bicep build` do the same thing;
this course calls `bicep` directly because the errors come back without the command line's wrapping.
If you write Bicep in an editor, Microsoft's Bicep extension for Visual Studio Code runs the same
compiler as you type, and shows the warnings you are about to see in the terminal as squiggles.
