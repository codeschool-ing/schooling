---
title: Peça uma resposta que um programa confira
version: 2
---

Uma resposta em prosa é lida por uma pessoa, e uma pessoa passa os olhos. **Uma resposta num formato
que uma ferramenta entende pode ser conferida antes de alguém ler**: um diff pode ser testado contra
o código, JSON pode ser interpretado e validado, um arquivo de teste pode ser rodado. Pedir esse
formato é a checagem de qualidade mais barata que existe, porque a checagem já existe.

## Um diff, conferido antes de ser aplicado

O `comma.diff` da aula 5 seção 03, deveria ser um diff unificado. O `git apply --check` testa um diff
contra a árvore de trabalho sem mudar nada:

```
ana@dev:~/shop$ git apply --check comma.diff && echo "applies cleanly"
error: corrupt patch at line 11
```

**Recusado, e nada mudou.** Um diff unificado é um formato rígido: o cabeçalho de cada trecho diz
quantas linhas do arquivo antigo ele cobre e quantas do novo, e o corpo tem de bater com esses números
e com o arquivo. O cabeçalho da resposta dizia seis e sete, e o corpo eram sete linhas de contexto sem
mudança e nenhuma linha acrescentada. As linhas nunca somam o que o cabeçalho prometeu, e o git chama o
patch de corrompido na linha 11, que é o fim do arquivo. Modelos pequenos erram esses números mais
vezes do que acertam, porque escrever um diff é contar linhas que não estão na página. Todo diff que o
`llama3.2:3b` escreveu enquanto esta aula era preparada foi recusado do mesmo jeito.

É o formato fazendo o trabalho dele. Uma resposta que fosse o arquivo inteiro em prosa teria sido
colada por cima do verdadeiro, e o estrago, achado mais tarde, se tanto.

## Uma função, conferida ao ser trocada

Um formato que o modelo escreve com segurança, e que um programa ainda consegue conferir, é a função
sozinha. A ana troca a última linha do prompt:

```
ana@dev:~/shop$ sed -i 's/^Answer with: .*/Answer with: only the new parse_price function, in one block of code, and nothing else./' prompts/comma.md && tail -n 1 prompts/comma.md
Answer with: only the new parse_price function, in one block of code, and nothing else.
```

e escreve a checagem: um programa curto que põe uma função no lugar da função de mesmo nome, e recusa
qualquer coisa que não seja exatamente uma função. É o que o botão de aplicar de um editor deveria
fazer, e o `ast`, o parser do próprio Python, faz a parte difícil:

```python
"""Put a function from one file in place of the function of the same name in another.

    python scratch/swap.py TARGET NEW

NEW must hold exactly one function and nothing else, and TARGET must already
have a function of that name at the top level. Anything else is refused before
TARGET is touched, which is the check an Apply button should make.
"""
import ast
import sys

target, new = sys.argv[1], sys.argv[2]
code = open(new).read()
tree = ast.parse(code)
if len(tree.body) != 1 or not isinstance(tree.body[0], ast.FunctionDef):
    sys.exit(f"swap: {new} is not one function and nothing else")
name = tree.body[0].name
lines = open(target).read().split("\n")
old = [f for f in ast.parse("\n".join(lines)).body if isinstance(f, ast.FunctionDef) and f.name == name]
if not old:
    sys.exit(f"swap: {target} has no function called {name}")
lines[old[0].lineno - 1:old[0].end_lineno] = code.rstrip("\n").split("\n")
open(target, "w").write("\n".join(lines))
print(f"swap: {name} replaced in {target}")
```

O mesmo pedido, com a última linha nova, e o bloco da resposta gravado em `scratch/parse_price.py`:

