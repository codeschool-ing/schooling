---
title: A guest network is a separate network
version: 1
---

The belief to replace: a guest network is a second SSID with a different password. If that SSID lands on
the same VLAN as the staff, **a visitor is on the office LAN**, one hop from the file server, the
printers and the management page of every switch. A second password only decides who gets on. A guest
network is defined by where they land.

Separation happens at every layer, and each layer has its own tool:

| layer | what separates guests | what it prevents |
|---|---|---|
| radio | its own SSID | nothing on its own |
| 2 | its own VLAN (lesson 19 of `networks-addressing`) | guests sharing a broadcast domain with staff |
| 2 | client isolation | one guest reaching another |
| 3 | a firewall: internet yes, internal ranges no | guests reaching anything inside |
| use | a rate limit per client and per SSID | one guest's download taking the staff's airtime |

**The firewall rule is the one that does the work.** The guest VLAN gets its own subnet, DHCP and DNS. Its policy lets it out to the internet and refuses every private range the company uses,
including the addresses the APs and switches are managed on. Written as "refuse 10.0.0.0/8,
172.16.0.0/12 and 192.168.0.0/16, then allow the rest", it stays right when somebody adds a new internal
network next year.

**Client isolation keeps guests from each other.** On one AP it is a setting: the AP refuses to forward
frames from one client to another. Guests on different APs meet on the switch, so the VLAN needs the same
rule there, as isolated switch ports or a firewall at the gateway that refuses traffic inside the guest
subnet.

## Encrypted or open

An open guest network is readable by anybody in range, as the section on WPA2 showed. Two better options:

- Enhanced Open, the Wi-Fi Alliance's name for OWE (RFC 8110): no password, but each client runs an
  unauthenticated key exchange with the AP and gets its own key. A passive listener reads nothing. It
  does not prove the AP is the real one, which is the price of having no secret at all.
- WPA3-Personal with a passphrase shown at reception and changed on a schedule, so last month's
  visitors are not this month's.

## The captive portal

A captive portal intercepts a new client's first web request and shows a page: the terms, a voucher code,
a sign-in with an e-mail address. **A captive portal is consent and accounting, not security**: it
encrypts nothing and separates nothing, so it sits on top of the VLAN and the firewall, never in place of
them.

## One radio, two networks

The whole design fits in one configuration file. Below is a fragment of `hostapd.conf`, the configuration
of the access point software that many Linux-based APs run. **It was not run**: hostapd needs a wireless
interface and this lab has none, so the file is an example to read, and its addresses are illustrative.

```schooling-example
{"language": "ini", "file": "hostapd.conf", "parts": [{"code": "interface=wlan0\ndriver=nl80211\ncountry_code=BR\nieee80211d=1\nhw_mode=a\nchannel=36\nieee80211n=1\nieee80211ac=1", "note": "The radio. One interface, the country whose rules it obeys (lesson 7: channels and power are law, not taste), the 5 GHz band and channel 36."}, {"code": "ssid=office\nbridge=br-staff", "note": "The first network. Its SSID, and the bridge its traffic lands on: `br-staff` is bridged to the staff VLAN on the switch port, so the SSID and the VLAN are one network."}, {"code": "wpa=2\nwpa_key_mgmt=WPA-EAP\nrsn_pairwise=CCMP\nieee80211w=2", "note": "WPA2 framing with 802.1X key management, AES-CCMP for the data, and `ieee80211w=2`: protected management frames required, so a client that cannot protect them is refused."}, {"code": "ieee8021x=1\nown_ip_addr=192.168.10.4\nnas_identifier=ap-hq-1\nauth_server_addr=192.168.10.5\nauth_server_port=1812\nauth_server_shared_secret=a-long-random-secret-per-ap", "note": "Where the verdict comes from. The AP is a RADIUS client: its own address, a name the server logs it by, and the server's address, port and shared secret. The lab has no RADIUS server, and these addresses are examples."}, {"code": "bss=wlan0_1\nssid=office-guest\nbridge=br-guest", "note": "A second network on the same radio. `bss=` gives it its own interface and so its own BSSID, and `br-guest` puts it on the guest VLAN, which the firewall lets out to the internet and nowhere else."}, {"code": "wpa=2\nwpa_key_mgmt=SAE\nsae_password=rotate-this-one-every-month\nsae_pwe=2\nrsn_pairwise=CCMP\nieee80211w=2", "note": "WPA3-Personal: SAE only, so no WPA2 client can join and weaken it. `sae_pwe=2` accepts both ways of deriving the password element, the original one and hash-to-element, which 6 GHz requires."}, {"code": "ap_isolate=1", "note": "Client isolation. Two guests on this AP cannot reach each other through it; guests on other APs are kept apart by the VLAN's switching and firewall, not by this line."}]}
```

The staff network authenticates each person against RADIUS; the guest network uses SAE with a passphrase
that changes every month. **What makes the second one a guest network is `br-guest`**, the bridge onto a
VLAN whose firewall lets it reach the internet and nothing else. `ap_isolate=1` is the second guard, and
the rate limits, which are not hostapd's job and are set on the gateway or the controller, are the third.
