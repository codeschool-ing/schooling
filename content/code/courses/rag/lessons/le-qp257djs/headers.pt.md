---
title: Cabeçalhos
version: 1
---

Cada fonte no prompt da aula 7 tem uma linha acima dela: o número, o caminho de títulos de onde veio e
a data em que o documento foi atualizado. O número torna a citação possível, o caminho diz a quem lê a
citação onde procurar, e a data foi o que deixou a aula 7 preferir a mais nova de duas fontes que
discordavam. Os três merecem o lugar. Eles também custam tokens, e ninguém tinha contado quantos:

```
ana@lab:~/rag$ python headers.py
headers 1499, texts 2380: headers are 39% of the sources' tokens
```

**39% dos tokens gastos com fontes foram gastos com cabeçalhos.** Nas 30 perguntas, empacotadas pelo
pipeline desta aula, os cabeçalhos somaram 1.499 tokens e o texto 2.380. Os caminhos de títulos são
longos: na primeira seção desta aula, o cabeçalho acima da seção de cartões-presente do documento de
pagamentos tinha 22 tokens antes de uma palavra da fonte, e a compressão piorou a proporção: encurtou
o texto e deixou o cabeçalho como estava.

Isso não quer dizer cortá-los; quer dizer **decidir para que serve cada parte de um cabeçalho**:

- **O número** fica. Sem ele não há citação, e as verificações da aula 7 não têm o que verificar.
- **A data** fica onde quer que duas fontes possam discordar, o que num acervo de políticas é em todo
  lugar. Uma fonte sem data não pode ser preferida a uma mais antiga.
- **O caminho** é o que se pesa. Quem lê uma citação precisa dele, mas quem lê uma citação é uma pessoa
  olhando a saída do programa, e o programa já tem o caminho: pode mostrá-lo ao lado da citação sem
  que o modelo o leia. Um pipeline que guarda a lista de fontes do seu lado pode mandar ao modelo
  `[1] (updated 2025-10-27)` e mostrar ao cliente o caminho inteiro.

O pipeline deste curso mantém o cabeçalho inteiro, porque a verificação de citações da aula 7 e o
teste da aula 8 foram construídos sobre ele, e mudá-lo agora mudaria duas coisas medidas de uma vez. O
número acima é o que uma equipe poria na balança contra isso, e é o tipo de número que só existe se
alguém contar as partes do prompt em vez do prompt.
