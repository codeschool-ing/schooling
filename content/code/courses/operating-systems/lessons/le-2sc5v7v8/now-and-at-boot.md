---
title: Now, and at every boot
version: 1
---

A service has **two switches**, and confusing them is the commonest mistake with services.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 180\" role=\"img\" aria-label=\"Two separate switches for a service. Start and stop act now: start runs it, stop stops it. Enable and disable act at every boot: enable makes it start at boot, disable leaves it off. They are independent: a service can be stopped now and still enabled, so it comes back at the next boot. enable --now does both at once.\"><defs><marker id=\"gr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"44\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">now</text><text x=\"20\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">at every boot</text><rect x=\"200\" y=\"24\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">start</text><text x=\"214\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">runs it now</text><rect x=\"450\" y=\"24\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">stop</text><text x=\"464\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">stops it now</text><rect x=\"200\" y=\"84\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"214\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">enable</text><text x=\"214\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">starts it at boot</text><rect x=\"450\" y=\"84\" width=\"230\" height=\"42\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"464\" y=\"98\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">disable</text><text x=\"464\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">leaves it off at boot</text><text x=\"200\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">enable --now</text><text x=\"300\" y=\"160\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">does both</text></svg>", "caption": "Stopping a service is not turning it off. cron was stopped and still enabled, so a restart would have brought it back; that is often what somebody wants, and sometimes the opposite."}
```

```
ana@server:~$ sudo systemctl stop cron
ana@server:~$ systemctl is-active cron
inactive
ana@server:~$ systemctl is-enabled cron
enabled
ana@server:~$ sudo systemctl start cron
ana@server:~$ systemctl is-active cron
active
```

After **`stop`**, cron was **inactive**, and it was still **enabled**. At the next boot it would start
again. That is right for a quick test, and wrong for a service that should stay off: that needs
**`disable`** as well, and `disable --now` does both.

What starts at boot is the list of enabled units:

```
ana@server:~$ systemctl list-unit-files --type=service --state=enabled --no-pager --no-legend
cron.service                enabled enabled
e2scrub_reap.service        enabled enabled
getty@.service              enabled enabled
networkd-dispatcher.service enabled enabled
systemd-pstore.service      enabled enabled
systemd-resolved.service    enabled enabled
systemd-timesyncd.service   enabled enabled
```

Seven, on this server. The same list on a laptop that "takes ages to start" is where to look for
something nobody needs, and lesson 16 comes back to startup when a machine is slow.

## Restart and reload

**`restart`** stops and starts a service, and is what to do after changing its configuration file.
**`reload`**, where a service supports it, rereads the configuration **without** stopping, so the
connections it holds are not dropped. When unsure, `restart` is the one that always works.
