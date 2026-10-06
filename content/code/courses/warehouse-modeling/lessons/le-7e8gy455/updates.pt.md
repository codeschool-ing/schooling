---
title: Mudando uma linha numa tabela de arquivos
version: 1
---

A lição 6 corrigiu um erro de caixa no warehouse: a terceira linha do pedido 112406 tinha sido registrada R$ 10,00
acima. A mesma correção, na tabela Delta:

```python
"""Correct one sale line, the till error of lesson 6, as a Delta update."""
from deltalake import DeltaTable

table = DeltaTable("lake/sales")
result = table.update(
    updates={"net_cents": "net_cents - 1000", "gross_cents": "gross_cents - 1000"},
    predicate="order_id = 112406 AND line_no = 3",
)
print(result)
```

```
ana@lab:~/wh$ python fix_line.py
{'num_added_files': 1, 'num_removed_files': 1, 'num_updated_rows': 1, 'num_copied_rows': 404066, 'execution_time_ms': 193, 'scan_time_ms': 11}
ana@lab:~/wh$ jq -c 'keys[0]' lake/sales/_delta_log/00000000000000000002.json
"commitInfo"
"add"
"remove"
ana@lab:~/wh$ python read_sales.py
version 2: 2 files, 887477 rows, net_cents 9574388852
```

O resumo é a conta honesta do que custa um update numa tabela de arquivos imutáveis. **Uma linha foi atualizada, e
404.066 foram copiadas**: o arquivo inteiro de 2024 foi lido, a linha mudou, e um arquivo novo foi gravado com todas
elas. O commit 2 tem um `add` para o arquivo novo e um `remove` para o antigo. A tabela continua com dois arquivos, um
novo para 2024 e o de 2025 intocado, e o total está 1.000 centavos menor, como a correção pretendia.

Essa estratégia se chama **copy on write**, cópia na escrita: uma mudança regrava todo arquivo que toca. Ela deixa a
leitura simples e rápida, porque o leitor só vê arquivos completos, e deixa mudanças pequenas caras, porque mudar uma
linha de um arquivo grande regrava o arquivo. Duas coisas suavizam isso:

- **Arquivos menores, por partição.** Só o arquivo de 2024 foi regravado, porque a mudança não tocou nada em 2025.
- **Vetores de deleção** (deletion vectors), que as versões mais novas dos formatos suportam: em vez de regravar um
  arquivo para remover algumas linhas, o commit registra uma lista pequena de posições a ignorar, e a regravação fica
  para quando o arquivo for compactado. É a abordagem **merge on read**, que a seção 11 diz ter sido a especialidade do
  Hudi.

**Nada foi apagado do disco.** O arquivo antigo de 2024 ainda está na sua pasta; o commit 2 só diz que ele não faz
mais parte da versão atual. A próxima seção usa exatamente isso.
