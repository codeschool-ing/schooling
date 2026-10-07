---
title: NetBox a partir do Python
version: 2
---

Os scripts desta aula ficam em `~/sot` no `ctl`. Dois arquivos vêm sem mudança do `~/tpl` da aula
10, o template e o `push.py`, e são copiados logo no começo:

```
ana@ctl:~$ mkdir -p sot/inventory && cp -r tpl/templates tpl/push.py sot/
```

O `pynetbox` embrulha a API em objetos Python: um endpoint é um atributo, um filtro é um método, um
resultado é um objeto cujos campos são atributos. Todo script desta aula se conecta por um módulo
pequeno:

```schooling-example
{
  "language": "python",
  "file": "nb.py",
  "parts": [
    {
      "code": "import pynetbox\n\n\ndef connect():"
    },
    {
      "code": "    nb = pynetbox.api(\"https://netbox\", token=open(\"/home/ana/.netbox-token\").read().strip())\n    nb.http_session.verify = \"/home/ana/lab-ca.pem\"\n    return nb",
      "note": "**Um lugar que sabe chegar ao NetBox**: o endereço, o token vindo do arquivo dele e a autoridade certificadora do laboratório, para que todo script desta aula confira o servidor com que fala."
    }
  ]
}
```

Com ele, os roteadores e seus endereços:

```schooling-example
{
  "language": "python",
  "file": "show.py",
  "parts": [
    {
      "code": "from nb import connect\n\nnb = connect()"
    },
    {
      "code": "for device in nb.dcim.devices.filter(role=\"router\"):\n    print(f\"{device.name}  site={device.site.slug}  platform={device.platform.slug}  mgmt={device.primary_ip4}\")",
      "note": "**Filtros são os parâmetros de consulta da API.** `filter(role=\"router\")` é `?role=router` em `/api/dcim/devices/`, e o pynetbox segue as páginas por você."
    },
    {
      "code": "    for ip in nb.ipam.ip_addresses.filter(device_id=device.id):\n        print(f\"    {ip.assigned_object.name:5} {ip.address}\")",
      "note": "**Objetos apontam para objetos.** Um endereço é atribuído a uma interface, que pertence a um dispositivo; o filtro por `device_id` percorre esse vínculo pela outra ponta."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python show.py
core1  site=core  platform=frr  mgmt=192.0.2.11/24
    eth0  192.0.2.11/24
    eth1  198.51.100.1/30
    eth2  198.51.100.5/30
    lo    203.0.113.251/32
edge1  site=branch-1  platform=frr  mgmt=192.0.2.12/24
    eth0  192.0.2.12/24
    eth1  198.51.100.2/30
    eth2  203.0.113.1/26
    lo    203.0.113.252/32
edge2  site=branch-2  platform=frr  mgmt=192.0.2.13/24
    eth0  192.0.2.13/24
    eth1  198.51.100.6/30
    eth2  203.0.113.65/26
    lo    203.0.113.253/32
```

Duas coisas nessa saída são o modelo do NetBox em ação. `device.site.slug` seguiu um link do
dispositivo para o site dele sem outra linha de código; o pynetbox buscou o que era preciso. E
`primary_ip4` é a resposta do NetBox à pergunta "qual endereço eu uso para alcançar este dispositivo",
que é o endereço de gerência na `eth0`. A seção 07 usa exatamente isso para montar um inventário.

**Cada laço é uma requisição por dispositivo**, e vale a pena notar isso antes de serem três mil
devices. Os filtros do NetBox aceitam listas, `device_id=[1, 2, 3]`, então os endereços de todos
os roteadores podem voltar numa só requisição; para os três do laboratório, o laço simples é mais
claro.
