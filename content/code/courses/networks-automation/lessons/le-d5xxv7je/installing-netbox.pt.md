---
title: Instalando o NetBox
version: 1
---

O NetBox é uma aplicação Django, e não está no repositório do Ubuntu. Ele é instalado do jeito que
a documentação dele instala: o código do repositório numa tag de release, e as bibliotecas Python
num ambiente virtual próprio, ao lado. Ele precisa de PostgreSQL e Redis, que o `apt-get` da aula 1
já trouxe. Mais dois pacotes, para compilar o driver do PostgreSQL:

```sh
sudo apt-get install -y libpq-dev python3.12-dev
```

Depois o NetBox v4.6.10, em `/opt/netbox`:

```sh
sudo git clone --depth 1 --branch v4.6.10 https://github.com/netbox-community/netbox.git /opt/netbox
sudo python3 -m venv /opt/netbox/venv
sudo /opt/netbox/venv/bin/pip install -r /opt/netbox/requirements.txt
```

O `requirements.txt` fixa cada biblioteca que o NetBox usa na versão com que aquela release foi
testada, e a instalação leva alguns minutos. O `netlab.sh` faz o resto, no `build_netbox`: grava o
`configuration.py` do NetBox, liga o PostgreSQL e o Redis dentro da máquina `netbox`, cria o banco e
roda as migrações do NetBox na primeira construção, e liga o servidor web em
`https://netbox.example.net`.

**Um NetBox vazio não ensinaria nada**, então a primeira construção também o preenche com o que o
laboratório é: três sites, os três roteadores e o `nc1` com suas interfaces e endereços, os
prefixos de onde eles vêm e os dois cabos entre os roteadores. Isso é um script rodado uma vez pelo
shell do próprio NetBox, e ele cria uma conta para a `ana` com um token de API, que o `netlab.sh`
grava em `~/.netbox-token` na home dela. Salve-o como `~/netlab/netbox_seed.py`:

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

Reconstrua o laboratório:

```sh
sudo ~/netlab/netlab.sh reset
```

**A primeira construção depois de instalar o NetBox leva minutos, não segundos**, porque um banco vazio
é construído rodando cada uma das migrações do NetBox. O `netlab.sh` guarda uma cópia do banco migrado e
populado em `/var/cache/netlab` e a desempacota em toda construção depois dessa. Os objetos e seus
ids saem iguais aos das transcrições; as datas de criação são as da sua primeira construção. A
interface web fica em `https://netbox.example.net` de dentro do laboratório, e esta aula não precisa
dela: tudo abaixo passa pela API.
