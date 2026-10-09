---
title: When the setup fails
version: 2
---

Most failures of this setup come from six places, and each one says so in its own way. Read the last line of the error first. Every message below is one this course's machine printed.

**Ollama is not running.** The installer makes Ollama a service that starts with the computer, and that needs systemd. WSL without systemd, a container, or a minimal server do not have it, and the installer says so in a line that is easy to scroll past: `WARNING: systemd is not running`. Then everything that talks to a model fails, and not with a message about models:

```
ana@lab:~/mm$ ollama list
Error: could not connect to ollama server, run 'ollama serve' to start it
ana@lab:~/mm$ python -c "from openai import OpenAI; OpenAI().models.list()" 2>&1 | tail -1
openai.APIConnectionError: Connection error.
ana@lab:~/mm$ ollama list | head -1
NAME                                                                         ID              SIZE      MODIFIED           
```

`ollama list` says it outright; a lesson's program only says `Connection error.`, because the OpenAI SDK knows an address and not what should be there. Start the server by hand, and leave it running in its own terminal or in the background:

```sh
nohup ollama serve > ~/ollama.log 2>&1 &
```

The last line above is a working Ollama answering again. On WSL the lasting fix is to switch systemd on (`[boot]` and `systemd=true` in `/etc/wsl.conf`, then `wsl --shutdown` from Windows); `setup.sh` already starts the server for you when it finds none.

**The Ollama installer stops at the start.** On a fresh Ubuntu it printed `ERROR: This version requires zstd for extraction. Please install zstd and try again` on this course's machine, before `zstd` was in `setup.sh`'s first lines. If you install Ollama yourself, install `zstd` first.

**A terminal opened before the setup has no course Python.** `~/.bashrc` is read when a terminal starts, so a window that was already open runs Ubuntu's own Python, which has none of the libraries:

```
ana@lab:~/mm$ deactivate; python3 listen.py 2>&1 | tail -1
python3: can't open file '/home/ana/mm/listen.py': [Errno 2] No such file or directory
```

Open a new terminal, or type `. ~/.bashrc` in this one.

**A model file is not the one it should be.** A download cut short, or a file somebody edited, loads with an error that names a layer or a tensor rather than the file. `setup.sh` checks every model against its SHA-256, and you can run the same check by hand. Here a copy of the noise model has had one byte added:

```
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /tmp/gtcrn.onnx" | sha256sum -c
/tmp/gtcrn.onnx: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /opt/multimodal/share/gtcrn_simple.onnx" | sha256sum -c
/opt/multimodal/share/gtcrn_simple.onnx: OK
```

`FAILED` on the copy and `OK` on the original. Delete a file that fails and run `sh setup.sh` again: it skips everything that is already there and fetches only what is missing.

**A system library is missing.** MediaPipe draws through OpenGL even on a machine with no screen, and on a minimal Ubuntu it stops with `OSError: libEGL.so.1: cannot open shared object file: No such file or directory`. That is what it said on the machine this course was built on, before `libegl1` was installed, which is why `setup.sh` installs `libegl1` and `libgles2`.

**The disk is full.** The course needs about 10 GB, 8 of them Ollama's models, and a download that runs out of room stops half-written. `df -h ~` says how much is left. `media/` can be deleted at any time, since `make_media.py` makes it again, and `ollama rm` removes a model you have finished with.

If something fails that is not on this list, the error's last line is still the place to start. Search for it with the name of the program that printed it, and say so where you ask for help: "sherpa-onnx raised this while loading the Whisper decoder" gets an answer, and "the setup does not work" does not.
