---
title: Mais fontes não são mais respostas
version: 1
---

O jeito óbvio de garantir que a resposta está no prompt é mandar mais: aumentar o `k`, e o que a busca
pôs em quarto ou oitavo lugar vem junto. O `sweep.py` mede o que isso compra, para as 26 perguntas
com resposta do `eval.jsonl`, em seis valores de `k`:

```
ana@lab:~/rag$ python sweep.py
  k  found  tokens  alike  above floor
  1  20/26      60      0          1.0
  2  26/26     116      3          1.8
  3  26/26     171      3          2.6
  5  26/26     278      7          3.4
  8  26/26     441     12          4.1
 12  26/26     660     16          4.7
```

As colunas são: em quantas perguntas um fato da resposta estava em algum lugar do que foi recuperado,
os tokens de texto das fontes por pergunta, quantos pares de pedaços recuperados tinham similaridade
0,8 ou mais, e quantos pedaços recuperados, em média, passariam do piso de 0,5 da aula 6.

**A recuperação para de melhorar em dois.** Com uma fonte, 20 de 26 respostas estavam no prompt; com
duas, as 26; depois disso, nada mais a achar. **Os tokens continuam crescendo em linha reta**, 116 com
duas e 660 com doze, e também os pares de pedaços que dizem quase a mesma coisa. Tudo depois da
segunda fonte é custo: as mesmas respostas, mais texto em volta.

## O que o texto a mais faz com um modelo

O extract-1 não se distrai com nada. Ele ordena cada frase pela similaridade com a pergunta e copia as
melhores, então um prompt com doze fontes lhe dá a mesma resposta que um prompt com duas, e este
laboratório não consegue mostrar o que o texto a mais faz com um modelo de linguagem. Duas medições
publicadas conseguem:

- **Texto irrelevante baixa a precisão.** Shi e outros, em *Large Language Models Can Be Easily
  Distracted by Irrelevant Context* (ICML 2023), acrescentaram uma frase que nada tinha a ver com a
  pergunta a problemas de aritmética em texto, e os modelos que testaram erraram visivelmente mais.
- **Onde a resposta fica importa.** Liu e outros, em *Lost in the Middle: How Language Models Use Long
  Contexts* (TACL 2024), puseram o trecho com a resposta em posições diferentes entre muitos outros e
  viram que os modelos o usavam melhor no começo ou no fim da entrada, e pior no meio, inclusive
  modelos feitos para entradas longas.

Nenhum dos dois artigos mediu o seu modelo nos seus documentos, e os modelos mudaram desde então. Eles
são o motivo para tratar cada fonte a mais como custo até uma medição dizer o contrário, e o motivo de
existir a seção de posicionamento. O teste que decide isso para uma implantação real é o da aula 8,
rodado contra o modelo real com dois valores de `k`.
