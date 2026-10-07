---
title: O que difere entre ambientes, e onde isso mora
version: 1
---

Nesta lição e na anterior, o mesmo código rodou em quatro lugares — os schemas da Ana, os da produção,
o warehouse de teste e, na lição 17, um diretório temporário — e nada no código dizia qual. O que
diferia era a **configuração**, guardada fora dele:

- **o target do dbt**, escolhido com `--target`, cujos detalhes estão em `~/.dbt/profiles.yml`;
- **variáveis de ambiente**: `SHOP_DB` e `WH_DB` para o carregador, `PRICES_API_KEY` para o cliente de
  preços;
- **o checkout**: em que tag o diretório está.

A regra que isso segue é curta e fácil de quebrar: **o código nunca pergunta em que ambiente está.** Um
`if target == "prod"` dentro de um modelo, um nome de schema escrito à mão num script, um teste que
sabe que é teste: cada um é um lugar em que a produção roda código que o desenvolvimento nunca rodou, e
é aí que moram as surpresas. Quando um ambiente precisa se comportar de outro jeito — menos threads em
desenvolvimento, uma amostra dos dados em teste —, a diferença vai para a configuração e o código a lê.

O mesmo vale, com mais força, para segredos. Uma senha no código está em toda cópia do código, toda
branch e toda tag, para sempre, já que uma versão é algo para o qual se pode voltar. Guarde-os no
ambiente, dê a cada ambiente os seus, e não dê ao desenvolvimento nenhum que consiga escrever na
produção. O laboratório tem um usuário para tudo, o que é conveniente para um curso e é a única coisa
aqui a não copiar.
