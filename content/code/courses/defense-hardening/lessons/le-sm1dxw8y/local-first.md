---
title: Looking at a file without opening it
version: 1
---

**The first questions about a suspicious file are answered on your own machine, without running it.**
What is it really? What is its hash? What text is inside it? Does it match a pattern you have seen
before? None of the four sends anything anywhere.

Two files have arrived on `desk`. One claims to be October's invoice; the other is a note. Both are
made here by the lesson, and the "invoice" is a harmless script that only prints a sentence, written
to look like the kind of thing that arrives by mail:

```
ana@desk:~$ mkdir -p ~/inbox && cd ~/inbox && cat > fatura-outubro.pdf <<'EOF'
#!/bin/sh
# A lab sample for lesson 19. It looks like a PDF by its name and is a shell script.
# It does nothing but print one sentence.
PAY_URL=http://pagamento.cobranca-urgente.example.org/boleto
echo "This file is a harmless lab sample. It would have opened $PAY_URL"
EOF
printf 'Reunião com o cliente às 15h.\nLevar o contrato assinado.\n' > nota.txt; ls -l
total 8
-rw-rw-r-- 1 ana ana 271 Oct 23 10:12 fatura-outubro.pdf
-rw-rw-r-- 1 ana ana  59 Oct 23 10:12 nota.txt
```

## What it really is

A file name is a label somebody chose. `file` reads the first bytes, where most formats announce
themselves, and says what they announce:

```
ana@desk:~$ cd ~/inbox && file *
fatura-outubro.pdf: POSIX shell script, ASCII text executable
nota.txt:           Unicode text, UTF-8 text
```

The invoice is a shell script. A real PDF starts with the four bytes `%PDF`, and this one starts with
`#!`, the mark of a script. **A file whose name and contents disagree is a finding before anything else
is known about it**, and on a workstation where somebody might double-click it, it is the finding that
matters.

## Its hash

```
ana@desk:~$ cd ~/inbox && sha256sum *
1f40c2b362d01d064dcc53f20fc9b0a3e624469b810c9c5e7493e02d9be70cce  fatura-outubro.pdf
881d0c339a944999540104f5a56afcf66ef77a8ff6fc50017e2d7fb718bec98e  nota.txt
```

A SHA-256 hash is 64 hexadecimal characters computed from every byte of the file: change one byte and
the hash changes completely, and nobody can work back from a hash to the content. That makes it the
right thing to search for and to write down. It is the identity a service looks a file up by, the line
an incident report records, and the input to the next three sections, **and it reveals nothing about a
client's data**, which the file itself would.

## What is written inside

`strings` prints the runs of readable text in any file, binary or not, and `xxd` shows the first bytes
with their hexadecimal values:

```
ana@desk:~$ cd ~/inbox && strings -n 8 fatura-outubro.pdf | grep -iE "http|sh"
#!/bin/sh
# A lab sample for lesson 19. It looks like a PDF by its name and is a shell script.
PAY_URL=http://pagamento.cobranca-urgente.example.org/boleto
ana@desk:~$ cd ~/inbox && xxd fatura-outubro.pdf | head -2
00000000: 2321 2f62 696e 2f73 680a 2320 4120 6c61  #!/bin/sh.# A la
00000010: 6220 7361 6d70 6c65 2066 6f72 206c 6573  b sample for les
```

The address the script would have visited is in plain text. In a real sample this is where you find
the domains to block at lesson 14's resolver and to look up in the last section of this lesson. The
`xxd` line shows the same first bytes `file` read: `2321` is `#!`.

## A pattern, written once

A YARA rule, which lesson 7 used to describe malware by its contents, can describe this situation too:
a script that carries a web address, whatever its name says. Write it on `desk` and run it over the
inbox, with `-s` to show what matched and where:

```
ana@desk:~$ cat > ~/disguised.yar <<'EOF'
rule script_named_like_a_document
{
    meta:
        description = "a shell script that carries a web address, whatever its name says"
    strings:
        $shebang = "#!/bin/sh"
        $url = /https?:\/\/[a-z0-9.-]+\.[a-z]{2,}/
    condition:
        $shebang at 0 and $url
}
EOF
yara -s ~/disguised.yar ~/inbox
script_named_like_a_document /home/ana/inbox/fatura-outubro.pdf
0x0:$shebang: #!/bin/sh
0x91:$url: http://pagamento.cobranca-urgente.example.org
```

One file matches, at byte 0 for the script mark and at byte `0x91` for the address; the note does not.
A rule like this costs nothing to run over every attachment a mail server receives, and it encodes what
an analyst learnt from one sample so that the next one is found without an analyst.

**Everything in this section stayed on `desk`.** The file was never executed, never uploaded, and the
four answers it gave are enough to decide that it should not reach anybody else's inbox. The next
sections are for the cases where they are not enough.
