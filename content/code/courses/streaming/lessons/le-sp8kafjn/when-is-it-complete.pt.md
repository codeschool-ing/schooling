---
title: Quando uma janela está completa?
version: 1
---

**Uma janela sobre o tempo do evento está completa quando todos os eventos que pertencem a ela
chegaram, e nenhum programa que lê um stream consegue saber que isso aconteceu.** A lição 10 terminou
nessa pergunta. Esta lição a responde do jeito que todo motor de stream responde: não com certeza,
mas com uma regra explícita, mensurável e ajustável.

Pegue a janela das 09:05 às 09:10 da lição 10. Às 09:10, pelos relógios das lojas, o tempo da janela
acabou. Às 09:12 já chegaram vendas das 09:12, então a maior parte do stream seguiu em frente. E a
venda 8, das 09:08:50, ainda não chegou; ela vem depois de uma venda das 09:13. Na lição 9, uma
janela das 10:30 às 10:35 ficou sem as vendas de Natal até as 14:00. Não existe um momento em que o
stream diga "isso foi tudo das 09:05", porque o stream também não sabe: o caixa de Natal não avisou
que estava segurando vendas.

## Três regras que não funcionam

**Esperar o relógio da parede.** Emitir a janela das 09:05 às 09:12 pelo relógio do próprio
processador, dois minutos depois que ela terminou. É simples e é tempo de processamento de novo, com
todos os defeitos que a lição 9 listou: releia o tópico amanhã e toda janela fecha "dois minutos
depois de terminar" num momento que não tem nada a ver com os eventos, então uma releitura dá
respostas diferentes. E quando o próprio processador para por uma hora, toda janela que termina
nessa hora fecha no instante em que ele volta, antes de os eventos que esperavam por ela terem sido
lidos.

**Esperar para sempre.** Nunca emitir, manter toda janela aberta, corrigir cada uma sempre que
aparecer um evento. Nada se perde, e nada termina nunca: toda janela já aberta continua na memória, e
ninguém lá na frente consegue agir sobre um número que ainda pode mudar.

**Contar eventos.** Emitir quando a janela tiver o número que costuma ter. Cinco lojas vendem em
ritmos mais ou menos conhecidos, então uma janela deveria ter tantas vendas. Dias calmos, dias cheios
e uma loja que fecha mais cedo quebram isso, e a regra não diz nada sobre quais eventos estão
faltando.

## O que funciona

O que o processador sabe são os tempos de evento que já viu. Toda venda que ele leu traz o seu `at`,
e esses tempos andam para a frente: devagar, de forma irregular, fora de ordem, mas para a frente. Se
a venda mais recente que ele viu aconteceu às 09:12:30, então o stream chegou mais ou menos às
09:12:30, e uma venda de antes das 09:10 teria de estar mais de dois minutos e meio atrasada para
chegar agora. A lição 9 mediu com que frequência isso acontece nos caixas da Ponto Final, e a resposta
foi: muitas vezes por segundos, raramente por minutos, e uma vez por dia por horas.

**Então o processador faz uma afirmação: "não espero mais nenhum evento mais antigo que este
horário".** Essa afirmação é um watermark. Ele é calculado a partir de tempos de evento, então uma
releitura do mesmo tópico faz as mesmas afirmações nos mesmos lugares. Ele só anda para a frente,
então uma janela que ele passou continua passada. E ele é uma aposta, que os eventos atrasados da
lição 9 às vezes vão fazer perder. O resto desta lição é sobre apostar bem e decidir o que fazer
quando a aposta é perdida.
