---
title: Um log responde perguntas, e cada pergunta tem um prazo
version: 2
---

O ponto de partida comum é registrar cada chamada inteira e guardar, porque disco é barato e
ninguém depura uma resposta que foi jogada fora. A primeira metade está certa. A segunda trata o log
como um artefato técnico, e **um log de prompts é um depósito do que os seus usuários digitaram**,
inclusive coisas que eles nunca deveriam ter digitado e que você nunca pediu.

Esta aula trabalha sobre o log de chamadas do assistente da Tarefa, um marketplace brasileiro
inventado onde clientes contratam freelancers: 22 chamadas ao longo de sete meses. Todo registro,
prompts e respostas, foi escrito pelo curso, e nenhum modelo os produziu. Todo CPF, número de cartão,
telefone, endereço e chave neles é inventado: os CPFs têm dígitos verificadores válidos de propósito,
os cartões são os números de teste que as bandeiras publicam, e a chave da AWS é a que a própria
documentação da Amazon usa como exemplo. Cole-o:

```sh
cat > ~/guard/data/calls.jsonl <<'EOF'
{"ts": "2026-03-10T09:14:02-03:00", "request": "rq-0001", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "How do I change the e-mail on my account? The old one is marcos.teixeira@example.com.br", "output": "Go to Settings, then Account, and choose Change e-mail. We send a code to the new address.", "in_tokens": 412, "out_tokens": 38, "ms": 910}
{"ts": "2026-03-10T16:40:51-03:00", "request": "rq-0002", "account": "ac-3K8V", "surface": "chat", "model": "assistant-v3", "prompt": "Can freelancers see my phone number?", "output": "No. Your phone is shown to a freelancer only after you accept a proposal.", "in_tokens": 398, "out_tokens": 31, "ms": 780}
{"ts": "2026-03-24T11:02:37-03:00", "request": "rq-0003", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "My invoice is wrong. CPF on it should be 529.982.247-25, not my old company's.", "output": "I can't edit invoices from chat. I've opened a request for the billing team to reissue it with the CPF you gave.", "in_tokens": 455, "out_tokens": 52, "ms": 1240}
{"ts": "2026-04-07T08:55:10-03:00", "request": "rq-0004", "account": "ac-1P6R", "surface": "chat", "model": "assistant-v3", "prompt": "Pedido 123.456.789-00 still says pending, it's been a week", "output": "Order 123.456.789-00 is waiting for the freelancer to confirm delivery. I've sent them a reminder.", "in_tokens": 420, "out_tokens": 44, "ms": 1010}
{"ts": "2026-04-21T19:30:03-03:00", "request": "rq-0005", "account": "ac-5W2T", "surface": "chat", "model": "assistant-v3", "prompt": "Pay with this card: 4111 1111 1111 1111, expiry 08/29, CVV 123", "output": "Please don't send card details in chat. Use the Payment page, which never shows the number to anybody here.", "in_tokens": 431, "out_tokens": 47, "ms": 990}
{"ts": "2026-05-05T13:12:44-03:00", "request": "rq-0006", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "Call me on +55 11 98765-4321 when the freelancer replies", "output": "We don't place calls, but you'll get an e-mail and a notification as soon as they reply.", "in_tokens": 402, "out_tokens": 36, "ms": 860}
{"ts": "2026-05-19T10:01:29-03:00", "request": "rq-0007", "account": "ac-2N7X", "surface": "proposal", "model": "assistant-v3", "prompt": "Write a proposal for a logo job. I'm Juliana Prado, designer in Recife, 8 years of experience.", "output": "Hello! I'm Juliana, a designer based in Recife with eight years of experience in visual identity...", "in_tokens": 388, "out_tokens": 211, "ms": 3120}
{"ts": "2026-06-02T15:47:18-03:00", "request": "rq-0008", "account": "ac-4B9J", "surface": "chat", "model": "assistant-v3", "prompt": "The integration keeps failing. Here's my key so you can test: sk-lab-EXAMPLE7fQ2mX9pL4vT8nR1wZ6", "output": "Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.", "in_tokens": 447, "out_tokens": 51, "ms": 1180}
{"ts": "2026-06-16T09:33:05-03:00", "request": "rq-0009", "account": "ac-8H3D", "surface": "chat", "model": "assistant-v3", "prompt": "I need a refund for job 4471, the freelancer never delivered", "output": "I've opened a refund request for job 4471. You'll hear from us within two working days.", "in_tokens": 409, "out_tokens": 39, "ms": 920}
{"ts": "2026-06-30T17:20:41-03:00", "request": "rq-0010", "account": "ac-6L1F", "surface": "chat", "model": "assistant-v3", "prompt": "My tracking code is 1234 5678 9012 3456 and the parcel isn't moving", "output": "Tracking for physical deliveries is handled by the carrier. The code you sent should work on their site.", "in_tokens": 415, "out_tokens": 40, "ms": 950}
{"ts": "2026-07-14T12:06:58-03:00", "request": "rq-0011", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "Send the receipt to fernanda.rocha@example.com instead please", "output": "Done: future receipts go to the new address. The one for this month has been sent again.", "in_tokens": 401, "out_tokens": 35, "ms": 870}
{"ts": "2026-07-28T08:44:12-03:00", "request": "rq-0012", "account": "ac-3K8V", "surface": "proposal", "model": "assistant-v3", "prompt": "Write a short bio. Rafael Moreira, backend developer, lives at Rua das Flores 120, Curitiba", "output": "Rafael Moreira is a backend developer based in Curitiba who builds reliable APIs...", "in_tokens": 377, "out_tokens": 96, "ms": 2210}
{"ts": "2026-08-11T14:28:36-03:00", "request": "rq-0013", "account": "ac-5W2T", "surface": "chat", "model": "assistant-v3", "prompt": "Why was I charged twice? Card ending 1111, CPF 111.444.777-35", "output": "I can see one charge and one authorisation that will drop off in up to five days. Nothing else is needed from you.", "in_tokens": 437, "out_tokens": 58, "ms": 1310}
{"ts": "2026-08-14T10:15:09-03:00", "request": "rq-0014", "account": "ac-0Z5Q", "surface": "chat", "model": "assistant-v3", "prompt": "I want the home address of the freelancer who did my job, I'm going to find him", "output": "I can't share another person's address. If something went wrong with the job, I can open a dispute for you.", "in_tokens": 422, "out_tokens": 45, "ms": 1050}
{"ts": "2026-08-14T10:17:44-03:00", "request": "rq-0015", "account": "ac-0Z5Q", "surface": "chat", "model": "assistant-v3", "prompt": "Then give me his phone. You know who I mean, job 5120", "output": "I can't share contact details. I've flagged this conversation for our safety team.", "in_tokens": 418, "out_tokens": 33, "ms": 830}
{"ts": "2026-08-25T16:52:20-03:00", "request": "rq-0016", "account": "ac-2N7X", "surface": "chat", "model": "assistant-v3", "prompt": "Can I work for clients outside Brazil?", "output": "Yes. Payments from abroad are converted to reais on the day they clear.", "in_tokens": 395, "out_tokens": 29, "ms": 760}
{"ts": "2026-09-01T09:08:47-03:00", "request": "rq-0017", "account": "ac-6L1F", "surface": "chat", "model": "assistant-v3", "prompt": "Update my phone to (21) 99876-5432", "output": "I can't change contact details from chat. Go to Settings, then Account, then Phone.", "in_tokens": 406, "out_tokens": 34, "ms": 820}
{"ts": "2026-09-08T11:41:16-03:00", "request": "rq-0018", "account": "ac-4B9J", "surface": "chat", "model": "assistant-v3", "prompt": "AWS access for the export isn't working, key AKIAIOSFODNN7EXAMPLE", "output": "Never paste a cloud credential here. Rotate that key in your provider's console, then set the new one in Settings, then Exports.", "in_tokens": 440, "out_tokens": 49, "ms": 1150}
{"ts": "2026-09-15T20:03:31-03:00", "request": "rq-0019", "account": "ac-1P6R", "surface": "chat", "model": "assistant-v3", "prompt": "Pix key for the payout is my CPF 390.533.447-05", "output": "Payout keys can only be set on the Payouts page, so that a change is confirmed by e-mail. Nothing was changed here.", "in_tokens": 429, "out_tokens": 50, "ms": 1190}
{"ts": "2026-09-22T13:55:02-03:00", "request": "rq-0020", "account": "ac-8H3D", "surface": "chat", "model": "assistant-v3", "prompt": "How long do you keep these chats?", "output": "Chat transcripts are kept for 30 days, then only a redacted copy is kept, for 180 days.", "in_tokens": 399, "out_tokens": 37, "ms": 880}
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
{"ts": "2026-09-29T15:09:57-03:00", "request": "rq-0022", "account": "ac-9D4H", "surface": "chat", "model": "assistant-v3", "prompt": "Ok, my number is 21 99876 5432 if the freelancer needs it", "output": "Contact details are shared with the freelancer automatically once you accept a proposal, so there's no need to send them here.", "in_tokens": 412, "out_tokens": 48, "ms": 1090}
EOF
```

