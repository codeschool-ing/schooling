---
title: Escrever requisitos para que possam ser conferidos
version: 1
---

**Um requisito que ninguém escreveu é renegociado toda vez que alguém se lembra dele de outro jeito.**
Escreva cada requisito significativo como um cenário com uma medida, mantenha todos numa página só,
dê o nome da pessoa e do objetivo por trás de cada linha e leia a página de volta para quem pediu. A
página é curta, e é para ela que aponta cada decisão posterior sobre a funcionalidade.

A falha comum não é nada ser escrito. É que o que se escreve é o próprio pedido, com adjetivos e tudo —
"o fluxo de reserva deve ser rápido e altamente disponível" — num documento que parece pronto e não pode
ser conferido. Seis meses depois o fluxo leva 40 minutos para confirmar um caminhão, e todos os
envolvidos conseguem argumentar que isso é rápido.

## Um atributo de qualidade como cenário

A aula 6 deu aos atributos de qualidade uma forma em seis partes: fonte, estímulo, ambiente, artefato,
resposta e medida da resposta. Lá ela foi usada para comparar desenhos. Aqui ela faz outro trabalho:
**transforma o que Helena disse numa frase à qual um teste, um painel ou um revisor pode cobrar o
desenho.**

O "rápido" de Helena, depois das perguntas da seção anterior:

| parte | o cenário da confirmação |
|---|---|
| fonte | um embarcador |
| estímulo | pede um caminhão para uma carga completa num corredor principal |
| ambiente | horário comercial, num dia útil comum |
| artefato | o fluxo de reserva: app do embarcador, Matching e app do motorista |
| resposta | um motorista se compromete com a carga e o embarcador é avisado de que vem um caminhão |
| medida da resposta | em até 15 minutos em 90% dos pedidos e em até 60 minutos em 99%, medido a cada mês |

Cada parte justifica o lugar. **O ambiente impede que o número seja lido como promessa para todas as
horas do ano**: uma carga fracionada num sábado à noite fica de fora de propósito. O artefato diz o que
está sendo medido, que aqui atravessa três times, e isso sozinho já diz que o cenário precisa de um
arquiteto. A resposta diz "se compromete", não "chega", porque foi isso que a despachante do event
storming disse que esperava. E a medida tem dois limites, porque uma meta de 90% não diz nada sobre o
décimo embarcador, e o décimo é o que liga para a concorrência.

A tabela é a forma longa. Com as partes claras, a maioria dos cenários cabe numa frase, e é a frase que
vai para a página:

> Quando o servidor de banco de dados por trás do fluxo de reserva falha em horário comercial, o fluxo
> volta a atender embarcadores em até 10 minutos e nenhuma reserva confirmada se perde; o tempo fora do
> ar em horário comercial soma no máximo 109 minutos por mês.

> Quando um motorista sem sinal registra um comprovante de entrega, o app do motorista o guarda no
> celular e ele chega a Tracking em até 5 minutos depois que o celular recupera a conexão, sem perder
> nada.

Repare no que o segundo não diz. Não menciona um banco local no celular, um protocolo de sincronização
ou uma fila. **Um requisito diz o que precisa ser verdade, não como torná-lo verdade.** O como é o
desenho, e deixá-lo fora do requisito deixa o time de Diego livre para achar um melhor.

## Requisitos que puxam em sentidos opostos

Escritos, dois requisitos podem ser vistos colidindo, o que é muito mais barato no papel do que em
produção. Ofertar uma carga a vários motoristas ao mesmo tempo é o jeito óbvio de atingir os 15
minutos. Mas Diego sabia de uma coisa que o lado dos embarcadores não sabia: **um motorista que toca em
"aceitar" e ouve que a carga já foi se sente enganado**, e motoristas enganados vezes demais param de
abrir ofertas.

Então o lado do motorista ganhou um requisito próprio: um motorista que toca em "aceitar" fica sabendo
em até 2 segundos se a carga é dele, e a parcela de aceites que terminam em "já foi" fica abaixo de um
em cinco. Agora os dois podem ser negociados abertamente. Ofertar cada carga a vinte motoristas de uma
vez confirmaria caminhões mais depressa e perderia mais aceites; ofertar a um é a situação de hoje, os
47 minutos. O desenho que Kátia propôs oferta a três por vez, os mais próximos primeiro.

