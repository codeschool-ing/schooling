---
title: Devolvendo a evidência
version: 1
---

A primeira resposta raramente é a última, e a pergunta útil é o que mandar de volta. "Está errado,
tente de novo" não dá nada de novo ao modelo; ele vai produzir uma variação do mesmo chute. **Mande
a evidência de que estava errado**: o teste que falhou, o erro, a saída, exatamente como as
ferramentas imprimiram. É a regra da aula 5 seção 03, aplicada à segunda rodada.

## A falha, literal

```
ana@dev:~/shop$ python -m pytest -q tests/test_comma.py 2>&1 | grep -A3 "def test_a_price_with_both" | head -4; python -m pytest -q tests/test_comma.py 2>&1 | tail -2 > failure.txt
    def test_a_price_with_both_a_dot_and_a_comma_is_refused():
>       with pytest.raises(ValueError):
E       Failed: DID NOT RAISE ValueError

```

A ana manda a falha de volta com o requisito que ela quebra, dito uma vez, e pede um diff contra o
arquivo como está agora, já que o primeiro diff foi aplicado:

```
ana@dev:~/shop$ assist ask "Your change to parse_price fails this test, which must pass: parse_price(\"1.234,56\") must raise ValueError. pytest says: $(cat failure.txt). Reply with a unified diff against the current shop/money.py." --open shop/money.py tests/test_comma.py > second.diff
context sent (238 of 3000 tokens):
    141  shop/money.py
     97  tests/test_comma.py
---
ana@dev:~/shop$ cat second.diff
diff --git a/shop/money.py b/shop/money.py
index 3eb6322..b9a7ed0 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -2,8 +2,11 @@
 
 
 def parse_price(text: str) -> int:
-    """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().replace(",", ".").partition(".")
+    """Turn a price as people write it into cents: '12.90' or '12,90' -> 1290."""
+    text = text.strip().replace(",", ".")
+    units, _, cents = text.partition(".")
+    if not units.lstrip("-").isdigit() or not (cents == "" or cents.isdigit()) or len(cents) > 2:
+        raise ValueError(f"not a price: {text!r}")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 

```

O segundo diff, escrito pelo curso, mantém o tratamento da vírgula e acrescenta a checagem que o
plano pedia: unidades só com dígitos, centavos com no máximo dois dígitos, senão `ValueError`.
Aplicado, com a suíte inteira rodando, não só o arquivo novo:

```
ana@dev:~/shop$ git apply second.diff && python -m pytest -q
.............                                                            [100%]
13 passed in 0.55s
```

Treze testes: os oito que o projeto tinha e os cinco novos.

## Quando parar de iterar

- **Quando os testes passam**, e é por isso que foram escritos primeiro. Sem eles, "pronto" é uma
  sensação.
- **Quando a mesma falha volta duas vezes.** Um modelo que não corrige algo na segunda tentativa,
  com a evidência na mão, raramente corrige na quinta. O problema costuma ser contexto que falta (um
  arquivo que ele não viu) ou um requisito que contradiz outro. Leia o código você mesmo, ou mude o
  que manda.
- **Quando os diffs crescem.** Uma correção que mexe em mais coisas a cada rodada está se afastando
  do problema. Volte ao último estado bom e faça uma pergunta mais estreita.

Cada rodada é uma requisição, e a aula 2 seção 06 vale: uma conversa que leva todas as tentativas
anteriores fica mais cara a cada turno. Começar uma requisição nova com o código atual e a falha
atual muitas vezes é ao mesmo tempo mais barato e melhor.
