---
title: Um nome para o site
version: 1
---

**Um domínio próprio são duas coisas: um nome que você aluga de um registrador, e registros DNS que dizem
para onde esse nome aponta.** O host não precisa ser avisado de que o nome existe; ele precisa ser avisado
de que o nome é seu, e os registros do nome precisam apontar para o host. A aula 8 de web-fundamentals
desmontou o DNS; esta seção o usa.

Nada nesta seção foi executado para este curso: ela precisa de um domínio, que custa dinheiro todo ano e é
do estudante. Os registros são a parte que dura, e são os mesmos onde quer que você compre o nome.

## Dois registros

Um site em geral responde em dois nomes: o domínio puro, `example.com`, chamado de **apex**, e
`www.example.com`. Cada um ganha um registro, e os dois são de tipos diferentes:

| nome | registro | valor | quer dizer |
|---|---|---|---|
| `www.example.com` | `CNAME` | o nome que o host deu a você, como `planner.pages.dev` | "este nome é outro nome; pergunte àquele" |
| `example.com` | `A` (e `AAAA` para IPv6) | os endereços que a documentação do host lista | "este nome está nestes endereços" |

**O apex não pode ser um `CNAME`.** O padrão do DNS proíbe um `CNAME` ao lado de qualquer outro registro
do mesmo nome, e o apex sempre tem outros: os registros `SOA` e `NS` que fazem a zona existir, o `MX` que
recebe o e-mail dele. Então o `www` pode dizer "eu sou `planner.pages.dev`", e o apex precisa dizer um
endereço. Essa regra pega todo mundo na primeira vez, porque o painel deixa você digitar um `CNAME` para
`@`, o símbolo que muitos provedores de DNS usam para o apex, e então o recusa ou quebra o e-mail em
silêncio.

Os provedores contornam isso de três jeitos, e você vai encontrar cada nome:

- **registros `A` para os endereços fixos do host**, que é o que o GitHub Pages e a Vercel documentam
  para um apex. Funciona em qualquer lugar, e quebra se o host um dia mudar esses endereços.
- **`ALIAS` ou `ANAME`**, um registro que alguns provedores de DNS oferecem e que se comporta como um
  `CNAME` mas responde com endereços, então pode ficar no apex. Não faz parte do padrão; cada provedor
  implementa o seu.
- **CNAME flattening**, o nome que a Cloudflare dá à mesma ideia, aplicada automaticamente no apex quando
  a Cloudflare cuida do DNS do domínio.

## Quanto tempo uma mudança leva

Todo registro leva um **TTL**, tempo de vida, em segundos: quanto tempo um resolvedor pode guardar a
resposta antes de perguntar de novo. Um registro com TTL de 3600 pode ser servido do cache de alguém por
uma hora depois que você o muda. Baixe-o para poucos minutos um dia antes de uma mudança, faça a mudança,
e suba-o de novo quando o site estiver funcionando no endereço novo. "O DNS leva 48 horas para propagar" é
folclore: uma mudança leva o tempo que o TTL antigo diz, e as 48 horas vêm de TTLs que ninguém baixou.

## E o lado do host

Cada host tem uma tela onde você acrescenta o domínio ao projeto, e então diz quais registros criar, com
os valores dele. Faça o que essa tela diz, e não o que um tutorial do ano passado diz: os endereços de um
apex são exatamente o tipo de valor que muda. O GitHub Pages também quer o domínio num arquivo chamado
`CNAME` na raiz da pasta publicada, ou definido nas configurações de Pages do repositório, que grava esse
arquivo por você.
