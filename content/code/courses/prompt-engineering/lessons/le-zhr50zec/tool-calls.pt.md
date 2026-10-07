---
title: Um pedido escrito como texto, e um programa que o executa
version: 2
---

Assistentes que consultam a previsão do tempo, rodam código ou reservam uma mesa parecem fazer
essas coisas sozinhos. **Um modelo não consegue executar nada. Ele escreve texto, e parte desse
texto pode ser um pedido, num formato combinado antes, para um programa executar uma ferramenta.**
O programa em volta do modelo lê o pedido, executa a ferramenta e põe o resultado de volta no texto;
depois o modelo é chamado a continuar, com o resultado na frente dele.

Sem esse arranjo, duas coisas que você já viu dão errado. Perguntado sobre a data de hoje, um
modelo só consegue escrever uma data provável, que é o problema da lição 5; perguntado quanto é
3 × 42,50, ele faz conta com blocos de dígitos, que é o problema da lição 3. Uma ferramenta troca a
resposta provável por uma consultada ou calculada.

## Dizer ao modelo o que ele pode pedir

O modelo fica sabendo quais ferramentas existem pela entrada dele. Na forma mais simples, a
descrição faz parte do prompt, junto com o formato que o programa vai procurar. Salve esta como
`~/pe/tools.txt`:

```sh
cat > ~/pe/tools.txt <<'EOF'
You answer customers of Café Aurora. You cannot know today's date or do
arithmetic yourself; a program does them for you. To use one, reply with
exactly one line and nothing else:
  Action: today[]
  Action: calculator[3 * 2.50]
The program replies with a line starting "Observation:". Never write an
Observation yourself. When you have every fact you need, reply with one line:
  Answer: your reply to the customer
EOF
```

Cada linha dela está aí porque uma versão mais curta falhou enquanto esta lição era escrita. Uma
versão com `calculator[sum]` de exemplo recebeu a palavra `sum` de volta, escrita dentro do pedido;
uma que não proibia isso viu o modelo escrever a própria Observation, com uma data inventada. Com a
descrição como mensagem de sistema e uma pergunta, o modelo escreve pedidos e para:

```
ana@lab:~/pe$ ask "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?" --system "$(cat tools.txt)" --temperature 0
Action: today[]
Action: calculator[3 * 42.50]
-- llama3.2:3b, finish: stop, prompt 154 tokens, output 16 tokens
```

Dois pedidos e mais nada, que é tudo o que um modelo consegue fazer. **Alguma coisa precisa
executá-los**, e devolver os resultados.

As APIs dos grandes provedores têm um campo para isso, em vez de um parágrafo no prompt. Cada
ferramenta é descrita por um nome, uma frase dizendo o que ela faz e um JSON Schema para a entrada
dela (a lição 19 trata de schemas). A resposta do modelo então traz a chamada da ferramenta como uma
parte separada e estruturada, e o seu código devolve o resultado numa mensagem própria. Os nomes dos
campos mudam entre provedores; uma definição para a calculadora fica assim, e este curso fica no
formato de texto acima, porque dá para ler cada byte dele:

```json
{
  "name": "calculator",
  "description": "Arithmetic with numbers and + - * /. Returns the result as a number.",
  "input_schema": {
    "type": "object",
    "properties": {"expression": {"type": "string"}},
    "required": ["expression"]
  }
}
```

**A descrição também é um prompt.** O modelo decide se e como chamar uma ferramenta a partir dessa
única frase, então "Arithmetic with numbers and + - * /" faz um trabalho de verdade: diz ao modelo
quais operações ele pode mandar, e que `sqrt(2)` não vai funcionar.

## O programa em volta do modelo

O `agent` é esse programa. Ele manda a pergunta ao modelo com o `tools.txt` como mensagem de
sistema, lê a resposta, acha a primeira linha `Action:`, confere se a ferramenta é permitida, a
executa, e devolve o resultado como uma `Observation:` para o turno seguinte. Ele para o modelo na
palavra `Observation:` com uma sequência de parada (lição 16), para que o modelo não escreva um
resultado próprio. Salve-o como `~/pe/bin/agent` e torne-o executável:

```python
#!/usr/bin/env python3
"""agent: the loop that lets a model act.

  agent RUN [--max-steps N] [--allow TOOL,...]
  agent --live QUESTION [--max-steps N] [--allow TOOL,...]

With RUN, the model's side of the conversation is read from a file, one turn
per block separated by '---', and played back: the turns are fixed, so the
loop's own behaviour can be watched exactly. With --live, each turn is asked
of the model through `ask`, with tools.txt as the system message and QUESTION
as the first message. Either way, the rest is the part an engineer builds:
reading the reply, finding the Action line, checking the tool is allowed,
running it, handing back an Observation, and stopping.

Tools: search[question]  calculator[expression]  today[]  reviews[]
       send_email[to | text]   (changes the world: never run without a person)
"""
import ast
import operator
import os
import re
import json
import subprocess
import sys
import tempfile

HERE = os.path.dirname(os.path.abspath(__file__))
SAFE = {"search", "calculator", "today", "reviews"}
ACTION = re.compile(r"^Action:\s*(\w+)\[(.*)\]\s*$")
OPS = {ast.Add: operator.add, ast.Sub: operator.sub, ast.Mult: operator.mul,
       ast.Div: operator.truediv, ast.USub: operator.neg}


def calc(expr):
    def ev(n):
        if isinstance(n, ast.Constant) and isinstance(n.value, (int, float)):
            return n.value
        if isinstance(n, ast.BinOp) and type(n.op) in OPS:
            return OPS[type(n.op)](ev(n.left), ev(n.right))
        if isinstance(n, ast.UnaryOp) and type(n.op) in OPS:
            return OPS[type(n.op)](ev(n.operand))
        raise ValueError("only numbers and + - * / are allowed")
    v = ev(ast.parse(expr, mode="eval").body)
    return str(round(v, 6)).rstrip("0").rstrip(".") if isinstance(v, float) else str(v)


def run_tool(name, arg, allowed):
    if name not in SAFE | {"send_email"}:
        return "error: there is no tool called %s" % name
    if name not in allowed:
        return "refused: %s is not allowed in this task" % name
    if name == "send_email":
        return "held: send_email changes something outside this conversation; nothing is sent until a person confirms it"
    if name == "calculator":
        try:
            return calc(arg)
        except (ValueError, SyntaxError, ZeroDivisionError) as e:
            return "error: %s" % e
    if name == "today":
        return os.environ.get("LAB_TODAY", "Friday 2 October 2026")
    if name == "search":
        out = subprocess.run([os.path.join(HERE, "retrieve"), arg, "--k", "1"],
                             capture_output=True, text=True).stdout.splitlines()
        hits = out[1:]
        return hits[0].split(None, 1)[1] if hits and not hits[0].startswith("no passage") else "nothing found"
    if name == "reviews":
        d = os.path.join(HERE, "..", "reviews")
        texts = [open(os.path.join(d, f), encoding="utf-8").read().strip() for f in sorted(os.listdir(d))]
        body = "\n".join("review %d: %s" % (i, t) for i, t in enumerate(texts, 1))
        return "<untrusted>\n%s\n</untrusted>" % body


def live(question, steps):
    """The model's turns, one at a time, each written after the last Observation."""
    with open(os.path.join(HERE, "..", "tools.txt"), encoding="utf-8") as f:
        messages = [{"role": "system", "content": f.read()}, {"role": "user", "content": question}]
    for _ in range(steps):
        with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as f:
            json.dump(messages, f)
        turn = subprocess.run([os.path.join(HERE, "ask"), "--chat", f.name, "--plain",
                               "--temperature", "0", "--stop", "Observation:"],
                              capture_output=True, text=True).stdout.strip()
        os.unlink(f.name)
        observation = yield turn
        messages.append({"role": "assistant", "content": turn})
        messages.append({"role": "user", "content": "Observation: %s" % observation})


def main():
    args = sys.argv[1:]
    steps, allowed = 5, set(SAFE)
    if "--max-steps" in args:
        i = args.index("--max-steps"); steps = int(args[i + 1]); del args[i : i + 2]
    if "--allow" in args:
        i = args.index("--allow"); allowed = set(args[i + 1].split(",")); del args[i : i + 2]
    if args[0] == "--live":
        turns = live(args[1], steps)
        result = None
    else:
        text = open(args[0], encoding="utf-8").read()
        blocks = [t.strip() for t in text.split("\n---\n")]
        turns = iter(["\n".join(l for l in t.splitlines() if not l.startswith("#")).strip() for t in blocks])
    print("tools allowed: %s" % ", ".join(sorted(allowed)))
    n = 0
    for n in range(1, steps + 1):
        try:
            turn = turns.send(result) if args[0] == "--live" and n > 1 else next(turns)
        except StopIteration:
            n -= 1
            break
        print("step %d" % n)
        action = None
        for line in turn.splitlines():
            print("  model> %s" % line)
            m = ACTION.match(line)
            if m and action is None:
                action = m.groups()
        if action is None:
            if any(l.startswith("Answer:") for l in turn.splitlines()):
                print("done: an answer after %d step%s" % (n, "" if n == 1 else "s"))
            else:
                print("stopped: the reply has neither an Action nor an Answer")
            return
        result = run_tool(action[0], action[1].strip(), allowed)
        for line in result.splitlines():
            print("  tool>  %s" % line)
    print("stopped: %d step%s and no answer" % (n, "" if n == 1 else "s"))


main()
```

