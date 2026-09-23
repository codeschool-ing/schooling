---
title: Três jeitos de ler, e o que escala
version: 2
---

```python
text = f.read()         # the whole file, as one string
lines = f.readlines()   # the whole file, as a list of strings
for line in f:          # one line at a time
```

Os dois primeiros põem o arquivo inteiro na memória. O terceiro não, e essa é a única diferença que
importa.

## Iterar o objeto de arquivo

```python
with open(path, encoding="utf-8") as f:
    for line in f:
        process(line.rstrip("\n"))
```

Um arquivo de quatro gigabytes custa uma linha de memória. `f.read()` no mesmo arquivo custa quatro
gigabytes — e o programa não falha com educação, ele é morto.

**A linha mantém o `\n` dela**, porque senão não daria para distinguir uma linha em branco do fim
do arquivo. `rstrip("\n")` o tira; `.strip()` tira os espaços também, que em geral é o que você quer
e de vez em quando esconde uma coluna de strings vazias.

## Gravar

```python
with open(path, "w", encoding="utf-8") as f:
    f.write("name,city\n")
    f.writelines(lines)      # no newlines are added
```

O `write` recebe uma string e não acrescenta nada — sem quebra de linha, sem separador. O
`writelines` tem nome ruim: ele grava uma sequência de strings e continua não acrescentando nada,
então as quebras precisam já estar nelas.

`print(..., file=f)` é a versão que acrescenta a quebra, e é um jeito perfeitamente bom de gravar
um arquivo de texto.

## Ler parte dele

```python
f.readline()        # one line
f.read(1024)        # at most 1024 characters
```

Útil para um cabeçalho, uma espiada na primeira linha, ou um formato que não é por linhas. **Um
arquivo tem uma posição**, e tudo acima a move — que é por que um `for line in f:` depois de um
`f.read()` dá nada, sem erro nenhum.

`f.seek(0)` volta ao começo, e precisar dele duas vezes em geral é sinal de que você queria o dado
numa lista.