```
ana@dev:~/shop$ python scratch/assist.py ask "$(cat prompts/comma.md) Traceback from running it: $(cat error.txt)" --open shop/money.py tests/test_money.py CONVENTIONS.md --write scratch/parse_price.py > /dev/null
context sent (596 of 3000 tokens):
    137  shop/money.py
     85  tests/test_money.py
    374  CONVENTIONS.md
---
ana@dev:~/shop$ cat scratch/parse_price.py
def parse_price(text: str) -> int:
    """Turn a price as people write it into cents: '12,90' -> 1290."""
    units, _, cents = text.strip().partition(",")
    cents = (cents + "00")[:2]
    return int(units) * 100 + int(cents)
ana@dev:~/shop$ python scratch/swap.py shop/money.py scratch/parse_price.py && git diff
swap: parse_price replaced in shop/money.py
diff --git a/shop/money.py b/shop/money.py
index 9af0e26..d22f18f 100644
--- a/shop/money.py
+++ b/shop/money.py
@@ -2,8 +2,8 @@
 
 
 def parse_price(text: str) -> int:
-    """Turn a price as people write it into cents: '12.90' -> 1290."""
-    units, _, cents = text.strip().partition(".")
+    """Turn a price as people write it into cents: '12,90' -> 1290."""
+    units, _, cents = text.strip().partition(",")
     cents = (cents + "00")[:2]
     return int(units) * 100 + int(cents)
 
```

O `swap` aceitou, e o `git diff` mostra exatamente o que mudou: duas linhas, e uma docstring que agora
diz `'12,90'`. As checagens que o prompt listou em "Done when" resolvem o resto em um segundo:

```
ana@dev:~/shop$ python -c 'from shop.money import parse_price; print(parse_price("12,90"), parse_price("12,9"), parse_price("12.90"))'
Traceback (most recent call last):
  File "<string>", line 1, in <module>
  File "/home/ana/shop/shop/money.py", line 8, in parse_price
    return int(units) * 100 + int(cents)
           ^^^^^^^^^^
ValueError: invalid literal for int() with base 10: '12.90'
ana@dev:~/shop$ python -m pytest -q
......F.                                                                 [100%]
=================================== FAILURES ===================================
_______________________________ test_parse_price _______________________________

    def test_parse_price():
>       assert parse_price("12.90") == 1290
               ^^^^^^^^^^^^^^^^^^^^

tests/test_money.py:5: 
_ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ _ 

text = '12.90'

    def parse_price(text: str) -> int:
        """Turn a price as people write it into cents: '12,90' -> 1290."""
        units, _, cents = text.strip().partition(",")
        cents = (cents + "00")[:2]
>       return int(units) * 100 + int(cents)
               ^^^^^^^^^^
E       ValueError: invalid literal for int() with base 10: '12.90'

shop/money.py:8: ValueError
=========================== short test summary info ============================
FAILED tests/test_money.py::test_parse_price - ValueError: invalid literal fo...
1 failed, 7 passed in 0.66s
```

**A função agora divide numa vírgula em vez de num ponto**, então `12.90` quebra onde `12,90`
quebrava, e o teste do próprio projeto para o `parse_price` falha. O formato fez o que lhe foi pedido.
A resposta pôde ser lida por um programa, posta no lugar por um programa e julgada pelos testes um
segundo depois de chegar, e é esse o ponto: ninguém precisou lê-la com cuidado para descobrir que
estava errada. A aula 5 seção 06, volta a esta função.

## Formatos que vale pedir

| tarefa | formato | a checagem |
|---|---|---|
| uma mudança em código existente | um diff unificado, de um modelo que os escreve bem | `git apply --check`, depois os testes |
| uma mudança numa função | a função, inteira | ela é interpretada, o `swap` a põe no lugar, os testes rodam |
| código novo | um arquivo completo ou uma função | importa, o linter passa, os testes rodam |
| dados extraídos de um texto | JSON que segue um esquema | interpretar e validar (aula 8) |
| uma decisão | uma palavra de uma lista fixa | está na lista? |
| testes | um arquivo de teste | roda, e falha no código de antes da mudança |

**Diga "e nada mais"** quando um programa for ler a resposta. Uma resposta que começa com "Claro,
aqui está a função:" não é uma função, e o parser que esperava uma ou falha ou, pior, pula a primeira
linha e segue em frente. O `assist --write` é tolerante aqui, porque pega o primeiro bloco de código
onde quer que ele esteja; a maioria dos programas não é.

A última linha merece uma frase própria: **um teste gerado deve falhar antes da mudança que ele
testa**. Um teste que passa no código antigo não confere nada do código novo, o que a aula 4 seção 04
descobriu do jeito difícil.
