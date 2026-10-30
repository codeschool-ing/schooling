---
title: Papéis, e contar às pessoas o que está acontecendo
version: 1
---

**Um incidente tem três trabalhos, e o perigo é uma pessoa fazer todos.** Investigar exige concentração; coordenar
exige alguém que não esteja concentrado numa coisa só; avisar os clientes exige alguém que não esteja tentando
consertar nada. Num time de duas pessoas, como a loja, uma pessoa pode ter dois papéis, mas os tem sabendo disso
e um de cada vez.

| papel | faz | não faz |
|---|---|---|
| comandante do incidente | decide, distribui, mantém a linha do tempo, decide o rollback | digita comandos |
| operações | investiga e muda o sistema | fala com clientes |
| comunicação | escreve as atualizações, num horário fixo | promete hora para a correção |

O hábito mais importante do comandante é uma pergunta feita a cada poucos minutos: "o que estamos tentando agora, e
quando decidimos que não funcionou?" Sem ela, uma investigação vaga por uma hora atrás de uma teoria que ninguém
escreveu.

## Atualizações, num horário fixo

Clientes e colegas precisam ouvir algo a cada trinta minutos durante um SEV1 ou SEV2, **mesmo quando não há nada
novo**, porque silêncio parece "ninguém está cuidando". Uma atualização tem quatro partes e nenhum adjetivo:

```localised
14:40 — Investigating. Some payments are failing and being retried; most orders
complete after one retry. We are looking at the connection to the payment
service. Next update at 15:10.
```

O que ela não contém: uma causa antes de confirmada, uma hora para a correção, ou culpa. "Um problema com o nosso
provedor de pagamento" escrito às 14:40 e errado às 15:00 é uma declaração pública sobre outra empresa que precisa
ser desmentida.

## Onde o incidente vive

Um canal por incidente, com o nome dele, aberto pelo comandante; um documento para a linha do tempo; e a página de
status para os clientes. **As decisões são escritas no canal, não tomadas numa chamada e esquecidas**, porque o
canal é de onde o postmortem é escrito, e uma decisão que ninguém escreveu é uma decisão que o postmortem não
consegue examinar.
