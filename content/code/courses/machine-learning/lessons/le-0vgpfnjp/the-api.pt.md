---
title: Um modelo atrás de um endereço
version: 1
---

Um arquivo em disco serve para programas escritos em Python, nesta máquina, por alguém que sabe importar o
`churn_model`. O sistema da equipe de retenção não é nada disso. O que ele sabe fazer é mandar um pedido a
um endereço e ler a resposta, e é isso que uma **API** é aqui: um programa pequeno que escuta numa porta,
recebe um assinante descrito em **JSON** e responde com uma chance.

O **FastAPI** monta esse programa a partir de funções comuns de Python, e o **Uvicorn** é o servidor que o
roda, os dois já instalados pelo `requirements.txt` da aula 1. O serviço inteiro é um arquivo. Salve isto
como `app.py`:

```schooling-example
{
  "language": "python",
  "file": "app.py",
  "parts": [
    {
      "code": "# app.py\nimport json\nimport time\nfrom typing import Literal\n\nimport pandas as pd\nfrom fastapi import FastAPI\nfrom pydantic import BaseModel, Field\n\nimport stored\nfrom feira import CREDIT, KEPT, SAVED\n\nMODEL, CARD = stored.load(\"churn-2025-12\")\nCUT = CREDIT / (SAVED * KEPT)\napp = FastAPI(title=\"Feira em Casa churn\")\n",
      "note": "O modelo é carregado **uma vez, quando o servidor sobe**, pelo `stored.load`, então um servidor com as versões erradas se recusa a subir em vez de responder."
    },
    {
      "code": "\nclass Subscriber(BaseModel):\n    customer_id: str\n    city: str\n    age: int = Field(ge=18, le=99)\n    app_user: Literal[0, 1]\n    payment: str\n    plan: str\n    box: str\n    channel: str\n    tenure_months: int = Field(ge=0)\n    price_month: float = Field(gt=0)\n    orders_90d: int = Field(ge=0)\n    skips_90d: int = Field(ge=0)\n    late_90d: int = Field(ge=0)\n    complaints_90d: int = Field(ge=0)\n    support_calls_90d: int = Field(ge=0)",
      "note": "**O pedido, descrito como uma classe.** Toda coluna que o pipeline lê, com o tipo e a faixa que pode ter. O FastAPI confere cada pedido contra ela antes de qualquer código seu rodar, e recusa o que não cabe."
    },
    {
      "code": "    rating_90d: float | None = Field(ge=1, le=5)\n    days_since_login: float | None = Field(ge=0)\n",
      "note": "**`float | None` sem valor padrão** quer dizer que o campo tem de ser enviado, e pode ser `null`. Um assinante sem nota é um fato que o modelo sabe ler; um pedido que esqueceu o campo é um erro, e os dois não podem parecer iguais."
    },
    {
      "code": "\n@app.get(\"/health\")\ndef health():\n    return {\"model\": CARD[\"name\"], \"trained_to\": CARD[\"to\"], \"cut\": round(CUT, 4)}\n",
      "note": "**Uma verificação de saúde** responde qual modelo está carregado, que é a primeira pergunta que alguém faz a um servidor que está se comportando de um jeito estranho."
    },
    {
      "code": "\n@app.post(\"/score\")\ndef score(subscriber: Subscriber):\n    rows = pd.DataFrame([subscriber.model_dump()])\n    chance = float(MODEL.predict_proba(rows)[0, 1])",
      "note": "**Um assinante entra, uma resposta sai.** O `model_dump` transforma o pedido conferido de volta num dicionário, e o dicionário vira uma tabela de uma linha, o formato com que o pipeline foi ajustado."
    },
    {
      "code": "    answer = {\"customer_id\": subscriber.customer_id, \"chance\": round(chance, 4),\n              \"credit\": chance >= CUT, \"model\": CARD[\"name\"]}\n    with open(\"scores.jsonl\", \"a\") as log:\n        log.write(json.dumps({\"at\": time.strftime(\"%Y-%m-%dT%H:%M:%S\"), **answer}) + \"\\n\")\n    return answer",
      "note": "A resposta leva **a decisão e o nome do modelo** além da chance, e toda resposta é gravada em `scores.jsonl`, uma linha cada. A aula 22 trata de por que esse arquivo importa."
    }
  ]
}
```

A maior parte do arquivo é a descrição de um assinante, e essa é a proporção certa. **O modelo confia
inteiramente no que recebe**: com uma idade de −3 ou uma nota 40 ele devolve uma chance sem reclamar,
porque o pipeline da aula 15 só sabe transformar números, não duvidar deles. Uma planilha que digita uma
nota como `"4,2"`, um cliente que manda idades em meses, um campo renomeado na versão de outra pessoa:
cada um vira uma chance confiante e errada, a não ser que algo na porta confira. O `Subscriber` é essa
conferência, e não custa nada no momento em que um pedido chega.

Vale explicar três escolhas dele:

- **As palavras são `str` simples**, não uma lista dos valores que o modelo conhece. Uma lista recusaria
  o plano mensal, que chegou em fevereiro de 2026 e que o pipeline sabe tratar: o
  `handle_unknown="ignore"` da aula 15 dá zeros a ele. O custo é que um erro de digitação num nome de
  plano também é aceito, e pontuado como um plano desconhecido. A próxima seção manda um.
- **As faixas são as que uma pessoa defenderia**: 18 a 99 para a idade, 1 a 5 para uma nota, nada
  negativo onde se quer uma contagem.
- **A decisão vai junto com a chance.** Quem chama é avisado se deve mandar o crédito, pelo mesmo `CUT`
  que toda aula usou, então a conta do ponto de equilíbrio mora num lugar só e não em cada sistema que
  pergunta.
