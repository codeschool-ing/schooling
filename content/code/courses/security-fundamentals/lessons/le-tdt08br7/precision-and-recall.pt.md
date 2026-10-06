---
title: Precisão e revocação
version: 1
---

Um limite de cinco falhas em dez minutos é um padrão comum. Veja o que ele faz com a semana da loja:

```
ana@laptop:~$ python3 detect.py 5
threshold 5: 10 alerts
  TP   3   FP   7
  FN   8   TN  80
precision 30%   recall 27%
```

Dez alertas numa semana, e a matriz diz quanto valeram. **Três verdadeiros positivos**: as três janelas
de oito falhas de quem adivinhava rápido. **Sete falsos positivos**: o backup, toda noite, falhando seis
vezes com a senha expirada. **Oito falsos negativos**: todas as janelas de quem adivinhava devagar, que
nunca falhou mais de três vezes em dez minutos, passaram por baixo da regra. **Oitenta verdadeiros
negativos**: a equipe errando a digitação, deixada em paz com razão.

Dois números resumem a matriz, e respondem a perguntas diferentes.

**Precisão** responde *"quando alerta, com que frequência acerta?"*

> precisão = TP ÷ (TP + FP) = 3 ÷ 10 = **30%**

Sete alertas em dez eram o backup. Quem os lê aprende, em uma semana, que esse alerta em geral quer
dizer "o backup de novo".

**Revocação** (*recall*) responde *"dos ataques reais, quantos pegou?"*

> revocação = TP ÷ (TP + FN) = 3 ÷ 11 = **27%**

O exercício produziu onze casos e a regra pegou três. Quem adivinhava devagar ficou invisível, e um
atacante real que conhece os padrões comuns adivinha devagar de propósito.

Então esta regra é ruim nas duas contas ao mesmo tempo, e os dois números dizem por quê com palavras
diferentes: ela alerta sobre a coisa errada (precisão) e perde a maior parte da coisa certa
(revocação). Nenhum dos números sozinho mostraria os dois problemas. Um detector com 100% de revocação
que alerta em todo login falho é inútil, e também é um com 100% de precisão que dispara uma vez por
ano e perde todo o resto.

### Os dois números têm outros nomes

Áreas diferentes usam palavras diferentes para as mesmas ideias, e você vai encontrar todas:

| aqui | também chamada de | a pergunta |
|---|---|---|
| revocação | sensibilidade, taxa de verdadeiros positivos, taxa de detecção | das coisas ruins, quantas pegamos? |
| precisão | valor preditivo positivo | dos alertas, quantos eram reais? |
| a taxa de falsos positivos | *fall-out* | dos casos inofensivos, em quantos alertamos? |

A última linha é FP ÷ (FP + TN), que aqui dá 7 ÷ 87, uns 8%. Parece pouco, e a última seção desta aula
mostra por que uma taxa pequena de falsos positivos ainda pode soterrar uma equipe.
