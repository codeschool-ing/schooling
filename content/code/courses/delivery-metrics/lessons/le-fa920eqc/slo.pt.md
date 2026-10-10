---
title: O objetivo, e por que ele não é 100%
version: 1
---

Um **objetivo de nível de serviço**, ou SLO, é a meta para um SLI ao longo de uma janela de tempo:

```localised
99,9% das tentativas de cobrança são boas, em quaisquer 30 dias
```

As duas metades importam. O número diz quão bom é bom o bastante, e a janela diz por quanto tempo o time é julgado. Uma janela **móvel** de 30 dias avança um dia de cada vez, então uma tarde ruim conta por exatamente 30 dias e depois sai; um mês do calendário zera no dia 1º, o que faz do último dia do mês um passe livre ou um desastre, dependendo do que aconteceu antes.

## O que cada nove compra

Ajuda transformar uma porcentagem em tempo, como se todas as requisições falhassem num trecho contínuo:

| objetivo | ruim permitido em 30 dias | como indisponibilidade contínua |
|---|---|---|
| 99% | 1 em 100 | 7 horas e 12 minutos |
| 99,5% | 1 em 200 | 3 horas e 36 minutos |
| 99,9% | 1 em 1.000 | 43 minutos |
| 99,99% | 1 em 10.000 | 4 minutos e 19 segundos |

Cada nove a mais é dez vezes mais rígido, e custa muito mais que dez vezes: 43 minutos por mês é tempo suficiente para uma pessoa ser acionada, abrir um laptop e reverter uma release; quatro minutos não é, então um serviço de 99,99% precisa que a reversão aconteça sem ninguém.

## Por que não 100%

**100% é o objetivo errado para quase tudo**, por três motivos que se sustentam sozinhos.

- **O usuário não consegue ver.** O terminal de uma loja fica no Wi-Fi da loja e numa rede móvel que falham com mais frequência que 1 em 1.000. A partir de certo ponto, as melhorias do time somem nas indisponibilidades de outra pessoa.
- **Ele proíbe mudança.** Toda release carrega algum risco. Um objetivo de 100% diz que nenhum risco é aceitável, o que, seguido com honestidade, significa nunca fazer release, e seguido sem honestidade significa fazer release mesmo assim e esconder os resultados.
- **Ele não pode ser cumprido, então deixa de significar alguma coisa.** A primeira cobrança ruim o quebra, e um objetivo que está sempre quebrado é ignorado a partir do segundo mês.

## Escolhendo o número

O melhor ponto de partida é **o que os usuários vêm recebendo sem reclamar**. Se o SLI está por volta de 99,95% há meses e as lojas estão satisfeitas, um objetivo de 99,9% deixa espaço para o time correr riscos e ainda mantém as lojas onde estão; um objetivo de 99,99% promete algo que ninguém pediu, e paga por isso a cada release.

O número é uma **decisão de produto**, não de engenharia. Ele diz quanta falta de confiabilidade o negócio aceita em troca de mudança, e as pessoas donas do produto o assinam ao lado do time que o opera.

## SLO e SLA

Um **SLA**, um acordo de nível de serviço, é um contrato com um cliente, com uma penalidade quando é quebrado: um reembolso, um crédito. Um SLO é interno. Os times mantêm o SLO mais rígido que qualquer SLA, para que o alarme toque enquanto ainda há tempo de agir antes de o contrato ser quebrado. As lojas do time de Billing têm um SLA de 99,5% nas cobranças no cartão; o objetivo do time é 99,9%.
