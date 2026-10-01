---
title: O que o NetBox não tem
version: 1
---

O template da aula 10 precisa de quatro coisas para cada interface: o nome, a descrição, o
endereço e o papel no OSPF. O NetBox tem as três primeiras. Alimentada pelo NetBox, a
renderização para antes de começar:

```
ana@ctl:~$ cd sot && python render_nb.py 2>&1 | tail -1
KeyError: 'ospf'
```

**O NetBox modela a rede, não o design de uma rede**, então um fato como "este enlace roda OSPF
como point-to-point" não tem onde ficar até alguém acrescentá-lo. Um **custom field** resolve isso:
um campo definido uma vez, num tipo de objeto, que aparece em todo objeto desse tipo, tanto na
interface web quanto na API.

```schooling-example
{
  "language": "python",
  "file": "ospf_field.py",
  "parts": [
    {
      "code": "from nb import connect\n\nnb = connect()"
    },
    {
      "code": "choices = nb.extras.custom_field_choice_sets.create(\n    name=\"OSPF interface\", extra_choices=[[\"point-to-point\", \"point-to-point\"], [\"passive\", \"passive\"]])\nnb.extras.custom_fields.create(\n    name=\"ospf\", label=\"OSPF\", type=\"select\", object_types=[\"dcim.interface\"], choice_set=choices.id)\n\nOSPF = {(\"core1\", \"eth1\"): \"point-to-point\", (\"core1\", \"eth2\"): \"point-to-point\",\n        (\"edge1\", \"eth1\"): \"point-to-point\", (\"edge1\", \"eth2\"): \"passive\",\n        (\"edge2\", \"eth1\"): \"point-to-point\", (\"edge2\", \"eth2\"): \"passive\"}\nfor (device, name), role in OSPF.items():\n    interface = nb.dcim.interfaces.get(device=device, name=name)",
      "note": "**O NetBox não tem campo para o papel OSPF de uma interface, então um é acrescentado.** Um conjunto de escolhas lista os valores permitidos; o campo personalizado o põe em toda interface."
    },
    {
      "code": "    interface.custom_fields[\"ospf\"] = role\n    interface.save()\n    print(f\"{device} {name}: ospf={role}\")",
      "note": "**Uma escrita é uma mudança no objeto e um save.** O pynetbox manda só os campos que mudaram, como PATCH."
    }
  ]
}
```

```
ana@ctl:~$ cd sot && python ospf_field.py
core1 eth1: ospf=point-to-point
core1 eth2: ospf=point-to-point
edge1 eth1: ospf=point-to-point
edge1 eth2: ospf=passive
edge2 eth1: ospf=point-to-point
edge2 eth2: ospf=passive
```

Um conjunto de escolhas em vez de texto livre significa que o NetBox confere o valor na entrada. O
mesmo campo, escrito pela API com um valor que não está no conjunto:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/interfaces/?device=edge1&name=eth2" | jq ".results[0].id"
7
ana@ctl:~$ curl -s --cacert lab-ca.pem -X PATCH -H "Authorization: Bearer $(cat ~/.netbox-token)" -H "Content-Type: application/json" -d "{\"custom_fields\": {\"ospf\": \"p2p\"}}" https://netbox/api/dcim/interfaces/7/ | jq
{
  "__all__": [
    "Invalid value for custom field 'ospf': Invalid choice (p2p) for choice set OSPF interface."
  ]
}
```

**O valor errado foi recusado na origem**, com uma mensagem que nomeia o campo e o conjunto de
escolhas. No YAML da aula 10, `ospf: p2p` teria sido aceito por tudo até o template, onde
`{% if i.ospf == "point-to-point" %}` teria silenciosamente não escrito linha de OSPF nenhuma. Uma
fonte da verdade que valida é uma em que esse erro não pode ser cometido, em vez de uma em que ele
é encontrado depois.

Os seis valores escritos aqui são os mesmos do YAML da aula 10. Levar os dados para o NetBox deve
mudar onde eles moram e nada do que eles dizem, e a próxima seção confere exatamente isso.
