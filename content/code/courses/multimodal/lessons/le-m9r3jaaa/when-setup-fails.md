---
title: When the setup fails
version: 1
---

Most failures of this lab come from four places, and each one says so in its own way. Read the last line of the error first.

**labmm is not running.** Every API lesson talks to it, and when it is down the SDKs report a connection error rather than anything about images or audio. Check it directly:

```
ana@lab:~/mm$ curl -sS http://127.0.0.1:8700/
curl: (7) Failed to connect to 127.0.0.1 port 8700 after 0 ms: Couldn't connect to server
ana@lab:~/mm$ curl -s -o /dev/null -w "%{http_code}\n" http://127.0.0.1:8700/
200
```

`Couldn't connect to server` means nothing is listening on port 8700. `sudo bash lab.sh reset` starts it again, and the second line is what a working lab answers. If it does not come back, its own error is in `/run/labmm.out`.

**A model file is not the one it should be.** A download that was cut short, or a file somebody edited, loads with an error that names a layer or a tensor rather than the file. `lab.sh` checks every model against a SHA-256 before using it, and you can run the same check by hand. Here a copy of the noise model has had one byte added:

```
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /tmp/gtcrn.onnx" | sha256sum -c
/tmp/gtcrn.onnx: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
ana@lab:~/mm$ echo "e77603ac0c23dac3227dd2d7135b3a585cbee2679048aecfa886657d3ae1b534  /opt/multimodal/share/gtcrn_simple.onnx" | sha256sum -c
/opt/multimodal/share/gtcrn_simple.onnx: OK
```

`FAILED` on the copy and `OK` on the original. Delete the file and run `lab.sh up` again; it fetches only what is missing.

**A system library is missing.** MediaPipe draws through OpenGL even on a machine with no screen, and on a minimal Ubuntu it stops with `OSError: libEGL.so.1: cannot open shared object file: No such file or directory`. That is what it said on the machine this course was built on, before `libegl1` was installed. `lab.sh up` installs `libegl1` and `libgles2` for that reason, along with ffmpeg, Tesseract and the DejaVu fonts the media is drawn with.

**The disk is full.** The lab needs about 2 GB. `df -h /opt /home` says how much is left, and `/opt/multimodal/media` can be deleted and rebuilt at any time, since the next `reset` draws it again.

If something fails that is not on this list, the error's last line is still the place to start. Search for it with the name of the library that raised it, and say so where you ask for help: "sherpa-onnx raised this while loading the Whisper decoder" gets an answer, and "the lab does not work" does not.
