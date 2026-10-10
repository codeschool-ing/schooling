---
title: Uma taxa, não uma anedota
version: 1
---

Tudo na suíte é determinístico. O comportamento que mais importa não é: se o classificador continua
respondendo `{"category": C}` com o C certo depois que alguém edita o prompt dele. A aula 20 achou uma
edição de uma frase que quebrou o formato, e achou rodando os doze chamados uma vez. Funcionou porque
a quebra era grande. **A maioria das regressões não é.**

## Um prompt candidato

Um colega propõe um classificador mais simpático. Ele ainda não está em `data/prompts/`, porque nada
entra ali sem revisão; ele espera como candidato:

```sh
mkdir -p ~/guard/data/candidates
cp ~/guard/data/prompts/classify.txt ~/guard/data/candidates/classify.txt
echo "Always greet the client warmly and thank them for their patience." >> ~/guard/data/candidates/classify.txt
```

## Uma execução de cada

O programa manda cada chamado da aula 14 ao modelo, um certo número de vezes, e conta as respostas
que não são exatamente a categoria certa. Salve-o como `~/guard/tools/rate.py`:

```python
# rate.py: how often a prompt fails on the cases, measured over many runs.
#
#   guard rate PROMPT CASES [--runs N] [--temperature T] [--ceiling PCT]
#
# It sends every case to the model RUNS times, with seeds 1 to RUNS at the
# given temperature, and counts the replies that are not exactly
# {"category": C} with the expected C. One run at temperature 0 says what
# the model does once; many runs above it say how often it fails, which is
# what a regression test compares. The interval is Wilson's 95% interval for
# a proportion: with few trials it is wide, and two versions whose intervals
# overlap have not been shown to differ. With --ceiling it exits 1 unless the
# whole interval sits under PCT: the build asks to be shown the rate is low,
# and too few trials to show it is a failure too.
import argparse
import json
import math
import sys
import urllib.error
import urllib.request

import ask


def wilson(k, n, z=1.96):
    if n == 0:
        return 0.0, 1.0
    p = k / n
    centre = (p + z * z / (2 * n)) / (1 + z * z / n)
    half = z * math.sqrt(p * (1 - p) / n + z * z / (4 * n * n)) / (1 + z * z / n)
    return max(0.0, centre - half), min(1.0, centre + half)


p = argparse.ArgumentParser(prog="guard rate")
p.add_argument("prompt")
p.add_argument("cases")
p.add_argument("--runs", type=int, default=10)
p.add_argument("--temperature", type=float, default=0.8)
p.add_argument("--ceiling", type=float)
a = p.parse_args()

with open(a.prompt, encoding="utf-8") as f:
    system = f.read().strip()
with open(a.cases, encoding="utf-8") as f:
    cases = [json.loads(line) for line in f]

failed = trials = 0
for seed in range(1, a.runs + 1):
    for c in cases:
        body = {"model": ask.MODEL, "temperature": a.temperature, "seed": seed,
                "messages": [{"role": "system", "content": system},
                             {"role": "user", "content": "Classify this ticket: " + c["text"]}]}
        req = urllib.request.Request(ask.URL + "/chat/completions", json.dumps(body).encode(),
                                     {"Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=600) as r:
                text = json.load(r)["choices"][0]["message"]["content"]
        except urllib.error.URLError as e:
            sys.exit("rate: cannot reach %s (%s). Is Ollama running?" % (ask.URL, e.reason))
        try:
            value = json.loads(text)
            ok = set(value) == {"category"} and value["category"] == c["expect"]
        except (json.JSONDecodeError, TypeError):
            ok = False
        trials += 1
        failed += not ok
lo, hi = wilson(failed, trials)
print("%s: %d of %d trials failed, %.1f%% (95%% interval %.1f%% to %.1f%%)" % (
    a.prompt, failed, trials, 100 * failed / trials, 100 * lo, 100 * hi))
if a.ceiling is not None and 100 * hi >= a.ceiling:
    print("  upper bound %.1f%% is not under the ceiling of %g%%" % (100 * hi, a.ceiling))
    sys.exit(1)
```

À temperatura 0 e numa execução, ele faz o que a aula 20 fez:

```
ana@lab:~/guard$ guard rate data/prompts/classify.txt data/tickets.jsonl --runs 1 --temperature 0
data/prompts/classify.txt: 2 of 12 trials failed, 16.7% (95% interval 4.7% to 44.8%)
ana@lab:~/guard$ guard rate data/candidates/classify.txt data/tickets.jsonl --runs 1 --temperature 0
data/candidates/classify.txt: 3 of 12 trials failed, 25.0% (95% interval 8.9% to 53.2%)
```

Duas falhas contra três. Lido como teste, isso diz que o candidato é pior, e alguém escreveria "a v2
piora o classificador" na revisão. **Os intervalos dizem outra coisa**: com doze tentativas cada, a
taxa real de falha do prompt atual pode estar em qualquer ponto entre uns 5% e 45%, e a do candidato
entre 9% e 53%. Um chamado respondido de outro jeito é a diferença inteira, e uma amostra à
temperatura 0 é uma amostra.

## Muitas execuções de cada

Um modelo em produção não responde à temperatura 0 com uma semente só, e um prompt que passa numa
amostra pode falhar na seguinte. Então o teste de regressão pergunta **com que frequência** uma
versão falha, ao longo de muitas amostras, na temperatura que o assistente usa de verdade. Dez
execuções de doze chamados são 120 tentativas por versão:

```
ana@lab:~/guard$ guard rate data/prompts/classify.txt data/tickets.jsonl --runs 10
data/prompts/classify.txt: 29 of 120 trials failed, 24.2% (95% interval 17.4% to 32.6%)
ana@lab:~/guard$ guard rate data/candidates/classify.txt data/tickets.jsonl --runs 10
data/candidates/classify.txt: 38 of 120 trials failed, 31.7% (95% interval 24.0% to 40.4%)
```

Agora existe uma diferença que vale olhar: 24,2% contra 31,7%, nove falhas a mais em 120. E os
intervalos ainda se sobrepõem, de 24,0% a 32,6%. Se os dois prompts falhassem de verdade 28% das
vezes, duas amostras de 120 difeririam tanto assim mais ou menos uma vez em cinco, que é vezes demais
para a diferença provar alguma coisa.

O intervalo de 95% é o de Wilson, e é a parte honesta da linha. Ele diz onde a taxa real de falha
plausivelmente está, dadas 120 tentativas. **Quando dois intervalos se sobrepõem tanto assim, o teste
não mostrou que as versões diferem**, em nenhuma direção. Relatar "a v2 é pior" com esses números
seria uma anedota com casas decimais.

## Quanto custa saber mais

O intervalo estreita com a raiz quadrada das tentativas: quatro vezes mais execuções o reduzem à
metade. Então uma diferença de três pontos, com taxas perto dessas, precisa de umas 1.700 tentativas
por versão antes de aparecer, e nesta máquina 120 levaram uns dois minutos. Isso decide como a
verificação é usada:

- **fixe um teto, não uma comparação.** "O intervalo inteiro fica abaixo de 40%" é uma pergunta que
  120 tentativas respondem. "A v2 não é pior que a v1" quase nunca é;
- **aumente os casos antes das execuções.** Doze chamados perguntados dez vezes são doze situações.
  Cem chamados distintos, escritos a partir de reais com os dados pessoais removidos como a aula 11
  fez, medem mais do que o classificador vai encontrar;
- **guarde as falhas, não só a taxa.** Uma taxa que se mantém enquanto as falhas mudam de uma
  categoria para outra é uma mudança que alguém deveria ler.
