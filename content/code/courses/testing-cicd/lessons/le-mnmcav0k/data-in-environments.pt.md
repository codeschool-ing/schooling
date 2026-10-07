---
title: Os dados de cada ambiente
version: 1
---

O código é o mesmo em todo ambiente e a configuração difere de propósito. **Os dados são a terceira
coisa que um ambiente guarda, e a mais difícil de acertar**, porque a escolha realista e a escolha
legal puxam para lados opostos.

## Os dados da produção ficam na produção

A aula 3 seção 11 definiu a regra para os testes, e ela vale com mais força para os ambientes: a
homologação costuma ser acessada por mais gente, com controles mais fracos, que a produção. Uma cópia
dos dados dos clientes ali é uma cópia de dados pessoais com menos proteção, e pela LGPD é um
tratamento que precisa de finalidade e de base legal. "Precisávamos de dados realistas na homologação"
é um motivo que já levou a vazamentos de verdade, porque bancos de homologação são os que ninguém
vigia.

## O que vai no lugar

| necessidade | resposta |
|---|---|
| tabelas com alguma coisa dentro | dados semeados pelas mesmas fábricas que os testes usam (aula 3) |
| volume realista, para desempenho | dados gerados na escala da produção, com a forma das estatísticas dela, não as linhas |
| um defeito que só um registro real mostra | a forma do registro reproduzida à mão, como um caso de fábrica |
| revisar um recurso com conteúdo real | conteúdo criado para isso, pela equipe ou pelo negócio |

Um script de semeadura que roda a cada deploy num ambiente que não é a produção faz dos dados parte da
definição do ambiente, como a configuração. Isso também torna possíveis os ambientes de prévia: cada um
começa com os mesmos dados conhecidos.

## Configuração que aponta para dados

As variáveis da seção 03 decidem que dados um ambiente toca: um endereço de banco, o nome de um bucket,
uma conta na transportadora. **O erro de configuração mais danoso é um ambiente que não é a produção
apontando para os dados da produção**, um serviço de homologação gravando no banco de produção porque
uma linha foi copiada do arquivo errado. Dois hábitos protegem contra isso: as credenciais da produção
só existem na configuração da produção, e os serviços de dados da produção recusam conexões vindas de
qualquer outro lugar. A aula 9 torna o primeiro deles concreto.
