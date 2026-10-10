---
title: Onde os papéis se sobrepõem
version: 1
---

**Os três papéis compartilham a maior parte das atividades, então os cargos sozinhos nunca resolvem
de quem é uma decisão.** Os três escrevem código (a aula 15 argumentou por que o arquiteto precisa
continuar escrevendo), os três revisam desenhos e os três tomam decisões técnicas toda semana. A
crença comum é que cargos bem definidos evitam conflito. Não evitam, porque um cargo diz quem a
pessoa é, e não quais decisões são dela. A Carreto passou pelos dois extremos disso: uma pessoa
ocupando todos os papéis, e duas pessoas cada uma certa de que a mesma decisão era sua.

## Uma pessoa, três papéis

No segundo ano da Carreto havia seis engenheiros, e Tomás Viana, que já liderava a engenharia,
ocupava os três papéis ao mesmo tempo. Escrevia cerca de um terço do código, decidia como o time o
construía e decidia como o monólito era dividido em módulos. Funcionava, e não por sorte: **quando
uma cabeça guarda todo o contexto, não existe uma fresta entre papéis por onde uma decisão possa
cair.** Ninguém precisava perguntar de quem era a decisão, porque todas eram dele e ele estava em
todas as conversas.

O arranjo falha aos poucos, e dá avisos antes de falhar. Três deles apareceram na Carreto quando a
empresa passou de dezoito engenheiros em três times:

- **As decisões esperavam por uma pessoa.** Um pull request que mexia em dois módulos ficava parado
  dois dias até Tomás conseguir olhar, e os times começaram a dividir as mudanças para não precisar
  dele.
- **Os times descobriam as decisões uns dos outros em produção.** Os times de Shipper e de Payments
  acrescentaram, cada um, um campo para o CNPJ do embarcador, com validações diferentes, e ninguém
  percebeu até uma fatura ser recusada.
- **A pessoa nos três papéis não fazia bem nenhum deles.** O código de Tomás era o mais revertido,
  porque ele o escrevia entre reuniões.

Nada disso prova que uma empresa pequena precisa de um arquiteto. Prova algo mais barato: **diga com
que chapéu a decisão está sendo tomada.** Num time de nove engenheiros com um tech lead, esse tech
lead toma também as decisões arquiteturais. A diferença está em se essas decisões recebem o
tratamento deste curso: um registro (aula 5), o conselho das pessoas afetadas (aula 3) e um cenário
com um número dentro (aula 6). A outra opção é tomá-las no mesmo fôlego em que se decide qual ticket
vem primeiro. O cargo pode esperar. Os hábitos, não.

## Duas pessoas, uma decisão

Com cinquenta engenheiros aparece o problema oposto: duas pessoas, cada uma certa no seu eixo.

Kátia Lemos, a tech lead do Matching, queria que o Matching lesse os preços direto das tabelas do
banco de dados do Pricing. Perguntar ao serviço de Pricing levava cerca de 400 ms por carga no pico,
ler as tabelas levava cerca de 40 ms, e oferecer uma carga aos motoristas dez vezes mais rápido é
exatamente o tipo de decisão que um tech lead existe para tomar. Para ela, era uma decisão interna de
desempenho. Para Renata, era uma decisão sobre **quem é dono de quais dados**, que atravessa dois
times e é muito cara de desfazer depois que o código de um time passa a depender do formato das
tabelas de outro. A aula 1 disse o mesmo sobre conectores: um banco compartilhado é uma arquitetura
diferente de uma chamada, com outras formas de falhar.

As duas estavam certas sobre a decisão do jeito que cada uma a via. A discussão levou duas semanas,
e não foi a resposta que levou esse tempo. **O que levou tempo foi ninguém saber de quem era a
pergunta**, então cada conversa reabria essa questão antes de chegar à substância.

A fresta oposta é mais silenciosa. O broker de mensagens que alguns times usam rodava havia catorze
meses uma versão sem suporte. O Platform o operava, três times dependiam dele, e cada um supunha que
a atualização era de outro. Ninguém estava errado; ninguém era responsável, tampouco.

## Uma tabela de direitos de decisão

A resposta da Carreto foi uma tabela, escrita por Renata com os sete tech leads e Tomás numa tarde
longa e guardada ao lado dos registros de decisão, no mesmo repositório, revisada como código
(aula 8). É uma prima mais leve da matriz RACI, com três colunas onde a RACI tem quatro:

| decisão | quem decide | quem precisa ser consultado antes | quem é informado |
|---|---|---|---|
| uma biblioteca ou o desenho interno do serviço de um time | o time, por meio do seu tech lead | as pessoas do time que vão mantê-lo | ninguém de fora do time |
| uma tabela que só o time lê e escreve | o time | o Platform, se precisar de um banco novo | — |
| um contrato entre serviços de dois times: uma API, um evento | os dois tech leads juntos | a arquiteta | os times que o consomem |
| quem é dono de quais dados, e quem pode lê-los | a arquiteta | os tech leads dos times envolvidos | Tomás |
| uma nova linguagem, banco ou broker em produção | a arquiteta | o Platform e os times que vão operá-lo | todos, no fórum de arquitetura |
| o que se constrói em seguida | produto, com o tech lead do time | a arquiteta, sobre o custo estrutural | o time |
| quem é contratado, promovido ou muda de time | o gestor de engenharia | o tech lead | — |

Três coisas nela merecem atenção.

**A arquiteta decide duas linhas em sete.** Esse é o objetivo da tabela, e não uma falha dela. A
maior parte das decisões técnicas da Carreto pertence aos times, e a tabela os protege de uma
arquiteta que avance sobre o espaço deles tanto quanto protege as decisões entre times de serem
tomadas por quem chegar primeiro.

**Ela não substitui o processo de aconselhamento da aula 3.** Nesse processo qualquer pessoa pode
tomar uma decisão, desde que antes consulte as pessoas afetadas e as que têm conhecimento no
assunto. A tabela diz quem **responde por** cada tipo de decisão e de quem o conselho não é
opcional. Kátia ainda poderia ter proposto ler as tabelas do Pricing; a quarta linha diz que Renata
responde por isso acontecer ou não, e que Kátia e o tech lead do Pricing precisam ser ouvidos antes
de ela decidir.

**Cada linha é um par de eixos.** As duas primeiras linhas são um time e um horizonte curto; as três
seguintes são vários times ou um horizonte longo. As duas últimas nem são decisões técnicas, e a
última seção desta aula explica por que ficam fora do alcance do arquiteto.

O caso de Kátia, passado pela tabela, cai na quarta linha em um minuto. A atualização do broker cai
na quinta, e a tabela acrescenta o que faltava: um nome.

## Quando a tabela está errada

Uma tabela de direitos de decisão envelhece como qualquer outro documento, e os sintomas são fáceis
de ver. **Uma decisão que não cabe em linha nenhuma**, ou que duas pessoas apontam em duas linhas
diferentes, é motivo para mudar a tabela em vez de discutir o caso. A da Carreto traz no topo a data
da última revisão e é revista sempre que um time é criado ou dividido, porque uma nova fronteira
entre times é um novo lugar para uma decisão cair entre duas cadeiras.

E a tabela não substitui a conversa. Renata continua indo falar com Kátia antes da próxima revisão
de desenho do Matching, não porque a tabela exija, mas porque as decisões que atravessam times são
aquelas em que uma conversa antes sai mais barata do que uma correção depois.
