---
title: Keeping the rule after a restart
version: 1
---

A rule loaded with `nft -f` lives in memory, and **the host's next restart forgets it**. The obvious
place to keep it is `/etc/nftables.conf`, which Ubuntu loads at boot, and it has a trap in its third
line:

```
ana@host:~$ grep -n "flush ruleset" /etc/nftables.conf
3:flush ruleset
```

`flush ruleset` empties **every** table, including the ones libvirt filled for its networks. Pasting the
lab's rule into that file works on the first boot and removes libvirt's rules the day somebody reloads
the firewall.

A file of its own and a small service that loads it at boot keep the two apart. **None of these were run
for this lesson**:

```sh
sudo install -m 644 labguard.nft /etc/labguard.nft
sudo tee /etc/systemd/system/labguard.service >/dev/null <<'EOF'
[Unit]
Description=Keep lab guests away from the host's services

[Service]
Type=oneshot
ExecStart=/usr/sbin/nft -f /etc/labguard.nft
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF
sudo systemctl enable labguard.service
```

The rule matches **`iifname`**, the interface by name, and that is why it can load at boot before labnet
exists: `iif` would look the interface up when the rule is loaded and fail.

On Windows and macOS the idea is the same and the tool is different: the host's own firewall, told to
refuse what arrives from the virtual network's adapter. The simplest answer there is the next section's:
a network on which the host has no address at all.
