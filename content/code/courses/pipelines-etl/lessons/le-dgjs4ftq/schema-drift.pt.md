---
title: Quando a origem muda de forma
version: 1
---

Em 5 de março o arquivo da distribuidora chegou noutra codificação, com ponto e vírgula, cabeçalhos
em português e um formato de data brasileiro. O carregador da Ana tratou o dia anterior e parou
neste:

```
ana@vm:~/etl$ python load_stock.py inbox/stock_2026-03-04.csv
inbox/stock_2026-03-04.csv: 1200 rows loaded
ana@vm:~/etl$ python load_stock.py inbox/stock_2026-03-05.csv; echo "exit status $?"
Traceback (most recent call last):
  File "/home/ana/etl/load_stock.py", line 11, in <module>
    header = next(reader)
  File "<frozen codecs>", line 325, in decode
UnicodeDecodeError: 'utf-8' codec can't decode byte 0xed in position 11: invalid continuation byte
exit status 1
```

Ele parou, e esse é o resultado certo — mas leia a mensagem. O carregador tem uma verificação para
exatamente isto: ele compara o cabeçalho com o esperado e recusa com uma frase que cita os dois.
**A verificação nunca rodou.** Disseram ao Python que o arquivo era UTF-8, ele encontrou o byte
`0xED` — `í` em Latin-1, o `í` de `disponível` — e lançou erro antes de o cabeçalho ser lido. A falha
é barulhenta, e aponta o problema errado: quem está de plantão lê "codec can't decode" e vai
procurar um arquivo corrompido.

Duas lições nisso:

- **Ordene as verificações pelo que pode falhar primeiro.** Ler a primeira linha como bytes, antes
  de decodificar qualquer coisa, e compará-la com o cabeçalho esperado teria produzido a frase que
  foi escrita para esse dia.
- **Uma mensagem de falha é escrita para a pessoa que a lê às 3 da manhã**, não para o programador.
  "O cabeçalho da distribuidora agora é `isbn;disponível;data`" manda a pessoa para o telefone. Um
  traceback a manda para o código.

## Falhar, ou se adaptar?

A correção tentadora é um carregador que se adapta: detecta a codificação, fareja o separador,
mapeia `disponível` para `available` e interpreta os dois formatos de data. Cada passo é razoável, e
juntos eles fazem um pipeline que aceita **qualquer** mudança que o fornecedor faça, inclusive
aquela em que `disponível` agora significa outra coisa — estoque reservado, digamos, em vez de
estoque em mãos.

**Mudanças de forma são decisões, e um pipeline não deve tomá-las sozinho.** A regra que serve
melhor:

- **pare numa mudança de forma** — uma coluna renomeada, acrescentada, removida, com outro tipo — com
  uma mensagem que diga o que mudou;
- **deixe uma pessoa decidir**, quase sempre perguntando ao fornecedor o que aconteceu e se é
  permanente;
- **mude o carregador de propósito**, num commit que diga por quê, para que quem ler no ano que vem
  saiba que `disponível` foi um mapeamento deliberado e não um acidente.

A lição 16 dá um nome a essa regra — um **contrato de dados** — e um jeito de escrevê-la que o
próprio pipeline confere. O arquivo de 5 de março fica na caixa de entrada sem carregar; a
distribuidora do laboratório volta ao formato antigo no dia 6, o que fornecedores de verdade
raramente fazem.
