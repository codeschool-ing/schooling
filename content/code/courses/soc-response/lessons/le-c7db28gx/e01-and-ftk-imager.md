---
title: E01, and FTK Imager
version: 1
---

A raw image is just bytes: the case number, who made it, when, and its hash all live somewhere else, in a
document that can be separated from it. The **Expert Witness Format**, the files ending in `.E01`, keeps them
**inside the image**, compresses the empty space, and stores a checksum for every block, so damage to the image
file is detected. It began with EnCase, a commercial forensic suite, and it is now the most common image format
in forensic work.

The tool most examiners use to write it is **FTK Imager**, free software from Exterro that runs on Windows.
**It was not run for this lesson**, because the lab is a Linux machine. In outline, it asks for exactly what the
next command takes as options: in *File, Create Disk Image*, a source (*Physical Drive*, through a write blocker),
an image type (*E01*), the evidence details (case number, evidence number, description, examiner, notes), a
destination folder, and a box worth always ticking, *Verify images after they are created*. When it finishes it
writes a text file beside the image with the hashes it calculated.

On Linux, `ewfacquire` from `ewf-tools` writes the same format, with the same details:

```
root@soc:~/case# ewfacquire -u -q -t evidence/files-data -C INC-2026-014 -E 001 -D 'files, data disk' -e diego -N 'imaged after containment' -d sha256 -c deflate:fast /dev/loop0
ewfacquire 20140814

Device information:
Bus type:				
Vendor:					
Model:					
Serial:					

Storage media information:
Type:					Device
Media type:				Fixed
Media size:				33 MB (33554432 bytes)
Bytes per sector:			512

MD5 hash calculated over data:		3260d6031df48a9f68dd1d7cb7578fda
SHA256 hash calculated over data:	eae7ac5a6c3fdefeba94adcb9f73955babaf7ffe4f54f20cb02e0d2cee186475
ewfacquire: SUCCESS
root@soc:~/case# ls -l evidence
total 32948
-rw-r--r-- 1 root root   180611 Oct  7 20:59 files-data.E01
-rw-r--r-- 1 root root 33554432 Oct  7 20:59 files-data.dd
```

`-u` runs it without questions; `-t` names the target, and `.E01` is added; `-C`, `-E`, `-D`, `-e` and `-N` are the
case number, evidence number, description, examiner and notes; `-d sha256` adds a SHA-256 to the MD5 it always
calculates; `-c deflate:fast` compresses. The SHA-256 it prints is **the same as `dd`'s**: the same disk, by two
tools. And the E01 is 180,611 bytes against the raw image's 33,554,432, because most of a new disk is empty and
empty compresses to almost nothing.

Then the verification, which reads the whole image back and compares, and the case details read out of the file
itself:

```
root@soc:~/case# ewfverify -q evidence/files-data.E01
ewfverify 20140814


MD5 hash stored in file:		3260d6031df48a9f68dd1d7cb7578fda
MD5 hash calculated over data:		3260d6031df48a9f68dd1d7cb7578fda

ewfverify: SUCCESS
root@soc:~/case# ewfinfo evidence/files-data.E01
ewfinfo 20140814

Acquiry information
	Case number:		INC-2026-014
	Description:		files, data disk
	Examiner name:		diego
	Evidence number:	001
	Notes:			imaged after containment
	Acquisition date:	Wed Oct  7 20:59:35 2026
	System date:		Wed Oct  7 20:59:35 2026
	Operating system used:	Linux
	Software version used:	20140814
	Password:		N/A

EWF information
	File format:		EnCase 6
	Sectors per chunk:	64
	Error granularity:	64
	Compression method:	deflate
	Compression level:	good (fast) compression

Media information
	Media type:		fixed disk
	Is physical:		yes
	Bytes per sector:	512
	Number of sectors:	65536
	Media size:		32 MiB (33554432 bytes)

Digest hash information
	MD5:			3260d6031df48a9f68dd1d7cb7578fda
```

One detail is worth noticing. The EnCase 6 format stores the **MD5** inside the file, and `ewfverify` checks that
one; the SHA-256 was calculated and printed, but this format has no place for it. So **the SHA-256 goes into the
custody record by hand**, from the acquisition's output, which is what the next section is about.
