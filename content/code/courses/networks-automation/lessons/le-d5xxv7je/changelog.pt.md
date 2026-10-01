---
title: Uma mudança, do NetBox ao roteador
version: 1
---

Com os dados no NetBox, uma mudança começa lá. A descrição da LAN do edge2 muda pela API, as
configurações são renderizadas de novo, e o `push.py` da aula 10 as compara com os roteadores:

```python
from nb import connect

nb = connect()
interface = nb.dcim.interfaces.get(device="edge2", name="eth2")
interface.description = "branch 2 LAN, floor 1"
interface.save()
print(f"edge2 eth2: {interface.description}")
```

```
ana@ctl:~$ cd sot && python rename.py && python render_nb.py > /dev/null && python push.py
edge2 eth2: branch 2 LAN, floor 1
core1: matches
edge1: matches
edge2:
interface eth2
- description branch LAN
interface eth2
+ description branch 2 LAN, floor 1
```

**Só o edge2 tem algo a fazer**, e o diff é exatamente o campo que mudou no NetBox. Este é o fluxo
da aula 10 com o arquivo YAML substituído por um objeto no NetBox, e o resto da cadeia não
percebeu.

O que o NetBox acrescenta é um registro da mudança do lado dele. Toda escrita, pela interface web
ou pela API, fica guardada num change log com o usuário, a hora e o objeto antes e depois:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/core/object-changes/?changed_object_type=dcim.interface&ordering=-time&limit=1" | jq ".results[0] | {time, user_name, action, object_repr, before: .prechange_data.description, after: .postchange_data.description}"
{
  "time": "2026-10-01T19:22:18.964589-03:00",
  "user_name": "ana",
  "action": {
    "value": "update",
    "label": "Updated"
  },
  "object_repr": "eth2",
  "before": "branch LAN",
  "after": "branch 2 LAN, floor 1"
}
```

**O histórico do roteador da aula 11 diz quando a configuração mudou; o change log do NetBox diz
quem mudou a intenção, e a partir de quê.** Juntos, eles respondem à pergunta que a aula 11 não
conseguia: quem decidiu isso. O `user_name` é `ana` porque o token é dela, e esse é o argumento
para dar a cada pessoa e a cada pipeline seu próprio token em vez de compartilhar um.
