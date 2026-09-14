# The transcripts section 28 needs, as a VHS tape.
#
# THIS IS THE ONE TAPE IN THE COURSE THAT HAS NOT BEEN RUN. The machine the
# section was written on cannot reach a container registry: its egress proxy
# refuses the Docker Hub blob host, so `docker pull alpine` fails after the
# manifest and before the layers.
#
# So the prose below quotes nothing it did not capture. It states what Alpine
# does and why, and this file is the exact session that turns those statements
# into transcripts — run it on a machine with a registry and paste the output
# into the section, replacing the prose that describes each command.
#
#     vhs alpine-and-containers.tape
#
# The four beats, in the order the section argues them: the size, the shell
# that is not bash, the package manager that is not apt, and the `ldd` that
# names musl.

Output alpine-and-containers.gif

Require docker

Set Shell bash
Set FontSize 20
Set Width 1200
Set Height 720
Set Padding 24
Set TypingSpeed 80ms

Hide
Type "clear" Enter
Show

Sleep 1s

# 1 · the size, next to the one it is usually compared with
Type "docker image ls --format '{{.Repository}}:{{.Tag}}  {{.Size}}' alpine ubuntu" Enter
Sleep 4s

# 2 · the userland is busybox, and `ls` is not GNU's
Type "docker run --rm alpine sh -c 'ls --help 2>&1 | head -3'" Enter
Sleep 4s
Type "docker run --rm alpine sh -c 'readlink -f /bin/ls'" Enter
Sleep 3s

# 3 · there is no bash, and /bin/sh is ash rather than dash
Type "docker run --rm alpine sh -c 'command -v bash; echo exit=$?'" Enter
Sleep 4s

# 4 · apk, and how fast it is
Type "docker run --rm alpine sh -c 'time apk add --no-cache curl' 2>&1 | tail -6" Enter
Sleep 6s

# 5 · musl, which is the reason a foreign binary refuses to start
Type "docker run --rm alpine sh -c 'ldd /bin/ls'" Enter
Sleep 4s
Type "docker run --rm ubuntu sh -c 'ldd /bin/ls'" Enter
Sleep 4s
