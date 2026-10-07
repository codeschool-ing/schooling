---
title: O viés chega com os dados, e tirar uma coluna não o impede
version: 2
---

O primeiro conserto que a maioria das equipes tenta é apagar a coluna sensível: se o sistema nunca
vê gênero, raça ou de onde a pessoa vem, diz o raciocínio, não tem como discriminar por eles. **Um
sistema pode usar o que quer que se correlacione com a coluna apagada**, e em dados reais quase tudo
se correlaciona com alguma coisa. Esta seção mostra isso acontecendo em três números.

O recurso de pré-seleção da Tarefa ordena os freelancers que se candidatam a um trabalho e põe os
melhores no topo do que o cliente vê. A versão desta aula lê quatro campos de cada perfil. Dezesseis
perfis, escritos pelo curso para pessoas que ele inventou:

```sh
cat > ~/guard/data/profiles.jsonl <<'EOF'
{"applicant": "fr-0101", "region": "Sudeste", "cep": "04538-133", "rating": 4.6, "jobs": 22}
{"applicant": "fr-0102", "region": "Sudeste", "cep": "20040-020", "rating": 4.2, "jobs": 10}
{"applicant": "fr-0103", "region": "Sudeste", "cep": "30130-010", "rating": 4.9, "jobs": 5}
{"applicant": "fr-0104", "region": "Sudeste", "cep": "01310-100", "rating": 3.8, "jobs": 30}
{"applicant": "fr-0105", "region": "Sudeste", "cep": "22071-900", "rating": 4.4, "jobs": 2}
{"applicant": "fr-0106", "region": "Sudeste", "cep": "13010-111", "rating": 4.0, "jobs": 12}
{"applicant": "fr-0107", "region": "Sudeste", "cep": "29010-120", "rating": 3.9, "jobs": 8}
{"applicant": "fr-0108", "region": "Sudeste", "cep": "05407-002", "rating": 4.7, "jobs": 40}
{"applicant": "fr-0201", "region": "Nordeste", "cep": "50010-000", "rating": 4.8, "jobs": 15}
{"applicant": "fr-0202", "region": "Nordeste", "cep": "40020-000", "rating": 4.3, "jobs": 12}
{"applicant": "fr-0203", "region": "Nordeste", "cep": "60060-440", "rating": 4.9, "jobs": 25}
{"applicant": "fr-0204", "region": "Nordeste", "cep": "57020-050", "rating": 4.5, "jobs": 20}
{"applicant": "fr-0205", "region": "Nordeste", "cep": "59012-300", "rating": 3.9, "jobs": 6}
{"applicant": "fr-0206", "region": "Nordeste", "cep": "64000-020", "rating": 4.6, "jobs": 9}
{"applicant": "fr-0207", "region": "Nordeste", "cep": "49010-030", "rating": 4.1, "jobs": 30}
{"applicant": "fr-0208", "region": "Nordeste", "cep": "58013-420", "rating": 4.7, "jobs": 44}
EOF
```

```
ana@lab:~/guard$ head -4 data/profiles.jsonl
{"applicant": "fr-0101", "region": "Sudeste", "cep": "04538-133", "rating": 4.6, "jobs": 22}
{"applicant": "fr-0102", "region": "Sudeste", "cep": "20040-020", "rating": 4.2, "jobs": 10}
{"applicant": "fr-0103", "region": "Sudeste", "cep": "30130-010", "rating": 4.9, "jobs": 5}
{"applicant": "fr-0104", "region": "Sudeste", "cep": "01310-100", "rating": 3.8, "jobs": 30}
```

O campo `region` está no arquivo para que esta aula possa medir por ele. O scorer nunca o lê.
Salve-o como `~/guard/tools/standin.py`:

```python
# standin.py: THE STAND-IN SCORER. It is not a model and it learned nothing.
#
# Four lines of arithmetic, written by the course to behave the way a model
# trained on Tarefa's past hires plausibly would: a bonus for a CEP that
# starts with 0, 1, 2 or 3, the postcodes of São Paulo, Rio de Janeiro,
# Espírito Santo and Minas Gerais. It never reads the `region` field. score.py
# and counterfactual.py import it; it prints nothing on its own.
THRESHOLD = 6.0


def score(profile):
    s = 1.0 * profile["rating"] + 0.05 * profile["jobs"]
    if profile["cep"][0] in "0123":
        s += 1.0
    return round(s, 2)
```

**Isto não é um modelo, e o curso o escreveu de propósito.** Ele faz as vezes de um modelo treinado
com as contratações passadas da Tarefa. A maioria dos clientes da Tarefa está no Sudeste e contratou
sobretudo gente perto deles, então um modelo ajustado a quem foi contratado aprende que um CEP do
Sudeste vem junto com ser contratado. O substituto diz o resultado numa linha: um bônus para CEP que
começa com 0, 1, 2 ou 3, o que cobre São Paulo, Rio de Janeiro, Espírito Santo e Minas Gerais. Um
modelo de verdade não escreveria isso onde alguém pudesse ler, e é por isso que o resto da aula mede
em vez de ler código.

