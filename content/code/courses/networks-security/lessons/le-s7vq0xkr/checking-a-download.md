---
title: Checking a download, and what that proves
version: 1
---

Software is usually published with a list of digests beside it. The shop's server offers an agent
for the company's machines, and its list. In the lab the agent is 20,000 bytes of the letter `a`;
put it and its list on `www`, and give nginx a location to serve them from, as root there:

```sh
mkdir -p /var/www/downloads; cd /var/www/downloads; head -c 20000 /dev/zero | tr "\0" "a" > agent-2.4.1.tar.gz; sha256sum agent-2.4.1.tar.gz > SHA256SUMS
sed -i "s|    location / {|    location /downloads/ {\n        root /var/www;\n    }\n    location / {|" /etc/nginx/sites-enabled/shop; nginx -s reload
```

Then, from `laptop`:

```
ana@laptop:~$ curl -sO https://www.example.com/downloads/agent-2.4.1.tar.gz; curl -sO https://www.example.com/downloads/SHA256SUMS; cat SHA256SUMS
cc17faaad36649c4603dda4d8ff97cb149722af0bcac0746305a2134ad2d0b97  agent-2.4.1.tar.gz
```

`sha256sum -c` reads the list, hashes each file it names, and compares:

```
ana@laptop:~$ sha256sum -c SHA256SUMS
agent-2.4.1.tar.gz: OK
```

`OK`: the file on `laptop` is the file the list describes. Then one byte is appended, which is how a
file might differ after a transfer that went wrong, or after somebody altered it:

```
ana@laptop:~$ printf "x" >> agent-2.4.1.tar.gz; sha256sum -c SHA256SUMS; echo "exit $?"
agent-2.4.1.tar.gz: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
exit 1
```

`FAILED`, and an exit code of 1 that a script can stop on.

**What this proved is narrower than it looks.** The file matches the list, and the list came from
the same server as the file. Somebody who can replace the file on that server can replace the list
too, and the check will say `OK` to their version. A digest from the same place as the file protects
against **accidents**: a truncated download, a corrupted disk. Against a **person**, the digest has to
come from somewhere that person cannot also change, or it has to be signed by somebody whose key the
attacker does not hold. Signatures are two sections on.
