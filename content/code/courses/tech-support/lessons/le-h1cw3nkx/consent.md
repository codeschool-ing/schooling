---
title: Consent, one step at a time
version: 1
---

The lab's computers have no desktop to share, so the shared screen here is a terminal one, **tmux**,
which has the same states a remote support tool has. Elisa starts a session of her own:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help new -d -s help; ls -l /tmp/help
srw------- 1 elisa elisa 0 Sep 26 01:36 /tmp/help
ana@pc1:~$ tmux -S /tmp/help send-keys -t help "hostname" Enter
error connecting to /tmp/help (Permission denied)
```

The session's socket is Elisa's alone, `srw-------`, and the technician is refused: **refused is the
default**, which is what anyone would want on their own computer. Making the file readable is not
enough either:

```
ana@pc1:~$ sudo -u elisa chmod 666 /tmp/help; tmux -S /tmp/help send-keys -t help "hostname" Enter
access not allowed
```

tmux keeps its own list of who may connect, and `ana` is not on it. Only Elisa can put her there:

```
ana@pc1:~$ sudo -u elisa tmux -S /tmp/help server-access -a ana
ana@pc1:~$ tmux -S /tmp/help send-keys -t help "hostname; whoami" Enter; sleep 1; sudo -u elisa tmux -S /tmp/help capture-pane -p -t help | grep -v "^$"
elisa@pc1:~$ hostname; whoami
pc1
elisa
elisa@pc1:~$
```

Now the technician can type, and the capture of Elisa's screen shows what that means: **the commands
appear in her session and run as her**, `whoami` answers `elisa`. She sees every key the technician
presses, and anything done there is done with her permissions, not the technician's.
