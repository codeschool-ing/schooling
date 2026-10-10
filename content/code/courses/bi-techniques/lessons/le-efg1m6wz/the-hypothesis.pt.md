---
title: A hipótese
version: 1
---

**Um teste sem hipótese escrita é uma pescaria**: alguma coisa vai aparecer, e vai ser confundida
com um achado. A hipótese é escrita antes de o teste começar, e tem quatro partes.

> **Se** mudarmos *a página de checkout para um passo só*,
> **então** *a fração de visitantes que fazem um primeiro pedido* vai subir **pelo menos** *0,6
> ponto percentual*,
> **porque** *o formulário atual de três passos perde gente no celular na etapa de pagamento*.

Cada parte trabalha.

- **A mudança** diz exatamente o que difere entre controle e tratamento. "Um checkout novo" não é
  uma mudança, é um projeto; um teste de tudo ao mesmo tempo pode dizer que algo ajudou e nunca o
  quê.
- **A métrica** é o único número que vai decidir. A próxima seção é sobre escolhê-la.
- **O tamanho**, "pelo menos 0,6 ponto", é o menor efeito que vale lançar. É um julgamento de
  negócio, não estatístico: abaixo dele a mudança não vale o que custa construir e manter. A aula 8
  o transforma no número de visitantes de que o teste precisa.
- **O motivo** é o que faz o resultado ensinar algo. Se o efeito aparece no computador e não no
  celular, o motivo estava errado, e isso vale saber mesmo quando a métrica se mexeu.

## A versão do estatístico

A aula 13 de `statistics` escreve a mesma coisa como duas hipóteses sobre a população de
visitantes:

- a **hipótese nula**, H₀: a taxa de conversão do tratamento é igual à do controle;
- a **alternativa**, H₁: elas diferem.

O teste pergunta se o dado é surpreendente caso H₀ seja verdade. Duas escolhas são feitas aqui,
antes de o dado existir, e as duas são para a aula 10 usar.

**Um lado ou dois.** Uma alternativa bilateral diz que as taxas diferem em qualquer direção; uma
unilateral diz que o tratamento é melhor. Um teste unilateral precisa de menos visitantes para
detectar a mesma melhora, e não enxerga dano: uma página que espanta clientes aparece como "sem
melhora" e não como um alerta. **Bilateral é o padrão seguro**, e é o que este curso usa.

**O nível de significância**, α, a chance de declarar um efeito quando não há nenhum. Cinco por
cento é a convenção. Uma empresa que roda cem testes por ano a 5 por cento deveria esperar cerca de
cinco vitórias falsas entre os testes em que nada funcionou, ao que a aula 11 volta.
