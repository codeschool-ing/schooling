---
title: Consertando uma resposta, e sabendo quando parar
version: 2
---

Quando uma resposta falha, o movimento óbvio é pedir de novo e torcer. **A maioria das falhas não
precisa de modelo nenhum**, e as que precisam pedem uma mensagem precisa e um limite de quantas
vezes ela é enviada. Consertar é uma sequência curta de passos baratos, cada um tentado só quando o
anterior falhou:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um fluxo. A resposta é lida como está; se falhar, o texto do primeiro abre-chaves ao último fecha-chaves é recortado e lido; se não há objeto, a falha é registrada. Um objeto lido é conferido contra o schema. Válido: usar. Inválido: se restam tentativas, os erros voltam ao modelo e a nova resposta recomeça o fluxo; se não, desistir e registrar.\"><defs><marker id=\"rep-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"110\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"75\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">a resposta</text><path d=\"M130 52 L168 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"170\" y=\"30\" width=\"150\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"245\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">1 · ler como está</text><path d=\"M320 52 L358 52\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"360\" y=\"30\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">2 · recortar do primeiro { ao último }</text><path d=\"M460 74 L460 106\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"582\" y=\"45\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">sem objeto:</text><text x=\"582\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">registrar a falha</text><rect x=\"360\" y=\"108\" width=\"200\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">3 · conferir contra o schema</text><path d=\"M245 74 L245 130 L358 130\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><path d=\"M560 130 L618 130\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><rect x=\"620\" y=\"108\" width=\"80\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"660\" y=\"130\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">usar</text><path d=\"M460 152 L460 188\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"468\" y=\"170\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">inválido</text><text x=\"589\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">válido</text><rect x=\"380\" y=\"190\" width=\"160\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">restam tentativas?</text><path d=\"M380 210 L232 210\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"306\" y=\"200\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">sim</text><rect x=\"90\" y=\"190\" width=\"140\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"160\" y=\"207\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">devolver os erros,</text><text x=\"160\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedir de novo</text><path d=\"M160 190 L160 160 L75 160 L75 76\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><path d=\"M540 210 L588 210 L588 248\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#rep-ah)\"></path><text x=\"604\" y=\"228\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">não</text><rect x=\"500\" y=\"250\" width=\"180\" height=\"36\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"590\" y=\"268\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">desistir e registrar</text></svg>", "caption": "O laço de reparo. Os passos 1 a 3 não custam nada e não chamam modelo; só um objeto inválido volta, e só enquanto restam tentativas."}
```

O `repair` roda os três primeiros passos e para antes de chamar qualquer coisa: ou ele imprime um
objeto válido, ou imprime a mensagem que voltaria ao modelo. O que acontece depois é decisão do
programa que o chamou, e esse é o lugar certo para ela. Salve-o como `~/pe/bin/repair` e torne-o
executável:

```python
#!/usr/bin/env python3
"""repair SCHEMA FILE: recover a JSON object from a reply that wrapped it.

Three steps, each tried only when the one before failed:
  1. parse the reply as it is;
  2. take the text between the first '{' and the last '}', which removes a
     code fence or a sentence before or after the object;
  3. if what is left parses but does not match the schema, print the message
     that would go back to the model with the errors in it. No model is
     called: what happens next is the caller's decision.
"""
import json
import sys

from jsonschema import Draft202012Validator

schema_path, reply_path = sys.argv[1:3]
schema = json.load(open(schema_path, encoding="utf-8"))
reply = open(reply_path, encoding="utf-8").read()

try:
    data = json.loads(reply)
    print("step 1: parsed as it is")
except json.JSONDecodeError as e:
    print("step 1: not JSON (%s)" % e)
    start, end = reply.find("{"), reply.rfind("}")
    if start < 0 or end < start:
        print("step 2: no object in the reply; nothing to repair")
        sys.exit(1)
    try:
        data = json.loads(reply[start : end + 1])
        print("step 2: parsed characters %d to %d" % (start, end))
    except json.JSONDecodeError as e:
        print("step 2: still not JSON (%s)" % e)
        sys.exit(1)

errors = sorted(Draft202012Validator(schema).iter_errors(data), key=lambda e: list(e.path))
if not errors:
    print("step 3: valid against %s" % schema_path)
    print(json.dumps(data, ensure_ascii=False))
    sys.exit(0)