A troca é uma decisão de negócio, e **foi para Helena, com os dois números na mesma página.** O papel
do arquiteto foi tornar o conflito visível e dizer quanto custa cada escolha, a mesma divisão de
trabalho que a aula 13 põe no centro da conversa inteira sobre qualidade, prazo e custo.

## A página única

Tudo o que é significativo no pedido cabe numa página, e Renata a manteve numa. Esta é a parte que
guarda os requisitos:

| id | requisito | pedido por | por quê | medida |
|---|---|---|---|---|
| R1 | um motorista se compromete com uma carga completa num corredor principal logo após o pedido | Helena | conversão de 30% para 40% das cotações | 90% em até 15 min, 99% em até 60 min, horário comercial |
| R2 | um motorista que aceita fica sabendo se a carga é dele | Diego | motoristas continuam abrindo ofertas | resposta em até 2 s; menos de 1 em 5 ouve "já foi" |
| R3 | o fluxo de reserva sobrevive à perda do servidor de banco de dados | Helena | reservas se perdem quando ele cai | de volta em até 10 min, nada confirmado perdido, no máximo 109 min fora do ar por mês em horário comercial |
| R4 | um comprovante de entrega é registrado sem sinal | Diego, Bruno | motoristas recebem pelo comprovante | chega a Tracking em até 5 min depois de reconectar, nada perdido |

Abaixo, as restrições, que não estão em discussão neste projeto e ficam escritas para que ninguém as
redescubra no meio do caminho:

- uma cotação nunca fica abaixo do piso mínimo do frete da ANTT para sua rota e seu veículo;
- um caminhão não sai antes de a SEFAZ autorizar o CT-e;
- no ar antes do pico da safra, em 2 de fevereiro;
- construído pelo time de Matching como ele é, seis engenheiros, com ajuda do time do app do motorista.

Algumas regras fizeram a página funcionar:

- **Cada linha tem o nome de uma pessoa e um objetivo.** Quando alguém quiser afrouxar R2 para acelerar
  R1, a página diz a quem perguntar e o que essa pessoa vai perder.
- **Números, não adjetivos.** "Rápido" e "altamente disponível" não aparecem nela.
- **Nenhuma solução.** "Uma tela só" foi a primeira frase de Helena, e não está na página. Virou uma das
  opções de desenho para mostrar ao embarcador o que está acontecendo enquanto um motorista decide, que
  é o lugar dela.
- **Uma data e uma versão no topo**, porque a página vai mudar e quem lê precisa saber qual está
  segurando.

Os requisitos também têm ids, e os ids são para depois. Um registro de decisão de arquitetura, que a
aula 5 apresentou, os cita no contexto: "para atender R1 e R2, Matching oferta cada carga a três
motoristas por vez". Assim quem ler a decisão daqui a dois anos encontra o requisito que a causou, e
quem mudar o requisito encontra as decisões que se apoiam nele.

## Ler de volta

Renata mandou a página para Helena e marcou trinta minutos para lerem juntas, linha a linha. **Ler de
volta é onde os mal-entendidos saem mais baratos**, e esta leitura achou um. O primeiro rascunho de R1
listava os doze corredores que levam a maior parte das cargas hoje. Helena lembrou que a lista muda com
a estação: em fevereiro as rotas de grãos do norte do Paraná passam metade deles. R1 agora diz "os
corredores que juntos levam 80% das cargas do mês", que é como Helena pensa no assunto e continua
verdade quando a lista muda.

O objetivo da reunião não é uma assinatura. **São duas pessoas concordando com os mesmos números**, para
que, quando um desenho for apresentado, a conversa seja sobre se ele atende R1, e não sobre o que R1
queria dizer.

## Depois que entra no ar

Um requisito com medida pode ser medido, e deve ser. R1 agora é um gráfico: a parcela de pedidos
confirmados em até 15 e em até 60 minutos, por semana, nos corredores principais. A instrumentação é do
tipo que a aula 7 de `scale` ensinou. **Um requisito que ninguém mede depois do lançamento é um
desejo**, e na primeira vez que ele escorregar ninguém vai saber até um embarcador reclamar.

A página em si é um documento vivo do tipo de que trata a aula 8: tem dono, data e motivo para ser
atualizada quando algo muda. A aula 6 de `architecture-modeling` vai mais fundo nos atributos de
qualidade e em como documentos de requisitos mais completos se organizam. Para um arquiteto, uma página
de números que o negócio reconhece como seus vale mais do que cinquenta que ele não lê.
