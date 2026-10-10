---
title: Componentes, zonas e os fluxos entre eles
version: 1
---

A aula 1 listou os lugares por onde o texto entra no assistente da Tarefa. Esse inventário responde
*onde*. Um modelo de ameaças responde uma pergunta mais difícil: **o que pode dar errado em cada
caminho que o texto percorre dentro da aplicação, e o que está no meio do caminho para impedir**. Cada
uma das doze primeiras aulas construiu uma defesa. Esta aula é como uma equipe decide de quais defesas
uma aplicação precisa antes de algo dar errado, e como percebe as que ainda faltam.

O método tem três passos, e cada um tem uma seção aqui:

1. **desenhar a aplicação** como componentes e os fluxos entre eles;
2. **fazer um conjunto fixo de perguntas** a cada fluxo que importa;
3. **anotar as respostas** num registro, ordenado, com o controle ou a lacuna ao lado de cada uma.

## Um componente mora numa zona

Um **componente** é qualquer coisa que guarda ou manipula dados: o navegador, a aplicação web, o
código que monta os prompts, o modelo, um banco de dados, o log. Uma **zona** é um conjunto de
componentes que confiam uns nos outros porque a mesma parte os opera e as mesmas pessoas podem
alterá-los. O assistente da Tarefa tem três:

- **internet**: o navegador do cliente e as empresas que chamam a API da Tarefa. A Tarefa não
  controla nada ali;
- **tarefa**: os servidores da própria Tarefa, da aplicação web ao log de chamadas;
- **provider**: o modelo de terceiros, operado por uma empresa com quem a Tarefa tem contrato e sobre
  a qual não tem controle.

Onde duas zonas se encontram há uma **fronteira de confiança**. Um fluxo que cruza uma delas é onde o
modelo de ameaças olha primeiro: os dados saem das mãos de quem cuidava deles, ou chegam de alguém
que ninguém conferiu.

A aplicação como dados, escrita pelo curso para uma empresa inventada. Cole:

```sh
cat > ~/guard/data/flows.json <<'EOF'
{
 "components": [
  {"id": "browser", "zone": "internet", "what": "a client's browser"},
  {"id": "partner", "zone": "internet", "what": "a company calling Tarefa's API"},
  {"id": "app", "zone": "tarefa", "what": "Tarefa's web application and API"},
  {"id": "assistant", "zone": "tarefa", "what": "the code that builds prompts and reads replies"},
  {"id": "helpdesk", "zone": "tarefa", "what": "the help centre pages"},
  {"id": "files", "zone": "tarefa", "what": "files clients attach to a job"},
  {"id": "tools", "zone": "tarefa", "what": "the tool runners behind the gate"},
  {"id": "orders", "zone": "tarefa", "what": "the orders database"},
  {"id": "log", "zone": "tarefa", "what": "the call log"},
  {"id": "model", "zone": "provider", "what": "the third-party model"}
 ],
 "flows": [
  {"id": "f1", "from": "browser", "to": "app", "carries": "chat message", "text_from": "client"},
  {"id": "f2", "from": "app", "to": "browser", "carries": "reply", "text_from": "model"},
  {"id": "f3", "from": "partner", "to": "app", "carries": "API request", "text_from": "partner"},
  {"id": "f4", "from": "app", "to": "assistant", "carries": "message and session", "text_from": "client"},
  {"id": "f5", "from": "helpdesk", "to": "assistant", "carries": "retrieved pages", "text_from": "tarefa"},
  {"id": "f6", "from": "files", "to": "assistant", "carries": "attachment text", "text_from": "client"},
  {"id": "f7", "from": "assistant", "to": "model", "carries": "prompt", "text_from": "client"},
  {"id": "f8", "from": "model", "to": "assistant", "carries": "completion", "text_from": "model"},
  {"id": "f9", "from": "assistant", "to": "tools", "carries": "proposed call", "text_from": "model"},
  {"id": "f10", "from": "tools", "to": "orders", "carries": "query", "text_from": "tarefa"},
  {"id": "f11", "from": "assistant", "to": "log", "carries": "prompt and reply", "text_from": "client"},
  {"id": "f12", "from": "browser", "to": "files", "carries": "upload", "text_from": "client"}
 ]
}
EOF
```

Dez componentes e doze fluxos. Cada fluxo nomeia suas duas pontas, o que carrega e **quem escreveu o
texto que vai nele**: o cliente (`client`), um parceiro (`partner`), o modelo (`model`) ou a Tarefa
(`tarefa`). O programa que o lê é curto. Salve-o como `~/guard/tools/flows.py`:

