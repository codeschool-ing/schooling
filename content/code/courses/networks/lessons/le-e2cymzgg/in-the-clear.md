---
title: Everything in the clear
version: 1
---

Plain FTP encrypts nothing. From the ISP's machine, which every packet between the office and `www`
crosses, one login and one listing look like this:

```
ana@isp:~$ sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -oE "FTP: .*"
FTP: 220 (vsFTPd 3.0.5)
FTP: USER example
FTP: 331 Please specify the password.
FTP: PASS Sunflower-77
FTP: 230 Login successful.
FTP: PWD
FTP: 257 "/" is the current directory
FTP: EPSV
FTP: 229 Entering Extended Passive Mode (|||40008|)
FTP: TYPE A
FTP: 200 Switching to ASCII mode.
FTP: LIST
FTP: 150 Here comes the directory listing.
FTP: 226 Directory send OK.
FTP: QUIT
FTP: 221 Goodbye.
```

**The whole conversation, and the password in it, `PASS Sunflower-77`.** Anybody on the path sees the
same: the ISP, the hotel's Wi-Fi, somebody on the office network with a laptop and ten minutes. The
files travel the same way, on the data connections. It is the plain HTTP of lesson 5 again, with a
password on top.

That password is also the hosting account's, which means whoever reads it can replace the website. **A
plain FTP password should be treated as already known**: never the same as any other password, and
changed when FTP is replaced by one of the encrypted ways below.
