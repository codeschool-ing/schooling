---
title: Dois ambientes, um JupyterLab
version: 1
---

**Uma versão fixada não é preciosismo: a mesma linha de pandas dá outra resposta em outra versão, e
roda sem reclamar nas duas.** O jeito mais rápido de acreditar nisso é ver. Eis um script de quatro
linhas, `check.py`, gravado em `pydata`:

```py
import sys
import pandas as pd

plans = pd.Series(["annual", "day", "annual"])
print(sys.version.split()[0], pd.__version__, plans.dtype)
```

Ele imprime o Python, o pandas, e o tipo que o pandas dá a uma coluna de texto. Agora um segundo
projeto, `oldpandas`, com o pandas que era o atual antes do deste curso:

```
ana@lab:~$ mkdir oldpandas && cd oldpandas
ana@lab:~/oldpandas$ python3 -m venv .venv && source .venv/bin/activate
(.venv) ana@lab:~/oldpandas$ pip install -q pandas==2.2.3 ipykernel
(.venv) ana@lab:~/oldpandas$ python ~/pydata/check.py
3.12.3 2.2.3 object
(.venv) ana@lab:~/pydata$ python check.py
3.12.3 3.0.6 str
```

**Mesmo Python, as mesmas três palavras, dois tipos diferentes.** O pandas 2 guarda texto numa
coluna de objetos Python genéricos, `object`; o pandas 3 dá ao texto um tipo próprio, `str`. Um
código que testa `dtype == object` para achar as colunas de texto, o que foi comum e correto por
anos, não acha nenhuma no pandas 3, e nada levanta erro. A aula 12 é sobre tipos no pandas, e essa
diferença é a primeira coisa nela.

## Escolhendo o ambiente pelo notebook

Cada ambiente pode rodar o JupyterLab, mas você não precisa de um JupyterLab por projeto. O
JupyterLab encontra **kernels**, e um ambiente com `ipykernel` instalado pode se registrar como
um:

```
(.venv) ana@lab:~/oldpandas$ python -m ipykernel install --user --name oldpandas --display-name "Python (pandas 2.2)"
Installed kernelspec oldpandas in /home/ana/.local/share/jupyter/kernels/oldpandas
(.venv) ana@lab:~/pydata$ jupyter kernelspec list
Available kernels:
  python3      /home/ana/pydata/.venv/share/jupyter/kernels/python3
  oldpandas    /home/ana/.local/share/jupyter/kernels/oldpandas
```

`--user` põe o registro na sua pasta pessoal, onde todo JupyterLab que você iniciar o enxerga;
`--name` é a pasta que ele ganha e `--display-name` é o que o lançador mostra. Agora o lançador do
JupyterLab de `pydata` tem dois cartões de Python, `Python 3 (ipykernel)` e `Python (pandas 2.2)`,
e **Kernel, Change Kernel…** troca um notebook aberto entre eles.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Um JupyterLab, iniciado do ambiente de pydata, lista dois kernels. O kernel python3 roda pydata/.venv/bin/python com pandas 3.0.6; o kernel oldpandas roda oldpandas/.venv/bin/python com pandas 2.2.3. O mesmo notebook pode ser trocado entre os dois.\" data-fig=\"kernels\"><defs><marker id=\"kernels-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"85\" width=\"170\" height=\"80\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">JupyterLab</text><text x=\"105.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">um servidor</text><rect x=\"275\" y=\"30\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">python3</text><text x=\"360.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kernel</text><rect x=\"275\" y=\"150\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"360.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">oldpandas</text><text x=\"360.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">kernel</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">pydata/.venv</text><text x=\"615.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pandas 3.0.6</text><rect x=\"530\" y=\"150\" width=\"170\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615.0\" y=\"177.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\" font-weight=\"600\">oldpandas/.venv</text><text x=\"615.0\" y=\"194.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">pandas 2.2.3</text><line x1=\"194\" y1=\"112\" x2=\"271\" y2=\"70\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"194\" y1=\"138\" x2=\"271\" y2=\"180\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"449\" y1=\"65\" x2=\"526\" y2=\"65\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><line x1=\"449\" y1=\"185\" x2=\"526\" y2=\"185\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#kernels-ah)\"></line><text x=\"487\" y=\"52\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda</text><text x=\"487\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">roda</text></svg>", "caption": "Um kernel é um Python registrado. Qual deles roda o notebook decide qual pandas responde.", "same": ["JupyterLab", "kernel"]}
```

Um notebook registra a escolha em `kernelspec`, os metadados que a aula 1 mostrou, e assim abre no
mesmo kernel da próxima vez.

O registro é uma pastinha com o caminho para `oldpandas/.venv/bin/python`. Apague o ambiente e o
cartão fica, apontando para o nada; remova-o com `jupyter kernelspec remove oldpandas`.

Dois hábitos evitam que isso vire fonte de confusão em vez de ferramenta:

- **Pergunte ao kernel, não ao lançador.** A segunda célula do notebook da aula 1,
  `sys.executable`, diz em que ambiente um notebook está rodando de verdade. O nome de um cartão é
  só um rótulo que alguém digitou.
- **Instale num ambiente pelo terminal dele.** Dentro de um notebook, `%pip install` instala no
  ambiente do kernel, que é o que você queria; um `!pip install` puro roda o primeiro `pip` que o
  shell achar, que pode ser o de outro ambiente. Melhor ainda: acrescente a linha ao
  `requirements.txt` e instale a partir do arquivo, para que o arquivo continue sendo a verdade.
