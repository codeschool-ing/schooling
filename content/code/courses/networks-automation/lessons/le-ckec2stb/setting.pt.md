---
title: Mudando um valor com Set
version: 1
---

O `Set` muda a configuração, e escreve em `config`, nunca em `state`. **Um `Set` pode levar várias
mudanças, e o equipamento aplica todas ou nenhuma**, a mesma promessa de um commit do NETCONF sem o
candidate para prepará-lo. O `gnmic set` com um update:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/description" --update-value "branch 1 LAN"
{
  "source": "edge1.example.net:9339",
  "timestamp": 1790681213416429796,
  "time": "2026-09-29T08:26:53.416429796-03:00",
  "results": [
    {
      "operation": "UPDATE",
      "path": "interfaces/interface[name=eth2]/config/description"
    }
  ]
}
ana@ctl:~$ ssh netops@edge1 "show running-config" | grep -A1 "interface eth2"
interface eth2
 description branch 1 LAN
```

A configuração do próprio roteador, lida pelo CLI dele, tem a linha que o FRR teria escrito se uma
pessoa a tivesse digitado. Isso acontece porque o target transformou o `Set` no mesmo comando
`vtysh`, e é também o que faz as duas formas de mudar o roteador concordarem.

Cada mudança num `Set` é de um de três tipos. **`update` mescla** o valor ao que já existe,
**`replace` deixa a subárvore exatamente** como o que foi enviado, e **`delete` a remove**. São os
nomes do gNMI para o que o NETCONF chamava de merge, replace e delete na aula 3.

Um equipamento recusa o que não suporta. O target do laboratório aceita `description` e `enabled`
sob `config` e nada mais, e diz isso:

```
ana@ctl:~$ gnmic -a edge1.example.net:9339 set --update-path "/interfaces/interface[name=eth2]/config/mtu" --update-value 9000
target "edge1.example.net:9339" set request failed: target "edge1.example.net:9339" SetRequest failed: rpc error: code = InvalidArgument desc = mtu cannot be set here
Error: one or more requests failed
```

`InvalidArgument`, com uma frase. Equipamentos reais suportam muito mais do modelo, e recusam o
resto do mesmo jeito. **O `Set` do gNMI é menos usado que o NETCONF para configuração** na prática:
ele não tem candidate, nem validate, nem confirmed commit, então as mudanças que precisam disso
ficam no NETCONF, e o gNMI é usado para aquilo para que foi construído, que é observar.