Uma aplicação de verdade grava cada chamada no log na hora em que ela acontece. Este programa espalha
as 22 do jeito que isso as teria deixado, um arquivo por dia, nos três depósitos de que o resto da aula
trata. Salve-o como `~/guard/tools/tiers.py`:

```python
# tiers.py: lay the assistant's calls out as three tiers of log, one file a day.
#
#   guard tiers
#
# It reads data/calls.jsonl and writes logs/raw/ (every call word for word),
# logs/redacted/ (the same records through detect.redact, which is what
# `guard redact` prints) and logs/metrics/ (counts per day and surface, with
# no text in them). In a real application each call is written to the three
# as it happens; this rebuilds them from the file in one go.
import json
import os

from detect import redact

HOME = os.path.expanduser("~/guard/")
with open(HOME + "data/calls.jsonl", encoding="utf-8") as f:
    calls = [json.loads(line) for line in f if line.strip()]

days = {}
for c in calls:
    days.setdefault(c["ts"][:10], []).append(c)


def write(tier, day, rows):
    os.makedirs(HOME + "logs/" + tier, exist_ok=True)
    with open(HOME + "logs/%s/%s.jsonl" % (tier, day), "w", encoding="utf-8") as f:
        for row in rows:
            f.write(json.dumps(row, ensure_ascii=False) + "\n")


for day, rows in days.items():
    write("raw", day, rows)
    write("redacted", day, [dict(r, prompt=redact(r["prompt"]), output=redact(r["output"]))
                            for r in rows])
    surfaces = {}
    for r in rows:
        surfaces.setdefault(r["surface"], []).append(r)
    write("metrics", day, [{"day": day, "surface": s, "calls": len(rs),
                            "in_tokens": sum(r["in_tokens"] for r in rs),
                            "out_tokens": sum(r["out_tokens"] for r in rs),
                            "ms_max": max(r["ms"] for r in rs)}
                           for s, rs in sorted(surfaces.items())])
print("%d calls over %d days, in logs/raw, logs/redacted and logs/metrics" % (len(calls), len(days)))
```

