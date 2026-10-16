---
title: O trimestre numa tela
version: 1
---

O primeiro rascunho de Bia tinha catorze gráficos porque o time tinha catorze jeitos de olhar o próprio trabalho. A revisão precisa de um punhado de números por mês, lado a lado, para que a direção de cada um apareça num relance. **Salve o programa abaixo como `quarter.py`**, na pasta onde `billing.py` escreveu `items.csv` e `deploys.csv`.

```schooling-example
{
  "language": "python",
  "file": "quarter.py",
  "parts": [
    {
      "code": "\"\"\"quarter.py: the Billing team's third quarter on one screen, month by month.\"\"\"\nimport csv\nimport math\nfrom datetime import datetime\n\n\ndef percentile(values, p):\n    \"\"\"The smallest value with at least p% of the values at or below it.\"\"\"\n    ordered = sorted(values)\n    return ordered[math.ceil(p / 100 * len(ordered)) - 1]\n\n\n",
      "note": "**O mesmo percentil do `cycle.py` da aula 2**: o menor valor com pelo menos aquela fração dos itens nele ou abaixo dele."
    },
    {
      "code": "months = {m: {\"cycle\": [], \"deploys\": 0, \"failed\": 0, \"restore\": 0} for m in (\"07\", \"08\", \"09\")}\nfor i in csv.DictReader(open(\"items.csv\")):\n    if i[\"merged\"] and i[\"merged\"][5:7] in months:\n        days = (datetime.fromisoformat(i[\"merged\"][:10]) - datetime.fromisoformat(i[\"started\"])).days\n        months[i[\"merged\"][5:7]][\"cycle\"].append(days)\nfor d in csv.DictReader(open(\"deploys.csv\")):\n    m = months.get(d[\"at\"][5:7])\n    if m:\n        m[\"deploys\"] += 1\n        if d[\"failed\"] == \"1\":\n            m[\"failed\"] += 1\n            m[\"restore\"] += (datetime.fromisoformat(d[\"restored\"]) -\n                             datetime.fromisoformat(d[\"at\"])).seconds // 60\n\n",
      "note": "**Três meses, reunidos numa passada por cada arquivo.** Um item pertence ao mês em que foi integrado, com seu tempo de ciclo do início à integração; um deploy pertence ao mês em que saiu, e um com falha soma os minutos até ser restaurado."
    },
    {
      "code": "print(\"month  finished  cycle median  85th  deploys  failed  minutes broken\")\nfor name, m in zip((\"Jul\", \"Aug\", \"Sep\"), months.values()):\n    c = m[\"cycle\"]\n    print(f\"{name:5}  {len(c):8}  {percentile(c, 50):10} d  {percentile(c, 85):2} d\"\n          f\"  {m['deploys']:7}  {m['failed']:6}  {m['restore']:14}\")\n",
      "note": "**Uma linha por mês**: quantos itens terminaram, a mediana e o percentil 85 dos seus tempos de ciclo, quantos deploys saíram, quantos falharam e por quantos minutos o serviço ficou quebrado."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 quarter.py
month  finished  cycle median  85th  deploys  failed  minutes broken
Jul          32          23 d  33 d        5       1             195
Aug          41          13 d  27 d       18       1              48
Sep          30           4 d   8 d       20       1              55
```

Seis números por mês, e cada um precisa passar no teste da seção anterior antes de chegar à página.

## O que sobrevive

- **O tempo de ciclo caiu de uma mediana de 23 dias para 4, e o percentil 85 de 33 para 8.** Foi isso que as regras de 3 de agosto fizeram. O "e daí" é o que importa ao head de produto: dos itens começados agora, cerca de seis em sete terminam em até 8 dias, quando em julho a mesma fração levava 33. Isso responde a "posso acreditar nas suas datas?" melhor do que qualquer promessa.
- **Os deploys foram de 5 por mês para 20, e as falhas ficaram em uma por mês.** O time faz release quatro vezes mais com o mesmo número de falhas, o que quer dizer que a fração de releases que falham caiu de um em cinco para um em vinte. O "e daí": as correções chegam às lojas em um dia, e fazer release com frequência não deixou o serviço menos confiável.
- **A falha de setembro é a que importou.** Cinquenta e cinco minutos quebrado é perto dos 48 de agosto, e a coluna não distingue os dois; nada nela diz que a de setembro cobrou 212 cartões em dobro. Uma tabela esconde o que um número significa para um cliente, e é por isso que o incidente ganha uma linha própria na página, a partir da linha do tempo da aula 14 e do orçamento da aula 16, em vez de uma célula nesta tabela.

