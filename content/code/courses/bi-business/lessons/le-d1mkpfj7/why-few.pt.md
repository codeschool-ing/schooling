---
title: Por que poucos
version: 1
---

Quando um analista é perguntado sobre quais números entram numa página, a resposta que parece segura
é todos: ninguém pode reclamar que o seu número ficou de fora, e o leitor ignora o que não precisa.
**A segunda metade é que está errada. Um leitor não consegue ignorar quarenta números de forma
seletiva**; ou ele lê todos por cima, ou pula a página, e nos dois casos os quatro que deviam abrir
uma conversa se perdem entre os trinta e seis que não deviam.

## Uma página é lida no tempo que a pessoa tem

A reunião de operações da Varanda é na segunda às nove, com Caio Barreto, Marcos das entregas, o
gerente do depósito, os três gerentes regionais de loja, a Lívia e mais uma pessoa: oito pessoas. Em
janeiro de 2026, a página que a Lívia herdou para essa reunião tinha quarenta indicadores. Suponha que
a reunião dê 45 segundos a cada um, o que não basta para discutir nada, ao longo de 48 semanas de
trabalho. Numa planilha nova:

| | A | B | C | D |
|---|---|---|---|---|
| 1 | Indicadores | Segundos cada | Pessoas | Semanas |
| 2 | 40 | 45 | 8 | 48 |
| 3 | 6 | 45 | 8 | 48 |

Minutos por reunião, horas de gente por semana e horas por ano:

```localised
=A2*B2/60                        30
=A2*B2/60*C2/60                  4
=ARRED(A2*B2/60*C2/60*D2;0)      192
```

**Trinta minutos de toda reunião, quatro horas de gente por semana e 192 horas por ano lendo números
em voz alta**, antes de alguém decidir qualquer coisa. As mesmas fórmulas na linha 3, para seis
indicadores:

```localised
=A3*B3/60                        4,5
=ARRED(A3*B3/60*C3/60*D3;0)      29
```

Quatro minutos e meio por reunião e 29 horas por ano. A diferença é tempo que a reunião pode gastar
com o único número que se mexeu.

## Todo indicador custa alguma coisa

O tempo de leitura é o custo visível. Outros três são pagos longe dos olhos:

- *Os dados*: alguém precisa extraí-los, conferi-los toda semana e perceber quando a fonte muda. Na
  Varanda, isso é o pipeline do Tiago e a manhã de segunda da Lívia;
- *A definição*: o cartão da aula 10, escrito e mantido verdadeiro. Quarenta cartões são um documento
  que ninguém mantém, e um indicador cujo cartão se desviou dá um número que ninguém sabe explicar;
- *A atenção do dono*: um KPI precisa de alguém que age quando ele se mexe. O Caio consegue agir
  sobre um punhado; com quarenta, ele age sobre o último que foi mencionado.

Então um indicador não é de graça só porque o sistema consegue produzi-lo. **Ele ganha o lugar se o
que ele muda vale mais do que ele custa**, que é o teste do valor da informação da aula 2 aplicado a
uma página em vez de a uma análise.

## Quantos são poucos

**Cinco a sete indicadores por público** é um limite de trabalho, não uma lei. Ele vem da prática, e
não de um experimento: é o que cabe numa tela ou numa página impressa sem rolar, e quantas coisas
separadas uma reunião consegue discutir no tempo que tem. Um conselho olhando o ano pode precisar de
menos; quem toca o chão de um depósito pode precisar de alguns a mais, desde que cada um seja algo
sobre o qual age hoje.

Dois detalhes mantêm o limite honesto. Ele é **por público**, então a página da Helena e a do Caio
têm cada uma o seu punhado, e um número pode ser KPI numa e métrica um clique abaixo na outra, como a
aula 10 mostrou. E os indicadores que ficam fora da página não são apagados: continuam como métricas,
disponíveis quando alguém estiver diagnosticando um problema. **Escolher poucos é escolher o que se lê
toda semana, não o que se guarda.**

A próxima seção é o método para escolhê-los, e ele parte do objetivo, não da lista do que os sistemas
conseguem produzir.
