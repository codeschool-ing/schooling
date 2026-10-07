---
title: Um limite que corta o laço
version: 2
---

Um máximo de tokens de saída é fácil de confundir com uma instrução de tamanho, como se ajustá-lo
em 50 pedisse ao modelo uma resposta de cinquenta tokens. Ele não pede nada. **O modelo escreve
exatamente como teria escrito, e o laço é parado quando a contagem chega ao limite**, onde quer que
isso caia numa frase. O modelo nunca fica sabendo que existia um limite.

A lição 1 mostrou os dois jeitos de a geração acabar: o modelo escolhe o fim, ou um limite é
atingido. O `toylm` diz qual dos dois na última linha. Sem um limite apertado o modelo termina
sozinho:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0
soup, bread and cake.
-- finish: end, prompt 3 tokens, output 6 tokens
```

Com `--max-tokens 3`:

```
ana@lab:~/pe$ toylm generate "the menu has" --temperature 0 --max-tokens 3
soup, bread
-- finish: length, prompt 3 tokens, output 3 tokens
```

`finish: length` diz que o laço foi parado de fora. Os três tokens foram `soup`, a vírgula e
`bread`, e o quarto nunca foi gerado.

## Alguns laços nunca acabam sozinhos

O limite também é o que para um modelo que, sem ele, seguiria para sempre. Na temperatura 0, o
`toylm` escreve isto depois de `the cat`:

```
ana@lab:~/pe$ toylm generate "the cat" --temperature 0 --max-tokens 20
sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat sleeps and the cat
-- finish: length, prompt 2 tokens, output 20 tokens
```

Depois de `cat sleeps` a palavra mais provável é `and`, depois de `and the` é `cat`, e depois de
`the cat` é `sleeps` de novo, então a decodificação gulosa dá voltas no mesmo círculo. **Sem o
limite o laço nunca acabaria.** Um modelo grande pode cair no mesmo tipo de círculo, repetindo uma
linha ou um item de lista, e o limite é o que transforma uma requisição que nunca voltaria numa que
volta comprida demais. A lição 17 mostra os controles que desencorajam o círculo desde o começo.

## Uma resposta cortada parece terminada

Leia de novo a saída da execução com `--max-tokens 3` sem a última linha: *the menu has soup,
bread*. É uma frase gramatical, e diz uma coisa falsa, porque o cardápio também tem bolo. **Uma
resposta cortada raramente parece cortada.** Uma lista para depois de um item, um parágrafo para
depois de uma frase, uma sequência de passos para antes do passo que importava, e quem não confere o
motivo segue em frente como se estivesse completa.

Então a regra para código que chama um modelo é simples: **confira por que ele parou antes de usar o
que escreveu.** Toda API de modelo devolve um motivo de término de algum tipo, com o nome que for; o
`toylm` o chama de `finish`, e `length` é o valor que quer dizer "isto foi cortado". Trate esse valor
como erro ou como uma nova tentativa com limite maior, nunca como resposta.

## Um objeto JSON cortado não é JSON

A saída estruturada torna o problema visível em vez de silencioso, o que é melhor e continua sendo
uma falha. Eis um pedido que manda o modelo classificar uma avaliação como um objeto JSON, e o
esquema com que a resposta dele deveria bater, os dois pequenos o bastante para digitar:

```
ana@lab:~/pe$ cat request.txt review.schema.json
You read customer reviews of Café Aurora. For the review below, reply with
one JSON object with three fields: "sentiment" (positive, neutral or
negative), "topic" (two or three words) and "summary" (one sentence).
Reply with the object and nothing else.

Review:
Waited fifteen minutes for a tea at noon. The staff were kind about it.
{
  "type": "object",
  "required": ["sentiment", "topic", "summary"],
  "properties": {
    "sentiment": {"enum": ["positive", "neutral", "negative"]},
    "topic": {"type": "string"},
    "summary": {"type": "string"}
  }
}
```

O `ask --json` pede um objeto JSON e mais nada. A resposta, como veio, e depois o mesmo pedido com
um limite de 20 tokens:

```
ana@lab:~/pe$ ask - --json --temperature 0 < request.txt
{"sentiment": "positive", "topic": "long wait", "summary": "Customer waited 15 minutes for a tea at noon, but staff were kind about the delay."}
-- llama3.2:3b, finish: stop, prompt 104 tokens, output 39 tokens
ana@lab:~/pe$ ask - --json --temperature 0 --max-tokens 20 < request.txt
{"sentiment": "positive", "topic": "long wait", "summary": "Customer waited
-- llama3.2:3b, finish: length, prompt 104 tokens, output 20 tokens
```

A primeira resposta levou 39 tokens e parou sozinha. A segunda parou em 20 com `finish: length`, no
meio do resumo, e nada no texto diz isso, a não ser que ele parece inacabado. Salve as duas, com
`--plain` para deixar de fora a linha de contabilidade:

```
ana@lab:~/pe$ ask - --json --temperature 0 --plain < request.txt > reply.json
ana@lab:~/pe$ ask - --json --temperature 0 --max-tokens 20 --plain < request.txt > cut.json
```

O `validate` confere um arquivo contra um esquema, com a biblioteca `jsonschema` que a lição 1
instalou. Salve-o como `~/pe/bin/validate` e torne-o executável:

```python
#!/usr/bin/env python3
"""validate SCHEMA FILE: is FILE valid JSON, and does it match SCHEMA?

Every problem is listed with the path to the field it is about, so a program
(or a person) can say exactly what to fix. Exit status 0 means valid.
"""
import json
import sys

from jsonschema import Draft202012Validator

schema_path, data_path = sys.argv[1:3]
with open(schema_path, encoding="utf-8") as f:
    schema = json.load(f)
try:
    with open(data_path, encoding="utf-8") as f:
        data = json.load(f)
except json.JSONDecodeError as e:
    print("not JSON: %s" % e)
    sys.exit(1)
errors = sorted(Draft202012Validator(schema).iter_errors(data), key=lambda e: list(e.path))
for e in errors:
    where = "/".join(str(p) for p in e.path) or "(top level)"
    print("%s: %s" % (where, e.message))
print("valid" if not errors else "%d problem%s" % (len(errors), "" if len(errors) == 1 else "s"))
sys.exit(1 if errors else 0)
```

O objeto completo passa na verificação do esquema, e o cortado nem é JSON:

```
ana@lab:~/pe$ validate review.schema.json reply.json
valid
ana@lab:~/pe$ validate review.schema.json cut.json
not JSON: Invalid control character at: line 1 column 76 (char 75)
```

**Um limite que serve para prosa pode ser fatal para JSON**, porque prosa cortada continua sendo
prosa e um objeto cortado não é um objeto. Ponha o limite com folga acima da maior resposta que você
espera, e confira o motivo da parada mesmo assim, porque "a maior resposta que você espera" é um
palpite.

Olhe de novo para o válido, também. `"sentiment": "positive"`, para um cliente que esperou quinze
minutos por um chá: o esquema permite `positive`, então o `validate` aprovou, e uma pessoa não
aprovaria. **Válido é uma afirmação sobre a forma, não sobre a verdade.** As lições 18 e 19 tratam de
saída estruturada e de validar e consertar essa saída, e a segunda termina exatamente nessa lacuna.