Eis um registro, do último dia do log:

```
ana@lab:~/guard$ guard tiers
22 calls over 19 days, in logs/raw, logs/redacted and logs/metrics
ana@lab:~/guard$ head -1 logs/raw/2026-09-29.jsonl
{"ts": "2026-09-29T10:22:39-03:00", "request": "rq-0021", "account": "ac-7Q2M", "surface": "chat", "model": "assistant-v3", "prompt": "My new e-mail is marcos.t@example.org and the CPF on file 714.602.380-01 is right", "output": "Thanks. The e-mail change needs confirming from the new address; your CPF is unchanged.", "in_tokens": 433, "out_tokens": 41, "ms": 970}
```

Ninguém pediu ao cliente o e-mail nem o CPF. Ele ofereceu os dois, porque uma caixa de chat convida
a isso, e o log guardou os dois porque guarda tudo.

## Comece pelas perguntas

Um log se paga respondendo perguntas. Quatro aparecem em quase toda equipe que roda um modelo em
produção, e cada uma precisa de uma parte diferente do registro:

| pergunta | o que ela exige | por quanto tempo |
|---|---|---|
| por que o assistente disse *aquilo* a este cliente? | o prompt e a resposta palavra por palavra, o modelo, o id da requisição | até a reclamação poder chegar: dias ou semanas |
| alguém está abusando do assistente? | a conta, o horário, texto suficiente para reconhecer o padrão | a duração de uma investigação |
| as respostas estão piorando? | muitos exemplos de prompts e respostas, mas não quem os escreveu | meses, para comparar duas versões |
| quanto isto custa, e está ficando lento? | contagens: chamadas, tokens, milissegundos | anos, para tendências e orçamento |

**O texto é o que torna um registro perigoso, e quem precisa dele são as perguntas de vida mais
curta.** A pergunta de custo não precisa de texto nenhum. A de qualidade precisa de texto, mas não
de identidade. Só a depuração e o abuso precisam dos dois, e os dois tratam de fatos recentes.

