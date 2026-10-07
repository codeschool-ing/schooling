---
title: Quão parecidos são dois textos?
version: 1
---

**A correspondência aproximada troca "igual ou não" por uma nota de 0 a 100.** As notas deste curso
vêm do RapidFuzz, uma biblioteca Python que implementa as medidas padrão; o SQL tem as suas versões,
nas extensões `pg_trgm` e `fuzzystrmatch` do PostgreSQL, construídas sobre as mesmas ideias.

A medida básica é a **distância de edição**: quantas inserções, remoções e substituições de um
caractere transformam um texto no outro. O `ratio` do RapidFuzz a transforma num percentual dos dois
tamanhos. Duas variantes importam para nomes:

```
ana@lab:~/clean$ python -c "from rapidfuzz import fuzz; print(fuzz.ratio('ana lima', 'ana lmia'), fuzz.ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('ana lima', 'lima ana'), fuzz.token_sort_ratio('renato p. gomes', 'renato pires gomes'))"
87.5 50.0 100.0 84.84848484848484
```

- `ratio('ana lima', 'ana lmia')` dá 87.5: duas letras trocadas, o erro de quem digita com pressa.
- `ratio('ana lima', 'lima ana')` dá 50.0: as mesmas duas palavras na outra ordem, avaliadas como
  metade diferentes, porque a distância de edição lê da esquerda para a direita.
- `token_sort_ratio` ordena as palavras de cada texto antes de comparar, então o mesmo par dá 100.0.
  A ordem dos nomes varia entre formulários; esta medida não liga.
- `'renato p. gomes'` contra `'renato pires gomes'` dá 84.8: um nome do meio abreviado custa cerca de
  quinze pontos.

**Uma nota não é uma probabilidade.** 85 não quer dizer "85% de chance de ser a mesma pessoa"; quer
dizer que os textos são 85% parecidos por uma medida específica. Se 85 basta depende do arquivo, e o
único jeito de saber é olhar os pares perto do limite, ou — neste laboratório — contar contra a
verdade, o que a penúltima seção faz.

Qual medida usar decorre de como o campo erra: `ratio` simples para códigos e valores curtos em que a
ordem importa, `token_sort_ratio` para nomes e endereços em que as palavras mudam de lugar, e uma
comparação exata para o que nunca deve ser aproximado, como um e-mail ou um CEP depois de os dois
estarem na forma simples.
