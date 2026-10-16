---
title: O que o Shield Advanced acrescenta
version: 1
---

O Shield Advanced é uma assinatura, comprada uma vez para a organização da AWS e aplicada aos recursos
nomeados nela. O que ele acrescenta ao Standard não é, na maior parte, mais filtragem. É **gente,
dinheiro de volta e automação**, e cada um vale ser entendido nos seus próprios termos:

| acrescenta | o que é |
|---|---|
| detecção ajustada ao recurso | o Shield aprende o tráfego normal de cada recurso protegido e detecta ataques menores contra ele; com um health check do Route 53 associado, usa a saúde da aplicação além do tráfego |
| mitigação automática na camada de aplicação | quando detecta uma enxurrada HTTP, o Shield escreve regras do WAF no web ACL do recurso para bloqueá-la, em `Count` ou `Block` conforme configurado, e as remove depois |
| o Shield Response Team | os especialistas em DDoS da AWS, alcançáveis durante um ataque, e, com o **engajamento proativo**, ligando para a equipe quando o health check de um recurso protegido falha; exige um plano de suporte Business ou Enterprise |
| proteção de custo | créditos pelas cobranças de escalonamento que um ataque causa em recursos protegidos, os balanceadores, instâncias e distribuições que cresceram para absorvê-lo |
| visibilidade | relatórios de ataque com vetores, tamanhos e durações, em `list-attacks` e em métricas do CloudWatch no namespace `AWS/DDoSProtection` |
| WAF incluído | para recursos protegidos, a AWS documenta o web ACL, suas regras e suas requisições como incluídos na assinatura |

## A proteção de custo, lida com cuidado

A proteção de custo é a linha mais mal lida. É **um crédito, pedido depois do ataque**, pelo uso extra que
um DDoS causou em recursos que estavam protegidos naquela hora, e cobre escalonamento, não tudo: um pedido
de crédito nomeia o ataque que o Shield registrou, e um ataque contra o qual ninguém se protegeu, ou que o
Shield não detectou, não é coberto. Para um serviço que escala sozinho, a conta de uma semana de ataque
pode ser o maior número do ano, e este é o seguro contra ela.

## O que o Advanced não faz

Ele não faz uma aplicação que cai a dez vezes o tráfego normal aguentar cem vezes. As proteções são as
mesmas três camadas de antes: a do Standard na borda, o WAF na camada 7, e capacidade suficiente, ou cache,
para responder o que passar. O Shield Advanced torna a segunda camada mais rápida de ajustar durante um
ataque, põe especialistas ao lado da equipe enquanto ele acontece, e paga pela terceira. Uma equipe que
não fez o trabalho da lição 15 compra pouco com a assinatura da lição 16.