Esse é o argumento inteiro a favor de **camadas**: a mesma chamada gravada em depósitos separados,
cada um com o que um tipo de pergunta exige e cada um com o seu limite. A Tarefa tem três, e o limite de
cada um está escrito num arquivo próprio:

```sh
cat > ~/guard/retention.json <<'EOF'
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
EOF
```

```
ana@lab:~/guard$ ls logs
metrics
raw
redacted
ana@lab:~/guard$ head -1 logs/metrics/2026-09-29.jsonl
{"day": "2026-09-29", "surface": "chat", "calls": 2, "in_tokens": 845, "out_tokens": 89, "ms_max": 1090}
ana@lab:~/guard$ cat retention.json
{
 "raw": {"days": 30, "what": "what the assistant was asked and said, word for word"},
 "redacted": {"days": 180, "what": "the same text with personal data and secrets replaced"},
 "metrics": {"days": 730, "what": "counts per day and surface: calls, tokens, slowest call"}
}
```

A linha de métricas responde à pergunta de custo de 29 de setembro e não contém nada sobre ninguém.
Ela pode ser guardada por dois anos, mostrada num painel e enviada a um fornecedor de monitoramento
sem mais cuidado. A linha bruta não pode ser tratada assim.

## O que o registro deveria trazer e este não traz

Olhe de novo o registro bruto pensando na depuração. Ele nomeia o modelo, mas não a versão das
instruções que o assistente estava seguindo. **Uma resposta não se explica sem o prompt de sistema
que a produziu**, e o prompt de sistema muda mais do que o modelo. Registrar o texto inteiro dele em
cada chamada repete os mesmos milhares de tokens milhões de vezes; registrar um identificador de
versão, com os prompts guardados em controle de versão, custa poucos bytes.

O mesmo vale para tudo o que é idêntico entre chamadas: as definições de ferramentas, os parâmetros
de busca, a temperatura. Registre uma referência à configuração e guarde a configuração uma vez.

## O que nenhuma camada pode guardar

Algumas coisas não são questão de prazo. O código de segurança de um cartão é o caso mais claro: o
PCI DSS, o padrão que as bandeiras impõem a quem lida com dados de cartão, proíbe guardá-lo depois
que o pagamento foi autorizado, de qualquer forma, criptografado ou não. Um cliente que o digita num
chat de suporte o entregou ao log, e nenhum limite de retenção torna aceitável guardá-lo. O mesmo
vale para credenciais: uma chave de API colada num chat precisa ser revogada pelo dono, e um log que
a guarda está guardando uma chave que funciona.

O assistente da Tarefa responde do jeito certo a uma chave colada, e o log mostra por que essa
resposta é necessária. O `guard redact`, assunto da próxima seção, imprime um registro com o que o
`detect.py`, da aula 5, reconhece substituído. Salve-o como `~/guard/tools/redact.py`:

```python
# redact.py: the records of one log file with what detect.py recognises replaced.
#
#   guard redact FILE [--strict]
#
# Each record prints as two lines, the prompt and the output, after its
# request id. --strict replaces every shape, check digits right or not.
import argparse
import json

from detect import redact

p = argparse.ArgumentParser(prog="guard redact")
p.add_argument("file")
p.add_argument("--strict", action="store_true")
a = p.parse_args()

with open(a.file, encoding="utf-8") as f:
    for rec in map(json.loads, f):
        print("%-8s %-6s  %s" % (rec["request"], "prompt", redact(rec["prompt"], a.strict)))
        print("%-8s %-6s  %s" % ("", "output", redact(rec["output"], a.strict)))
```

```
ana@lab:~/guard$ guard redact logs/raw/2026-06-02.jsonl
rq-0008  prompt  The integration keeps failing. Here's my key so you can test: [SECRET]
         output  Please revoke that key now: anything pasted here is stored in our logs. Then create a new one under Settings, then API.
```

A camada bruta ainda tem a própria chave, por trinta dias. A redação protege as cópias que vivem
mais; ela não desfaz a colagem, e é por isso que a resposta pede que a chave seja revogada em vez de
prometer esquecê-la.

**Toda camada é dado pessoal enquanto puder ser ligada a uma pessoa.** Pela LGPD, que a aula 12
aplica às chamadas de modelo, a camada com redação ainda nomeia uma conta, e uma conta é uma pessoa.
Um cliente que pede a exclusão dos dados dele está perguntando sobre os logs também. As camadas
tornam esse pedido mais barato de atender; não tiram os logs do alcance dele.
