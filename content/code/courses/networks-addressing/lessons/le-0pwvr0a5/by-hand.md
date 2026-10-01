---
title: Working it out without a calculator
version: 1
---

Converting every octet to binary works and is slow. There is a shortcut that gives the network and
broadcast of any address in a few seconds, and it rests on the pattern of the previous section:
every range starts at a multiple of its own size. **The block size method** has four steps.

1. **Find the interesting octet**: the one where the mask is neither 255 nor 0. Octets before it are
   copied from the address; octets after it are 0 in the network and 255 in the broadcast.
2. **Block size = 256 − the mask's value in that octet.**
3. **The network's value in that octet is the largest multiple of the block size that is not more than
   the address's value.**
4. **The broadcast's value in that octet is the network's value + block size − 1.**

Work one that is not in this lab: `172.16.45.77/20`.

- `/20` is 16 + 4, so the mask is `255.255.240.0` and the interesting octet is the **third**.
- Block size: 256 − 240 = **16**.
- The multiples of 16 are 0, 16, 32, 48 and so on. The address's third octet is 45, which sits between
  32 and 48, so the network's third octet is **32**: the network is `172.16.32.0`.
- Broadcast: 32 + 16 − 1 = 47 in the third octet, and 255 after it: `172.16.47.255`.
- Size: 20 network bits leave 12 host bits, so 2^12 = **4096** addresses and 4094 hosts. The same
  number again from the block: 16 values of the third octet, each with 256 values of the fourth,
  16 × 256 = 4096.

Now check it. sipcalc prints more than ipcalc does, and every line can be held against the work above:

```
ana@sales1:~$ sipcalc 172.16.45.77/20
-[ipv4 : 172.16.45.77/20] - 0

[CIDR]
Host address		- 172.16.45.77
Host address (decimal)	- 2886741325
Host address (hex)	- AC102D4D
Network address		- 172.16.32.0
Network mask		- 255.255.240.0
Network mask (bits)	- 20
Network mask (hex)	- FFFFF000
Broadcast address	- 172.16.47.255
Cisco wildcard		- 0.0.15.255
Addresses in network	- 4096
Network range		- 172.16.32.0 - 172.16.47.255
Usable range		- 172.16.32.1 - 172.16.47.254

-
```

`Network address 172.16.32.0`, `Broadcast address 172.16.47.255`, `Addresses in network 4096` and a
usable range from `.32.1` to `.47.254`. **The method and the calculator agree, and the method took
four lines of arithmetic.** sipcalc adds two readings worth noticing. `Host address (decimal)
2886741325` and `(hex) AC102D4D` are the address as the single 32-bit number lesson 8 said it was:
`AC` is 172, `10` is 16, `2D` is 45, `4D` is 77. And `Cisco wildcard 0.0.15.255` is the mask inside out,
255 − 240 = 15 in the third octet, as the first section of this lesson explained.

One more, with the interesting octet in a different place: `10.0.77.200/21`. `/21` is 16 + 5, so the
mask is `255.255.248.0`, the third octet again, and the block is 256 − 248 = 8. The multiples of 8 near
77 are 72 and 80, so the network is `10.0.72.0` and the broadcast is 72 + 8 − 1 = 79 in the third octet:
`10.0.79.255`. The fourth octet of the address, 200, did not matter at all, because the mask there is
0. That one was not run through a calculator in the lab; it is arithmetic, and **the way to trust it is
to check it once with ipcalc or sipcalc on any Linux machine** until you trust the method on its own.

The common slip is applying the block size to the wrong octet. For `/20` the block of 16 is in the
third octet; taking `172.16.45.64` as the network, as if the block were in the fourth, gives a range
that is both too small and in the wrong place. **Find the interesting octet before anything else**,
and the rest follows.