## O que não sobrevive, e por que ainda importa

- **Os itens terminados por mês não subiram.** 32, 41, 30. O pico de agosto é o quadro esvaziando depois que as regras mudaram, o antes e depois da aula 4; setembro voltou para onde julho estava. Esse número vai para a página mesmo assim, porque é a resposta honesta à pergunta que alguém vai fazer: **o time não terminou mais. Terminou mais cedo.** Dizer isso primeiro evita a leitura errada mais comum de um gráfico de tempo de ciclo, a de que o time ficou mais rápido para digitar.
- **Os minutos quebrado, como total**, não sobrevivem sozinhos. Três meses são três falhas, e um total de três números diz principalmente o quão ruim foi a pior. A página cita, em vez disso, o tempo para restaurar de cada incidente.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 290\" role=\"img\" data-fig=\"l19-quarter\" aria-label=\"Tempo de ciclo dos itens integrados em cada mês, de julho a setembro, com uma barra cheia para a mediana e uma barra contornada mais alta para o percentil 85: julho, mediana de 23 dias e percentil 85 de 33; agosto, mediana de 13 dias e percentil 85 de 27; setembro, mediana de 4 dias e percentil 85 de 8. Uma linha tracejada entre julho e agosto marca 3 de agosto, quando o time mudou as regras.\"><path d=\"M70.0 50.0 L70.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"240.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">0 d</text><path d=\"M70.0 192.5 L640.0 192.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"192.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">10 d</text><path d=\"M70.0 145.0 L640.0 145.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"145.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">20 d</text><path d=\"M70.0 97.5 L640.0 97.5\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"97.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">30 d</text><path d=\"M70.0 50.0 L640.0 50.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"64.0\" y=\"50.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">40 d</text><path d=\"M70.0 240.0 L640.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><path d=\"M125.0 83.2 L205.0 83.2 L205.0 240.0 L125.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M125.0 130.8 L205.0 130.8 L205.0 240.0 L125.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"165.0\" y=\"73.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">p85: 33</text><text x=\"165.0\" y=\"120.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mediana 23</text><text x=\"165.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">julho</text><path d=\"M315.0 111.8 L395.0 111.8 L395.0 240.0 L315.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M315.0 178.2 L395.0 178.2 L395.0 240.0 L315.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"355.0\" y=\"101.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">p85: 27</text><text x=\"355.0\" y=\"168.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mediana 13</text><text x=\"355.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">agosto</text><path d=\"M505.0 202.0 L585.0 202.0 L585.0 240.0 L505.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--panel)\"></path><path d=\"M505.0 221.0 L585.0 221.0 L585.0 240.0 L505.0 240.0 Z\" stroke=\"var(--phosphor)\" stroke-width=\"1\" fill=\"var(--phosphor-dim)\"></path><text x=\"545.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">p85: 8</text><text x=\"545.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mediana 4</text><text x=\"545.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">setembro</text><path d=\"M260.0 44.0 L260.0 240.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"5 3\"></path><text x=\"266.0\" y=\"44.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">3 ago: um item cada, revisões primeiro</text><text x=\"70.0\" y=\"20.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">tempo de ciclo dos itens integrados em cada mês, em dias</text></svg>", "caption": "O gráfico que sustenta a revisão: a mudança, o tamanho dela e quando aconteceu, numa imagem só.", "same": ["0 d", "10 d", "20 d", "30 d", "40 d"]}
```

## Um gráfico, não catorze

De tudo o que o time poderia mostrar, **um gráfico carrega a maior parte da revisão**: o tempo de ciclo por mês, mediana e percentil 85, com a data em que as regras mudaram marcada nele. Ele mostra a mudança, o tamanho da mudança e o momento dela, e responde à primeira pergunta do diretor, se as regras de 3 de agosto deveriam se espalhar para outros times, melhor do que um parágrafo. Os números DORA e o incidente vão ao lado como texto, porque cada um é dois ou três números e uma frase, e um gráfico para dois números é decoração.
