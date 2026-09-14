# The demonstration of section 19, as a VHS tape.
#
# THE WHOLE SESSION USES ONLY WHAT LESSON 1 TAUGHT. No `cd`, no `grep`, no
# redirection — those are lessons 3 and 8, and a demonstration that reached for
# them would be showing off rather than closing a lesson. What it shows is the
# arc: arrive, ask what the machine is, ask who you are, ask where you are,
# look, and read a refusal.
#
#     vhs a-first-session.tape
#
# Recorded as `ana` on Ubuntu 24.04, in ~/plain, which holds readme.txt,
# folder/ and .hidden.

Output a-first-session.gif

Require bash

Set Shell bash
Set FontSize 20
Set Width 1100
Set Height 700
Set Padding 24
Set TypingSpeed 90ms

Hide
Type "cd ~/plain && clear" Enter
Show

Sleep 1500ms

# Four questions, in the order you ask them on a machine you have just reached.
Type "whoami"           Enter  Sleep 2s
Type "uname -s"         Enter  Sleep 2s
Type "pwd"              Enter  Sleep 2s
Type "ls -la"           Enter  Sleep 4s

# What is this thing, and what is in it.
Type "file readme.txt"  Enter  Sleep 3s
Type "cat readme.txt"   Enter  Sleep 3s

# And the refusal, which is the beat the lesson has been building to.
Sleep 1s
Type "cat /etc/shadow"  Enter  Sleep 3s
Type "echo $?"          Enter  Sleep 3s
