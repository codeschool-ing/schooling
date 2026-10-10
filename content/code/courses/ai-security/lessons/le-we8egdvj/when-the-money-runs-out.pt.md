---
title: O que o assistente faz quando um limite é atingido
version: 1
---

Um limite decide quando as chamadas param. **O que o cliente vê quando elas param** é outra decisão, e
deixá-la sem decidir é como um orçamento vira uma página de erro.

## Recusar com clareza, e dizer o que acontece depois

A conta em laço da seção anterior foi recusada 567 vezes. Para uma integração, isso é o certo: ela
recebe um erro com um status que diz *orçamento esgotado*, diferente de uma falha, e a hora em que o
orçamento volta. Um programa consegue parar com isso, ou ao menos registrar, e uma pessoa lendo o log
sabe o que aconteceu. Um erro que diz só "algo deu errado" faz a integração tentar de novo, e uma nova
tentativa contra um orçamento esgotado é o laço outra vez, agora sem custar nada e sem resolver nada.

Para uma pessoa no chat a mesma recusa precisa virar palavras: o assistente não consegue responder mais
hoje, alguém da equipe vai responder, e é assim que se fala com essa pessoa. **Um limite atingido em
silêncio parece um produto quebrado**, e a pessoa tenta de novo, que é a única coisa que não pode
ajudar.

## Degradar antes de recusar

Entre o serviço completo e nenhum há degraus, e um orçamento pode escolhê-los:

- **um modelo mais barato** pelo resto do dia, para perguntas que um modelo menor responde bem o
  bastante;
- **um `max_tokens` menor**, aceitando respostas mais curtas;
- **a própria página da central de ajuda** no lugar de uma resposta gerada, quando a pergunta combina
  com uma.

Cada degrau é pior que o serviço completo e melhor que nada, e cada um é uma decisão a anotar antes do
dia em que for preciso, com quem pode acioná-la.

## O alerta é para uma pessoa, e diz o que fazer

O alerta de 80% da seção anterior só vale a pena se alguém o recebe e sabe para onde olhar. Ele diz o
teto e a hora; a próxima linha útil é a conta que gasta mais rápido, que a tabela do `budget.py` já
separa. A aula 22 monta o monitoramento onde isso mora, e a aula 24 a resposta quando ele dispara.

## Anotar os números

Todo limite desta aula é um número que alguém escolheu: 60 tokens, 100.000 por dia, R$ 20,00. **Nenhum
deles está certo**, e todos são melhores que nenhum. O que os torna defensáveis é uma nota ao lado de
cada um dizendo por que é esse número, contra que tráfego foi definido e quando vai ser revisto, para
que a próxima pessoa que aumentar um saiba o que está trocando.
