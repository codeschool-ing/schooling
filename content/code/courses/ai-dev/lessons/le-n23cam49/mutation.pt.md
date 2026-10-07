---
title: Os testes pegam alguma coisa?
version: 2
---

Uma suíte de testes pode estar verde e testar quase nada. A aula 3 seção 06 mostrou isso: oito
testes passando, e uma mudança que não fazia o que foi pedido passou direto, como passaria a que
mudava o que o cliente paga, que o mesmo pedido produziu em outra execução. A cobertura, a
fração de linhas que os testes executam, teria contado toda linha do `shipping()` como coberta, porque todo
teste a executa. **Executar uma linha não é o mesmo que conferir o que ela faz.**

O **teste de mutação** faz a pergunta direta. Mude o código de propósito, uma mudança pequena por
vez (um `>=` vira `>`, um `-` vira `+`), e rode os testes depois de cada uma. Uma mudança que os
testes notam é *morta*. Uma que não notam *sobreviveu*, e cada sobrevivente é um comportamento do
código que nenhum teste fixa.

## Um testador de mutação em quarenta linhas

Existem bibliotecas para isso, e num projeto grande você usaria uma. A ideia cabe num script curto,
então a ana o escreve, como `~/shop/scratch/mutate.py`, o que também deixa todo resultado legível. Ele troca um operador de
comparação ou de aritmética por vez, roda a suíte inteira e restaura o arquivo:

```python
"""Change one operator at a time, run the tests, and report the changes nobody noticed."""
import ast
import pathlib
import subprocess
import sys

SWAP = {ast.Gt: ast.GtE, ast.GtE: ast.Gt, ast.Lt: ast.LtE, ast.LtE: ast.Lt,
        ast.Add: ast.Sub, ast.Sub: ast.Add, ast.FloorDiv: ast.Div}
NAME = {ast.Gt: ">", ast.GtE: ">=", ast.Lt: "<", ast.LtE: "<=", ast.Add: "+", ast.Sub: "-",
        ast.FloorDiv: "//", ast.Div: "/"}

path = pathlib.Path(sys.argv[1])
original = path.read_text()


def operators(tree):
    for node in ast.walk(tree):
        ops = node.ops if isinstance(node, ast.Compare) else [node.op] if isinstance(node, ast.BinOp) else []
        for k, op in enumerate(ops):
            if type(op) in SWAP:
                yield node, k, op


survived = 0
for i in range(len(list(operators(ast.parse(original))))):
    tree = ast.parse(original)
    node, k, op = list(operators(tree))[i]
    new = SWAP[type(op)]()
    if isinstance(node, ast.Compare):
        node.ops[k] = new
    else:
        node.op = new
    path.write_text(ast.unparse(tree))
    run = subprocess.run([sys.executable, "-m", "pytest", "-q", "-x", "-p", "no:cacheprovider"],
                         capture_output=True)
    verdict = "killed" if run.returncode else "SURVIVED"
    survived += verdict == "SURVIVED"
    print(f"{path}:{node.lineno}  {NAME[type(op)]:>2} -> {NAME[type(new)]:<2}  {verdict}")
path.write_text(original)
print(f"{survived} survived")
```

Rodando nos dois arquivos da loja, com os testes que o projeto tinha antes desta aula mais os que
ganhou nela:

```
ana@dev:~/shop$ python scratch/mutate.py shop/cart.py
shop/cart.py:20   < -> <=  killed
shop/cart.py:32  // -> /   SURVIVED
shop/cart.py:35  >= -> >   killed
shop/cart.py:40   + -> -   killed
shop/cart.py:35   - -> +   SURVIVED
shop/cart.py:40   - -> +   SURVIVED
3 survived
ana@dev:~/shop$ python scratch/mutate.py shop/coupons.py
shop/coupons.py:24   > -> >=  killed
0 survived
```

**Três sobreviventes no `cart.py`, nenhum no `coupons.py`.** O `>` do cupom foi morto pelos testes
de limite da aula 4 seção 05, que foram escritos para isso. Os três do carrinho são três regras que
ninguém testa:

- **linha 32, `//` para `/`**: o desconto poderia virar fração de centavo e nada falharia. Todo
  desconto testado por acaso dá conta exata, então divisão inteira e divisão real concordam.
- **linha 35, `-` para `+`**: o limite do frete grátis poderia somar o desconto em vez de
  subtraí-lo. O teste da aula 3 seção 06 guarda isso, e este branch não tem esse teste.
- **linha 40, `-` para `+`**: o total poderia somar o desconto em vez de subtraí-lo, a mudança que o
  assistente da aula 3 seção 06 fez em outra execução. Nenhum teste tem um desconto e confere o total.

## Matando-os

Dois testes, cada um escrito a partir de uma regra que a loja tem, fecham os três:

```python
from datetime import date

from shop.cart import Cart
from shop.coupons import apply_coupon


def test_a_discount_rounds_down_to_a_whole_cent():
    cart = Cart()
    cart.add("MUG-01", 3990)
    apply_coupon(cart, "FRIENDS15", today=date(2026, 10, 2))
    assert cart.discount() == 598  # 15% of 39.90 is 5.985


def test_free_shipping_threshold_is_checked_after_the_discount():
    cart = Cart()
    cart.add("LAMP-02", 21000)
    apply_coupon(cart, "WELCOME10", today=date(2026, 10, 2))
    assert cart.total() == 21000 - 2100 + 1500
```

```
ana@dev:~/shop$ python -m pytest -q tests/test_cart_rules.py && python scratch/mutate.py shop/cart.py
..                                                                       [100%]
2 passed in 0.73s
shop/cart.py:20   < -> <=  killed
shop/cart.py:32  // -> /   killed
shop/cart.py:35  >= -> >   killed
shop/cart.py:40   + -> -   killed
shop/cart.py:35   - -> +   killed
shop/cart.py:40   - -> +   killed
0 survived
```

**0 survived.** Os valores esperados vêm das regras, não de rodar o código: 15% de 39,90 é 5,985, e
a loja arredonda um desconto para baixo até um centavo inteiro, então 598.

## Para que serve

- **Achar os testes a escrever**, em especial depois de um assistente gerar uma suíte: um arquivo
  gerado de testes que passam todos é exatamente onde o teste de mutação mostra o que eles nunca
  conferem.
- **Não como um número a maximizar.** Alguns mutantes não mudam nada que um cliente notaria (dois
  jeitos de escrever a mesma condição) e sobrevivem por um bom motivo. Leia cada sobrevivente e
  decida; não persiga uma porcentagem.
- **É lento por natureza**: a suíte inteira roda uma vez por mutante. Rode-o no módulo em que você
  está trabalhando, não em todo commit de um projeto grande.
