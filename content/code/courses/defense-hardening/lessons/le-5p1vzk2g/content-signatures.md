---
title: Content signatures and YARA
version: 1
---

**A content signature describes something inside a file rather than the whole file.** It is a
sequence of bytes, a pattern, or a combination of them, and it matches every file that contains it,
however much else differs. One content signature can cover a family of variants that would need a
hash each.

ClamAV's simplest content signature lives in a `.ndb` file: a name, the kind of file it applies to
(`0` is any), where to look (`*` is anywhere), and the bytes, written in hexadecimal. `xxd -p` turns
the stand-in's marker into those bytes:

```
ana@desk:~$ printf "JATOBA-LAB-SAMPLE" | xxd -p
4a41544f42412d4c41422d53414d504c45
ana@desk:~$ echo "Jatoba.Lab.Marker:0:*:4a41544f42412d4c41422d53414d504c45" > lab.ndb; clamscan --no-summary -d lab.ndb samples/; echo "exit $?"
samples/copy.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/changed.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
samples/invoice.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
exit 1
```

All three samples are found, `changed.txt` included, because the marker is in all three. ClamAV
also has logical signatures (`.ldb`), which combine several patterns with *and* and *or* and
conditions on how many times each appears, and signatures tied to a file format, for example a pattern
that only counts inside the code section of a Windows executable.

## YARA, the defender's pattern language

**YARA** is the tool analysts reach for when they write their own rules, and many security products
read its rules directly. A rule names its strings and then states a condition over them, which can
include the file's size, its format and how many strings matched:

```
ana@desk:~$ cat > lab.yar <<"EOF"
rule jatoba_lab_marker
{
    strings:
        $marker = "JATOBA-LAB-SAMPLE"
        $word = "invoice" nocase
    condition:
        $marker and $word and filesize < 1KB
}
EOF
yara lab.yar samples/
jatoba_lab_marker samples//invoice.txt
jatoba_lab_marker samples//copy.txt
jatoba_lab_marker samples//changed.txt
```

The rule matches a file that contains the marker *and* the word "invoice" in any case, *and* is under
a kilobyte. Each clause narrows it: a marker alone would be a weaker rule, and a size limit keeps a
large document that happens to quote the marker from matching. Analysts keep rules like this one in
version control, test them against a set of files that must match and a set that must not, and share
them with each other.

## The price of matching more

A pattern matches any file that contains it, including files nobody meant it to describe:

```
ana@desk:~$ printf "Training notes: files marked JATOBA-LAB-SAMPLE are invoice test files.\n" > notes.txt; yara lab.yar notes.txt; clamscan --no-summary -d lab.ndb notes.txt
jatoba_lab_marker notes.txt
notes.txt: Jatoba.Lab.Marker.UNOFFICIAL FOUND
```

A training note that quotes the marker, which is perfectly innocent, is flagged by both. This is a
**false positive**, and every content rule has some. A rule broad enough to catch tomorrow's variant is
broad enough to catch somebody's document, and the cost lands on the person whose file was quarantined
and on whoever has to decide whether it was right. Writing a good rule is choosing what in a file is
specific to the thing you mean, and nothing else.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"l07-matches\" aria-label=\"Which rule matched which file in this lesson. Four files across: invoice.txt, its exact copy, changed.txt which differs by one space, and an innocent training note that quotes the marker. Three rules down. The hash signature matched the original and the copy only. The content signature matched all three samples and also the note. The YARA rule, with the marker, the word invoice and a size limit, matched the same four.\"><text x=\"260.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">invoice.txt</text><text x=\"375.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">copy.txt</text><text x=\"490.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">changed.txt</text><text x=\"605.0\" y=\"36.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">notes.txt</text><text x=\"605.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">innocent</text><rect x=\"20.0\" y=\"70.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">hash (.hsb)</text><rect x=\"220.0\" y=\"78.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"335.0\" y=\"78.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><text x=\"490.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">OK</text><text x=\"605.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">OK</text><rect x=\"20.0\" y=\"120.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">content (.ndb)</text><rect x=\"220.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"335.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"450.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"565.0\" y=\"128.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">false positive</text><rect x=\"20.0\" y=\"170.0\" width=\"680.0\" height=\"40.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"36.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">YARA rule</text><rect x=\"220.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"260.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"335.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"450.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">found</text><rect x=\"565.0\" y=\"178.0\" width=\"80.0\" height=\"24.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"605.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">false positive</text><text x=\"360.0\" y=\"232.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">the broader the rule, the more it catches, wanted or not</text></svg>", "caption": "Exact rules miss variants; broad rules catch innocent files."}
```
