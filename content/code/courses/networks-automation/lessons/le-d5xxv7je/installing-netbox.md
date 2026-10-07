---
title: Installing NetBox
version: 1
---

NetBox is a Django application, and it is not in Ubuntu's archive. It is installed the way its own
documentation installs it: the code from its repository at a release tag, and its Python
libraries in a virtual environment of its own, beside it. It needs PostgreSQL and Redis, which
lesson 1's `apt-get` already brought. Two more packages, to build the PostgreSQL driver:

```sh
sudo apt-get install -y libpq-dev python3.12-dev
```

Then NetBox v4.6.10, into `/opt/netbox`:

```sh
sudo git clone --depth 1 --branch v4.6.10 https://github.com/netbox-community/netbox.git /opt/netbox
sudo python3 -m venv /opt/netbox/venv
sudo /opt/netbox/venv/bin/pip install -r /opt/netbox/requirements.txt
```

`requirements.txt` pins every library NetBox uses to the version that release was tested with,
and the install takes a few minutes. `netlab.sh` does the rest, in `build_netbox`: it writes
NetBox's `configuration.py`, starts PostgreSQL and Redis inside the `netbox` machine, creates
the database and runs NetBox's migrations on the first build, and starts the web server on
`https://netbox.example.net`.

**An empty NetBox would teach nothing**, so the first build also fills it with what the lab is:
three sites, the three routers and `nc1` with their interfaces and addresses, the prefixes they
come from and the two cables between the routers. That is a script run once through NetBox's own
shell, and it creates an account for `ana` with an API token, which `netlab.sh` writes to
`~/.netbox-token` in her home. Save it as `~/netlab/netbox_seed.py`:

```python
# What NetBox holds when the lab is built: the three routers and nc1, where
# they are, their interfaces and addresses, and how they are cabled. Run once,
# through `manage.py shell`, on the first build.
import os
from dcim.models import (Cable, Device, DeviceRole, DeviceType, Interface,
                         InterfaceTemplate, Manufacturer, Platform, Site)
from ipam.models import IPAddress, Prefix
from users.models import Token, User

admin = User.objects.create_superuser("admin", "admin@example.net", os.environ["ADMIN_PASSWORD"])
ana = User.objects.create_user("ana", "ana@example.net", os.environ["ADMIN_PASSWORD"])
ana.is_superuser = True
ana.save()
Token.objects.create(user=ana, version=2, pepper_id=1, key=os.environ["TOKEN_KEY"],
                     token=os.environ["TOKEN"], write_enabled=True,
                     description="ana's automation on ctl")

sites = {}
for name, slug in (("Core", "core"), ("Branch 1", "branch-1"), ("Branch 2", "branch-2")):
    sites[slug] = Site.objects.create(name=name, slug=slug, status="active",
                                      time_zone="America/Sao_Paulo")

lab = Manufacturer.objects.create(name="Lab", slug="lab")
router_t = DeviceType.objects.create(manufacturer=lab, model="FRR router", slug="frr-router")
switch_t = DeviceType.objects.create(manufacturer=lab, model="Clixon switch", slug="clixon-switch")
for t in (router_t, switch_t):
    InterfaceTemplate.objects.create(device_type=t, name="eth0", type="1000base-t", mgmt_only=True)
    InterfaceTemplate.objects.create(device_type=t, name="eth1", type="1000base-t")
    InterfaceTemplate.objects.create(device_type=t, name="eth2", type="1000base-t")
InterfaceTemplate.objects.create(device_type=router_t, name="lo", type="virtual")

router = DeviceRole.objects.create(name="Router", slug="router", color="2f6f4e")
switch = DeviceRole.objects.create(name="Switch", slug="switch", color="3f51b5")
frr = Platform.objects.create(name="FRR", slug="frr")
clixon = Platform.objects.create(name="Clixon", slug="clixon")

devices = {}
for name, site, dtype, role, platform in (
        ("core1", "core", router_t, router, frr),
        ("edge1", "branch-1", router_t, router, frr),
        ("edge2", "branch-2", router_t, router, frr),
        ("nc1", "core", switch_t, switch, clixon)):
    devices[name] = Device.objects.create(name=name, site=sites[site], device_type=dtype,
                                          role=role, platform=platform, status="active")


def iface(dev, name):
    return Interface.objects.get(device=devices[dev], name=name)


ADDRESSES = [
    ("core1", "eth0", "192.0.2.11/24", ""), ("edge1", "eth0", "192.0.2.12/24", ""),
    ("edge2", "eth0", "192.0.2.13/24", ""), ("nc1", "eth0", "192.0.2.21/24", ""),
    ("core1", "eth1", "198.51.100.1/30", "link to edge1"),
    ("core1", "eth2", "198.51.100.5/30", "link to edge2"),
    ("edge1", "eth1", "198.51.100.2/30", "uplink to core1"),
    ("edge2", "eth1", "198.51.100.6/30", "uplink to core1"),
    ("edge1", "eth2", "203.0.113.1/26", "branch LAN"),
    ("edge2", "eth2", "203.0.113.65/26", "branch LAN"),
    ("core1", "lo", "203.0.113.251/32", ""), ("edge1", "lo", "203.0.113.252/32", ""),
    ("edge2", "lo", "203.0.113.253/32", ""),
]
for dev, name, address, description in ADDRESSES:
    i = iface(dev, name)
    if description:
        i.description = description
        i.save()
    ip = IPAddress.objects.create(address=address, status="active", assigned_object=i,
                                  dns_name=f"{dev}.example.net" if name == "eth0" else "")
    if name == "eth0":
        devices[dev].primary_ip4 = ip
        devices[dev].save()

for prefix, description in (("192.0.2.0/24", "management"), ("198.51.100.0/30", "core1-edge1"),
                            ("198.51.100.4/30", "core1-edge2"), ("203.0.113.0/26", "branch 1 LAN"),
                            ("203.0.113.64/26", "branch 2 LAN")):
    Prefix.objects.create(prefix=prefix, status="active", description=description)

for a, b in ((("core1", "eth1"), ("edge1", "eth1")), (("core1", "eth2"), ("edge2", "eth1"))):
    Cable.objects.create(a_terminations=[iface(*a)], b_terminations=[iface(*b)], status="connected")

print("seeded", Device.objects.count(), "devices,", Interface.objects.count(), "interfaces,",
      IPAddress.objects.count(), "addresses")
```

Rebuild the lab:

```sh
sudo ~/netlab/netlab.sh reset
```

**The first build after installing NetBox takes minutes, not seconds**, because an empty database is
built by running every one of NetBox's migrations. `netlab.sh` keeps a copy of the migrated and seeded
database in `/var/cache/netlab` and unpacks it on every build after that. The objects and their
ids come out the same as in the transcripts; their creation times are your first build's. The
web interface is on `https://netbox.example.net` from inside the lab, and this lesson does not
need it: everything below goes through the API.
