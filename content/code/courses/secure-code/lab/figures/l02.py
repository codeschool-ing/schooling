"""Lesson 2: the figures and annotated examples."""
from fig import Fig

T = {
    "en": dict(
        sets_aria="Two ways to decide what a field accepts, drawn as regions of every possible input. On the left, a denylist: everything is accepted except a few listed bad values, so anything nobody thought of gets through, including an impossible date and a clinic that does not exist. On the right, an allowlist: nothing is accepted except a small described region, the four clinics, real dates, opening hours, so whatever nobody thought of is refused.",
        deny="denylist", allow="allowlist",
        every="every possible input",
        listed="the values somebody listed",
        through1="accepted: everything else,", through2="the unforeseen included",
        described="what is described:", d2="four clinics, real dates,", d3="opening hours",
        refused="refused: everything else",
        sets_cap="A denylist has to know every bad value in advance. An allowlist only has to know the good ones, and there are far fewer.",
        flow_aria="Where validation sits in the booking application. A request arrives at the boundary, the route. One function, validate, turns the raw JSON into a Booking with typed fields, or refuses it with a 400 that names the field. Past the boundary, the rest of the code receives only Booking values and never looks at raw input again.",
        req="request", raw="raw JSON: text, anything",
        val="validate()", typed="a Booking: typed, in range",
        rest="the rest of the code", bad="400, naming the field",
        boundary="the boundary",
        flow_cap="Validate once, where the data enters, and turn it into a type the rest of the code can trust.",
    ),
    "pt": dict(
        sets_aria="Duas maneiras de decidir o que um campo aceita, desenhadas como regiões de toda entrada possível. À esquerda, uma lista de bloqueio: tudo é aceito menos alguns valores ruins listados, então o que ninguém previu passa, inclusive uma data impossível e uma clínica que não existe. À direita, uma lista de permissão: nada é aceito além de uma pequena região descrita, as quatro clínicas, datas reais, horário de funcionamento, então o que ninguém previu é recusado.",
        deny="lista de bloqueio", allow="lista de permissão",
        every="toda entrada possível",
        listed="os valores que alguém listou",
        through1="aceito: todo o resto,", through2="inclusive o imprevisto",
        described="o que está descrito:", d2="quatro clínicas, datas reais,", d3="horário de funcionamento",
        refused="recusado: todo o resto",
        sets_cap="Uma lista de bloqueio precisa conhecer de antemão todo valor ruim. Uma lista de permissão só precisa conhecer os bons, e eles são bem menos.",
        flow_aria="Onde a validação fica na aplicação de agendamento. Uma requisição chega à fronteira, a rota. Uma função, validate, transforma o JSON bruto num Booking com campos tipados, ou recusa com um 400 que nomeia o campo. Depois da fronteira, o resto do código só recebe valores Booking e nunca mais olha a entrada bruta.",
        req="requisição", raw="JSON bruto: texto, qualquer coisa",
        val="validate()", typed="um Booking: tipado, no intervalo",
        rest="o resto do código", bad="400, nomeando o campo",
        boundary="a fronteira",
        flow_cap="Valide uma vez, onde o dado entra, e transforme-o num tipo em que o resto do código pode confiar.",
    ),
}


def figures(lang):
    t = T[lang]
    out = {}
    f = Fig("l02-sets", 720, 290, t["sets_aria"])
    for x, title in ((20, t["deny"]), (380, t["allow"])):
        f.text(x + 160, 22, title, bold=True, size=11)
        f.rect(x, 40, 320, 200, stroke="paper-dim", dashed=True)
        f.text(x + 160, 58, t["every"], fill="paper-dim", italic=True)
    f.box(40, 80, 140, 44, [t["listed"]], stroke="amber", size=9.5)
    f.text(180, 190, t["through1"], fill="paper")
    f.text(180, 206, t["through2"], fill="paper")
    f.box(460, 90, 160, 70, [t["described"], t["d2"], t["d3"]], stroke="phosphor", size=9.5)
    f.text(540, 206, t["refused"], fill="paper")
    out["l02-sets"] = f.json(t["sets_cap"])

    f = Fig("l02-flow", 720, 230, t["flow_aria"])
    f.box(20, 80, 120, 44, [t["req"]], stroke="wire")
    f.text(80, 140, t["raw"], fill="paper-dim", size=9, italic=True)
    f.box(220, 80, 140, 44, [t["val"]], stroke="phosphor", mono=True, bold=True)
    f.box(470, 40, 230, 44, [t["rest"]], stroke="wire")
    f.text(585, 100, t["typed"], fill="paper-dim", size=9, italic=True)
    f.box(470, 150, 230, 44, [t["bad"]], stroke="amber")
    f.arrow([(140, 102), (220, 102)])
    f.arrow([(360, 95), (420, 95), (420, 62), (470, 62)])
    f.arrow([(360, 110), (420, 110), (420, 172), (470, 172)], color="amber")
    f.arrow([(190, 30), (190, 210)], head=False, dashed=True, color="paper-dim")
    f.text(190, 20, t["boundary"], fill="paper-dim", italic=True)
    out["l02-flow"] = f.json(t["flow_cap"])
    return out


