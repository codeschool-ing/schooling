---
title: Burlando os números do time de Billing, de propósito
version: 1
---

O jeito mais rápido de reconhecer um truque é executá-lo uma vez. **Salve o programa abaixo como `game.py`.** Ele pega o agosto e o setembro do time de Billing, que já têm números bons, e os reporta de três jeitos: como o pipeline os registrou, com cada mudança contada como um deploy próprio, e com uma definição mais estreita de falha.

```schooling-example
{
  "language": "python",
  "file": "game.py",
  "parts": [
    {
      "code": "\"\"\"game.py: the same August and September, reported three ways.\"\"\"\nimport csv\nimport statistics\nfrom datetime import datetime\n\nmerged = {i[\"id\"]: datetime.fromisoformat(i[\"merged\"])\n          for i in csv.DictReader(open(\"items.csv\")) if i[\"merged\"]}\ndeploys = [d for d in csv.DictReader(open(\"deploys.csv\")) if d[\"at\"] >= \"2026-08\"]\nWEEKS = 61 / 7\n",
      "note": "**Só agosto e setembro**, o período dos números bons. A pergunta é quanto melhor eles poderiam parecer sem nada mudar."
    },
    {
      "code": "\n\ndef report(name, rows):\n    \"\"\"rows: one (deployed at, changes carried, failed, minutes to restore) per deployment.\"\"\"\n    lead = [(at - merged[c]).total_seconds() / 3600 for at, changes, _, _ in rows for c in changes]\n    failed = [minutes for _, _, f, minutes in rows if f]\n    restore = f\"{statistics.median(failed):.0f} min\" if failed else \"-\"\n    print(f\"{name:20} {len(rows) / WEEKS:5.1f}/week  lead {statistics.median(lead):4.1f} h  \"\n          f\"failures {len(failed)}/{len(rows)} = {len(failed) / len(rows):3.0%}  restore {restore}\")\n",
      "note": "**Uma linha de números DORA para uma lista de deploys**, calculada como o `dora.py` calcula. Cada versão abaixo é o mesmo histórico passado por esta função em outro formato."
    },
    {
      "code": "\n\nrows = []\nfor d in deploys:\n    at = datetime.fromisoformat(d[\"at\"])\n    minutes = (datetime.fromisoformat(d[\"restored\"]) - at).total_seconds() / 60 if d[\"failed\"] == \"1\" else 0\n    rows.append((at, d[\"items\"].split(), d[\"failed\"] == \"1\", minutes))\nreport(\"as recorded\", rows)\n",
      "note": "**O histórico como o pipeline registrou.**"
    },
    {
      "code": "\nsplit = []\nfor at, changes, failed, minutes in rows:\n    for k, c in enumerate(changes):\n        split.append((at, [c], failed and k == 0, minutes))\nreport(\"one per change\", split)\n",
      "note": "**O primeiro truque: contar cada mudança como um deploy próprio.** Mesmo minuto, mesmo código, mesmas falhas, e uma mudança com defeito continua sendo uma falha. Nada chega aos usuários de outro jeito."
    },
    {
      "code": "\nreport(\"only long failures\", [(at, ch, f and m > 60, m) for at, ch, f, m in rows])\n",
      "note": "**O segundo truque: uma definição mais estreita de falha.** Uma falha só conta se a restauração levou mais de uma hora. A regra soa razoável, *um rollback rápido não é bem um incidente*, e é escrita depois de olhar os números."
    }
  ]
}
```

```
ana@laptop:~/delivery$ python3 game.py
as recorded            4.4/week  lead  4.5 h  failures 2/38 =  5%  restore 52 min
one per change         8.3/week  lead  4.5 h  failures 2/72 =  3%  restore 52 min
only long failures     4.4/week  lead  4.5 h  failures 0/38 =  0%  restore -
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 230\" role=\"img\" data-fig=\"l07-split\" aria-label=\"Duas linhas mostrando a mesma rodada do pipeline às 17h20 levando três mudanças, a primeira com falha. Na de cima ela conta como um deploy; na de baixo como três deploys no mesmo minuto. As mudanças, a hora em que chegaram aos usuários e a única falha são idênticas nas duas linhas; só a contagem muda.\"><text x=\"20.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">como registrado</text><path d=\"M160.0 70.0 L640.0 70.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"400.0\" cy=\"70.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:20</text><rect x=\"264.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"304.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"344.0\" y=\"36.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M256 30 L384 30 L384 62 L256 62 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"560.0\" y=\"60.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">1 deploy</text><text x=\"560.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">taxa de falha 100%</text><text x=\"20.0\" y=\"160.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um por mudança</text><path d=\"M160.0 160.0 L640.0 160.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><circle cx=\"400.0\" cy=\"160.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"400.0\" y=\"182.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">17:20</text><rect x=\"264.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><rect x=\"304.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"344.0\" y=\"126.0\" width=\"32.0\" height=\"20.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M260 122 L300 122 L300 150 L260 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M300 122 L340 122 L340 150 L300 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M340 122 L380 122 L380 150 L340 150 Z\" stroke=\"var(--paper)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"560.0\" y=\"150.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">3 deploys</text><text x=\"560.0\" y=\"168.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">taxa de falha 33%</text><text x=\"340.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a primeira mudança falhou; as três chegaram aos usuários no mesmo minuto nas duas linhas</text></svg>", "caption": "Dividir muda a contagem, não o evento. Lead time e tempo para restaurar são medidos nas mudanças e na falha, então não se mexem."}
```

## Um por mudança

Contar cada mudança como um deploy **quase dobra a frequência de deploy**, de 4,4 por semana para 8,3, e corta a taxa de falha de 5% para 3%. Nada aconteceu com o código, com os usuários ou com as duas mudanças que falharam. O pipeline rodou 38 vezes nas duas versões.

Veja o que **não** se moveu: o lead time de mudanças é de 4,5 horas nas duas linhas, e o tempo para restaurar é de 52 minutos nas duas. Essa é a assinatura do truque. Dividir muda quantos deploys são contados; não consegue mudar quanto tempo uma mudança esperou nem quanto tempo uma falha levou para ser corrigida, porque esses são medidos nas próprias mudanças e nas próprias falhas.

## Só falhas longas

Redefinir falha como aquela que levou mais de uma hora para ser restaurada **remove as duas falhas**, porque as duas foram restauradas em menos de uma hora, em 48 e 55 minutos. A taxa de falha vira 0% e o tempo para restaurar não tem mais nada para medir, então imprime um traço.

Um traço onde antes havia um número merece atenção. Um time que zerou a taxa de falha de mudanças também tornou, como efeito colateral, o tempo para restaurar impossível de medir, e um relatório que mostra "0% de falhas" sem um tempo para restaurar está mostrando o rastro de uma definição, não de um time perfeito.

## O que seria preciso para enxergar através disso

Os dois truques estavam à vista de qualquer um que olhasse para mais do que o número melhorado:

- **as métricas que o truque não alcançava ficaram onde estavam**: lead time e tempo para restaurar, no primeiro caso;
- **um número ficou indefinido**: o traço, no segundo;
- **a contagem bruta mudou de um jeito que não corresponde a nenhum evento**: 72 deploys a partir de 38 execuções do pipeline.

O motivo de executar os truques você mesmo é reconhecer essas assinaturas de relance. A próxima seção as usa no caso mais difícil: uma mudança que de fato deixou os lotes menores.
