---
title: Review e retrospectiva
version: 1
---

O sprint termina com duas reuniões fáceis de confundir, porque as duas olham para trás. **A review olha o
produto; a retrospectiva olha a equipe.**

## A sprint review

Quem pediu o trabalho (o dono da padaria, o product owner, qualquer um que use o site) vê o que ficou pronto,
**funcionando, não em slides**. A Ana encomenda um pão para as 07:30 no celular e paga com Pix, na frente
deles.

O que faz valer uma hora é o retorno: *"A confirmação pode repetir o horário de retirada?"* Isso é um ticket
novo para o backlog, achado duas semanas depois de o trabalho começar, e não dois meses depois de ser
lançado. Uma review em que ninguém de fora da equipe aparece, ou em que ninguém pode mudar de ideia, é uma
demonstração, e perdeu o sentido.

Só se mostra trabalho que atende à definição de pronto. Mostrar a tela de pagamento com cartão pela metade
convida retorno sobre algo que não está pronto, e faz parecer quase terminado o que não está.

## A retrospectiva

Depois a equipe, sozinha, olha **como trabalhou**. O formato mais simples faz três perguntas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Um quadro de retrospectiva com três colunas. Foi bem: o horário de retirada saiu, e revisões em até um dia. Não foi bem: o 35 começou sem critérios, uma imagem esquecida achada na revisão, e dailies que chegaram a 30 minutos. Tentar no próximo sprint, duas ações, cada uma com responsável: nenhum ticket entra num sprint sem critérios de aceite, com a Carla; check-links.sh roda em todo pull request, com o Bruno.\"><defs><marker id=\"rt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">foi bem</text><rect x=\"30\" y=\"50\" width=\"200\" height=\"31\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">horário de retirada saiu</text><rect x=\"30\" y=\"91\" width=\"200\" height=\"31\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"107\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">revisões em até um dia</text><rect x=\"260\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"272\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">não foi bem</text><rect x=\"270\" y=\"50\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">#35 começou</text><text x=\"280\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sem critérios</text><rect x=\"270\" y=\"106\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">imagem esquecida</text><text x=\"280\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">achada na revisão</text><rect x=\"270\" y=\"162\" width=\"200\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"280\" y=\"178\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dailies chegaram</text><text x=\"280\" y=\"193\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a 30 minutos</text><rect x=\"500\" y=\"10\" width=\"220\" height=\"210\" rx=\"3\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"512\" y=\"32\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">tentar no próximo sprint</text><rect x=\"510\" y=\"50\" width=\"200\" height=\"61\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"66\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">nenhum ticket entra num</text><text x=\"520\" y=\"81\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">sprint sem critérios</text><text x=\"520\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">responsável: Carla</text><rect x=\"510\" y=\"121\" width=\"200\" height=\"61\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"520\" y=\"137\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">check-links.sh roda em</text><text x=\"520\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">todo pull request</text><text x=\"520\" y=\"167\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">responsável: Bruno</text></svg>", "caption": "Três problemas, duas ações, cada uma com um nome ao lado. A daily longa espera outra retro; tentar corrigir tudo de uma vez não corrige nada."}
```

Três regras a tornam útil em vez de uma sessão de reclamação:

- **Sem culpados.** A pergunta é o que no processo deixou o #35 começar sem critérios, não quem começou.
  Muitas retros abrem lendo uma frase: todo mundo fez o melhor que podia com o que sabia na hora. É o que
  deixa as pessoas dispostas a dizer o que de fato deu errado.
- **Poucas ações, cada uma com responsável.** Duas mudanças que acontecem valem mais que oito que não
  acontecem. A padaria escolhe duas: a Carla vai recusar na planning tickets sem critérios de aceite, e o
  Bruno vai pôr o `check-links.sh` na CI, que é o workflow da aula 17.
- **Comece pelas ações da última retro.** Aconteceram? Ajudaram? Uma retro que nunca confere as próprias
  ações ensina à equipe que nada dito nela importa.

## O custo das reuniões

Quatro pessoas numa reunião de uma hora são quatro horas de trabalho. Vale pagar quando a reunião evita
uma semana de trabalho errado, e não vale em outro caso. O teste para qualquer reunião recorrente é a
pergunta com que esta aula abriu: **o que daria errado sem ela?** Se ninguém souber responder, tente um
sprint sem ela, e traga de volta se algo der errado.