```python
# flows.py: the assistant's data flows, and the ones a threat model reviews.
#
#   guard flows [--text]
#
# It reads data/flows.json: each component and the zone it runs in, and each
# flow between two components with who wrote the text it carries. A flow
# whose ends sit in different zones crosses a trust boundary and is marked
# for review. With --text, so is a flow that carries text Tarefa did not
# write, wherever it runs.
import argparse
import json
import os
import sys

p = argparse.ArgumentParser(prog="guard flows")
p.add_argument("--text", action="store_true")
a = p.parse_args()

with open(os.path.expanduser("~/guard/data/flows.json"), encoding="utf-8") as f:
    model = json.load(f)
zone = {c["id"]: c["zone"] for c in model["components"]}
for fl in model["flows"]:
    for end in (fl["from"], fl["to"]):
        if end not in zone:
            sys.exit("flows: %s names %s, which is not a component" % (fl["id"], end))


def review(fl):
    """Why a flow needs a threat model's attention, or None."""
    a_zone, b_zone = zone[fl["from"]], zone[fl["to"]]
    if a_zone != b_zone:
        return "crosses %s -> %s" % (a_zone, b_zone)
    if a.text and fl["text_from"] != "tarefa":
        return "carries %s text" % fl["text_from"]
    return None


marked = 0
print("%-4s %-10s %-10s %-22s %s" % ("flow", "from", "to", "carries", "review"))
for fl in model["flows"]:
    why = review(fl)
    marked += why is not None
    print("%-4s %-10s %-10s %-22s %s" % (fl["id"], fl["from"], fl["to"], fl["carries"], why or "-"))
print("%d flows, %d marked for review" % (len(model["flows"]), marked))
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 350\" role=\"img\" aria-label=\"O assistente da Tarefa como diagrama de fluxo de dados: dez componentes em três zonas, a internet, os servidores da Tarefa e o fornecedor do modelo, ligados por doze fluxos. Seis fluxos passam de uma zona a outra: f1, f2, f3, f7, f8 e f12.\"><defs><marker id=\"dfd-a\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"dfd-b\" viewBox=\"0 0 8 8\" refX=\"7\" refY=\"4\" markerWidth=\"7\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0,0 L8,4 L0,8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"22\" width=\"140\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"14\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">internet</text><rect x=\"185\" y=\"22\" width=\"410\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"189\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidores da Tarefa</text><rect x=\"605\" y=\"22\" width=\"110\" height=\"300\" rx=\"6\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"6 4\"></rect><text x=\"609\" y=\"16\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fornecedor</text><line x1=\"128.0\" y1=\"80.0\" x2=\"202.0\" y2=\"80.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"70.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f1</text><line x1=\"202.0\" y1=\"92.0\" x2=\"128.0\" y2=\"92.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"108.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f2</text><line x1=\"94.1\" y1=\"237.9\" x2=\"235.9\" y2=\"104.1\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"166.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f3</text><line x1=\"282.4\" y1=\"103.6\" x2=\"367.6\" y2=\"158.4\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"325.0\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f4</text><line x1=\"395.0\" y1=\"75.0\" x2=\"395.0\" y2=\"157.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"399.0\" y=\"111.0\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f5</text><line x1=\"308.0\" y1=\"176.0\" x2=\"342.0\" y2=\"176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"325.0\" y=\"171.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f6</text><line x1=\"448.0\" y1=\"170.0\" x2=\"609.0\" y2=\"170.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"528.5\" y=\"160.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f7</text><line x1=\"609.0\" y1=\"182.0\" x2=\"448.0\" y2=\"182.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"528.5\" y=\"198.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f8</text><line x1=\"395.0\" y1=\"195.0\" x2=\"395.0\" y2=\"262.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"399.0\" y=\"223.5\" text-anchor=\"start\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f9</text><line x1=\"448.0\" y1=\"281.0\" x2=\"492.0\" y2=\"281.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"470.0\" y=\"276.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f10</text><line x1=\"421.5\" y1=\"158.3\" x2=\"503.5\" y2=\"103.7\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-a)\"></line><text x=\"462.5\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">f11</text><line x1=\"109.7\" y1=\"103.3\" x2=\"220.3\" y2=\"158.7\" stroke=\"var(--amber)\" stroke-width=\"1.4\" marker-end=\"url(#dfd-b)\"></line><text x=\"165.0\" y=\"126.0\" text-anchor=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">f12</text><rect x=\"25\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">browser</text><rect x=\"25\" y=\"240\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">partner</text><rect x=\"205\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">app</text><rect x=\"205\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"255\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">files</text><rect x=\"345\" y=\"40\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"56\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">helpdesk</text><rect x=\"345\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">assistant</text><rect x=\"345\" y=\"265\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"395\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">tools</text><rect x=\"480\" y=\"70\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"530\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">log</text><rect x=\"495\" y=\"265\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"545\" y=\"281\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">orders</text><rect x=\"612\" y=\"160\" width=\"100\" height=\"32\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"662\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">model</text><text x=\"12\" y=\"340\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">vermelho: o fluxo cruza uma fronteira de confiança</text></svg>", "caption": "Os doze fluxos de `data/flows.json`. As caixas tracejadas são as zonas, e uma seta vermelha é um fluxo que o `guard flows` marca porque suas duas pontas ficam em zonas diferentes.", "same": ["internet"]}
```

