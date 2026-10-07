---
title: A driver for FRR
version: 1
---

**NAPALM ships drivers for Arista EOS, Cisco IOS, IOS-XR and NX-OS, and Juniper Junos, and none
for FRR.** It finds a driver it does not ship by importing a package called `napalm_<name>`, which
is how community drivers work, so `get_network_driver("frr")` imports `napalm_frr`. The lab's is
written for this course, and it is small because it borrows the hard part: the difference between
two configurations is worked out by `frr-reload.py`, the tool FRR ships for exactly that.

The getters read FRR's own JSON. A replace sends the lines `frr-reload.py` says to remove and to
add. A commit keeps the configuration it replaced, which is what `rollback()` puts back. Save it as
`~/netlab/napalm_frr.py`:

```python
"""napalm_frr: a NAPALM driver for FRR, written for the lab.

NAPALM ships drivers for EOS, IOS, IOS-XR, Junos and NX-OS, and none for FRR.
NAPALM finds a driver it does not ship by importing a package called
napalm_<name>, which is how community drivers work, so this is one:
get_network_driver("frr") imports it.

How it does what it does, so nothing about it is magic:
  - it logs in with Netmiko, as the cisco_ios device type (FRR's CLI is
    modelled on Cisco's, and that driver's prompts and paging match it);
  - the getters read FRR's own JSON (`show interface json`, `show version`);
  - a replace is worked out by FRR's frr-reload.py, the tool FRR ships for
    exactly that: it compares two configurations context by context and says
    which lines to remove and which to add. This driver sends those lines.
  - a commit saves the configuration it replaced, which is what rollback()
    puts back.
"""
import importlib.util
import os
import tempfile
import warnings

from napalm.base import NetworkDriver
from napalm.base.exceptions import (ConnectionClosedException, MergeConfigException,
                                    ReplaceConfigException)
from netmiko import ConnectHandler

with warnings.catch_warnings():
    warnings.simplefilter("ignore")
    _spec = importlib.util.spec_from_file_location("frr_reload", "/usr/lib/frr/frr-reload.py")
    frr_reload = importlib.util.module_from_spec(_spec)
    _spec.loader.exec_module(frr_reload)


def _clean(text):
    """Drop the lines vtysh prints around a configuration that are not configuration."""
    skip = ("Building configuration", "Current configuration")
    return "\n".join(l for l in text.splitlines() if not l.startswith(skip)) + "\n"


class FRRDriver(NetworkDriver):
    def __init__(self, hostname, username, password, timeout=60, optional_args=None):
        self.hostname, self.username, self.password, self.timeout = hostname, username, password, timeout
        self.optional_args = optional_args or {}
        self.device = None
        self.candidate = None     # the text loaded, or None
        self.merge = None
        self.rollback_config = None

    # ------------------------------------------------------------- the session
    def open(self):
        args = {"device_type": "cisco_ios", "host": self.hostname, "username": self.username,
                "timeout": self.timeout}
        if self.password:
            args["password"] = self.password
        else:
            args.update(use_keys=True, key_file=self.optional_args.get("key_file"))
        self.device = ConnectHandler(**args)

    def close(self):
        if self.device:
            self.device.disconnect()
            self.device = None

    def is_alive(self):
        return {"is_alive": bool(self.device and self.device.is_alive())}

    def _show(self, command):
        if not self.device:
            raise ConnectionClosedException("open() first")
        return self.device.send_command(command)

    # ---------------------------------------------------------------- getters
    def get_facts(self):
        import json
        first = self._show("show version").splitlines()[0]          # FRRouting 8.4.4 (edge1) on Linux(...)
        name = first.split("(")[1].split(")")[0]
        interfaces = json.loads(self._show("show interface json"))
        return {"hostname": name, "fqdn": f"{name}.example.net", "vendor": "FRRouting",
                "model": "FRR", "os_version": first.split(" (")[0].split()[-1],
                "serial_number": "", "uptime": -1.0,   # FRR does not report the router's uptime
                "interface_list": sorted(interfaces)}

    def get_interfaces(self):
        import json
        out = {}
        for name, i in json.loads(self._show("show interface json")).items():
            out[name] = {"is_up": i.get("operationalStatus") == "up",
                         "is_enabled": i.get("administrativeStatus") == "up",
                         "description": i.get("description", ""),
                         "last_flapped": -1.0, "speed": float(i.get("speed", 0)),
                         "mtu": i.get("mtu", 0), "mac_address": i.get("hardwareAddress", "")}
        return out

    def get_interfaces_ip(self):
        import json
        out = {}
        for name, i in json.loads(self._show("show interface json")).items():
            for a in i.get("ipAddresses", []):
                ip, plen = a["address"].split("/")
                out.setdefault(name, {"ipv4": {}})["ipv4"][ip] = {"prefix_length": int(plen)}
        return out

    def get_config(self, retrieve="all", full=False, sanitized=False, format="text"):
        running = _clean(self._show("show running-config")) if retrieve in ("all", "running") else ""
        return {"running": running, "startup": "", "candidate": self.candidate or ""}

    # ----------------------------------------------------------- configuration
    def _load(self, filename, config, merge):
        if filename:
            with open(filename) as f:
                config = f.read()
        self.candidate, self.merge = config, merge

    def load_merge_candidate(self, filename=None, config=None):
        self._load(filename, config, True)

    def load_replace_candidate(self, filename=None, config=None):
        self._load(filename, config, False)

    def discard_config(self):
        self.candidate = self.merge = None

    def _changes(self):
        """(lines to delete, lines to add), each a list of commands with their context."""
        if self.candidate is None:
            return [], []
        if self.merge:
            lines = [l for l in self.candidate.splitlines() if l.strip() and l.strip() != "!"]
            return [], [lines]
        vtysh = frr_reload.Vtysh(bindir="/usr/bin")
        with tempfile.TemporaryDirectory() as d:
            files = {}
            for kind, text in (("running", self.get_config("running")["running"]), ("new", self.candidate)):
                files[kind] = os.path.join(d, kind + ".conf")
                with open(files[kind], "w") as f:
                    f.write(_clean(text))
            configs = {}
            for kind, path in files.items():
                c = frr_reload.Config(vtysh)
                c.load_from_file(path)
                configs[kind] = c
        add, delete = frr_reload.compare_context_objects(configs["new"], configs["running"])
        todel = [frr_reload.lines_to_config(k, l, True) for k, l in delete if l != "!"]
        toadd = [frr_reload.lines_to_config(k, l, False) for k, l in add if l != "!"]
        return todel, toadd

    def compare_config(self):
        """The change as a diff: context lines as they are, then - or + and the line."""
        out = []
        for sign, groups in zip("-+", self._changes()):
            for cmd in groups:
                last = cmd[-1]
                if sign == "-":   # show the line that goes, not the command that removes it
                    indent = last[:len(last) - len(last.lstrip())]
                    last = indent + last.lstrip()[3:]
                out += cmd[:-1] + [sign + last]
        return "\n".join(out)

    def _send(self, commands):
        """Send configuration commands; return the lines the router answered with %."""
        output = self.device.send_config_set(commands)
        return [l.strip() for l in output.splitlines() if l.lstrip().startswith("%")]

    def commit_config(self, message="", revert_in=None):
        if self.candidate is None:
            return
        todel, toadd = self._changes()
        before = self.get_config("running")["running"]
        errors = []
        if self.merge:
            errors += self._send(toadd[0])
        else:
            # A "no" form FRR refuses is retried shorter, a word at a time, as
            # frr-reload.py does: `no description branch LAN` is `no description`.
            for cmd in todel:
                while self._send(cmd + ["exit"] * (len(cmd) - 1)):
                    words = cmd[-1].split()
                    if len(words) <= 2:
                        errors.append("could not remove: " + " / ".join(c.strip() for c in cmd))
                        break
                    indent = cmd[-1][:len(cmd[-1]) - len(cmd[-1].lstrip())]
                    cmd = cmd[:-1] + [indent + " ".join(words[:-1])]
            for cmd in toadd:
                errors += self._send(cmd + ["exit"] * (len(cmd) - 1))
        if errors:
            exc = MergeConfigException if self.merge else ReplaceConfigException
            raise exc("the router refused: " + "; ".join(errors))
        self.device.save_config()
        self.rollback_config = before
        self.discard_config()

    def rollback(self):
        if self.rollback_config is None:
            return
        self.load_replace_candidate(config=self.rollback_config)
        self.commit_config()
```

`netlab.sh` installs it into the virtual environment as the package `napalm_frr`, on the next
build:

```sh
sudo ~/netlab/netlab.sh reset
```

A driver for a platform NAPALM does support is the same shape, only somebody else maintains it.
Reading this one is the quickest way to see what `load_replace_candidate`, `compare_config` and
`commit_config` cost a driver to provide, which is what the next section uses.
