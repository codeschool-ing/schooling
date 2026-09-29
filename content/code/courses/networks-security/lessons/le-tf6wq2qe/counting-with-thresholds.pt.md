---
title: Contar em vez de casar uma vez
version: 1
---

Certo comportamento só é suspeito em quantidade. Um login é um cliente. Quinze em poucos segundos de um
endereço só é um script, e seja a integração bugada de alguém ou alguém tentando senhas, uma pessoa
precisa ficar sabendo. `remote` envia o formulário de login quinze vezes, sem senha nenhuma:

```
ana@remote:~$ for i in $(seq 15); do curl -s -o /dev/null -w "%{http_code} " -d "user=ana" http://www.example.com/login; done; echo
200 200 200 200 200 200 200 200 200 200 200 200 200 200 200 
```

Todo pedido foi respondido, porque o sensor fica ao lado do tráfego. O que ele registrou:

```
root@sensor:~# grep -c 1000201 /var/log/suricata/fast.log
5
root@sensor:~# jq -c "select(.event_type==\"alert\" and .alert.signature_id==1000201) | [.timestamp[11:19], .src_ip, .http.url]" /var/log/suricata/eve.json | head -2
["18:03:37","203.0.113.50","/login"]
["18:03:37","203.0.113.50","/login"]
```

**Cinco alertas para quinze pedidos.** Os dez primeiros casaram com a regra e ficaram em silêncio, porque
o `count 10` não tinha sido ultrapassado; os pedidos de onze a quinze produziram um alerta cada. Os dois
primeiros alertas têm o mesmo segundo, que é a cara de *um script* em um log.

O Suricata oferece três jeitos de fazer uma regra contar, e eles respondem a perguntas diferentes:

| palavra-chave | dispara | responde |
|---|---|---|
| `detection_filter` | a cada casamento **depois** que a contagem é ultrapassada | "me avise quando isto estiver claramente acontecendo, e continue avisando" |
| `threshold: type threshold` | uma vez a **cada** N casamentos | "um alerta a cada dez, para o volume aparecer sem me afogar" |
| `threshold: type limit` | no máximo N vezes por período | "me avise que começou; o resto eu dispenso" |

A contagem pertence à regra quando o padrão *é* a contagem, como aqui. Quando a regra está certa e o
problema é a frequência com que ela dispara, a contagem pertence ao arquivo de limiares do motor, assunto da
última seção desta aula.
