---
title: Destino compartilhado, e padrões que mudam a linha na prática
version: 1
---

**O contrato ainda divide o trabalho em dois. O que mudou nos últimos anos é o quanto os provedores
ajudam na sua metade, quase sempre decidindo coisas por você a menos que você decida outra coisa.** O
Google Cloud deu nome à ideia, **destino compartilhado** (*shared fate*): o resultado do provedor
depende das configurações dos clientes, então ele entrega padrões mais seguros, modelos testados e
proteções, em vez de só uma lista do que é seu.

A leitura errada é a de que a linha subiu, e algumas das suas camadas agora são do provedor. Ela não
subiu, em contrato nenhum. Um padrão continua sendo uma configuração na sua conta; você pode mudá-lo,
e se mudar, as consequências são suas exatamente como antes.

## Três jeitos de um provedor ajudar na sua metade

| | o que é | um exemplo |
|---|---|---|
| um **padrão mais seguro** | a configuração com que um recurso novo começa | a AWS ligando o Block Public Access em todo bucket novo em 2023, seção 03 desta aula |
| uma **proteção** (*guardrail*) | uma regra definida uma vez, acima das contas, que uma configuração posterior não consegue quebrar | uma política da organização negando qualquer região fora do Brasil, aula 17 |
| um **modelo** (*blueprint*) | um arranjo inteiro e testado de contas, redes e logs para começar | a landing zone do AWS Control Tower, as landing zones do Azure, o enterprise foundations blueprint do Google Cloud |

Cada um muda a linha **na prática**: a camada continua sua, e o provedor fez a primeira versão do
trabalho nela. É um ganho real para os buckets, chaves e redes em que ninguém da sua equipe teria
pensado. Não é ganho nenhum para os que alguém já mudou.

## O que isso pede de você

Três hábitos, e cada aula depois desta pratica pelo menos um:

- **Mantenha os padrões**, e trate desligar um deles como uma decisão que precisa de um motivo
  escrito. Todo bucket público da aula 9 começou com alguém desligando uma proteção para algo
  funcionar.
- **Saiba quais recursos são anteriores a um padrão.** Um padrão vale a partir do dia em que saiu. A
  conta da clínica é mais velha que 2023, e os buckets mais antigos dela são exatamente os que a
  mudança não alcançou.
- **Leia o padrão de volta, nunca o suponha.** Ele é uma configuração como qualquer outra, então a
  prova dele é a mesma: uma requisição, e a resposta que ela recebeu. A seção 03 desta aula fez isso
  para um bucket, e a aula 16 faz para todos.

Então o modelo com que você trabalha no resto do curso tem três partes. **A linha diz de quem é o
trabalho de uma camada. Os padrões dizem quanto desse trabalho já foi adiantado em seu lugar. A sua própria
prova diz o que é verdade hoje.** Só a terceira é sempre específica da sua conta.
