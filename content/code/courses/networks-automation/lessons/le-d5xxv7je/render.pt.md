---
title: Configurações renderizadas a partir do NetBox
version: 1
---

O template da aula 10 não muda. O que muda é de onde vem o dicionário dele:

```schooling-example
{
  "language": "python",
  "file": "render_nb.py",
  "parts": [
    {
      "code": "import ipaddress\nimport pathlib\n\nfrom jinja2 import Environment, FileSystemLoader, StrictUndefined\n\nfrom nb import connect\n\n\ndef network(address):\n    return str(ipaddress.ip_interface(address).network)\n\n\nenv = Environment(loader=FileSystemLoader(\"templates\"), trim_blocks=True, lstrip_blocks=True,\n                  keep_trailing_newline=True, undefined=StrictUndefined)\nenv.filters[\"network\"] = network\ntemplate = env.get_template(\"frr.j2\")\nnb = connect()\npathlib.Path(\"configs\").mkdir(exist_ok=True)\n\nfor device in nb.dcim.devices.filter(role=\"router\"):\n    addresses = {ip.assigned_object.name: ip.address for ip in nb.ipam.ip_addresses.filter(device_id=device.id)}"
    },
    {
      "code": "    data = {\n        \"hostname\": device.name,\n        \"loopback\": addresses[\"lo\"].split(\"/\")[0],\n        \"interfaces\": [\n            {\"name\": i.name, \"description\": i.description, \"address\": addresses[i.name],\n             \"ospf\": i.custom_fields[\"ospf\"]}\n            for i in nb.dcim.interfaces.filter(device_id=device.id, mgmt_only=False)\n            if i.name != \"lo\"\n        ],\n    }\n    text = template.render(data)\n    pathlib.Path(f\"configs/{device.name}.conf\").write_text(text)\n    print(f\"NetBox -> configs/{device.name}.conf, {len(text.splitlines())} lines\")",
      "note": "**O mesmo dicionário que a aula 10 lia do YAML**, montado a partir do NetBox: o nome, o loopback sem o `/32` e toda interface que não é de gerência, com descrição, endereço e papel OSPF."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python render_nb.py
NetBox -> configs/core1.conf, 34 lines
NetBox -> configs/edge1.conf, 34 lines
NetBox -> configs/edge2.conf, 34 lines
ana@ctl:~$ cd sot && for h in core1 edge1 edge2; do ssh netops@$h "show running-config" | tail -n +5 | diff -q - configs/$h.conf > /dev/null && echo "$h: same"; done
core1: same
edge1: same
edge2: same
```

**Três roteadores, configurações renderizadas a partir do NetBox, idênticas ao que está
rodando.** Essa é a conferência a fazer no dia em que a fonte da verdade muda, e é a mesma
comparação que a aula 10 fez com YAML. Qualquer coisa que o NetBox guardasse diferente dos
roteadores, um endereço digitado na interface errada ou uma descrição com um espaço no fim, teria
aparecido aqui como um roteador que não estava `same`, antes de qualquer push.

Dois filtros no script carregam decisões. `mgmt_only=False` deixa de fora a `eth0`, que o template
não configura; a rede de gerência é montada quando um roteador é instalado, não pelo template. E
`i.name != "lo"` deixa de fora a loopback, que o template escreve por conta própria a partir de
`loopback`. As duas regras ficam visíveis num só lugar, e esse é o motivo de escrevê-las no script
em vez de lembrar delas.

Os arquivos de dados da aula 10 agora podem ser apagados. Mantê-los seria manter duas fontes da
verdade, e a segunda é sempre a que está desatualizada.
