---
title: A disk to image
version: 1
---

The lab needs a disk with something on it. Real disks are large and slow to copy; a **disk image file** of 32 MB
behaves exactly like a disk for everything in this lesson, and Linux can present it as a block device, the same
kind of thing as `/dev/sda`.

The contents come from a short program. Make a folder for the case, `mkdir /root/case`, and write this in it as
`make_disk.py`:

```schooling-example
{"language": "python", "file": "make_disk.py", "parts": [{"code": "# make_disk.py: the files a small office keeps on its file server, written into ./data\nimport csv\nimport os\nimport random\n"}, {"code": "random.seed(16)\nCLIENTS = [\"acme-logistica\", \"bento-advogados\", \"casa-verde\", \"delta-engenharia\", \"estrela-saude\"]\nNAMES = [\"Alice Moreira\", \"Caio Prado\", \"Denise Rocha\", \"Enzo Lima\", \"Fabiana Reis\", \"Gustavo Alves\"]\n", "note": "A fixed seed, so every run writes the same contents: five clients and six people, all invented."}, {"code": "for client in CLIENTS:\n    folder = os.path.join(\"data\", \"clients\", client)\n    os.makedirs(folder, exist_ok=True)\n    with open(os.path.join(folder, \"contracts.csv\"), \"w\", newline=\"\") as f:\n        w = csv.writer(f)\n        w.writerow([\"contract\", \"signed\", \"value_brl\"])\n        for n in range(1, random.randint(3, 6)):\n            w.writerow([f\"{client}-{n:03}\", f\"2026-0{random.randint(1, 8)}-1{n}\", random.randint(5, 90) * 1000])\n", "note": "One folder per client, each with a few contracts. This is the ordinary business data a file server holds."}, {"code": "os.makedirs(os.path.join(\"data\", \"exports\"), exist_ok=True)\nwith open(os.path.join(\"data\", \"exports\", \"contacts-2026-08.csv\"), \"w\", newline=\"\") as f:\n    w = csv.writer(f)\n    w.writerow([\"client\", \"contact\", \"email\"])\n    for client in CLIENTS:\n        name = random.choice(NAMES)\n        w.writerow([client, name, name.split()[0].lower() + \"@\" + client + \".example\"])\nprint(\"written:\", sum(len(files) for _, _, files in os.walk(\"data\")), \"files\")", "note": "One export of contacts, with names and e-mail addresses: personal data. The lesson deletes it, and lesson 17 gets it back."}]}
```

Then three commands. The program writes the files. `mke2fs` makes an ext4 file system of 32 MB in a file called
`disk.img` and fills it with the folder `data` (`-d`), with no need to mount anything. And `debugfs`, the ext
file systems' own repair tool, deletes the export **inside** the image, the way a member of staff tidying up
would have deleted it from the server:

```
root@soc:~/case# python3 make_disk.py
written: 6 files
root@soc:~/case# mke2fs -q -t ext4 -L files-data -d data disk.img 32M
Creating regular file disk.img
root@soc:~/case# debugfs -w -R 'rm exports/contacts-2026-08.csv' disk.img
debugfs 1.47.0 (5-Feb-2023)

root@soc:~/case# ls -l disk.img
-rw-r--r-- 1 root root 33554432 Oct  7 20:59 disk.img
```

The disk now holds five contract files, and the export is gone from its folder. Gone from the folder is not gone
from the disk: deleting a file on ext4 removes the name and marks the space free, and the bytes stay until
something overwrites them. Lesson 17 finds them. For now, the disk is the evidence, and this lesson's job is to
copy it without changing it.

This lesson needs one package that lesson 1 did not install, `ewf-tools`, used in the fifth section. Install it
now, `sudo apt install ewf-tools`, so the lab is ready.
