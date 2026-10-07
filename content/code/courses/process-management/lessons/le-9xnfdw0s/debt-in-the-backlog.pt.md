---
title: Trabalho técnico no mesmo backlog
version: 1
---

Os itens mais difíceis de priorizar são aqueles cujo valor é invisível para os usuários: a atualização do banco, a refatoração do módulo de faturamento, o teste de carga, a migração para fora de uma biblioteca que não é mais mantida. O custo do atraso deles costuma ser **intangível**, no sentido da quarta seção desta aula: pouco se perde nesta semana, muito se perde depois. Deixados competindo com funcionalidades só por valor, eles perdem toda vez, até virarem urgentes e custarem muito mais.

## Dê a eles um termo na fórmula

As técnicas desta aula conseguem carregar trabalho técnico se ele for descrito nos termos delas:

- No **WSJF**, o terceiro componente do custo do atraso, *redução de risco e habilitação de oportunidades*, existe exatamente para isso. A atualização do banco do time Agenda marcou 13 ali, e foi isso que a pôs em segundo.
- No **RICE**, o efeito pode ser expresso como alcance e impacto sobre as pessoas afetadas quando o risco se materializa: todo paciente, se o banco sem suporte falhar.
- No **MoSCoW**, uma correção de segurança pode ser must-have, porque sem ela a versão seria irresponsável.
- Nos termos da aula 11, um trabalho técnico muitas vezes é uma **resposta a risco**, e o valor dele é o custo esperado que remove.

A contribuição do arquiteto é fazer essa tradução. "Precisamos atualizar o banco" vai perder para "os pacientes querem lembretes por SMS". "A versão do banco que usamos sai de suporte em agosto; depois disso, uma falha de segurança não terá correção, e a plataforma guarda dados de saúde" compete em pé de igualdade.

## Alocação de capacidade

Algumas organizações adotam uma segunda abordagem, mais direta: **reservam uma parcela da capacidade de cada Sprint** para trabalho técnico e deixam o time escolher o que entra nela, fora da priorização de funcionalidades. O SAFe chama isso de alocação de capacidade; uma parcela por volta de 20% é um ponto de partida comum, embora nenhuma evidência torne esse número especial. Ela protege o trabalho técnico de perder toda comparação, e o custo é que a parcela reservada não é pesada contra funcionalidades de jeito nenhum, então pode ser gasta nas melhorias favoritas do time em vez das mais valiosas.

As duas abordagens combinam bem: uma parcela reservada para o trabalho constante de manter o sistema saudável, e WSJF ou RICE para os itens técnicos grandes que merecem ser pesados contra funcionalidades abertamente. A aula 14 trata de registrar, medir e negociar a dívida técnica para que as duas sejam defendidas com evidência.
