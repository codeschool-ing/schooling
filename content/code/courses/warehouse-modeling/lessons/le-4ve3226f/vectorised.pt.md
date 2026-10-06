---
title: Vetores, não linhas
version: 1
---

Ler menos explica parte da diferença de quarenta vezes da seção 04. O resto é como o motor faz a
aritmética depois que os dados estão na memória.

Um motor tradicional por linhas processa **uma linha de cada vez**: busca uma linha, extrai `net_cents`,
soma ao total, busca a próxima. Para cada linha, uma cadeia de chamadas de função, verificações e desvios,
em que a soma é a menor parte.

Um motor colunar processa **um vetor de cada vez**: um lote de valores de uma coluna, de 2.048 no DuckDB,
entregue a um laço apertado que soma todos. Três coisas tornam isso rápido nos processadores modernos:

- **Menos custo fixo por valor.** As chamadas de função e verificações acontecem uma vez por vetor, e não
  uma vez por linha.
- **Os valores estão contíguos na memória**, então o cache do processador fica cheio dos dados que ele vai
  usar, e não das outras colunas da linha.
- **O processador consegue trabalhar em vários valores numa instrução.** Processadores modernos têm
  instruções que somam quatro ou oito números de uma vez, e um laço sobre um vetor contíguo de inteiros é
  exatamente para o que elas servem.

Mais duas técnicas costumam vir junto:

- **Trabalhar sobre dados comprimidos.** Um filtro numa coluna codificada por dicionário pode comparar os
  códigos pequenos em vez das strings, e uma soma sobre uma coluna em RLE pode multiplicar cada valor pelo
  tamanho da sua sequência.
- **Materialização tardia.** Uma consulta que filtra por uma coluna e devolve outra lê primeiro a coluna do
  filtro, descobre que linhas sobrevivem, e só então busca a outra coluna para essas linhas.

Nada disso muda o que uma consulta significa; muda o que ela custa, e por isso a lição 6 conseguiu medir
uma junção e a ausência dela quase na mesma velocidade.
