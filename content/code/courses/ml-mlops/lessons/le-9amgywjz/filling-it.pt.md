---
title: Enchendo a store: um backfill e uma fotografia por noite
version: 1
---

Um armazenamento vazio não responde nada, então o primeiro trabalho é um **backfill**: calcular os
atributos de dias passados, como teriam sido calculados naqueles dias. Depois, de hoje em diante,
uma **fotografia** (*snapshot*) por noite o mantém atualizado.

```
ana@dev:~/ml$ python featurestore.py backfill 2025-06-01 2026-02-22
39 snapshots, 116285 rows in the offline store
ana@dev:~/ml$ python featurestore.py snapshot 2026-02-28
2026-02-28: 3355 members
ana@dev:~/ml$ ls -lh features.db
-rw-r--r-- 1 ana ana 11M Oct 10 16:44 features.db
```

Trinta e nove domingos, de 1º de junho de 2025 a 22 de fevereiro de 2026, depois hoje à noite,
sábado, 28 de fevereiro. Cada fotografia guarda os membros ativos naquele dia, então as contagens
crescem e encolhem com a loja: 3.355 hoje. O armazenamento offline guarda 116.285 linhas do backfill
e mais 3.355 de hoje, e o `ls` dá o tamanho do arquivo.

**O backfill só está certo porque o `features.py` calcula tudo em relação ao corte.** Ele lê as
compras até cada domingo e não além, então uma fotografia tirada hoje para junho passado é a mesma
que teria sido tirada em junho passado. Um backfill feito a partir de uma tabela de resumo encheria o
passado com os valores de hoje, e todo conjunto de treino tirado dele carregaria o vazamento da lição
3.

**Por que semanal no passado e por noite daqui em diante?** Custo contra necessidade. Os dois cortes
com que este curso treina e testa, 31 de agosto e 30 de novembro de 2025, são domingos, então a
história semanal os cobre; o serviço precisa dos valores de hoje. Uma store que quisesse qualquer dia
do passado tiraria fotografias diárias, com sete vezes as linhas. Escolher a cadência é escolher o
quão velha uma linha de treino pode ser, e a próxima seção mostra como isso aparece.
