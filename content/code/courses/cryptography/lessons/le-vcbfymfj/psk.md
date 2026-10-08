---
title: What a passphrase becomes
version: 1
---

**On a WPA2-Personal network, the passphrase typed into every device is turned into a 256-bit key,
and that key is the same for every device, every day, until somebody changes the passphrase.** The
function that does it is PBKDF2, the slow hash of lesson 5, with the network's name as its salt. It
can be computed without a radio, which is what this section does.

## The key, computed

`wpa_passphrase` comes with `wpa_supplicant`, the program that joins Wi-Fi networks on Linux, and
Ubuntu packages it as `wpasupplicant`. It needs no Wi-Fi card for what this section does with it:

```sh
sudo apt-get install -y wpasupplicant
```

Given a network name, the SSID, and a passphrase, it prints the configuration block a client would
use, with the derived key as `psk`. Vereda's reception network, with the lab's passphrase:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Recepcao 'sala de espera, cadeira azul 2026'
network={
	ssid="Vereda-Recepcao"
	#psk="sala de espera, cadeira azul 2026"
	psk=3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84
}
```

That 64-hex-digit `psk` is the **pairwise master key**, the PMK. A client configured with it joins
the network without ever knowing the passphrase, which is why a company can push that line to its
laptops rather than telling staff the passphrase. The line still opens the network: whoever reads
it from a laptop's configuration has what the passphrase gave them.

The same passphrase on the staff network gives a different key, because the SSID is the salt:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Equipe 'sala de espera, cadeira azul 2026'
network={
	ssid="Vereda-Equipe"
	#psk="sala de espera, cadeira azul 2026"
	psk=e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42
}
```

And a passphrase below the standard's minimum is refused before anything is computed:

```
ana@lab:~/lab$ wpa_passphrase Vereda-Recepcao 'vereda1'; echo "exit status $?"
Passphrase must be 8..63 characters
exit status 1
```

## The whole derivation, in Python

There is no secret ingredient in that output. The derivation fits in one function, and running it
reproduces both keys above byte for byte. The copy button on the block gives you the whole file;
save it as `~/lab/wifi_pmk.py`:

```schooling-example
{
  "language": "python",
  "file": "wifi_pmk.py",
  "parts": [
    {
      "code": "import hashlib\nimport sys",
      "note": "Nothing outside the standard library: PBKDF2 is in `hashlib`."
    },
    {
      "code": "def pmk(passphrase: str, ssid: str) -> bytes:\n    if not 8 <= len(passphrase) <= 63:\n        raise ValueError(\"a WPA passphrase has 8 to 63 characters\")\n    return hashlib.pbkdf2_hmac(\"sha1\", passphrase.encode(), ssid.encode(), 4096, 32)",
      "note": "The whole of WPA2-Personal's key derivation. The passphrase is the password, the network name is the salt, the count is fixed at 4096 and the hash is SHA-1. The length check is the standard's own rule, the one `wpa_passphrase` refused above."
    },
    {
      "code": "passphrase = sys.argv[1]\nfor ssid in sys.argv[2:]:\n    print(f\"{ssid:16} {pmk(passphrase, ssid).hex()}\")",
      "note": "One passphrase, any number of network names, one key per name."
    }
  ],
  "output": "Vereda-Recepcao  3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84\nVereda-Equipe    e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42"
}
```

```
ana@lab:~/lab$ python3 wifi_pmk.py 'sala de espera, cadeira azul 2026' Vereda-Recepcao Vereda-Equipe
Vereda-Recepcao  3bd65e981d999f03d88db9970b60870c02f2b5b2aaf34f2c6c043d02ea49df84
Vereda-Equipe    e9b24a92126776e00bad20171d3f80df7e8b51d433f03ebb185bd585cbe14d42
```

## What follows from it

- **Everybody who knows the passphrase has the PMK.** There is no per-user secret. The receptionist,
  the physiotherapists and the technician who installed the access point all hold the same key.
- **The SSID is the salt, so a common SSID is a weak salt.** Lesson 5 explained why a salt has to be
  unique: a precomputed table only works for the salt it was computed with. Networks named after a
  router's default, `linksys` or `NETGEAR`, share their salt with millions of others, and tables for
  the most common names and passwords have been published for years. A distinct name, like
  `Vereda-Recepcao`, takes the network out of all of them.
- **4,096 rounds of SHA-1 was slow in 2004.** Today it is cheap. A single current graphics card computes
  more than two million PMKs a second. Argon2id, lesson 5's answer, came eleven years too late for
  this standard, so the only thing that makes guessing expensive here is the passphrase.
- **Changing the passphrase is the only revocation.** When somebody leaves Vereda, the key they knew
  still opens the network until the passphrase changes on the access point and on every device.

The next section shows where the PMK is used, and why somebody who never touched the network can
still test guesses against it.