print("step 3: %d problem%s; the follow-up message would be:" % (len(errors), "" if len(errors) == 1 else "s"))
print()
print("Your last reply did not match the schema:")
for e in errors:
    where = "/".join(str(p) for p in e.path) or "(top level)"
    print("- %s: %s" % (where, e.message))
print("Reply again with only the corrected JSON object.")
sys.exit(1)
```

## Uma resposta embrulhada num bloco de código e em duas frases

Esta resposta, escrita pelo curso, tem um objeto correto dentro, num bloco de código em Markdown,
com uma frase antes e outra depois: o embrulho que o modelo da lição 18 escolheu para o JSON dele. O `cat -n` numera as linhas para o embrulho ficar fácil de ver:

```
ana@lab:~/pe$ cat -n replies/fenced.txt
     1	Here is the triage for the complaint:
     2	
     3	```json
     4	{"category": "wrong_item", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
     5	```
     6	
     7	Let me know if you need anything else!
ana@lab:~/pe$ repair schema.json replies/fenced.txt; echo "exit $?"
step 1: not JSON (Expecting value: line 1 column 1 (char 0))
step 2: parsed characters 47 to 166
step 3: valid against schema.json
{"category": "wrong_item", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
exit 0
```

O passo 1 falha exatamente como o parser da lição 18, no primeiro caractere. O passo 2 pega o texto
do primeiro `{` ao último `}`, os caracteres 47 a 166 do arquivo, o que deixa de fora a frase, o
bloco e a despedida. Isso é lido, e o passo 3 o acha válido. **Nenhum segundo pedido foi feito**, e
nenhum era preciso: o modelo deu a resposta certa no embrulho errado.

O passo 2 é uma heurística, e é honesto sobre isso. Ele funciona quando a resposta tem um objeto só.
Uma resposta com dois, ou com uma frase contendo `}` depois do objeto, recortaria algo que não é
lido, e o `repair` diria `still not JSON` em vez de chutar mais. Quando o passo 2 dá certo, o que ele
recortou passa pela mesma conferência de schema que qualquer outra resposta, então a heurística
nunca deixa passar um objeto sem conferir.

## Uma resposta que é lida e está errada

Também escrita pelo curso:

```
ana@lab:~/pe$ cat replies/wrong-enum.txt
{"category": "drinks", "refund": true, "refund_amount": 14, "summary": "Ordered an oat flat white, got cow's milk."}
ana@lab:~/pe$ repair schema.json replies/wrong-enum.txt; echo "exit $?"
step 1: parsed as it is
step 3: 1 problem; the follow-up message would be:

Your last reply did not match the schema:
- category: 'drinks' is not one of ['wrong_item', 'cold_or_late', 'allergen', 'billing', 'other']
Reply again with only the corrected JSON object.
exit 1
```

Nada a recortar desta vez: o objeto foi lido como estava. Ele falha no schema em um campo, e o
`repair` imprime a mensagem de retorno em vez de um objeto. **A mensagem leva as palavras do próprio
validador, com o caminho**, então o modelo fica sabendo qual campo e por quê. "Isso estava errado,
tente de novo" não lhe dá nada para seguir; esta nomeia `category` e lista os cinco valores
permitidos.

O programa envia essa mensagem como o próximo turno da mesma conversa, com a resposta ruim ainda nela,
e confere a nova resposta com os mesmos passos.

## Limites de tentativas

O laço da figura tem uma saída fácil de esquecer: **restam tentativas?** Um programa que tenta de
novo até a resposta ser válida vai um dia encontrar uma resposta que nunca é válida. Uma reclamação
que de fato não cabe em nenhuma das cinco categorias, um schema com um erro dentro, um modelo fora do
ar. Sem limite, esse pedido roda para sempre e é cobrado a cada tentativa.

Então o número de tentativas é escrito, e é pequeno. O `triage.py` permite três ao todo, a primeira
resposta e duas novas tentativas, pelo raciocínio de que um modelo que errou duas vezes com os erros
na frente dele dificilmente vai acertar na quarta. Quando as tentativas acabam, o programa **registra
a falha e segue em frente**: a reclamação vai para a fila de uma pessoa sem classificação, com a
última resposta e os erros anexados. É um caminho mais lento para uma reclamação, não um buraco
silencioso nos dados.

Eis o laço inteiro, com o prompt que ele manda. O prompt carrega o próprio esquema, como a primeira
seção disse que deveria. Salve-os como `~/pe/prompts/triage.txt` e `~/pe/triage.py`:

```
ana@lab:~/pe$ cat prompts/triage.txt
Triage one complaint to Café Aurora. Reply with one JSON object that
matches this JSON Schema, and nothing else:

{
  "type": "object",
  "properties": {
    "category": {"enum": ["wrong_item", "cold_or_late", "allergen", "billing", "other"]},
    "refund": {"type": "boolean"},
    "refund_amount": {"type": "number", "minimum": 0},
    "summary": {"type": "string", "maxLength": 80}
  },
  "required": ["category", "refund", "summary"],
  "additionalProperties": false
}

refund is true when the café owes the customer money back, and
refund_amount is how much, in reais.
ana@lab:~/pe$ cat triage.py
"""triage.py COMPLAINT: sort one complaint with the model, checked by repair.

The complaint goes to the model with prompts/triage.txt in front of it. Each
reply goes through repair; when it fails, repair's follow-up message is sent
back as the next turn. After MAX_ATTEMPTS replies the failure is recorded for
a person, and nothing is invented to fill the gap.
"""
import json
import subprocess
import sys

MAX_ATTEMPTS = 3

prompt = open("prompts/triage.txt", encoding="utf-8").read()
complaint = open(sys.argv[1], encoding="utf-8").read()
messages = [{"role": "user", "content": prompt + "\nComplaint:\n" + complaint}]

for attempt in range(1, MAX_ATTEMPTS + 1):
    json.dump(messages, open("triage-chat.json", "w", encoding="utf-8"))
    reply = subprocess.run(["ask", "--chat", "triage-chat.json", "--plain", "--temperature", "0"],
                           capture_output=True, text=True).stdout
    open("triage-reply.txt", "w", encoding="utf-8").write(reply)
    check = subprocess.run(["repair", "schema.json", "triage-reply.txt"],
                           capture_output=True, text=True)
    print("attempt %d" % attempt)
    print("  " + check.stdout.strip().replace("\n", "\n  "))
    if check.returncode == 0:
        sys.exit(0)
    follow_up = check.stdout.partition("would be:\n\n")[2] or "Reply with only the JSON object."
    messages += [{"role": "assistant", "content": reply}, {"role": "user", "content": follow_up}]

print("failed after %d attempts: recorded for a person, with the last reply" % MAX_ATTEMPTS)
sys.exit(1)
ana@lab:~/pe$ cat complaints/3.txt
I ordered an oat flat white and got cow's milk. I'm lactose intolerant and paid R$ 14 for it.
ana@lab:~/pe$ python3 triage.py complaints/3.txt
attempt 1
  step 1: parsed as it is
  step 3: 1 problem; the follow-up message would be:
  
  Your last reply did not match the schema:
  - summary: 'Received cow’s milk in oat flat white despite lactose intolerance, requesting refund of R$ 14.00' is too long
  Reply again with only the corrected JSON object.
attempt 2
  step 1: parsed as it is
  step 3: valid against schema.json
  {"category": "allergen", "refund": true, "refund_amount": 14.0, "summary": "Received cow’s milk in oat flat white despite lactose intolerance"}
```

A primeira resposta foi lida e falhou no esquema num campo só: um resumo com mais de 80 caracteres.
O `repair` escreveu a mensagem de retorno, o `triage.py` a mandou como o turno seguinte, e **a
segunda resposta consertou exatamente esse campo** e manteve todo o resto. Dois pedidos, e o laço
terminou sozinho. O `range(1, MAX_ATTEMPTS + 1)` é o que o faz terminar quando o modelo não colabora,
e a última linha é o que quem chamou vê então: uma falha, registrada, nunca um objeto que alguém
inventou.

## Quando o provedor confere a forma por você

No momento em que este curso é escrito (2026), vários provedores de modelos oferecem um modo de
**saída estruturada**: você passa um JSON Schema junto com o pedido, e a escolha de cada próximo
token pelo modelo fica restrita aos tokens que mantêm a saída válida contra esse schema. Isso se
chama **decodificação restrita**. O modelo não consegue mais escrever `Sure!` primeiro, porque
nenhum objeto válido começa com `S`.

Isso muda a frequência com que cada passo do laço é necessário, e não elimina o laço. Os nomes
exatos dos parâmetros mudam entre provedores e entre versões, então tire-os da documentação do
provedor, e confira quais partes do JSON Schema ele aceita: alguns modos aceitam só um subconjunto.
E **uma resposta que cabe no schema ainda pode estar errada**. A decodificação restrita faz da
categoria uma de cinco palavras; não faz dela a certa entre as cinco.
