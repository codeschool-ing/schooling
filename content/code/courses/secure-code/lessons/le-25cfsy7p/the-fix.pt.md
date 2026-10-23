---
title: A correção, numa fronteira só
version: 1
---

A correção troca a lista de bloqueio por uma lista de permissão por campo, e leva toda a verificação
para um lugar só. **A validação pertence à fronteira**, onde o dado de fora entra no programa, e deve
acontecer ali uma vez. Uma verificação espalhada pelo código é uma verificação que alguém esquece na
rota nova; uma verificação na fronteira é o motivo de o resto do código nunca precisar perguntar.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"l02-flow\" aria-label=\"Onde a validação fica na aplicação de agendamento. Uma requisição chega à fronteira, a rota. Uma função, validate, transforma o JSON bruto num Booking com campos tipados, ou recusa com um 400 que nomeia o campo. Depois da fronteira, o resto do código só recebe valores Booking e nunca mais olha a entrada bruta.\"><defs><marker id=\"l02-flow-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-flow-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"80\" width=\"120\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"80.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">requisição</text><text x=\"80\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">JSON bruto: texto, qualquer coisa</text><rect x=\"220\" y=\"80\" width=\"140\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"290.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">validate()</text><rect x=\"470\" y=\"40\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o resto do código</text><text x=\"585\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-style=\"italic\" fill=\"var(--paper-dim)\">um Booking: tipado, no intervalo</text><rect x=\"470\" y=\"150\" width=\"230\" height=\"44\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">400, nomeando o campo</text><path d=\"M140 102 L220 102\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-paper-dim)\"></path><path d=\"M360 95 L420 95 L420 62 L470 62\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-paper-dim)\"></path><path d=\"M360 110 L420 110 L420 172 L470 172\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l02-flow-ah-amber)\"></path><path d=\"M190 30 L190 210\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 4\"></path><text x=\"190\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">a fronteira</text></svg>", "caption": "Valide uma vez, onde o dado entra, e transforme-o num tipo em que o resto do código pode confiar."}
```

Aqui está o `app.py` inteiro depois da mudança. Substitua o arquivo por ele:

```schooling-example
{"language": "python", "file": "app.py", "parts": [{"code": "import re\nfrom dataclasses import dataclass\nfrom datetime import date\n\nfrom flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n", "note": "A mesma aplicação; `looks_safe` e a lista dela saíram."}, {"code": "CLINICS = {\"pinheiros\", \"moema\", \"tatuape\", \"santana\"}\nSLOTS = {f\"{hour:02d}:00\" for hour in range(7, 20)}\nPHONE = re.compile(r\"[0-9]{10,11}\")\n", "note": "As listas de permissão: quatro clínicas, um horário por hora das 07:00 às 19:00, um telefone de 10 ou 11 dígitos ASCII. Cada uma descreve o que é bom, então a próxima surpresa é recusada sem que ninguém a tenha previsto."}, {"code": "\nclass Invalid(Exception):\n    def __init__(self, field):\n        super().__init__(field)\n        self.field = field\n\n\n@dataclass(frozen=True)\nclass Booking:\n    clinic: str\n    day: date\n    time: str\n    phone: str\n", "note": "O que sai da fronteira é um `Booking`, com uma `date` de verdade dentro, não um dicionário de strings."}, {"code": "\ndef validate(data):\n    if not isinstance(data, dict):\n        raise Invalid(\"body\")\n    clinic, day, time, phone = (data.get(k) for k in (\"clinic\", \"date\", \"time\", \"phone\"))\n    if clinic not in CLINICS:\n        raise Invalid(\"clinic\")\n    try:\n        parsed = date.fromisoformat(day)\n    except (TypeError, ValueError):\n        raise Invalid(\"date\") from None\n    if time not in SLOTS:\n        raise Invalid(\"time\")\n    if not isinstance(phone, str) or not PHONE.fullmatch(phone):\n        raise Invalid(\"phone\")\n    return Booking(clinic, parsed, time, phone)\n", "note": "Uma função, uma verificação por campo, e cada recusa nomeia o campo. `fullmatch` testa a string inteira, onde `match` aceitaria um telefone válido seguido de qualquer coisa. Um campo ausente é `None`, e `None` não está em lista de permissão nenhuma."}, {"code": "\n@app.post(\"/bookings\")\ndef create():\n    try:\n        booking = validate(request.get_json(silent=True))\n    except Invalid as e:\n        return jsonify(error=f\"invalid {e.field}\"), 400\n    BOOKINGS.append(booking)\n    return jsonify(clinic=booking.clinic, date=booking.day.isoformat(),\n                   time=booking.time, phone=booking.phone), 201", "note": "A rota valida e depois só mexe no `Booking`. `silent=True` transforma um corpo que não é JSON em `None`, que `validate` recusa como qualquer outra entrada ruim, em vez de deixar o Flask responder por conta própria."}]}
```

Três decisões nesse arquivo valem nome, porque são os hábitos que valem para qualquer outro
formulário:

- **A saída da validação é de um tipo diferente da entrada.** `validate` recebe o JSON que chegou e
  devolve um `Booking`, ou levanta exceção. O código que recebe um `Booking` sabe que a data dele é
  uma data real, sem verificar de novo, e uma função que ainda recebe um dicionário bruto chama
  atenção numa revisão.
- **O erro nomeia o campo e mais nada.** Não devolve o valor, e não explica a regra de um jeito que
  ajude alguém a sondá-la um caractere por vez. `invalid phone` basta para o formulário destacar a
  caixa certa.
- **Ausente e errado são recusados pela mesma verificação.** `data.get("phone")` é `None` quando o
  campo falta, e `None` não está em lista de permissão nenhuma, então o campo ausente não precisa de
  código próprio.

### Verde

```
(.venv) ana@vm:~/sc/booking$ pytest
============================= test session starts ==============================
platform linux -- Python 3.13.16, pytest-9.1.1, pluggy-1.7.0
rootdir: /home/ana/sc/booking
collected 9 items

