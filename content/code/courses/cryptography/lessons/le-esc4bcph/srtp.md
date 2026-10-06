---
title: SRTP, protecting a call packet by packet
version: 1
---

**SRTP, the Secure Real-time Transport Protocol, encrypts and authenticates the audio and video
packets of a call one by one, because real-time media cannot wait for retransmissions the way a TLS
stream can.** Vereda runs physiotherapy follow-ups by video call, and those calls carry exactly the
kind of conversation the LGPD treats as sensitive health data. This section has no capture: the lab
has no telephony, and the protocol is shown as its standards describe it.

## Why not just TLS

Voice and video travel over **RTP**, on UDP. A packet that arrives late is useless, so it is never
resent; a lost packet is simply a moment of silence or a frozen frame. TLS assumes a reliable stream
where every byte arrives in order, which is the opposite. SRTP (RFC 3711) keeps RTP's packet-by-packet
nature and protects each packet independently:

- the payload is encrypted, with AES in counter mode or, in newer profiles, AES-GCM, the modes of
  lesson 1. Each packet's counter is built from its sequence number and timestamp, so a packet can be
  decrypted without the ones before it;
- an authentication tag (HMAC-SHA1 truncated to 80 bits in the classic profile, or the GCM tag)
  covers the header and payload, so a forged or altered packet is dropped;
- a replay window refuses packets already seen.

Note what stays visible: the RTP header, with its sequence numbers and timestamps, and the packet
sizes and timing. Somebody watching cannot hear the call, but can tell that a call happened, how
long it lasted, and roughly when each side was speaking.

## Where the keys come from

SRTP needs a key agreed by the two sides, and how that key is agreed is where deployments differ:

| method | how the key is agreed | weakness |
|---|---|---|
| **SDES** | written into the call's SIP signalling | anybody who reads the signalling has the key; it must itself travel over TLS (SIPS, port 5061) |
| **DTLS-SRTP** | a DTLS handshake (TLS adapted to UDP) between the two endpoints | none in principle; this is what WebRTC requires |
| **ZRTP** | a Diffie-Hellman exchange in the media path, with a short code users read aloud to each other | depends on people actually comparing the code |

**WebRTC**, the technology inside browser-based video calls, makes DTLS-SRTP mandatory: a browser
will not send media without it. That is why a telemedicine call in a browser is encrypted by default,
while an old desk phone system on SIP may send its audio in clear text or with keys readable from the
signalling. A defender reviewing a VoIP system asks the same question as everywhere else in this
course: where does the key come from, and who else can read it?

Encryption from endpoint to endpoint holds only when the media flows between the two participants.
Many video platforms route media through their own servers, which decrypt and re-encrypt it, so
the platform can see the call. End-to-end encrypted calling exists, and a team choosing a platform
for health consultations checks which kind it is buying.
