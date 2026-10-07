---
title: Reading the log when it works, and when it does not
version: 1
---

When a tunnel will not come up, people read the configuration again, and both files look right to
whoever wrote them. **The log of one negotiation says which step failed**, and that narrows the search to
a few lines. `swanctl --initiate` starts a negotiation by hand and prints the daemon's log as it goes. A
working one is the reference to read a broken one against. Tear the connection down first, as in the
previous section, so that there is something to negotiate:

```
ana@hq:~$ sudo swanctl --initiate --child lans
[IKE] initiating IKE_SA offices[3] to 198.51.100.2
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (464 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (472 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[CFG] selected proposal: IKE:AES_CBC_256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
[IKE] authentication of 'hq.example.com' (myself) with pre-shared key
[IKE] establishing CHILD_SA lans{4}
[ENC] generating IKE_AUTH request 1 [ IDi N(INIT_CONTACT) IDr AUTH SA TSi TSr N(MULT_AUTH) N(EAP_ONLY) N(MSG_ID_SYN_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (272 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (224 bytes)
[ENC] parsed IKE_AUTH response 1 [ IDr AUTH SA TSi TSr ]
[IKE] authentication of 'branch.example.com' with pre-shared key successful
[IKE] IKE_SA offices[3] established between 203.0.113.2[hq.example.com]...198.51.100.2[branch.example.com]
[IKE] scheduling rekeying in 13711s
[IKE] maximum IKE_SA lifetime 15151s
[CFG] selected proposal: ESP:AES_GCM_16_256/NO_EXT_SEQ
[IKE] CHILD_SA lans{4} established with SPIs 9ab696f9_i 4ad97b9d_o and TS 192.168.10.0/24 === 192.168.20.0/24
initiate completed successfully
```

The `[NET]` lines are the four messages of the figure: 464 bytes out, 472 back, 272 out, 224 back. They
are tshark's frame lengths minus the 42 bytes of Ethernet, IP and UDP around each message, 506 − 42 =
464. The two runs were separate, and the sizes agree to the byte. The `[ENC]` lines list what each
message carried, including the two `NATD` hashes the next section puts to work, and `selected proposal`
appears once for each SA.

**`authentication of 'branch.example.com' with pre-shared key successful` is the line that says the other
side knew the key.** The rekey at 13711 seconds and the maximum lifetime at 15151 are 1440 apart, a tenth
of 14400: the grace an IKE SA gets to rekey before it is abandoned. The last line is what the exchange
was for, two SPIs and `TS 192.168.10.0/24 === 192.168.20.0/24`.

## A wrong key

Take the last letter, the `l` of `Quill`, off `branch`'s secret and reload it, on `branch`:
`sudo sed -i 's/7294-Quill/7294-Quil/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`. Tear the
connection down on `hq` again, and try:

```
ana@hq:~$ sudo swanctl --initiate --child lans
initiate failed: establishing CHILD_SA 'lans' failed
[IKE] initiating IKE_SA offices[4] to 198.51.100.2
[ENC] generating IKE_SA_INIT request 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(REDIR_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (464 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (472 bytes)
[ENC] parsed IKE_SA_INIT response 0 [ SA KE No N(NATD_S_IP) N(NATD_D_IP) N(FRAG_SUP) N(HASH_ALG) N(CHDLESS_SUP) N(MULT_AUTH) ]
[CFG] selected proposal: IKE:AES_CBC_256/HMAC_SHA2_256_128/PRF_HMAC_SHA2_256/MODP_2048
[IKE] authentication of 'hq.example.com' (myself) with pre-shared key
[IKE] establishing CHILD_SA lans{5}
[ENC] generating IKE_AUTH request 1 [ IDi N(INIT_CONTACT) IDr AUTH SA TSi TSr N(MULT_AUTH) N(EAP_ONLY) N(MSG_ID_SYN_SUP) ]
[NET] sending packet: from 203.0.113.2[500] to 198.51.100.2[500] (272 bytes)
[NET] received packet: from 198.51.100.2[500] to 203.0.113.2[500] (80 bytes)
[ENC] parsed IKE_AUTH response 1 [ N(AUTH_FAILED) ]
[IKE] received AUTHENTICATION_FAILED notify error
```

The verdict came out first, above the log it sums up. **The first exchange succeeded**, because
IKE_SA_INIT involves no key. The answer to IKE_AUTH was 80 bytes instead of 224, carrying only
`N(AUTH_FAILED)`: `branch` checked `hq`'s proof against its own secret, and they did not match.

Put the letter back before going on, with the opposite substitution, on `branch`:
`sudo sed -i 's/7294-Quil"/7294-Quill"/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`.

The notification says that authentication failed and not why. **The side that refused knows more than
the side that asked**, and `branch`'s own log, not captured here, would say more. A wrong `id` ends in
the same notification as a wrong secret, a case not captured either, so check both on both routers.

## Networks that do not match

The classic failure between two companies, or two vendors' routers, is a disagreement about which
networks the tunnel joins. Change `hq`'s `remote_ts` to `192.168.30.0/24`, a network `branch` does not
have, with the connection torn down first:
`sudo sed -i 's/192.168.20.0/192.168.30.0/' /etc/swanctl/swanctl.conf && sudo swanctl --load-all`.
Then initiate:

```
ana@hq:~$ sudo swanctl --initiate --child lans 2>&1 | tail -5
[IKE] IKE_SA offices[5] established between 203.0.113.2[hq.example.com]...198.51.100.2[branch.example.com]
[IKE] scheduling rekeying in 14399s
[IKE] maximum IKE_SA lifetime 15839s
[IKE] received TS_UNACCEPTABLE notify, no CHILD_SA built
[IKE] failed to establish CHILD_SA, keeping IKE_SA
```

**The IKE SA was established and the CHILD SA was refused**: `TS_UNACCEPTABLE`, traffic selectors
unacceptable. The two routers trust each other and carry nothing, the state people call "phase 1 up,
phase 2 down". The same `sed` the other way round, `s/192.168.30.0/192.168.20.0/`, puts the file back. The safe rule is to make the selectors on the two sides mirror each other exactly. IKEv2
lets a responder narrow a request to the part it accepts, and implementations use that differently. A
`/24` against a `/16` may work with one pair of routers and fail with another.

Each mistake is refused at a different step, which is what makes the log worth reading:

| what is wrong | where it stops | what the initiator's log says |
|---|---|---|
| no algorithm in common | IKE_SA_INIT | `NO_PROPOSAL_CHOSEN` (not captured here) |
| a different secret, or a wrong `id` | IKE_AUTH | `AUTHENTICATION_FAILED` |
| different networks | the CHILD SA, after IKE_AUTH | `TS_UNACCEPTABLE` |
| UDP 500 blocked on the way | nothing comes back | retransmissions, then a timeout (not captured here) |