test_app.py .........                                                    [100%]

============================== 9 passed in 0.12s ===============================
```

O `git diff --stat` resume a mudança: um arquivo, 43 linhas entrando e 9 saindo. As 9 são a lista de
bloqueio e a função que a aplicava, que sumiram por inteiro; as 43 são as listas de permissão, o tipo
`Booking` e o `validate`.

```
(.venv) ana@vm:~/sc/booking$ git diff --stat
 app.py | 52 +++++++++++++++++++++++++++++++++++++++++++---------
 1 file changed, 43 insertions(+), 9 deletions(-)
(.venv) ana@vm:~/sc/booking$ git commit -am "Validate bookings against allowlists, at one boundary"
[main 4bbe89f] Validate bookings against allowlists, at one boundary
 1 file changed, 43 insertions(+), 9 deletions(-)
```

### E de fora

O cliente de teste e uma requisição de verdade veem a mesma resposta. Inicie a aplicação com
`flask --app app run` e, de um segundo terminal, envie a data impossível com `curl`:

```
(.venv) ana@vm:~/sc/booking$ curl -s -X POST http://127.0.0.1:5000/bookings -H 'Content-Type: application/json' -d '{"clinic": "moema", "date": "2026-11-31", "time": "09:00", "phone": "11987654321"}'
{"error":"invalid date"}
```

Validação não torna um valor **seguro para usar em qualquer lugar**. Um nome de clínica que passou
pela lista de permissão continua sendo texto, e no momento em que vai para HTML, SQL ou um comando de
shell precisa do tratamento próprio daquele lugar. As aulas 4 a 6 tratam desses lugares. O que a
validação compra é mais estreito e ainda vale uma aula: o programa só guarda dados que significam o
que dizem significar.
