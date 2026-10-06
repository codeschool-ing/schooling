---
title: Cobertura das linhas que a mudança tocou
version: 1
---

Um total se move devagar. Num projeto grande, uma mudança que acrescenta quarenta linhas sem teste
mal mexe na porcentagem, e quem revisa lendo "cobertura 81% → 80%" não aprende nada sobre a mudança à
sua frente. A pergunta útil para um pull request é mais estreita: **os testes rodaram as linhas que
esta mudança acrescentou?**

Aqui uma sobretaxa para encomendas pesadas entra em `freight`, duas linhas, e nenhum teste:

```python
    if weight_g > 30_000:           # heavy parcels go by road freight
        return BASE[zone] * 3 + extra * EXTRA_PER_500G
```

```
ana@laptop:~/shipquote$ git diff --stat
 shipquote/quote.py | 2 ++
 1 file changed, 2 insertions(+)
ana@laptop:~/shipquote$ coverage run -m pytest -q | tail -1; coverage report | tail -1
41 passed, 2 skipped in 1.67s
TOTAL                     166     33     26      5    80%
ana@laptop:~/shipquote$ coverage report -m --include=shipquote/quote.py
Name                 Stmts   Miss Branch BrPart  Cover   Missing
----------------------------------------------------------------
shipquote/quote.py      21      1      8      1    93%   30
----------------------------------------------------------------
TOTAL                   21      1      8      1    93%
```

O total foi de **81% para 80%**. No arquivo, o relatório aponta a linha 30, o `return` novo, como
nunca executada. O `if` acima dela rodou, porque toda cotação passa por ele, então um relatório só de
linhas diria que metade da mudança estava testada. **Do comportamento novo, nada foi testado**:
nenhum teste manda uma encomenda acima de 30 kg, e o preço dela poderia ser qualquer coisa.

## Transformando em verificação

Essa comparação, as linhas que um diff acrescentou contra as linhas que a cobertura viu rodar, é o
que ferramentas chamadas de *diff coverage* ou *patch coverage* calculam. O `diff-cover` lê um
relatório de cobertura e um `git diff` e imprime as linhas mudadas sem cobertura; serviços
hospedados como Codecov e Coveralls mostram a mesma coisa como comentário no pull request. Uma equipe
que quer uma barreira de cobertura costuma ser mais bem servida por uma sobre a mudança do que sobre
o total:

- ela pede algo **à pessoa que fez a mudança**, sobre **a mudança dela**, que ela consegue
  responder;
- não pune uma mudança por código antigo sem teste que ela não tocou;
- não pode ser satisfeita com um teste em outro lugar, como o total pode.

Ela tem a mesma fraqueza de toda barreira de cobertura: linhas que rodaram não são linhas
conferidas. Na revisão, a pergunta depois de "o código novo está coberto?" continua sendo "o que o
teste verifica?".

## Lendo um relatório na revisão

Seja qual for a ferramenta, o hábito é o mesmo. Para cada arquivo mudado, olhe a coluna **Missing**
ao lado do diff. Uma linha faltando num ramo que a mudança acrescentou é um teste a escrever, ou uma
decisão, por escrito, de que o caminho não vale um. A sobretaxa acima é um preço, então é o primeiro
caso.
