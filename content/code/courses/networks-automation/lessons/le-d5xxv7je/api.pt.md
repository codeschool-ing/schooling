---
title: A API REST
version: 1
---

Todo objeto da interface web do NetBox também é uma URL sob `/api/`. Os roteadores são devices,
filtrados por papel:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/dcim/devices/?role=router&brief=1" | jq
{
  "count": 3,
  "next": null,
  "previous": null,
  "results": [
    {
      "id": 1,
      "url": "https://netbox/api/dcim/devices/1/",
      "display": "core1",
      "name": "core1",
      "description": ""
    },
    {
      "id": 2,
      "url": "https://netbox/api/dcim/devices/2/",
      "display": "edge1",
      "name": "edge1",
      "description": ""
    },
    {
      "id": 3,
      "url": "https://netbox/api/dcim/devices/3/",
      "display": "edge2",
      "name": "edge2",
      "description": ""
    }
  ]
}
```

A forma é a mesma em todo endpoint de lista: **`count`, `next`, `previous` e `results`**, que é a
paginação por offset da aula 2. `next` é null porque três dispositivos cabem numa página; com três
mil, `next` seria a URL da página seguinte. `?brief=1` pede a forma curta de cada objeto, seu id,
nome e URL, em vez de todos os campos.

O token vai no header `Authorization`, como o da aula 2, e `--cacert` indica a autoridade
certificadora do laboratório, porque o NetBox é acessado por HTTPS e o certificado dele é
verificado. O token pertence à usuária `ana` e pode escrever; um token só de leitura bastaria para
tudo nesta seção e na próxima, e é isso que um script que só lê deve receber.

Filtros são parâmetros da query, e a maioria deles segue os relacionamentos. Os endereços que
pertencem ao edge1 são os endereços atribuídos a uma interface do dispositivo chamado `edge1`:

```
ana@ctl:~$ curl -s --cacert lab-ca.pem -H "Authorization: Bearer $(cat ~/.netbox-token)" "https://netbox/api/ipam/ip-addresses/?device=edge1" | jq -r ".results[] | [.assigned_object.name, .address] | @tsv"
eth0	192.0.2.12/24
eth1	198.51.100.2/30
eth2	203.0.113.1/26
lo	203.0.113.252/32
```

O `jq` transformou o JSON em duas colunas. Tudo o que a aula 10 precisava para o edge1, as
interfaces e seus endereços, já está no NetBox; uma coisa não está, e a seção 06 descobre qual.
