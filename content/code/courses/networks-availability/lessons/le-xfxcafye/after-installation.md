---
title: The survey document, and the survey after installation
version: 1
---

A survey ends in a written document, and that document is what the next person relies on when a user says
the Wi-Fi is bad in room 204. **Its job is to make the design checkable**: what was required, what was
measured, how, and where the result fell short. A document that is only a set of green pictures answers
none of that.

What it carries, and why each part is there:

| part | why it is there |
|---|---|
| the requirements: applications, targets, the weakest client | what every measurement is judged against |
| method, dates and the building's state | predictive or measured, and empty or occupied |
| the adapter or device, and its offset from the real clients | a map read 5 dB optimistic is a different design |
| floor plans with each AP, its mounting height and antenna | how to put it back after somebody moves it |
| the channel and power plan | the co-channel arithmetic of lesson 7, written down |
| heat maps: primary, secondary, SNR, channel overlap | the views of the section before, not only the first |
| the path walked | which areas were measured and which were painted in |
| **exceptions** | every area below target, and why that was accepted |

**The exceptions are the most useful page in it.** A stairwell below −75 dBm because nobody makes calls
there is a decision. The same stairwell with no line in the document is a fault waiting for a ticket.

## Validate after installation

A predictive design assumed wall materials; the building has the real ones. Cables end up a metre from
where the plan said, a ceiling hides a metal duct, and a meeting room turns out to have coated glass.
**So the survey is walked again once the APs are up**, passive and active, against the same requirements.
This is the step most often skipped, because the network already works for the people who installed it,
standing beside the APs.

What validation checks, beyond the maps:

- a roam test with the devices that matter: a voice call carried along the busiest route, with any drop
  noted and located, since a heat map cannot show a roam;
- the active measurements in the places the requirements named: the lecture theatre full, the warehouse
  at the far end of the aisles;
- every exception, confirmed to be where the document says and no larger.

Where something falls short, the fix is in placement, channel or power, then a survey of that area again.
**Turning the power up is the fix that does not work**: it enlarges the AP's cell in one direction only,
the one the phone cannot answer across, and adds co-channel overlap for everybody else.

## And again, later

A survey describes the building on the day it was walked. **New walls, a new tenant next door on your
channels, a warehouse restocked to the ceiling** each change the answer, and the sensible trigger for a
new survey is a change to the building, not a complaint. The document's own numbers are what the new
survey is compared with, which is one more reason to write them down.
