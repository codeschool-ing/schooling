---
title: O que acontece quando uma resposta falha, e os limites em volta
version: 2
---

Um validador que recusa uma resposta fez só metade do trabalho. **O código também precisa decidir o que
acontece em seguida**, e as duas respostas fáceis estão erradas: mostrar a resposta mesmo assim derrota
o validador, e mostrar ao cliente um erro a cada recusa torna o recurso inútil nos dias em que o modelo
está com problemas.

A resposta comum é pedir mais uma vez dizendo ao modelo o que estava errado, e então parar. O laço tem oito
linhas, o `retry_loop` abaixo, e o resto do programa é o comando que o roda. Salve-o como
`~/guard/tools/retry.py`:

```schooling-example
{"language": "python", "file": "tools/retry.py", "parts": [
 {"code": "import json\nimport os\nimport sys\n\nfrom shapes import check_output\n\n\ndef retry_loop(call, check, attempts=2):\n    feedback = []\n", "note": "`call` pergunta ao modelo e devolve o texto; `check` devolve a lista de problemas, vazia quando a resposta passa. `attempts` é um limite rígido, e dois é a escolha usual."},
 {"code": "    for n in range(1, attempts + 1):\n        text = call(feedback)\n        problems = check(text)\n        yield n, text, problems\n", "note": "Cada tentativa é conferida pelas mesmas regras. Quem chama vê cada tentativa, com o texto, para que cada uma possa ser registrada."},
 {"code": "        if not problems:\n            return\n        feedback = problems\n", "note": "Uma resposta que passa encerra o laço. Uma que falha entrega os problemas à próxima chamada, que pode pô-los no prompt: as mensagens do validador são escritas para serem lidas pelo modelo e por uma pessoa."},
 {"code": "\n\nif __name__ == \"__main__\":\n    # guard retry ID [ID ...]: the loop, with the replies named on the command\n    # line, from data/outputs.jsonl, standing in for the model's attempts.\n    data = os.path.expanduser(\"~/guard/data/\")\n    with open(data + \"output-schema.json\") as f:\n        schema = json.load(f)\n    with open(data + \"allowed-hosts.json\") as f:\n        hosts = json.load(f)\n    with open(data + \"outputs.jsonl\") as f:\n        texts = {o[\"id\"]: o[\"text\"] for o in map(json.loads, f)}\n    replies = iter(sys.argv[1:])\n\n    def call(feedback):\n        if feedback:\n            print(\"           sent back: %d problem(s) with the previous reply\" % len(feedback))\n        return texts[next(replies)]\n\n    def check(text):\n        return check_output(text, schema, hosts, 120000)\n\n    for n, _, problems in retry_loop(call, check, attempts=len(sys.argv) - 1):\n        print(\"attempt %d  %s\" % (n, \"ok\" if not problems else \"REJECT \" + problems[0]))\n        for p in problems[1:]:\n            print(\"                  %s\" % p)\n    if problems:\n        print(\"no valid reply after %d attempts: the job goes to a person\" % (len(sys.argv) - 1))\n        sys.exit(1)\n", "note": "O comando, `guard retry`: o laço com respostas do `data/outputs.jsonl`, nomeadas na linha de comando, no lugar das tentativas do modelo. O orçamento é o do in-1."}
]}
```

O `guard retry` roda este laço com **respostas escritas pelo curso fazendo as vezes das
tentativas do modelo**: o primeiro ID na linha de comando é a primeira tentativa, o segundo é a nova
tentativa. Nenhum modelo é chamado; o que é real é o laço e as verificações. Uma nova tentativa que
funciona, e uma que não:

```
ana@lab:~/guard$ guard retry out-3 out-1; echo "exit $?"
attempt 1  REJECT $.category: 'illustration' is not one of design, development, writing, translation, marketing
           sent back: 1 problem(s) with the previous reply
attempt 2  ok
exit 0
ana@lab:~/guard$ guard retry out-2 out-7; echo "exit $?"
attempt 1  REJECT not JSON: Expecting value at character 0
           sent back: 1 problem(s) with the previous reply
attempt 2  REJECT $.summary: 607 characters, limit 400
                  $.skills: 7 items, limit 5
no valid reply after 2 attempts: the job goes to a person
exit 1
```

Quando as tentativas acabam, o trabalho vai para uma pessoa, e **nada das respostas recusadas chega ao
cliente**. Essa é a regra que mais importa nesta seção: um validador falha fechado. Uma resposta que não
pôde ser conferida é tratada como uma resposta que falhou, porque a alternativa é uma verificação que
só funciona quando nada está errado.

## O mesmo laço com um modelo de verdade

As respostas acima foram escritas para serem pegas. Este programa pede a coisa de verdade ao
`llama3.2:3b`: manda uma requisição do `data/inputs.jsonl` com o schema no prompt de sistema, pede só
JSON e passa a resposta pelos mesmos `retry_loop` e `check_output`. Salve-o como
`~/guard/tools/draft.py`:

