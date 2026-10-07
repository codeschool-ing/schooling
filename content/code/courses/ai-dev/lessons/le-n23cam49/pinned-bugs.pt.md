---
title: Testes gerados fixam o que o código faz
version: 2
---

"Escreva testes para esta função" é um dos pedidos mais comuns a um assistente, e o resultado
parece exatamente o que foi pedido: um arquivo de testes, com bons nomes. **O que decide se eles
ajudam é de onde vieram os valores esperados.** Um teste escrito lendo o código descreve o código, e
o código inclui os bugs dele.

## Pedindo testes

A ana pede testes para o `apply_coupon`, com a versão com bug da aula 4 seção 02 ainda no lugar, e
pede os imports, porque um arquivo de testes que não consegue importar o que testa é a falha mais
comum de um arquivo gerado. O `--write` põe o bloco de código da resposta direto em
`tests/test_generated.py`. Depois ela lista o que ele testa, e toda linha que menciona o último dia
do cupom, antes de rodá-lo:

```
ana@dev:~/shop$ python scratch/assist.py ask "Write pytest tests for apply_coupon, including its end dates. Start the file with every import it needs." --open shop/coupons.py --write tests/test_generated.py > /dev/null
context sent (187 of 3000 tokens):
    187  shop/coupons.py
---
ana@dev:~/shop$ grep -n "^def test_\|10, 31" tests/test_generated.py
7:def test_apply_coupon_known_code():
12:def test_apply_coupon_unknown_code():
17:def test_apply_coupon_expired_code():
23:def test_apply_coupon_code_with_end_date():
25:    today = date(2026, 10, 31)
29:def test_apply_coupon_code_with_end_date_expired():
31:    today = date(2026, 10, 31)
35:def test_apply_coupon_code_with_end_date_not_set():
37:    today = date(2026, 10, 31)
ana@dev:~/shop$ python -m pytest -q tests/test_generated.py | tail -n 15
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_generated.py::test_apply_coupon_unknown_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_expired_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date - shop.c...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_expired
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_not_set
5 failed, 1 passed in 0.71s
```

Seis testes, e cinco falham. Veja com que cada um falha antes de decidir o que ele diz. O
`test_apply_coupon_code_with_end_date` falha com `ExpiredCoupon: FRIENDS15` (encurtado para
`shop.c...` no resumo): ele usa 31 de outubro, linha 25, e espera que o cupom funcione, então **ele
achou o bug**. O `test_apply_coupon_code_with_end_date_not_set`, o último do arquivo, também usa 31
de outubro, e o traceback acima do resumo é a falha dele: a mesma recusa, da mesma linha. Os outros
três são `NameError`, nomes que o arquivo usa e nunca importou, embora o pedido tenha pedido todos
os imports. E um desses três, o `test_apply_coupon_code_with_end_date_expired`, também usa 31 de
outubro, linha 31, e você vai ver na aula 4 seção 05 o que ele espera desse dia.

```
ana@dev:~/shop$ sed -i "1i from datetime import date" tests/test_generated.py && python -m pytest -q tests/test_generated.py | tail -n 15
        if code not in COUPONS:
            raise UnknownCoupon(code)
        percent, until = COUPONS[code]
        if until is not None and today >= until:
>           raise ExpiredCoupon(code)
E           shop.coupons.ExpiredCoupon: FRIENDS15

shop/coupons.py:25: ExpiredCoupon
=========================== short test summary info ============================
FAILED tests/test_generated.py::test_apply_coupon_unknown_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_expired_code - NameError: n...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date - shop.c...
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_expired
FAILED tests/test_generated.py::test_apply_coupon_code_with_end_date_not_set
5 failed, 1 passed in 0.70s
```

A ana acrescenta o import de `date`, o conserto de que um arquivo de testes gerado mais precisa.
Este arquivo já o tinha, e nada muda: as cinco falhas são dos outros dois tipos. **Então o arquivo
discorda de si mesmo sobre 31 de outubro**, e nada nele diz qual dos seus testes está certo. Essa é
a descrição honesta de um arquivo de testes gerado: uma lista de palpites sobre o que o código
deveria fazer, alguns lidos do próprio código, a conferir contra algo que não é o código.

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
