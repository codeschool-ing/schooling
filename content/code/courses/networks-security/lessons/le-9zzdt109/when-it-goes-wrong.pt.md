---
title: Quando o bloqueador erra, ou para
version: 1
---

Bloquear só é tão bom quanto a regra, e a regra foi escrita às pressas. A loja publica uma página de
ajuda chamada `admin-guide.html`, para os clientes. No laboratório é uma linha no `app`, escrita lá
como root com `printf "how to use the admin console\n" > /srv/app/admin-guide.html`:

```
ana@remote:~$ curl -s -m3 http://www.example.com/admin-guide.html; echo "exit $?"
exit 28
root@ips:~# jq -c "select(.event_type==\"alert\") | [.alert.action, .alert.signature_id, .src_ip, .http.url]" /var/log/suricata/eve.json | tail -1
["blocked",1000101,"203.0.113.50","/admin-guide.html"]
```

**Bloqueado**: `/admin-guide.html` começa com `/admin`, e foi só isso que a regra perguntou. No sensor
isso teria sido mais um alerta para descartar; em linha, todo cliente que clica no link de ajuda
espera três segundos e não recebe nada. A correção é uma regra mais estreita, `/admin/` com a barra. A
lição é a geral: **uma regra só entra em linha depois de ter sido observada contra o tráfego real**,
por tempo suficiente para saber o que mais ela casa.

## Falhar fechado, ou falhar aberto

Quando o programa no `ips` para, a pergunta é o que acontece com o cabo:

```
root@ips:~# kill -INT $(cat /var/log/suricata/suricata.pid); sleep 2; pgrep -c suricata
0
ana@remote:~$ curl -s -m3 http://www.example.com/; echo "exit $?"
exit 28
```

O Suricata sumiu, e a loja está inalcançável de novo. Este elemento em linha **falha fechado**
(*fails closed*): nada passa sem ter sido inspecionado. Se isso é o certo depende do que o enlace
carrega:

| | falha fechado | falha aberto |
|---|---|---|
| quando o IPS para | o enlace para | o tráfego flui sem inspeção |
| o risco | uma queda causada pelo próprio dispositivo de segurança | uma janela sem inspeção, talvez despercebida |
| serve para | enlaces em que tráfego sem inspeção é pior do que nenhum: um segmento de pagamentos | enlaces em que a disponibilidade vem primeiro: a porta de entrada da loja |

Appliances comerciais de IPS e taps de rede costumam incluir um **bypass** que une fisicamente as duas
portas quando o dispositivo perde energia ou o software para, de modo que um IPS com defeito vira um
cabo em vez de uma parede. Seja qual for o projeto, é uma decisão a tomar e registrar com antecedência,
e a testar, exatamente como esta seção fez: parar o serviço de propósito e ver o que o enlace faz.
