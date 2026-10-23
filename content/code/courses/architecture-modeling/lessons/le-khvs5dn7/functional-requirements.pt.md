---
title: Requisitos funcionais que podem ser conferidos
version: 1
---

**Um requisito funcional diz o que o sistema faz, para quem, e como alguém saberia que foi feito.**
A última parte é a que mais falta, e é ela que transforma um desejo num requisito. Duas formas
dominam a prática, e servem a momentos diferentes.

## Texto de caso de uso

A aula 2 desenhou o diagrama de casos de uso e disse que o caso de uso de verdade é texto. Aqui está
o texto de um dos casos da Carcará, no formato que Alistair Cockburn popularizou:

```localised
Caso de uso: Cancelar uma passagem paga
Ator principal: Passageiro
Pré-condição: o passageiro está autenticado e é dono de uma passagem Paga
Cenário principal de sucesso:
  1. O passageiro pede para cancelar a passagem.
  2. O sistema mostra o valor do reembolso e a política que se aplica.
  3. O passageiro confirma.
  4. O sistema libera o assento e solicita o reembolso.
  5. O sistema confirma o cancelamento por e-mail e no app.
Extensões:
  2a. Faltam menos de três horas para a partida:
      O sistema oferece a troca para outra viagem mediante taxa; sem reembolso.
  2b. A viagem já partiu:
      O sistema recusa, dizendo por quê.
  4a. A solicitação de reembolso falha:
      O sistema mantém a passagem Cancelada, tenta o reembolso de novo,
      e alerta Pagamentos depois de três falhas.
Garantia de sucesso: assento liberado; reembolso solicitado exatamente uma vez.
```

O valor está nas **extensões**. O cenário principal é o que todo mundo já tinha imaginado; as
extensões são as perguntas que alguém precisa responder, e cada resposta é um requisito. A 2b é a
terceira guarda que o diagrama de atividades da aula 4 encontrou; a 4a é um requisito de qualidade
escondido dentro de um funcional.

## Histórias de usuário com critérios de aceitação

Times ágeis escrevem um requisito como **história de usuário**, *como passageiro, quero cancelar uma
passagem paga, para receber meu dinheiro de volta quando meus planos mudarem*, e o tornam conferível
com **critérios de aceitação**. Uma forma comum para os critérios é *Dado / Quando / Então*, do
desenvolvimento guiado por comportamento (BDD):

```localised
Dado uma passagem Paga para uma viagem que parte em 5 horas
Quando o passageiro a cancela
Então o assento é liberado
E um reembolso integral é solicitado uma vez
E o passageiro recebe um e-mail de confirmação

Dado uma passagem Paga para uma viagem que parte em 2 horas
Quando o passageiro a cancela
Então nenhum reembolso é solicitado
E o passageiro recebe a oferta de troca mediante taxa
```

Cada cenário dá nome a um estado inicial, um evento e resultados observáveis: a tabela de estados da
aula 4, escrita uma linha por vez. Muitos times rodam critérios nessa forma como testes
automatizados.

## Qual usar

- **Texto de caso de uso** quando o comportamento tem muitos ramos e vários atores, e a análise é
  feita antes de o trabalho ser dividido. Ele mantém o objetivo inteiro num lugar só.
- **Histórias com critérios** quando o trabalho é planejado em incrementos pequenos. Uma história é
  uma fatia de um caso de uso; várias histórias juntas costumam cobrir um.

De um jeito ou de outro, **um requisito funcional sem um jeito de conferi-lo é um assunto, não um
requisito**. *Passageiros podem gerenciar suas passagens* é um assunto. O caso de uso acima é um
requisito.
