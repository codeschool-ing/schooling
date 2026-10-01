---
title: dBm and milliwatts
version: 1
---

Radio power spans a range no ordinary unit handles well. An access point transmits a tenth of a watt;
what reaches a phone across the office is often less than a millionth of a milliwatt, and the link
still works. Writing those as milliwatts means counting zeros, so everybody in wireless writes them in
**dBm: decibels relative to one milliwatt**, ten times the logarithm of the power in mW.

The logarithm is what makes it worth learning, because it turns multiplying into adding. **+3 dB
doubles the power, +10 dB multiplies it by ten**, and the minus signs halve and divide. A gain or a loss
in dB, an antenna's gain, a cable's loss, a wall's attenuation, is simply added to a level in dBm. The
program below converts both ways and does a small budget. It was run with `python3`:

```schooling-example
{"language": "python", "file": "dbm.py", "parts": [{"code": "from math import log10\n\ndef to_dbm(mw):\n    return 10 * log10(mw)\n\ndef to_mw(dbm):\n    return 10 ** (dbm / 10)", "note": "The two conversions, and nothing else is needed. dBm is ten times the base-10 logarithm of the power in milliwatts; going back is ten to the power of a tenth of it."}, {"code": "for mw in (1, 2, 10, 100, 200, 1000):\n    print(f\"{mw:5} mW = {to_dbm(mw):5.1f} dBm\")", "note": "Milliwatts to dBm. Doubling, 1 to 2 or 100 to 200, adds 3.0; multiplying by ten adds exactly 10."}, {"code": "for dbm in (-30, -67, -90):\n    print(f\"{dbm:4} dBm = {to_mw(dbm):.0e} mW\")", "note": "Received levels, which are negative because they are fractions of a milliwatt. Printed to one significant figure, so -67 dBm shows as 2e-07 mW."}, {"code": "radio, antenna, cable = 17, 5, -2  # dBm, dBi, dB: gains and losses simply add\nprint(f\"EIRP: {radio} + {antenna} + ({cable}) = {radio + antenna + cable} dBm\")", "note": "A transmit budget. A 17 dBm radio, a 5 dBi antenna and a cable losing 2 dB give 20 dBm of EIRP, by addition alone."}, {"code": "ap, phone = 23, 14  # transmit power in dBm\nprint(f\"AP {ap} dBm is {to_mw(ap):.0f} mW; phone {phone} dBm is {to_mw(phone):.0f} mW\")\nprint(f\"{ap - phone} dB apart: the AP is {to_mw(ap) / to_mw(phone):.1f} times louder\")", "note": "The two ends of one link, with the transmit powers of the next section: nine decibels is almost eight times the power."}, {"code": "loss = 98  # dB between the two, the same in both directions\nprint(f\"the phone hears the AP at {ap - loss} dBm; the AP hears the phone at {phone - loss} dBm\")", "note": "The same loss applies both ways, so each end hears the other exactly as much weaker as it transmits."}], "output": "    1 mW =   0.0 dBm\n    2 mW =   3.0 dBm\n   10 mW =  10.0 dBm\n  100 mW =  20.0 dBm\n  200 mW =  23.0 dBm\n 1000 mW =  30.0 dBm\n -30 dBm = 1e-03 mW\n -67 dBm = 2e-07 mW\n -90 dBm = 1e-09 mW\nEIRP: 17 + 5 + (-2) = 20 dBm\nAP 23 dBm is 200 mW; phone 14 dBm is 25 mW\n9 dB apart: the AP is 7.9 times louder\nthe phone hears the AP at -75 dBm; the AP hears the phone at -84 dBm"}
```

Read the first block as a table to learn by heart: **0 dBm is 1 mW, 20 dBm is 100 mW, 30 dBm is one
watt**, and 23 dBm is 200 mW because 3 dB more is twice as much. The second block is the other end of the
scale. A phone that reports −67 dBm is receiving about 2e-07 mW, two ten-millionths of a milliwatt, and
the printed values are rounded to one figure. That is a strong signal by Wi-Fi's standards; lesson 10
explains why −67 dBm is the level designers aim for, and −90 dBm is close to where the noise begins.

**A received level is negative, and closer to zero is stronger.** −50 dBm is a hundred times more power
than −70 dBm, not a smaller number that is somehow better. People who read −70 as "higher" than −50
because 70 is bigger are misreading a scale where the minus sign does all the work.

## EIRP, what the rules limit

A radio's power is only part of what leaves the antenna. **EIRP**, the effective isotropic radiated
power, is the radio's output plus the antenna's gain in dBi minus the loss in the cable between them:
17 + 5 − 2 = 20 dBm in the example. Regulators limit EIRP, not the radio alone, because the antenna
is what decides how much energy reaches a given direction. In Europe the 2.4 GHz limit is 100 mW EIRP,
20 dBm; in the United States a radio may put out 1 W and use an antenna of up to 6 dBi. Fitting a
bigger antenna to an access point therefore uses up the same allowance, and an access point that
knows its country and its antenna turns its own power down to stay inside it.
