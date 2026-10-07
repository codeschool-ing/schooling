---
title: O GDPR, e quando ele alcança uma empresa brasileira
version: 1
---

O **Regulamento Geral sobre a Proteção de Dados** — o GDPR, na sigla em inglês que todo mundo usa —,
Regulamento (UE) 2016/679, vale em todos os Estados-membros da União Europeia desde 25 de maio de
2018. É um *regulamento*, e não uma diretiva: o mesmo texto é lei em todos eles, com alguns pontos
deixados à lei nacional — a idade do consentimento de uma criança é um deles. A LGPD foi escrita com
ele aberto na mesa, e é por isso que a aula 7 vai parecer familiar aqui, e por isso que vale saber as
diferenças com exatidão.

## A Ipê em Lisboa

A partir desta aula, a Ipê tem um segundo endereço. Ela abriu uma pequena empresa em **Lisboa** que
vende vitaminas e cosméticos — e não medicamentos com receita — a clientes em Portugal, a partir de um
armazém com quatro funcionários. Os pedidos dela vão para o mesmo banco em São Paulo, no mesmo schema
`sales`. Os dados do laboratório não os incluem: a pergunta aqui é que lei alcança que linha, e ela
se responde sem mil pedidos portugueses para olhar. A decisão traz duas leis europeias, e esta seção
trata de como.

O **artigo 3º** do GDPR tem dois gatilhos:

- **estabelecimento** (art. 3(1)): tratamento *no contexto das atividades de um estabelecimento* na
  União, onde quer que o tratamento aconteça fisicamente. A empresa de Lisboa é um estabelecimento. O
  que ela faz com os dados dos clientes está sob o GDPR, mesmo com o banco em São Paulo.
- **direcionamento** (art. 3(2)): um controlador **sem** estabelecimento na União também é alcançado
  quando oferece bens ou serviços a pessoas na União, ou monitora o comportamento delas lá. Se a Ipê
  vendesse para Portugal direto do Brasil — uma loja em português de Portugal, preços em euros,
  entrega no Porto —, este gatilho valeria, e o artigo 27 exigiria um representante na União.

De um jeito ou de outro, a lei segue as pessoas, e não o servidor, que é a mesma ideia do artigo 3º
da LGPD lida pelo outro lado. Um time de dados não responde "estamos sob o GDPR?" olhando onde o banco
roda.

## O que não é alcançado

Os clientes brasileiros da empresa de São Paulo não ficam sob o GDPR por dividirem uma tabela com os
portugueses. O GDPR se aplica ao tratamento feito no contexto do estabelecimento de Lisboa e às
pessoas a quem ele se dirige. Mas uma tabela que guarda os dois é uma tabela em que **as duas leis
valem para linhas diferentes**, e a diferença tem de estar visível no dado: uma coluna dizendo a que
empresa, e portanto a que lei, cada cliente pertence. Uma coluna que decide isso precisa ser
confiável (aula 9).

## Quem fiscaliza

Cada Estado-membro tem uma **autoridade de controle**; em Portugal é a **CNPD**, a Comissão Nacional
de Proteção de Dados. Uma empresa estabelecida em vários Estados-membros trata principalmente com a
autoridade do seu estabelecimento principal, o **balcão único** (*one-stop shop*). A Ipê tem um só,
então a CNPD é o seu regulador na Europa e a ANPD no Brasil.
