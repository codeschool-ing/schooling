---
title: A linguagem de um incidente
version: 1
---

**Sob pressão, as pessoas escrevem do jeito que se sentem, e mensagens de incidente escritas assim
saem vagas, alarmantes e cheias de culpa.** Alguns hábitos, decididos com antecedência e guardados num
modelo, deixam as palavras calmas e exatas quando quem as escreve não está.

## Palavras que causam problema

| escrito no calor do momento | o que é lido | escreva em vez disso |
|---|---|---|
| "probleminha" | não sabem o tamanho, ou estão escondendo | "a maioria dos clientes não consegue fazer o checkout" |
| "deve ser resolvido logo" | uma promessa | "próxima atualização até 19:45" |
| "causado pela tarefa do Paulo" | o Paulo fez algo errado | "uma tarefa em segundo plano" |
| "o banco morreu" | dados foram perdidos | "o banco parou de aceitar conexões; nenhum dado foi perdido" |
| "achamos que pode ser a rede" | é a rede | nada, até ser confirmado |
| "voltou ao normal" | resolvido de vez | "funcionando normalmente desde 19:41; estamos monitorando" |

O padrão da coluna da direita: **diga o efeito, diga o que se sabe, diga quando vem a próxima notícia
e não cite ninguém.**

## Horários, com o fuso

A Marola fica em Recife, o painel do provedor de nuvem mostra UTC, e um dos seus clientes tem lojas em
dois fusos horários. "Desde 22:10", num canal de incidente, foi lido por um engenheiro como horário de
Recife e por outro como UTC, e durante dez minutos os dois olharam para horas diferentes de logs.
**Todo horário numa mensagem de incidente leva o fuso, ou o modelo diz uma vez, no topo, em que fuso
estão todos os horários.** O modelo da Marola agora diz "todos os horários de Recife (UTC−3)".

## Severidade, em palavras com que todos concordam

"Esse é dos grandes?" é a pergunta mais feita num canal de incidente. Uma tabela pequena de níveis de
severidade, combinada antes, transforma a pergunta num rótulo:

| nível | significa | exemplo |
|---|---|---|
| **SEV1** | uma função central está fora do ar para a maioria dos clientes | 6 de março: checkout fora do ar |
| **SEV2** | uma função central está degradada, ou fora do ar para alguns | timeouts de sexta à noite para 2% |
| **SEV3** | uma função secundária foi afetada; existe um contorno | histórico de pedidos lento para carregar |

Os níveis exatos importam menos do que tê-los antes do incidente. Um rótulo decidido com calma é
aceito numa crise; um rótulo inventado durante uma é motivo de discussão.

## Escreva o modelo com calma

Tudo nesta aula fica mais fácil com um modelo pronto: a atualização de quatro linhas, a frase do
suporte, a linha para a diretoria, os cinco blocos do resumo, o fuso. O da Marola fica no runbook de
incidentes, e **a primeira ação do líder de comunicação é abri-lo**, não começar a escrever numa
página em branco com a adrenalina no comando.
