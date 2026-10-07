---
title: Sob controle de versão
version: 1
---

A última peça é a história. O código muda, os mapas crescem, uma regra é corrigida, e seis meses
depois alguém precisa saber que versão do pipeline produziu o relatório do trimestre passado.
**Controle de versão** guarda toda versão de todo arquivo, com quem mudou, quando e por quê. Neste
laboratório é o git, e a primeira decisão é o que entra:

```
ana@lab:~/clean$ git init -q && git config user.name 'Ana' && git config user.email ana@lab.example
ana@lab:~/clean$ cat .gitignore
raw/
ref/
out/
__pycache__/
*.png
ana@lab:~/clean$ git add . && git status --short
A  .gitignore
A  categorise.py
A  category_map.csv
A  checks.py
A  consent.py
A  derive.py
A  keyed.py
A  keys.py
A  lines.py
A  match.py
A  merge.py
A  orders.py
A  raw.sha256
A  raw_customers.py
A  ready.py
A  run.py
A  sources.csv
A  survivors.csv
A  typos.py
A  when.py
A  years.py
ana@lab:~/clean$ git commit -q -m 'Cleaning pipeline for the 2025 data, as of lesson 17' && git log --format='%an: %s'
Ana: Cleaning pipeline for the 2025 data, as of lesson 17
```

O `.gitignore` é uma lista de decisões, uma por linha:

- **`raw/` e `ref/` ficam de fora.** Dados não são código: podem ser grandes, podem ter dados
  pessoais que não devem ser copiados para todo clone de um repositório, e a identidade deles já
  está registrada, com precisão, pelo `raw.sha256`, que entra.
- **`out/` fica de fora.** Tudo nele é reconstruído pelo `run.py`; versioná-lo criaria uma segunda
  cópia que pode discordar do código que a fez.
- **`__pycache__/` e gráficos ficam de fora.** São subprodutos.

Todo o resto entra, e a lista de arquivos adicionados é o curso em miniatura: os módulos de leitura
das aulas 7 e 10, a comparação da aula 5, o mapa de categorias da aula 8, as decisões das aulas 9 e
10, as colunas derivadas da aula 12, as fontes da aula 14, o pipeline e as suas verificações. **Os
mapas e a lista de sobreviventes também são código**: `category_map.csv` foi escrito por uma pessoa
e `survivors.csv` por uma regra que uma pessoa consegue ler inteira, e os dois guardam decisões que
mudam de jeitos que dá para revisar.

A mensagem do commit diz o que esta versão é. Daqui em diante, toda mudança numa regra é um commit
novo, e um relatório pode dizer de que commit foi feito. Junto com o manifesto dos brutos, esse
identificador basta para reconstruir exatamente qualquer resultado passado.
