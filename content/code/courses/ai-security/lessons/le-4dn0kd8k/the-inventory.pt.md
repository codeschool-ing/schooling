---
title: Um inventário dos pontos de entrada
version: 1
---

Um modelo de ameaças começa como uma lista. Para o assistente da Tarefa ela é o `data/surface.json`,
escrito pelo curso para uma empresa que ele inventou: uma entrada por lugar onde texto entra ou sai,
com três fatos sobre cada uma e as aulas deste curso que constroem os controles dela. Cole o arquivo:

```sh
cat > ~/guard/data/surface.json <<'EOF'
[
{"id": "client-chat", "what": "a client's message in the chat", "enters": "prompt", "trusted": false, "controls": ["guard check-in", "guard moderate"], "lessons": [9, 6]},
{"id": "helpdesk", "what": "help centre pages retrieved for an answer", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["guard ground"], "lessons": [2]},
{"id": "ticket-text", "what": "messages inside a support ticket", "enters": "prompt", "trusted": false, "controls": ["guard minimise"], "lessons": [12]},
{"id": "uploaded-files", "what": "briefs and files clients attach to a job", "enters": "prompt", "trusted": false, "controls": [], "lessons": []},
{"id": "system-prompt", "what": "the assistant's instructions", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["canary in guard filter"], "lessons": [5]},
{"id": "model-reply", "what": "the model's reply, before a client reads it", "enters": "screen", "trusted": false, "controls": ["guard check-out", "guard filter"], "lessons": [9, 5]},
{"id": "tool-calls", "what": "tool calls the model proposes", "enters": "tools", "trusted": false, "controls": ["guard gate"], "lessons": [10]},
{"id": "partner-api", "what": "requests from companies using Tarefa's API", "enters": "prompt", "trusted": false, "controls": ["guard onboard", "guard drift", "guard ratelimit"], "lessons": [8, 7]},
{"id": "call-log", "what": "the log of every prompt and reply", "enters": "storage", "trusted": "Tarefa's own", "controls": ["guard redact", "guard sweep"], "lessons": [11]},
{"id": "provider", "what": "the third-party model and its records of the calls", "enters": "outside", "trusted": "by contract", "controls": ["guard minimise", "guard enduser"], "lessons": [12, 7]}
]
EOF
```

O programa que o lê imprime uma linha por ponto de entrada. Salve-o como `~/guard/tools/surface.py`:

```python
# surface.py: the assistant's entry points, and which control covers each.
#
#   guard surface [--gaps]
#
# It reads data/surface.json and prints one row per entry point. --gaps
# prints only the rows with no control, which are the ones to act on.
import argparse
import json
import os

p = argparse.ArgumentParser(prog="guard surface")
p.add_argument("--gaps", action="store_true")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/surface.json"), encoding="utf-8") as f:
    rows = json.load(f)

print("%-15s %-8s %-18s %s" % ("entry point", "goes to", "trusted?", "controls"))
gaps = 0
for r in rows:
    trusted = "no" if r["trusted"] is False else r["trusted"]
    gaps += not r["controls"]
    if a.gaps and r["controls"]:
        continue
    print("%-15s %-8s %-18s %s" % (r["id"], r["enters"], trusted,
                                   ", ".join(r["controls"]) or "NONE"))
print("%d entry points, %d with no control" % (len(rows), gaps))
```

```
ana@lab:~/guard$ head -3 data/surface.json
[
{"id": "client-chat", "what": "a client's message in the chat", "enters": "prompt", "trusted": false, "controls": ["guard check-in", "guard moderate"], "lessons": [9, 6]},
{"id": "helpdesk", "what": "help centre pages retrieved for an answer", "enters": "prompt", "trusted": "written by Tarefa", "controls": ["guard ground"], "lessons": [2]},
ana@lab:~/guard$ guard surface
entry point     goes to  trusted?           controls
client-chat     prompt   no                 guard check-in, guard moderate
helpdesk        prompt   written by Tarefa  guard ground
ticket-text     prompt   no                 guard minimise
uploaded-files  prompt   no                 NONE
system-prompt   prompt   written by Tarefa  canary in guard filter
model-reply     screen   no                 guard check-out, guard filter
tool-calls      tools    no                 guard gate
partner-api     prompt   no                 guard onboard, guard drift, guard ratelimit
call-log        storage  Tarefa's own       guard redact, guard sweep
provider        outside  by contract        guard minimise, guard enduser
10 entry points, 1 with no control
```

Leia as colunas como três perguntas:

- **goes to** é o que o texto alcança: o prompt, a tela, as ferramentas, o armazenamento, ou algo fora
  da Tarefa. Texto que vai às ferramentas é o mais perigoso, porque vira ação.
- **trusted?** é quem o escreveu. Só duas entradas são confiáveis de saída, o prompt de sistema e a
  central de ajuda, ambos escritos pela Tarefa. O log é da própria Tarefa e o fornecedor é confiável por
  contrato, o que a aula 12 mostra ser uma confiança com condições.
- **controls** nomeia os comandos deste curso que cobrem a entrada. Nenhum deles existe ainda na sua
  máquina: cada um é um programa que uma aula seguinte imprime, e os números das aulas estão no arquivo.

A lista é curta porque o assistente da Tarefa é pequeno. Uma aplicação maior tem mais linhas, não mais
colunas: cada recurso novo acrescenta um ponto de entrada, e **um recurso não está pronto enquanto a
linha dele não for escrita**, com a confiança e o controle. Uma linha acrescentada depois de um incidente
é uma linha que alguém achou do jeito difícil.

## Duas linhas que valem uma leitura atenta

O `model-reply` está marcado como não confiável, embora a Tarefa rode o modelo. A saída do modelo é
moldada por toda entrada não confiável que chegou a ele, então herda o nível de confiança delas. É por
isso que a aula 9 confere toda resposta contra um schema e a aula 5 a filtra antes de um cliente vê-la.

As `tool-calls` são não confiáveis pelo mesmo motivo, e vão às ferramentas. Uma proposta é texto que o
modelo escreveu depois de ler coisas que ninguém na Tarefa escreveu, então ela é conferida como
qualquer outra entrada não confiável, pelo portão da aula 10, antes de virar efeito.