FLAWED = [
    ("from flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n\nFORBIDDEN = (\"<\", \">\", \";\", \"--\")\n\n\ndef looks_safe(value):\n    return not any(bad in value for bad in FORBIDDEN)\n\n",
     "A list of characters somebody once decided were dangerous. Everything else is welcome.",
     "Uma lista de caracteres que alguém um dia decidiu que eram perigosos. Todo o resto é bem-vindo."),
    ("@app.post(\"/bookings\")\ndef create():\n    data = request.get_json()\n    for field in (\"clinic\", \"date\", \"time\", \"phone\"):\n        if not looks_safe(str(data.get(field, \"\"))):\n            return jsonify(error=f\"invalid {field}\"), 400\n    BOOKINGS.append(data)\n    return jsonify(data), 201",
     "Each field is checked against the list and stored exactly as it arrived. A missing field becomes an empty string, which contains nothing forbidden.",
     "Cada campo é conferido contra a lista e guardado exatamente como chegou. Um campo ausente vira uma string vazia, que não contém nada proibido."),
]

FIXED = [
    ("import re\nfrom dataclasses import dataclass\nfrom datetime import date\n\nfrom flask import Flask, jsonify, request\n\napp = Flask(__name__)\nBOOKINGS = []\n",
     "Same application; `looks_safe` and its list are gone.",
     "A mesma aplicação; `looks_safe` e a lista dela saíram."),
    ("CLINICS = {\"pinheiros\", \"moema\", \"tatuape\", \"santana\"}\nSLOTS = {f\"{hour:02d}:00\" for hour in range(7, 20)}\nPHONE = re.compile(r\"[0-9]{10,11}\")\n",
     "The allowlists: four clinics, one slot an hour from 07:00 to 19:00, a phone of 10 or 11 ASCII digits. Each one describes what is good, so the next surprise is refused without anybody having predicted it.",
     "As listas de permissão: quatro clínicas, um horário por hora das 07:00 às 19:00, um telefone de 10 ou 11 dígitos ASCII. Cada uma descreve o que é bom, então a próxima surpresa é recusada sem que ninguém a tenha previsto."),
    ("\nclass Invalid(Exception):\n    def __init__(self, field):\n        super().__init__(field)\n        self.field = field\n\n\n@dataclass(frozen=True)\nclass Booking:\n    clinic: str\n    day: date\n    time: str\n    phone: str\n",
     "What leaves the boundary is a `Booking`, with a real `date` in it, not a dictionary of strings.",
     "O que sai da fronteira é um `Booking`, com uma `date` de verdade dentro, não um dicionário de strings."),
    ("\ndef validate(data):\n    if not isinstance(data, dict):\n        raise Invalid(\"body\")\n    clinic, day, time, phone = (data.get(k) for k in (\"clinic\", \"date\", \"time\", \"phone\"))\n    if clinic not in CLINICS:\n        raise Invalid(\"clinic\")\n    try:\n        parsed = date.fromisoformat(day)\n    except (TypeError, ValueError):\n        raise Invalid(\"date\") from None\n    if time not in SLOTS:\n        raise Invalid(\"time\")\n    if not isinstance(phone, str) or not PHONE.fullmatch(phone):\n        raise Invalid(\"phone\")\n    return Booking(clinic, parsed, time, phone)\n",
     "One function, one check per field, and each refusal names the field. `fullmatch` tests the whole string, where `match` would accept a valid phone followed by anything. A field that is absent is `None`, and `None` is in no allowlist.",
     "Uma função, uma verificação por campo, e cada recusa nomeia o campo. `fullmatch` testa a string inteira, onde `match` aceitaria um telefone válido seguido de qualquer coisa. Um campo ausente é `None`, e `None` não está em lista de permissão nenhuma."),
    ("\n@app.post(\"/bookings\")\ndef create():\n    try:\n        booking = validate(request.get_json(silent=True))\n    except Invalid as e:\n        return jsonify(error=f\"invalid {e.field}\"), 400\n    BOOKINGS.append(booking)\n    return jsonify(clinic=booking.clinic, date=booking.day.isoformat(),\n                   time=booking.time, phone=booking.phone), 201",
     "The route validates and then only touches the `Booking`. `silent=True` turns a body that is not JSON into `None`, which `validate` refuses like any other bad input instead of letting Flask answer on its own.",
     "A rota valida e depois só mexe no `Booking`. `silent=True` transforma um corpo que não é JSON em `None`, que `validate` recusa como qualquer outra entrada ruim, em vez de deixar o Flask responder por conta própria."),
]

EXAMPLES = {
    "booking-form": [{"language": "python", "file": "app.py", "parts": FLAWED}],
    "the-fix": [{"language": "python", "file": "app.py", "parts": FIXED}],
}
