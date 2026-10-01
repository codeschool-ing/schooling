---
title: "CIDR: reading /16 and carving a range"
version: 1
---

A common first reading of `/24` and `/16` is that the bigger number is the bigger network. It is the
other way round, and once you see why, the rest of this section is arithmetic.

An IPv4 address is 32 bits, written as four numbers of 8 bits each. **The number after the slash
says how many of those 32 bits are fixed**; the ones left over are free to vary, and every
combination of them is one address in the block. So a block holds 2 to the power of (32 − N)
addresses. Fix more bits and fewer are left: `/24` leaves 8 free bits, `/16` leaves 16.

```
ana@laptop:~/cloud$ python3 -c "print(2**(32-16), 2**(32-20), 2**(32-24))"
65536 4096 256
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(ipaddress.ip_network('10.0.0.0/16').num_addresses)"
65536
```

The first line is the formula, done three times; the second asks Python's `ipaddress` module, which
knows the notation, about the VPC from the previous section. **A `/16` is 65,536 addresses, a `/20`
is 4,096 and a `/24` is 256.** This way of writing a network is called CIDR, for classless
inter-domain routing, and the `/N` is its prefix length. You met prefix lengths in `networks`, where
`/24` meant "the first three numbers match".

## When the slash falls on a boundary, and when it does not

At `/8`, `/16` and `/24` the fixed bits end exactly at a dot, so the block reads straight off the
address: `10.0.0.0/16` is every address that starts with `10.0`. Anything in between falls inside
one of the four numbers, and that is where people stop trusting their eyes.

Take `/20`. Sixteen bits cover the first two numbers, and **four more bits are fixed inside the
third**. Four fixed bits out of eight leave four free, so the third number moves in steps of 16,
which is two to the power of four. One `/20` covers third numbers 0 to 15, the next 16 to 31, the next 32 to 47. Carving
`10.0.0.0/16` into `/20` subnets:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress, itertools; vpc = ipaddress.ip_network('10.0.0.0/16'); print(*itertools.islice(vpc.subnets(new_prefix=20), 4), sep='\n')"
10.0.0.0/20
10.0.16.0/20
10.0.32.0/20
10.0.48.0/20
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(len(list(ipaddress.ip_network('10.0.0.0/16').subnets(new_prefix=20))))"
16
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(ipaddress.ip_address('10.0.17.5') in ipaddress.ip_network('10.0.16.0/20'))"
True
```

`itertools.islice` stops the list at four; the second command counts the whole of it. **Sixteen
subnets of `/20` fit in a `/16`**, which is 2 to the power of (20 − 16), and each is 4,096
addresses. The last command asks whether `10.0.17.5` belongs to `10.0.16.0/20`, and it does: 17 is
between 16 and 31. That is the question every route table in this lesson asks about every packet.

A block starts at a multiple of its own size. `10.0.16.0/20` is a network and `10.0.8.0/20` is
not, because 8 is not a multiple of 16, and `ipaddress` refuses it rather than guessing which
network was meant:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; ipaddress.ip_network('10.0.8.0/20')" 2>&1 | tail -1
ValueError: 10.0.8.0/20 has host bits set
```

The "host bits" are the free ones. In `10.0.8.0` one of them is already set, so the address is
somewhere inside a `/20` and not the start of one.

## The private ranges, read with the formula

The three ranges in the previous section are ordinary CIDR blocks, and the formula gives their
size:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; [print(n, n[0], n[-1], n.num_addresses) for n in map(ipaddress.ip_network, ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'])]"
10.0.0.0/8 10.0.0.0 10.255.255.255 16777216
172.16.0.0/12 172.16.0.0 172.31.255.255 1048576
192.168.0.0/16 192.168.0.0 192.168.255.255 65536
```

`172.16.0.0/12` is the one that surprises people. Twelve fixed bits reach four bits into the
second number, so it runs from `172.16` to `172.31`, and `172.32.0.1` is a public address.
The default VPC's `172.31.0.0/16` sits at its very top.

And the overlap that the previous section warned about is one call:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; vpc = ipaddress.ip_network('10.0.0.0/16'); print(vpc.overlaps(ipaddress.ip_network('10.0.128.0/24')), vpc.overlaps(ipaddress.ip_network('10.1.0.0/16')))"
True False
```

A `/24` at `10.0.128.0` sits inside `10.0.0.0/16`, so a network using it cannot be joined to that
VPC; `10.1.0.0/16` shares no address with it and can. Checking a proposed range against everything
you already run is a loop around this line, and it is cheaper than the migration.
