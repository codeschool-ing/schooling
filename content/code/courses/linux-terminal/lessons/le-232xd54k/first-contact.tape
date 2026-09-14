# The demonstration of section 05, as a VHS tape.
#
# THE TAPE IS THE SOURCE AND THE RECORDING IS NOT COMMITTED. What is quoted in
# the prose comes from running these commands, so the tape is what lets the next
# person re-run them against a newer distribution and see what moved. A
# transcript typed from memory is how a course teaches a prompt that does not
# exist and a flag that was removed two releases ago.
#
#   vhs first-contact.tape
#
# Recorded as `ana` on Ubuntu 24.04, in ~/demo, which holds readme.txt,
# "with space.txt", -strange, folder/ and .hidden.

Output first-contact.gif

Require bash

Set Shell bash
Set FontSize 20
Set Width 1100
Set Height 640
Set Padding 24
Set TypingSpeed 90ms

Hide
Type "cd ~/demo && clear" Enter
Show

Sleep 1500ms

Type "whoami"      Enter  Sleep 2s
Type "pwd"         Enter  Sleep 2s
Type "ls"          Enter  Sleep 3s
Type "ls -l"       Enter  Sleep 4s
Type "cat readme.txt" Enter Sleep 3s

# The mistake is the point of the last beat: the error names who is speaking
# and what it could not find, which is section 17's whole subject.
Sleep 1s
Type "celar"       Enter  Sleep 4s
