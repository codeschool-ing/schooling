---
title: Comparando dois prompts com números
version: 2
---

"O prompt novo parece melhor" é um juízo feito sobre as duas ou três respostas que alguém por acaso
leu. **Uma avaliação roda os dois prompts sobre o mesmo conjunto de casos e dá nota a toda resposta
com as mesmas checagens.** Ela não precisa ser grande para ser melhor que uma impressão: cinco casos
com checagens automáticas já dizem mais que a leitura cuidadosa de um.

## Uma avaliação pequena

Os casos são os cinco commits da loja, que vêm com diffs. A tarefa é a da aula 5 seção 04, um
assunto de commit, e as checagens são as regras do projeto para um: uma linha, menos de sessenta
caracteres, sem ponto final, no imperativo:

```schooling-example
{
  "language": "python",
  "file": "scratch/eval_subjects.py",
  "parts": [
    {
      "code": "\"\"\"Ask for a commit subject for each of the project's commits, with two prompts, and check them.\"\"\"\nimport subprocess\n\nimport anthropic\n\n"
    },
    {
      "code": "EXAMPLES = \"\"\"Examples of this project's commit subjects:\nRefuse a coupon after its last day\nKeep shipping free from 200.00 after the discount\nFormat negative prices with the sign first\n\nThe subject is imperative, under sixty characters, with no full stop.\n\"\"\"\nRUNS = 3\nclient = anthropic.Anthropic()\n\n\n",
      "note": "**A regra, dita, e três exemplos dela**, o prompt com exemplos da aula 5, seção 04. `RUNS` pede cada caso três vezes, porque cada resposta é um sorteio (aula 1, seção 08) e um sorteio por caso daria nota à sorte daquele sorteio."
    },
    {
      "code": "def subject(diff: str, examples: bool) -> str:\n    prompt = (EXAMPLES + \"\\n\" if examples else \"\") + \"Write a commit message for this diff. One line.\\n\\n\" + diff\n    r = client.messages.create(model=\"llama3.2:3b\", max_tokens=100,\n                               messages=[{\"role\": \"user\", \"content\": prompt}])\n    return r.content[0].text.strip()\n\n\n",
      "note": "**Uma requisição por caso**, com ou sem os exemplos. Todo o resto é idêntico nas duas rodadas, então uma diferença de nota é do prompt."
    },
    {
      "code": "def problems(s: str) -> list[str]:\n    first = s.split()[0].lower()\n    found = []\n    if \"\\n\" in s:\n        found.append(\"more than one line\")\n    if len(s.split(\"\\n\")[0]) > 60:\n        found.append(\"too long\")\n    if s.endswith(\".\"):\n        found.append(\"full stop\")\n    if first.endswith((\"ed\", \"ing\")) or (first.endswith(\"s\") and not first.endswith(\"ss\")):\n        found.append(\"not imperative\")\n    return found\n\n\n",
      "note": "**As checagens, como código.** Cada uma devolve a lista do que está errado, então uma falha diz por quê, e não só que falhou. Só a primeira linha é julgada pelo tamanho, e uma resposta de várias linhas falha só por isso."
    },
    {
      "code": "shas = subprocess.run([\"git\", \"log\", \"--format=%h\", \"main\"], capture_output=True, text=True).stdout.split()\nfor examples in (False, True):\n    passed = 0\n    print(\"with examples\" if examples else \"without examples\")\n    for sha in shas:\n        diff = subprocess.run([\"git\", \"show\", \"--format=\", sha], capture_output=True, text=True).stdout\n        for _ in range(RUNS):\n            s = subject(diff, examples)\n            p = problems(s)\n            passed += not p\n            line = s.split(\"\\n\")[0]\n            print(f\"  {sha}  {'ok ' if not p else 'BAD'}  {line[:50]}{'…' if len(line) > 50 else ''}  {', '.join(p)}\")\n    print(f\"  {passed} of {len(shas) * RUNS} pass\")\n",
      "note": "**Todo caso, os dois prompts, uma nota para cada.** Os casos são os próprios commits do projeto, lidos do git, e a saída é cortada em cinquenta caracteres para cada tentativa caber numa linha."
    }
  ]
}
```