Quatro ferramentas só leem alguma coisa. O `today` devolve uma data fixa, para que toda execução do
curso concorde sobre que dia é; o `search` devolve a melhor linha do manual; o `reviews` vem na lição
7. A quinta, `send_email`, fica retida, nunca executada. Eis a encomenda de bolos, ao vivo:

```
ana@lab:~/pe$ agent --live "Bruno wants three whole cakes at R\$ 42.50 each, to collect tomorrow. What day is tomorrow, and what is the total?"
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[] 
  model> Action: calculator[3 * 42.50]
  tool>  Friday 2 October 2026
step 2
  model> Answer: You can collect your cakes tomorrow, which is Saturday 3 October 2026, and the total will be R$ 127.50.
done: an answer after 2 steps
```

Leia as linhas por quem as escreveu. As linhas `model>` são os turnos do modelo. **A linha `tool>`
foi impressa por uma ferramenta de verdade**: a data veio do `today`. O modelo escreveu os dois
pedidos no primeiro turno, e o `agent` executou o primeiro, como o `tools.txt` disse que faria; a
calculadora nunca rodou. Então o total da resposta, R$ 127.50, é conta do próprio modelo. Acontece de
estar certo, e nada na execução o conferiu. O dia depois de sexta, 2 de outubro, é sábado, 3 de
outubro, e esse passo também foi do modelo. **Uma ferramenta só fornece um fato quando roda**, e só
as linhas `tool>` dizem quais fatos vieram de uma.

## Reproduzindo uma execução

O `agent` também consegue ler o lado do modelo de um arquivo, um bloco por turno, separados por
`---`; as linhas que começam com `#` são notas e são puladas. **Aí os turnos ficam fixos**, e toda
execução do laço faz a mesma coisa, que é como um programa destes é testado: o lado do modelo fica
parado, para que o que o programa faz possa ser conferido com exatidão. A próxima seção usa isso
para olhar cada regra sozinha. Eis a mesma encomenda, como os turnos que um modelo poderia escrever
para ela:

```
ana@lab:~/pe$ cat runs/order.txt
# Question: Bruno wants three whole cakes at R$ 42.50 each, to collect
# tomorrow. What day is tomorrow, and what is the total?
Action: today[]
---
Action: calculator[3 * 42.50]
---
Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
ana@lab:~/pe$ agent runs/order.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

Aqui as duas ferramentas rodaram, porque o arquivo pede uma por turno. A reprodução mostra o que o
programa faz com um turno; só uma execução ao vivo mostra o que um modelo escreve.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três caixas da esquerda para a direita. Dentro de uma fronteira tracejada chamada o programa em volta do modelo estão o modelo, que só escreve texto, e o laço. O modelo manda ao laço a linha Action: calculator[3 * 42.50]. O laço confere se a ferramenta é permitida e a executa. Fora da fronteira estão as ferramentas, a única parte que age. A calculadora devolve 127.5 ao laço, e o laço junta o resultado ao texto que o modelo lê em seguida.\"><defs><marker id=\"tool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"444\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o programa em volta do modelo</text><rect x=\"30\" y=\"90\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"92\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só escreve texto</text><rect x=\"330\" y=\"90\" width=\"112\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o laço</text><text x=\"242\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Action: calculator[3 * 42.50]</text><path d=\"M154 104 L328 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><path d=\"M328 146 L156 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"242\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resultado, juntado ao texto</text><rect x=\"586\" y=\"90\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">as ferramentas</text><text x=\"646\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a única parte que age</text><path d=\"M442 104 L584 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitida?</text><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">então executa</text><path d=\"M584 146 L444 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">127.5</text></svg>", "caption": "O que é uma chamada de ferramenta. O modelo só escreve uma linha pedindo uma ferramenta; o programa em volta dele decide se a executa, executa e põe o que voltou no texto que o modelo lê em seguida."}
```

## O que "agente" quer dizer aqui

A palavra é usada sem muito rigor, para qualquer coisa entre um chatbot com uma caixa de busca e um
sistema que roda por horas. Neste curso, **um agente é um modelo rodando num laço como este**: ele
pode pedir uma ferramenta, o programa a executa, e o laço dá voltas até o modelo escrever uma
resposta ou um limite ser atingido. O laço é o assunto da próxima seção, e é o programa, não o
modelo, que segura cada limite dele.
