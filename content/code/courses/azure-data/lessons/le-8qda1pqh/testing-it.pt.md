---
title: Testando uma transformação antes que ela encontre a noite
version: 1
---

**Uma transformação escrita como código pode ser testada em quatro linhas, num laptop, em um segundo;
uma transformação desenhada como data flow é testada rodando-a num cluster.** Essa diferença decide
mais escolhas entre os dois do que qualquer outra, e esta seção a mostra. Ela roda no seu computador
e não precisa de emulador, porque a função testada não toca em armazenamento nenhum.

As quatro linhas são escolhidas para quebrar cada regra uma vez: um pedido enviado duas vezes, uma
forma de pagamento em maiúsculas com espaços em volta, um total com um dígito decimal, `9,5`, e um
pedido tarde da noite. Salve o teste ao lado do `clean.py`:

`test_clean.py`:

```python
"""test_clean.py: the transformation's rules, checked on four rows, with no storage at all."""
import pyarrow as pa

from clean import clean

raw = pa.table({
    "order_id": ["1001-00002", "1001-00001", "1001-00001", "1001-00003"],
    "created_at": ["2026-10-01 07:18", "2026-10-01 07:04", "2026-10-01 07:04", "2026-10-01 21:59"],
    "customer_id": ["c-2", "c-1", "c-1", "c-3"],
    "neighbourhood": ["Moema", "Penha", "Penha", "Lapa"],
    "payment": [" PIX ", "credit", "credit", "Meal-Voucher"],
    "total": ["42,87", "9,5", "9,5", "1234,00"],
})
out = clean(raw).to_pylist()
assert [o["order_id"] for o in out] == ["1001-00001", "1001-00002", "1001-00003"], "one row per order"
assert [o["payment"] for o in out] == ["credit", "pix", "meal-voucher"], "payment in lower case"
assert [o["hour"] for o in out] == [7, 7, 21], "the hour of the order"
assert [o["total_cents"] for o in out] == [950, 4287, 123400], "totals in cents"
print("4 checks passed")
```

```
ana@laptop:~/azure$ python test_clean.py
4 checks passed
ana@laptop:~/azure$ sed -i "s/replace(total, ',', '.')/replace(total, ',', '')/" clean.py && python test_clean.py 2>&1 | tail -1; sed -i "s/replace(total, ',', '')/replace(total, ',', '.')/" clean.py
AssertionError: totals in cents
```

**O segundo comando comete um erro que alguém poderia cometer de propósito**: tirar a vírgula em vez
de trocá-la por ponto, o que parece um atalho sensato. Em todo total com dois dígitos decimais ele dá
o número certo, então o export da noite, onde a loja sempre escreve dois, carregaria sem reclamar. A
quarta linha é a que o pega: `9,5` vira `95` reais em vez de `9,50`, e o teste diz o nome da regra que
quebrou. O `sed` do fim põe a linha certa de volta.

## Por que um data flow não consegue fazer isso

**Um mapping data flow tem um modo de debug, e ele roda num cluster.** Você o liga no editor, o Data
Factory inicia um cluster Spark para a sessão, e cada transformação mostra uma prévia de linhas
enquanto é construída. É uma boa ferramenta para olhar dados, e é cobrada enquanto a sessão está
ligada. O que ela não é é um teste: nada nela roda de novo, nas mesmas quatro linhas, toda vez que o
data flow muda, reprovando a mudança quando uma regra quebra. Um time consegue testar um data flow
rodando o pipeline inteiro contra um conjunto pequeno de dados numa factory de desenvolvimento e
comparando a saída, o que funciona e leva minutos e um cluster a cada vez.

**Código num notebook pode ser testado do jeito que este arquivo é**, se for escrito do jeito que o
`clean.py` é: as regras em funções, o armazenamento na borda. Um notebook que lê, limpa e grava numa
célula longa é tão difícil de testar quanto um data flow, e a disciplina que o torna testável é de
quem escreve, não da ferramenta. Notebooks do Fabric, do Synapse e do Databricks podem viver no Git,
e a lição 17 de `pipelines-etl` trata de testar um pipeline com mais profundidade do que este curso
consegue.
