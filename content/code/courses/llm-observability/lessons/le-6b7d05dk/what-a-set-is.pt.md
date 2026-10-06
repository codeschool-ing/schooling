---
title: O que é um conjunto de avaliação
version: 1
---

As aulas 8 a 12 avaliaram as mesmas trinta perguntas várias vezes: o `data/eval.jsonl`, que a aula 8 de
`rag` escreveu para medir a recuperação. Cada linha é um **caso**: um id, uma pergunta, as seções dos
documentos que a respondem (`gold`) e os fatos que uma resposta certa contém. Quatro dos trinta não têm
gold nem fatos; a resposta certa a esses é a recusa.

Esse arquivo é um **conjunto de avaliação**, e é uma coisa diferente de tudo o que a aula 9 amostrou.
Uma amostra do tráfego diz como o assistente foi na semana passada, no que os clientes calharam de
perguntar. Um conjunto de avaliação faz **as mesmas perguntas a toda versão**, para que duas versões
possam ser comparadas em pé de igualdade, que é o trabalho da aula 14, e para que um build possa ser
reprovado quando uma piora, que é o da aula 15.

Quatro propriedades tornam um conjunto apto para isso, e esta aula é sobre mantê-las:

- **Todo caso tem um id que nunca muda e nunca é reaproveitado.** Resultados, rótulos e comparações
  nomeiam casos por id. Um conjunto renumerado compara perguntas diferentes em silêncio.
- **Toda resposta esperada é verdade segundo os documentos.** Um caso cujo fato a loja mudou desde então
  reprova toda versão, e logo ninguém confia nas reprovações.
- **O conjunto não guarda dados de ninguém.** Ele é copiado para toda execução, todo relatório e todo
  pull request, então o que estiver nele vai para todo lugar.
- **O conjunto é fixado.** Todo resultado diz de que versão do conjunto veio, e uma versão é um arquivo
  fixo cujo hash pode ser conferido.

Os trinta casos do `rag` foram escritos por pessoas lendo os documentos. É um bom começo e um mau fim:
são as perguntas que alguém achou que os clientes fariam, escritas do jeito que alguém escreve. A
próxima seção acrescenta as perguntas que os clientes fizeram.
