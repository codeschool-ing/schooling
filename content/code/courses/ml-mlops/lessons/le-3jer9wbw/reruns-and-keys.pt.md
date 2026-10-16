---
title: Rodando duas vezes, e lendo o que ficou gravado
version: 1
---

Jobs de lote são refeitos. Uma carga chega atrasada e a noite é pontuada de novo; alguém corrige um
bug e refaz a semana passada. **Um job que acrescenta dobraria a nota de cada membro na segunda
execução**, e todo relatório construído sobre a tabela os contaria duas vezes sem erro em lugar
nenhum. `score_batch.py` apaga a noite antes de gravá-la, dentro de uma transação, então refazer
substitui em vez de somar.

```
ana@dev:~/ml$ python score_batch.py 2026-02-28
3355 members scored as of 2026-02-28 by lapse version 1; 3355 rows in lapse_scores
ana@dev:~/ml$ sqlite3 -header -column scores.db "SELECT * FROM lapse_scores ORDER BY p_lapse DESC LIMIT 5"
member_id  cutoff      p_lapse  model_version
---------  ----------  -------  -------------
2291       2026-02-28  0.9431   1            
877        2026-02-28  0.9292   1            
1920       2026-02-28  0.9214   1            
2443       2026-02-28  0.8971   1            
4539       2026-02-28  0.8853   1            
```

A segunda execução gravou as mesmas 3.355 linhas e a tabela continua com 3.355: **o job é
idempotente**, a palavra para um passo que deixa o mesmo resultado não importa quantas vezes rode. A
consulta é a que o marketing rodaria, os membros com mais chance de se afastar, cada um com a data
de
corte e a versão que o pontuou. Quando a versão 2 assumir, as linhas dela dirão isso, e um relatório
que mistura duas versões no mesmo mês consegue distinguir uma da outra.

**A tabela cresce uma noite de cada vez, e isso é proposital.** As notas do mês que vem não
sobrescrevem as deste mês, porque a lição 9 precisa das duas. As notas de 28 de fevereiro,
comparadas com o que os membros de fato fizeram nos 90 dias seguintes, são o boletim do modelo, e só
podem ser lidas se tiverem sido guardadas.
