---
title: Nomeie o que é permitido, e não o que é proibido
version: 1
---

Dois tipos de lista atravessam este curso. Uma **lista de bloqueio** nomeia o que é recusado: a lista de
palavras da moderação da aula 6, a lista de frases da aula 8. Uma **lista permitida** nomeia o que é
aceito e recusa todo o resto: as categorias e os campos da aula 9, os hosts, o snapshot de registro da
aula 2. Elas falham em direções opostas, e a diferença aparece em dois comandos:

```
ana@lab:~/guard$ guard moderate 'Shut up, you clown'
{"harassment": 0.84, "threat": 0.0, "spam": 0.0}
ana@lab:~/guard$ guard moderate 'Shut up, you cl0wn'
{"harassment": 0.6, "threat": 0.0, "spam": 0.0}
ana@lab:~/guard$ guard check-in data/inputs.jsonl | grep in-4
in-4   REJECT  category: 'photography' is not one of design, development, writing, translation, marketing
```

A lista de bloqueio perdeu boa parte de uma palavra para um zero: *clown* deixou de contar e o score caiu
de 0.84 para 0.60. **Uma lista de bloqueio falha aberta**: o que ela não previu passa. A lista permitida
recusou `photography`, que ninguém escreveu como proibido. **Uma lista permitida falha fechada**: o que ela
não previu é barrado, e o custo é um valor legítimo recusado até alguém acrescentá-lo.

Essa assimetria dá a regra prática:

- **Onde o conjunto de valores bons é pequeno e conhecido, use uma lista permitida.** Categorias, campos,
  hosts, pacotes, ferramentas. Cada recusa é visível, diz o que é permitido, e se conserta acrescentando
  uma entrada.
- **Onde os valores bons são abertos, uma lista de bloqueio é a única opção**, e ela é tratada como sinal e
  não como garantia. Texto livre é o caso: ninguém lista toda frase aceitável, então a moderação pontua e
  uma pessoa revisa a faixa duvidosa, como na aula 6.

O erro a evitar é uma lista de bloqueio onde uma lista permitida era possível. Um filtro de links que
bloqueia hosts ruins conhecidos precisa saber de cada host ruim antes de ele aparecer; um que permite só
os hosts da própria Tarefa só precisa conhecer a Tarefa.
