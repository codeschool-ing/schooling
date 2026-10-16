---
title: Pré-processamento ajustado em tudo
version: 1
---

A quarta forma é a mais silenciosa. **Todo passo de pré-processamento que aprende algo com os dados é
um pequeno modelo**, e ele vaza se aprender com as linhas de teste.

O `StandardScaler` aprende uma média e uma dispersão por coluna. Ajustado em todas as linhas antes da
divisão, ele viu os valores das linhas de teste, e as linhas de treino são postas em escala com esse
conhecimento. O `OneHotEncoder` aprende quais valores existem, então ajustado em tudo ele sabe de uma
categoria que só aparece no período de teste. Um passo que preenche valores faltantes com a média
aprende essa média das linhas que receber.

Para o scaler, com três mil linhas de dados estáveis, o efeito numa nota é pequeno demais para ser
medido com honestidade, e esta lição não finge o contrário com um número. **Dois passos de
pré-processamento vazam muito, e os dois são comuns:**

- **target encoding**, que troca uma categoria pela média do rótulo das linhas que a têm, então
  "loja de referência Paulista" vira "0,21". Ajustado em todas as linhas, ele escreve os rótulos de
  teste dentro dos atributos;
- **seleção de atributos pela correlação com o rótulo**, feita uma vez sobre todos os dados antes da
  divisão, que escolhe as colunas que por acaso se encaixam nas linhas de teste também.

**A proteção é estrutural, e a lição 2 já a usou.** O `classify.py` pôs o scaler e o codificador
dentro do pipeline junto com o modelo, então o `fit` nas linhas de treino ajusta os três e o
`predict_proba` em linhas novas só os aplica. Nada pode ser ajustado nas linhas de teste porque nada
é ajustado fora do `fit`. Quando um engenheiro de dados recebe código de pré-processamento para pôr
em produção, a pergunta a fazer é se as transformações fazem parte do objeto do modelo ou foram
calculadas num notebook antes. **Só a primeira opção pode ser treinada de novo do mesmo jeito duas
vezes.**
