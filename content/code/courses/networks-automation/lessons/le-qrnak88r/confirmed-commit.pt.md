---
title: Um commit que se desfaz sozinho
version: 1
---

Algumas mudanças serram o galho em que você está sentado: um novo filtro na interface de gerência,
uma rota que desvia o tráfego de gerência, um endereço errado no uplink. A mudança entra em commit,
a sessão cai, e ninguém consegue alcançar o equipamento para desfazê-la. **Um confirmed commit é a
resposta**: ele aplica a mudança e dispara um relógio, e se nenhum segundo commit a confirmar antes
de o tempo acabar, o equipamento volta sozinho para a configuração que tinha antes.

A versão do laboratório de serrar o galho é desabilitar a `eth1`, a interface descrita como o
uplink, com um timeout de dez segundos, e depois não confirmar:

```schooling-example
{
  "language": "python",
  "file": "confirmed.py",
  "parts": [
    {
      "code": "import time\n\nfrom nc import connect, describe, interface_config\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><enabled>false</enabled></interface>\"))"
    },
    {
      "code": "    m.commit(confirmed=True, timeout=\"10\")\n    print(\"t=0 \", describe(m, \"running\", \"eth1\"))\n    time.sleep(5)\n    print(\"t=5 \", describe(m, \"running\", \"eth1\"))",
      "note": "**Um commit confirmado aplica a mudança e liga um relógio.** Se nada o confirmar em `timeout` segundos, o equipamento põe a configuração anterior de volta sozinho."
    },
    {
      "code": "    time.sleep(8)\n    print(\"t=13\", describe(m, \"running\", \"eth1\"))",
      "note": "**Ninguém confirma.** É o que acontece quando a mudança cortou o caminho até o equipamento: o script que deveria confirmar já não o alcança."
    },
    {
      "code": "    print(\"    \", describe(m, \"candidate\", \"eth1\"))\n    m.discard_changes()",
      "note": "**O running voltou; o candidate não.** Ele ainda guarda a mudança que foi desfeita, e o próximo `commit` simples de qualquer pessoa a aplicaria de novo. Descarte-a."
    }
  ]
}
```

```
ana@ctl:~$ python confirmed.py
t=0  running   eth1: description='uplink to core1' enabled=false
t=5  running   eth1: description='uplink to core1' enabled=false
t=13 running   eth1: description='uplink to core1' enabled=true
     candidate eth1: description='uplink to core1' enabled=false
```

`enabled=false` estava em vigor aos 0 e aos 5 segundos. **Aos 13 segundos estava `true` de novo**,
e ninguém tinha enviado nada: o `nc1` fez o rollback da mudança quando os dez segundos acabaram.
Num equipamento real é isso que manda um engenheiro de redes para casa: a mudança que deixou todo
mundo trancado do lado de fora dura dez segundos, ou dez minutos, e não até alguém dirigir até o
local.

A última linha é uma descoberta sobre este equipamento, e vale a pena verificá-la em todos os
outros: **o running voltou e o candidate não.** O `enabled=false` desfeito ainda estava no
candidate, esperando o próximo commit, fosse de quem fosse. O script o descarta antes de sair.

Quando a mudança é boa, a confirmação é simplesmente um segundo `commit` sem `confirmed`, depois
de qualquer verificação que decida que o equipamento continua saudável:

```schooling-example
{
  "language": "python",
  "file": "confirmed_ok.py",
  "parts": [
    {
      "code": "from nc import connect, describe, interface_config\n\nwith connect() as m:\n    m.edit_config(target=\"candidate\", config=interface_config(\n        \"<interface><name>eth1</name><description>uplink to core1, port 7</description></interface>\"))\n    m.commit(confirmed=True, timeout=\"60\")"
    },
    {
      "code": "    print(describe(m, \"running\", \"eth1\"))",
      "note": "**A verificação que decide se a mudança fica.** Aqui é só \"ainda consigo ler o equipamento\"; a aula 13 a transforma num teste de verdade."
    },
    {
      "code": "    m.commit()\n    print(\"confirmed\")",
      "note": "**Um `commit` simples a confirma**, e o relógio para."
    }
  ]
}
```

```
ana@ctl:~$ python confirmed_ok.py
running   eth1: description='uplink to core1, port 7' enabled=true
confirmed
```

**A verificação entre os dois commits é o projeto inteiro.** Aqui ela só lê o equipamento de
volta; se a mudança tivesse quebrado o caminho, essa leitura falharia, o script nunca chegaria ao
segundo `commit`, e o equipamento faria o rollback sozinho. A aula 13 troca a leitura por testes
de verdade.