```
ana@dev:~/shop$ python scratch/eval_subjects.py
without examples
  19265e0  BAD  "Added shop conventions for code, money, and testi…  not imperative
  19265e0  BAD  "Added project conventions and code style guide to…  too long, not imperative
  19265e0  BAD  "Added conventions for money, code, tests, and com…  too long, not imperative
  b88cbb3  BAD  "Added README for small online shop example"  not imperative
  b88cbb3  BAD  "Added shop example to README"  not imperative
  b88cbb3  BAD  "Added shop example to README.md"  not imperative
  c2b5d79  BAD  "Added coupon logic and tests for shop cart"  not imperative
  c2b5d79  BAD  "Added coupon and cart classes for managing discou…  not imperative
  c2b5d79  BAD  "Added coupon functionality and tests to shop modu…  not imperative
  fe437dd  BAD  "Added Cart class and tests for shop cart function…  not imperative
  fe437dd  BAD  "Added Cart and Line dataclasses with calculation …  not imperative
  fe437dd  BAD  "Added Cart class and tests with shipping, discoun…  too long, not imperative
  33fefcf  BAD  Added initial files and tests for money functional…  full stop, not imperative
  33fefcf  BAD  "Added money module with price parsing and formatt…  too long, not imperative
  33fefcf  BAD  "Added shop module with money functionality"  not imperative
  0 of 15 pass
with examples
  19265e0  ok   Format negative prices with the sign first  
  19265e0  ok   Refactor money formatting for negative prices  
  19265e0  ok   Format negative prices with the sign first  
  b88cbb3  ok   Format README.md for shop documentation  
  b88cbb3  BAD  Fixed README formatting  not imperative
  b88cbb3  ok   Update README with cart explanation  
  c2b5d79  ok   Refuse unknown coupon  
  c2b5d79  ok   Refuse unknown coupon  
  c2b5d79  ok   Update coupon application and testing  
  fe437dd  ok   "Add cart functionality with shipping"  
  fe437dd  ok   "Implement Cart class with shipping and discount"  
  fe437dd  ok   `Add shipping calculations to Cart class`  
  33fefcf  ok   Format negative prices with the sign first  
  33fefcf  ok   Format negative prices with the sign first  
  33fefcf  ok   Format negative prices with the sign first  
  14 of 15 pass
```

**Nenhum de quinze sem exemplos, catorze de quinze com eles.** Isso é uma medição, deste modelo
nestes cinco diffs num dia, e diz que os exemplos acertam a forma, o que a seção 04 só podia sugerir a
partir de uma resposta. Toda falha da primeira rodada é o mesmo hábito, `Added …`, e quase todas vêm
entre aspas, que as checagens não procuram.

Agora leia os aprovados. Cinco dos catorze são `Format negative prices with the sign first`, um dos
exemplos, para dois commits que nunca tocam num preço negativo: as convenções e a primeira versão do
`money.py`. Mais dois vêm entre aspas e um entre crases, o que o projeto também não escreve. **As
checagens mediram exatamente o que foram escritas para medir**, e um exemplo copiado palavra por
palavra cumpre toda regra de forma. Uma sexta checagem, de que um assunto igual a um exemplo falha,
levaria a nota de catorze para nove, e é a próxima coisa que a ana acrescenta, porque uma checagem é
mais barata de escrever do que a discussão sobre se a nota era real.

É assim que uma avaliação cresce: uma rodada, uma leitura do que passou, e uma checagem para o que não
devia ter passado. A nota é tão boa quanto as checagens por trás dela.

## O que torna uma avaliação útil

- **Checagens que um programa consegue fazer.** Tamanho, formato, uma interpretação, um teste que
  roda, uma palavra de uma lista fixa, uma resposta que não é cópia do prompt. Onde a checagem pede
  juízo (este resumo é fiel?), uma pessoa dá nota a uma amostra; alguns times usam um segundo modelo
  como juiz, que é em si um prompt que precisa de avaliação.
- **Casos do uso real.** Entradas colhidas do próprio tráfego da funcionalidade, inclusive as que
  deram errado. Cada relato de bug vira um caso, para ele não voltar sem ser notado.
- **Rodada a cada mudança no prompt, e no modelo.** Um prompt que foi bem num modelo pode ir
  diferente na versão seguinte, ou no `llama3.2:1b`. A aula 10 troca de provedor; este é o harness
  que diz quanto a troca custou.
- **Pequena o bastante para rodar sempre.** Trinta requisições curtas levam uns dois minutos na
  máquina da gravação. Cem casos que rodam em poucos minutos são rodados; mil que levam uma tarde são
  pulados.

O prompt, os casos e as checagens vão todos para o repositório, ao lado do código que testam.
