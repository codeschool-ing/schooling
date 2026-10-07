---
title: Comparando dois prompts com números
version: 1
---

"O prompt novo parece melhor" é um juízo feito sobre as duas ou três respostas que alguém por acaso
leu. **Uma avaliação roda os dois prompts sobre o mesmo conjunto de casos e dá nota a toda resposta
com as mesmas checagens.** Ela não precisa ser grande para ser melhor que uma impressão: cinco casos
com checagens automáticas já dizem mais que a leitura cuidadosa de um.

## Uma avaliação pequena

Os casos são os cinco commits da loja, que vêm com diffs. A tarefa é a da aula 5 seção 04, um
assunto de commit, e as checagens são as regras do projeto para um: menos de sessenta caracteres,
sem ponto final, no imperativo:

```schooling-example
{
  "language": "python",
  "file": "lab/eval_subjects.py",
  "parts": [
    {
      "code": "\"\"\"Ask for a commit subject for each of the project's commits, with two prompts, and check them.\"\"\"\nimport subprocess\n\nimport anthropic\n\n"
    },
    {
      "code": "EXAMPLES = \"\"\"Examples of this project's commit subjects:\nRefuse a coupon after its last day\nKeep shipping free from 200.00 after the discount\nFormat negative prices with the sign first\n\nThe subject is imperative, under sixty characters, with no full stop.\n\"\"\"\nclient = anthropic.Anthropic()\n\n\n",
      "note": "**A regra, dita, e três exemplos dela**, o prompt com exemplos da aula 5 seção 04."
    },
    {
      "code": "def subject(diff: str, examples: bool) -> str:\n    prompt = (EXAMPLES + \"\\n\" if examples else \"\") + \"Write a commit message for this diff. One line.\\n\\n\" + diff\n    r = client.messages.create(model=\"scripted-1\", max_tokens=100,\n                               messages=[{\"role\": \"user\", \"content\": prompt}])\n    return r.content[0].text.strip()\n\n\n",
      "note": "**Uma requisição por caso**, com ou sem os exemplos. Todo o resto das duas execuções é idêntico, então uma diferença de nota é do prompt."
    },
    {
      "code": "def problems(s: str) -> list[str]:\n    first = s.split()[0].lower()\n    found = []\n    if len(s) > 60:\n        found.append(\"too long\")\n    if s.endswith(\".\"):\n        found.append(\"full stop\")\n    if first.endswith((\"ed\", \"ing\")) or (first.endswith(\"s\") and not first.endswith(\"ss\")):\n        found.append(\"not imperative\")\n    return found\n\n\n",
      "note": "**As checagens, como código.** Cada uma devolve a lista do que está errado, então uma falha diz o porquê e não só o quê."
    },
    {
      "code": "shas = subprocess.run([\"git\", \"log\", \"--format=%h\", \"main\"], capture_output=True, text=True).stdout.split()\nfor examples in (False, True):\n    passed = 0\n    print(\"with examples\" if examples else \"without examples\")\n    for sha in shas:\n        diff = subprocess.run([\"git\", \"show\", \"--format=\", sha], capture_output=True, text=True).stdout\n        s = subject(diff, examples)\n        p = problems(s)\n        passed += not p\n        print(f\"  {sha}  {'ok ' if not p else 'BAD'}  {s[:58]}{'…' if len(s) > 58 else ''}  {', '.join(p)}\")\n    print(f\"  {passed} of {len(shas)} pass\")",
      "note": "**Todo caso, os dois prompts, uma nota cada.** Os casos são os próprios commits do projeto, lidos do git."
    }
  ]
}
```

```
ana@dev:~/shop$ python lab/eval_subjects.py
without examples
  19265e0  ok   Add CONVENTIONS.md  
  b88cbb3  BAD  Updated README.  full stop, not imperative
  c2b5d79  BAD  Added coupon support.  full stop, not imperative
  fe437dd  BAD  Implemented Cart and Line dataclasses with subtotal, disco…  too long, full stop, not imperative
  33fefcf  BAD  Added parse_price and format_price functions to handle mon…  too long, full stop, not imperative
  1 of 5 pass
with examples
  19265e0  ok   Write down the project's conventions  
  b88cbb3  ok   Explain the project in a README  
  c2b5d79  ok   Add coupon codes with a percentage off  
  fe437dd  ok   Add a cart with lines, a discount and shipping  
  33fefcf  ok   Keep prices as integer cents  
  5 of 5 pass
```

**Um de cinco sem exemplos, cinco de cinco com eles.** As respostas foram escritas pelo curso para
mostrar a mecânica, então este resultado é uma ilustração, não a medição de modelo nenhum. O que é
real é o harness: os mesmos casos, as mesmas checagens, uma nota por prompt, e toda falha listada com
o motivo. Contra um modelo real você rodaria cada caso várias vezes, já que as respostas variam (aula
1 seção 08), e informaria com que frequência cada prompt passa.

## O que torna uma avaliação útil

- **Checagens que um programa consegue fazer.** Tamanho, formato, uma interpretação, um teste que
  roda, uma palavra de uma lista fixa. Onde a checagem pede juízo (este resumo é fiel?), uma pessoa
  dá nota a uma amostra; alguns times usam um segundo modelo como juiz, que é em si um prompt que
  precisa de avaliação.
- **Casos do uso real.** Entradas colhidas do próprio tráfego da funcionalidade, inclusive as que
  deram errado. Cada relato de bug vira um caso, para ele não voltar sem ser notado.
- **Rodada a cada mudança no prompt, e no modelo.** Um prompt que foi bem num modelo pode ir
  diferente na versão seguinte. A aula 10 troca de provedor; este é o harness que diz quanto a troca
  custou.
- **Pequena o bastante para rodar sempre.** Cem casos que rodam num minuto são rodados; mil que levam
  uma hora são pulados.

O prompt, os casos e as checagens vão todos para o repositório, ao lado do código que testam.
