---
title: Que parte da Roda Livre precisa de quê
version: 1
---

**O CAP é escolhido por pedaço de dado, não por empresa, e a Roda Livre precisa das duas respostas,
em lugares diferentes.** O erro a evitar é escolher um banco pelas letras dele e depois conviver com
essa escolha para todo tipo de dado que a empresa tem. A pergunta vai a cada pedaço de dado, um de
cada vez: se os dois lados de um corte dissessem sim ao mesmo tempo, daria para combinar as duas
respostas depois?

## Cinco dados, cinco respostas

| dado | durante um corte, ele deve | por quê |
|---|---|---|
| o pagamento de uma viagem | **recusar** | uma cobrança feita duas vezes ou registrada errado não se combina; vira um estorno e um telefonema |
| que cliente está com a bicicleta `B017` | **recusar** | uma bicicleta, um ciclista; dois "sim" põem duas pessoas diante de uma doca |
| o mapa de docas do aplicativo | **responder** | um mapa um pouco atrasado ainda manda as pessoas mais ou menos para o lugar certo, e contagens se combinam |
| as leituras dos sensores das docas | **responder** | uma leitura é um fato sobre um momento, e uma duplicata pode ser descartada depois pelo seu id |
| o relatório matinal de Marta | **nenhuma das duas, de propósito** | ele é calculado a partir de uma cópia mantida horas atrás |

As duas primeiras são o motivo de o aplicativo da Roda Livre guardar pagamentos e destravamentos num
banco com um primário só, e de ter um provedor de pagamentos que é, ele próprio, o registro de cada
cobrança. As duas do meio são o motivo de o mapa e as leituras dos sensores poderem ficar num banco
que aceita escritas em qualquer máquina. Nenhuma escolha é a melhor. **Cada uma é certa para o dado
que guarda, e errada para o outro.**

## A última linha é da plataforma de dados

O relatório de Marta é a linha de que este curso tratou o tempo todo, e o CAP não se aplica a ele do
jeito que se aplica aos outros. O pipeline da aula 3 copia as viagens de ontem do banco do
aplicativo uma vez por noite. Todo número que o relatório mostra tem, portanto, até um dia de idade
— e ninguém se importa, porque esse atraso foi escolhido e posto por escrito.

Nos termos do PACELC, uma plataforma de dados levou a escolha do *senão* o mais longe possível na
direção da latência: ela nunca espera a fonte concordar, e aceita estar atrasada numa medida
conhecida. **O que ela promete no lugar da linearizabilidade é atualidade**, que a aula 2
transformou numa meta que pode ser medida. Para o relatório de Marta, ela poderia dizer: toda
viagem até a meia-noite está no relatório às sete.

Daí saem dois deveres, e os dois já apareceram neste curso.

- **Dizer quão atrasado.** Um painel que mostra a idade dos seus dados transforma um número velho
  num número honesto. A meta de atualidade da aula 2 é essa promessa feita em público.
- **Tornar seguro o ato de alcançar.** Uma plataforma atrasada vai ser posta em dia, por uma nova
  execução, um reprocessamento ou uma carga repetida. A ingestão da aula 3 que podia rodar duas
  vezes sem contar duas vezes, e a entrega efetivamente única da aula 8, são o que torna isso
  seguro — a combinação do mundo AP, num pipeline.
