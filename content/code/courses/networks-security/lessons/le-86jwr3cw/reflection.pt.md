---
title: Reflexão e amplificação, e como não fazer parte de uma
version: 1
---

Os maiores ataques volumétricos raramente vêm direto das máquinas do atacante. Eles são
**refletidos** (reflection): o atacante envia pequenas perguntas UDP a servidores espalhados pela
internet com o **endereço da vítima** forjado como origem, e cada servidor envia a resposta para a
vítima. Quando a resposta é muito maior do que a pergunta, o ataque é **amplificado** (amplification).

É a aritmética que o torna atraente. Um serviço cuja pergunta de 60 bytes produz uma resposta de
3.000 bytes tem um fator de amplificação de 50: um megabit por segundo de perguntas vira cinquenta de
respostas apontadas para outra pessoa. Protocolos com uma resposta grande para uma pergunta UDP
pequena já foram usados assim: DNS, NTP, memcached, SSDP entre eles.

Duas coisas decorrem disso para um defensor, e nenhuma é sobre receber o ataque:

- **Não rode um serviço que responde a estranhos com mais do que eles pediram.** Um servidor DNS
  aberto para a internet deve responder pelos próprios nomes e recusar todo o resto.
- **Não deixe sua rede enviar pacotes com o endereço de origem de outra pessoa**, que é o que são as
  perguntas forjadas. A aula 8 escreve esse filtro.

O servidor de nomes do laboratório na DMZ é alcançável pela internet, de propósito. Perguntado sobre o
próprio nome, e sobre um nome que não é da conta dele:

```
ana@remote:~$ dig @192.0.2.53 www.example.com +qr | grep -E "status|QUERY SIZE|MSG SIZE"
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14931
;; QUERY SIZE: 56
;; ->>HEADER<<- opcode: QUERY, status: NOERROR, id: 14931
;; MSG SIZE  rcvd: 60
ana@remote:~$ dig @192.0.2.53 example.org | grep -E "status|MSG SIZE"
;; ->>HEADER<<- opcode: QUERY, status: REFUSED, id: 5292
;; MSG SIZE  rcvd: 46
```

Para `www.example.com` ele responde, 60 bytes para uma pergunta de 56 bytes, um fator perto de 1.
Para `example.org` ele diz `REFUSED`, em 46 bytes: **ele não é um resolvedor aberto** (open
resolver), então ninguém pode usá-lo para apontar a uma vítima as respostas às próprias perguntas. A
opção por trás disso é `no-resolv` na configuração do `dnsmasq` dele: ele não encaminha nada e só
sabe o que lhe disseram.

Um resolvedor que *deve* responder a perguntas recursivas, o que a equipe usa, fica onde só a equipe
consegue alcançá-lo: a matriz da aula 4 põe a célula de DNS da internet apenas no servidor
autoritativo.