```python
# draft.py: the job intake with a real model, its reply checked and retried once.
#
#   guard draft REQUEST_ID
#
# It sends one request from data/inputs.jsonl to the model, with the schema
# the reply must follow, and runs the reply through retry_loop() and
# check_output(). A failed reply's problems go back with the next attempt.
import json
import os
import sys

from ask import ask
from retry import retry_loop
from shapes import check_output

DATA = os.path.expanduser("~/guard/data/")
with open(DATA + "output-schema.json") as f:
    schema = json.load(f)
with open(DATA + "allowed-hosts.json") as f:
    hosts = json.load(f)
with open(DATA + "inputs.jsonl") as f:
    req = next(r for r in map(json.loads, f) if r["id"] == sys.argv[1])

SYSTEM = """You turn a client's job request on Tarefa, a freelance marketplace,
into one JSON object that follows this JSON Schema exactly, with no other text:

%s

The price is in cents of a real, and must not exceed twice the client's budget.
Links, if any, may only point at https://help.tarefa.example/.""" % json.dumps(schema)
REQUEST = json.dumps({k: v for k, v in req.items() if k != "id"})


def call(feedback):
    question = REQUEST
    if feedback:
        question += "\n\nYour previous reply had these problems; fix them:\n" + "\n".join(feedback)
    return ask(question, system=SYSTEM, json_only=True)


def check(text):
    return check_output(text, schema, hosts, req["budget_cents"])


for n, text, problems in retry_loop(call, check):
    print("attempt %d  %s" % (n, text))
    print("           %s" % ("ok" if not problems else "REJECT " + problems[0]))
    for p in problems[1:]:
        print("                  %s" % p)
if problems:
    print("no valid reply after 2 attempts: the job goes to a person")
    sys.exit(1)
```

```
ana@lab:~/guard$ guard draft in-1; echo "exit $?"
attempt 1  {"type": "object", "category": "design", "title": "Logo for a bakery", "summary": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "price_suggestion_cents": 60000, "skills": ["design"], "links": ["https://help.tarefa.example/"]}
           REJECT $: 'type' is not allowed
attempt 2  {"category": "design", "title": "Logo for a bakery", "summary": "We are opening a bakery in Recife and need a logo that works on the shop sign, the packaging and Instagram.", "price_suggestion_cents": 60000, "skills": ["design"], "links": ["https://help.tarefa.example/"]}
           ok
exit 0
```

A primeira resposta é um JSON bem formado, e a verificação a recusou: o modelo copiou o
`"type": "object"` do schema para a própria resposta, um campo que o schema não permite. O problema
voltou com a segunda tentativa, e a segunda resposta passou. É o laço fazendo o que deve, num erro que
ninguém escreveu num arquivo de teste. A sua execução pode falhar de outro jeito, ou passar de
primeira.

Olhe também o que passou. O resumo é a frase do próprio cliente copiada de volta, e o preço é metade do
orçamento. Nada no schema diz que um resumo tem de resumir, e nenhuma verificação aqui sabe dizer se
R$ 600,00 é um preço justo por um logo. **Uma resposta que passa é uma resposta segura de mostrar, não
uma resposta certa**, e a segunda pergunta é para quem revisa o recurso, com amostras, do jeito que a
aula 6 mediu a moderação.

## Os limites que vêm junto

O laço de novas tentativas é um de vários limites, e cada um limita um jeito diferente de uma chamada
ao modelo sair do controle:

| limite | o que ele limita | onde apareceu |
|---|---|---|
| tentativas por requisição | quantas vezes uma requisição é repetida | o laço acima |
| `max_tokens` em cada chamada | o tamanho, e portanto o custo, de uma resposta | a API do fornecedor |
| tamanho de cada campo de entrada | o custo do prompt, e quanto o modelo precisa ler | as regras de entrada |
| tokens por usuário por dia | quanto uma pessoa pode gastar | aula 7 |
| chamadas de ferramenta ou turnos por tarefa | até onde um agente vai antes de parar | aula 10 |

O `max_tokens` merece uma nota porque é fácil defini-lo alto demais, com o argumento de que uma resposta
nunca deve ser cortada. Uma resposta cujo resumo o schema limita a 400 caracteres nunca precisa de
milhares de tokens. Um limite perto do que o schema permite transforma uma resposta prolixa numa que
falha rápido e barato, e o laço de novas tentativas cuida dela a partir dali.

## Conte as recusas

Toda recusa vai para o log com o id da requisição, como a aula 11 recomenda, com o caminho e a regra que
falhou. Contadas por dia, as recusas são um dos números mais úteis que este recurso produz. Uma taxa que
sobe depois de uma mudança de prompt ou de uma atualização do modelo é o primeiro sinal de que algo
mudou, e chega antes de qualquer cliente reclamar. A camada de métricas da aula 11 é o lugar dela: uma
contagem por dia, sem texto nenhum, guardada tanto quanto as outras contagens.
