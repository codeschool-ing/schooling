---
title: Testes gerados fixam o que o código faz
version: 1
---

"Escreva testes para esta função" é um dos pedidos mais comuns a um assistente, e o resultado
parece exatamente o que foi pedido: um arquivo de testes, com bons nomes, que passam. **Que passem é
o problema.** Um teste escrito lendo o código descreve o código, e o código inclui os bugs dele.

## Pedindo testes

A ana pede testes para o `apply_coupon`, com a versão com bug da aula 4 seção 02 ainda no lugar. A
resposta, escrita pelo curso para parecer um arquivo de testes gerado típico, vai direto para
`tests/test_generated.py`:

```
ana@dev:~/shop$ assist ask "Write pytest tests for apply_coupon." --open shop/coupons.py > tests/test_generated.py
context sent (187 of 3000 tokens):
    187  shop/coupons.py
---
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py
....                                                                     [100%]
4 passed in 0.54s
```

Os quatro passam, num código com um bug conhecido. Este é o que não devia passar:

```
ana@dev:~/shop$ grep -n -A2 "def test_friends15" tests/test_generated.py
21:def test_friends15_expires_on_2026_10_31():
22-    with pytest.raises(ExpiredCoupon):
23-        apply_coupon(Cart(), "FRIENDS15", today=date(2026, 10, 31))
```

O `test_friends15_expires_on_2026_10_31` afirma que o cupom é recusado no último dia válido. **O
teste é o bug, escrito como requisito.** Ele foi tirado de `today >= until`, então concorda com
`today >= until`, e vai falhar no dia em que alguém corrigir o código. A aula 4 seção 05 mostra
exatamente isso acontecendo.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Dois lugares de onde o valor esperado de um teste pode vir. Da especificação, os termos do cupom, um teste diz que o dia 31 é válido; contra o código com bug ele falha, e o bug é achado. Do próprio código, today &gt;= until, um teste gerado diz que o dia 31 é recusado; contra o código com bug ele passa, e o bug fica registrado.\"><defs><marker id=\"sr-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a especificação</text><text x=\"125.0\" y=\"66.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">válido até 31 de outubro, inclusive</text><rect x=\"20\" y=\"140\" width=\"210\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"125.0\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o código</text><text x=\"125.0\" y=\"176.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">today &gt;= until</text><rect x=\"280\" y=\"38\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">teste: o dia 31 é válido</text><rect x=\"280\" y=\"148\" width=\"190\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"375.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">teste: o dia 31 é recusado</text><path d=\"M232 58 L276 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M232 168 L276 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M472 58 L516 58\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><path d=\"M472 168 L516 168\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#sr-ah)\"></path><text x=\"522\" y=\"58\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">falha: o bug é achado</text><text x=\"522\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">passa: o bug é fixado</text></svg>", "caption": "De onde vem o valor esperado decide o que um teste verde quer dizer. Os dois testes rodam contra a mesma linha com bug."}
```

## Por que isso acontece

Um modelo a quem se pede que teste uma função tem duas coisas contra as quais testar: o que a função
deve fazer, e o que a função faz. Ele só tem a segunda, porque o código está no contexto e a
intenção em geral não está. Então faz o razoável com o que tem, e escreve o que o código faz, com
casos de borda e com bugs. Uma pessoa que escreve testes lendo a implementação produz o mesmo
arquivo.

Testes gerados não são inúteis. Duas coisas para as quais servem:

- **Registrar o comportamento antes de uma refatoração**, o trabalho da aula 3 seção 06: quando o
  objetivo é "nada muda", um teste do que o código faz agora é exatamente o teste certo, com bugs e
  tudo.
- **Uma lista inicial de casos em que pensar.** Ler um arquivo de testes gerado é um jeito rápido de
  ver para que entradas a função tem ramos. Cada caso é então conferido contra a especificação, e
  os valores esperados vêm dela.

O que eles não são é evidência de que o código está certo. Uma suíte gerada e verde diz que o
código faz o que faz.