O programa que o roda sobre um arquivo de perfis é o `~/guard/tools/score.py`:

```python
# score.py: the stand-in scorer over a file of profiles.
#
#   guard score FILE
#
# FILE has one profile per line, as JSON. Every profile scoring at least the
# threshold is shortlisted.
import json
import sys

from standin import THRESHOLD, score

with open(sys.argv[1], encoding="utf-8") as f:
    profiles = [json.loads(line) for line in f if line.strip()]

print("%-8s %-9s %-10s %6s %4s  %5s  %s" % (
    "who", "region", "cep", "rating", "jobs", "score", "shortlisted"))
for p in profiles:
    s = score(p)
    print("%-8s %-9s %-10s %6.1f %4d  %5.2f  %s" % (
        p["applicant"], p["region"], p["cep"], p["rating"], p["jobs"], s,
        "yes" if s >= THRESHOLD else "no"))
print("threshold %.1f" % THRESHOLD)
```

```
ana@lab:~/guard$ guard score data/profiles.jsonl
who      region    cep        rating jobs  score  shortlisted
fr-0101  Sudeste   04538-133     4.6   22   6.70  yes
fr-0102  Sudeste   20040-020     4.2   10   5.70  no
fr-0103  Sudeste   30130-010     4.9    5   6.15  yes
fr-0104  Sudeste   01310-100     3.8   30   6.30  yes
fr-0105  Sudeste   22071-900     4.4    2   5.50  no
fr-0106  Sudeste   13010-111     4.0   12   5.60  no
fr-0107  Sudeste   29010-120     3.9    8   5.30  no
fr-0108  Sudeste   05407-002     4.7   40   7.70  yes
fr-0201  Nordeste  50010-000     4.8   15   5.55  no
fr-0202  Nordeste  40020-000     4.3   12   4.90  no
fr-0203  Nordeste  60060-440     4.9   25   6.15  yes
fr-0204  Nordeste  57020-050     4.5   20   5.50  no
fr-0205  Nordeste  59012-300     3.9    6   4.20  no
fr-0206  Nordeste  64000-020     4.6    9   5.05  no
fr-0207  Nordeste  49010-030     4.1   30   5.60  no
fr-0208  Nordeste  58013-420     4.7   44   6.90  yes
threshold 6.0
```

O bônus vale um ponto inteiro, e o limiar é 6.0. O `fr-0201`, em Recife, tem nota 4.8 e 15
trabalhos e marca 5.55. O `fr-0103`, em Belo Horizonte, tem 4.9 e 5 trabalhos e marca 6.15. Quatro
perfis do Sudeste em oito são pré-selecionados, e dois do Nordeste em oito.

## Quatro jeitos de ele entrar

O CEP é um caminho. Um modelo encontra quatro, e a maioria dos casos reais envolve mais de um:

| fonte | o que significa | na Tarefa |
|---|---|---|
| **histórico** | os rótulos registram decisões passadas, com o preconceito delas | "foi contratado" é o que os clientes antigos escolheram, perto deles |
| **proxy** | um campo que faz as vezes de um protegido | o CEP carrega a região; um nome carrega gênero, muitas vezes região e raça |
| **representação** | um grupo com poucos exemplos é aprendido mal e medido pior | 12 candidatos do Norte, contra 200 do Sudeste |
| **medição** | o próprio rótulo é desigualmente preciso entre grupos | as notas dos clientes, que alimentam `rating`, também podem carregar o preconceito do cliente |

Um modelo de linguagem traz as quatro antes de alguém fazer qualquer ajuste fino: ele aprendeu com
texto escrito por pessoas, com as associações delas, e lê nomes, dialetos e endereços em todo prompt.
Quando um prompt pede a um modelo que ordene currículos ou resuma uma reclamação, essas associações
estão em jogo, quer alguém tenha pedido, quer não.

## Por que isto pertence a um curso de segurança

Uma decisão enviesada fere pessoas do mesmo jeito que um vazamento, e traz exposição jurídica do
mesmo jeito. No Brasil, a Constituição põe entre os objetivos fundamentais promover o bem de todos
*sem preconceitos de origem, raça, sexo, cor, idade* (art. 3, IV). A LGPD lista a **não
discriminação** entre os princípios (art. 6, IX), e o art. 20 dá a quem é afetado por uma decisão
tomada só com base em tratamento automatizado o direito de pedir revisão e de saber os critérios
usados. Uma lista que decide quem um cliente vê é esse tipo de decisão. *"Nunca demos a região a
ele"* não responde a um pedido de revisão quando o CEP fez o trabalho, e as próximas seções são como
descobrir isso antes que alguém pergunte.