Rode:

```
ana@lab:~/guard$ guard flows
flow from       to         carries                review
f1   browser    app        chat message           crosses internet -> tarefa
f2   app        browser    reply                  crosses tarefa -> internet
f3   partner    app        API request            crosses internet -> tarefa
f4   app        assistant  message and session    -
f5   helpdesk   assistant  retrieved pages        -
f6   files      assistant  attachment text        -
f7   assistant  model      prompt                 crosses tarefa -> provider
f8   model      assistant  completion             crosses provider -> tarefa
f9   assistant  tools      proposed call          -
f10  tools      orders     query                  -
f11  assistant  log        prompt and reply       -
f12  browser    files      upload                 crosses internet -> tarefa
12 flows, 6 marked for review
```

Seis dos doze cruzam uma fronteira, e cada travessia é uma frase que o modelo de ameaças precisa saber
terminar. `f1`: a mensagem de um cliente chega da internet. `f7`: um prompt sai para o fornecedor.
`f8`: a resposta do fornecedor volta. `f12`: um arquivo escolhido por um cliente cai no disco da
Tarefa.

## A segunda lente: quem escreveu o texto

A regra das zonas deixa escapar uma coisa, e esse escape é a razão de existir deste curso. **O `f6`
leva o texto de um anexo do armazenamento de arquivos da própria Tarefa para o próprio assistente da
Tarefa.** As duas pontas estão na mesma zona, então a regra não diz nada. Mas foi um cliente quem
escreveu esse texto, e o modelo vai lê-lo no mesmo fluxo das instruções da Tarefa. A aula 1 chamou
isso de a propriedade que torna diferente uma aplicação com LLM: o modelo não consegue distinguir com
segurança as instruções que deveria seguir de um texto com cara de instrução dentro do material em que
está trabalhando.

Por isso o programa tem uma segunda regra, `--text`. Um fluxo que carrega texto que a Tarefa não
escreveu também é marcado, onde quer que rode:

```
ana@lab:~/guard$ guard flows --text
flow from       to         carries                review
f1   browser    app        chat message           crosses internet -> tarefa
f2   app        browser    reply                  crosses tarefa -> internet
f3   partner    app        API request            crosses internet -> tarefa
f4   app        assistant  message and session    carries client text
f5   helpdesk   assistant  retrieved pages        -
f6   files      assistant  attachment text        carries client text
f7   assistant  model      prompt                 crosses tarefa -> provider
f8   model      assistant  completion             crosses provider -> tarefa
f9   assistant  tools      proposed call          carries model text
f10  tools      orders     query                  -
f11  assistant  log        prompt and reply       carries client text
f12  browser    files      upload                 crosses internet -> tarefa
12 flows, 10 marked for review
```

Agora são dez de doze. Os quatro novos estão dentro da zona da Tarefa e carregam palavras de outra
pessoa: a mensagem do cliente a caminho do assistente (`f4`), o anexo (`f6`), a chamada de ferramenta
proposta que o modelo escreveu (`f9`) e o log que guarda tudo isso (`f11`). **Numa aplicação com LLM,
a fronteira de confiança acompanha o texto, não só a rede.** Um diagrama que desenha apenas os
servidores mostra o `f6` como seguro, e ele é o fluxo que a aula 1 deixou sem controle nenhum.
