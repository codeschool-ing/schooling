---
title: O que é um workspace, e quantos ter
version: 1
---

**Um workspace do Log Analytics é um banco Kusto que o Azure Monitor gerencia para você**: as tabelas são criadas pelos
serviços que escrevem nelas, toda linha ganha um `TimeGenerated` e um `_ResourceId`, e o workspace tem uma região, uma
retenção e uma conta. Diagnostic settings, data collection rules e o Application Insights escrevem todos num deles, e
toda consulta que você escrever neste curso rodaria num deles sem mudança, contra tabelas reais com os mesmos nomes.

**Quantos workspaces** é a primeira pergunta de desenho, e a orientação da própria Microsoft é começar com o mínimo
possível. Um workspace por ambiente é a forma usual: `log-shop-prod` e `log-shop-dev`, porque dados de produção têm
outros leitores e outra retenção. Os motivos para ter mais são específicos: dados que precisam ficar numa certa região,
uma equipe cobrada à parte, um operador de fora da empresa que pode ler uma parte e nada mais.

O que torna um workspace viável para várias equipes é o **acesso no contexto do recurso**: uma pessoa com leitura em
`rg-shop` consulta as linhas que vieram dos recursos de `rg-shop`, no workspace compartilhado, e nenhuma outra. A
configuração do workspace para isso é o *modo de controle de acesso*, e a permissão vem dos recursos e não do workspace.

## Planos de tabela

Toda tabela de um workspace tem um **plano**, e o plano define o que a tabela consegue fazer e quanto custa.

| plano | para que serve | do que abre mão |
|---|---|---|
| **Analytics** | o padrão: tudo em que você alerta, faz gráfico ou consulta com frequência | de nada; é o mais caro por GB |
| **Basic** | logs de alto volume consultados de vez em quando, para investigar | de alguns recursos de consulta; cada consulta é cobrada pelos dados que varre |
| **Auxiliary** | logs verbosos guardados para auditoria ou investigação rara | da maior parte da velocidade e dos recursos; é o mais barato de ingerir |

A loja mantém `AppRequests` e as outras tabelas da aplicação em Analytics, porque as lições 12 e 14 alertam sobre elas.
A saída falante do console de um contêiner, lida só quando alguém está depurando, é a candidata a Basic. Nada disso
existe no emulador, que tem um tipo só de tabela; os planos vêm da documentação da Microsoft.
