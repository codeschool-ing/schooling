---
title: Auditando aquilo de que o código é feito
version: 1
---

A maior parte do código que uma aplicação roda foi escrita por outra pessoa. Um serviço Python que
instala cinco bibliotecas do PyPI instala também tudo de que essas cinco precisam, e qualquer uma
delas pode ter uma falha que alguém encontra, relata e publica no mês que vem. A **análise de
composição de software**, a SCA dos cinco scanners da aula 16, é a verificação que compara a lista
do que você instalou com a lista do que foi publicado contra isso. Ela não lê o seu código, e não
consegue achar uma falha que ninguém relatou ainda. O que ela acha são as conhecidas, que são as que
qualquer um consegue consultar.

Para Python a ferramenta é o **pip-audit**, mantido pela Python Packaging Authority. Ele lê um
arquivo de requisitos ou um ambiente instalado, pergunta a um banco de vulnerabilidades sobre cada
pacote e versão, e imprime o que achou. O banco padrão é o do próprio PyPI, e é o usado aqui.

## Instalando

O pip-audit vai para o ambiente virtual da aula 6, ao lado do Locust:

```sh
~/venv/bin/pip install pip-audit==2.10.1
```

A máquina do laboratório o tinha instalado com essa mesma linha. Confira que o seu responde:

```
ana@nft:~$ ~/venv/bin/pip-audit --version
pip-audit 2.10.1
```

## Um projeto para auditar

Nenhum dos serviços deste curso usa uma biblioteca de fora da biblioteca padrão do Python, o que é
bom para eles e não dá nada para um auditor achar. Então esta aula audita um projeto pequeno, do
tipo que um testador recebe: um auxiliar que avisa o canal de chat da equipe quando um espetáculo
esgota, escrito há algum tempo com a popular biblioteca `requests`, e fixado na versão com que foi
escrito. Crie um diretório para ele, `mkdir ~/audit && cd ~/audit`, e crie dois arquivos ali. O
primeiro com `nano requirements.txt`:

```
# audit/requirements.txt
# What notify.py needs, pinned to the version the project has always used.
requests==2.31.0
```

O segundo com `nano notify.py`. Você não o roda, porque não há canal de chat para onde postar; ele é
o código contra o qual os achados vão ser conferidos:

```python
# audit/notify.py
# Tells the box office's team channel that a show has sold out.
import os
import requests

session = requests.Session()

def sold_out(show_id):
    url = os.environ["NOTIFY_URL"]          # set by whoever deploys it, never typed by a customer
    session.post(url, json={"text": f"show {show_id} is sold out"}, timeout=5)
```

**Este passo precisa da internet**, porque o pip-audit pergunta ao PyPI. Ele também instala os
requisitos num ambiente temporário próprio para achar cada pacote que eles puxam, então a primeira
execução leva alguns segundos:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit -r requirements.txt; echo "exit $?"
Found 6 known vulnerabilities in 1 package
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
exit 1
```

Esse é o relatório inteiro, e a primeira coisa a ler nele não é uma linha, e sim o resumo. **"6
known vulnerabilities" são três alertas, cada um impresso duas vezes**: os mesmos três
identificadores aparecem na mesma ordem, uma vez e depois de novo. Contar linhas dobraria o
trabalho de quem fizer a triagem, e dobraria o número num painel. Três alertas, cada um com uma
versão do `requests` que o corrige. O código de saída é 1, e é isso que permite a um pipeline parar
nele.

**O que o PyPI sabe muda todo dia.** Estas linhas foram gravadas num dia de outubro de 2026; em
outro dia o mesmo comando pode listar mais alertas, porque mais foram publicados, e é por isso que a
aula 16 disse que a SCA roda num agendamento além de a cada mudança.

## E o ambiente que você já tem

Sem `-r`, o pip-audit audita o ambiente em que está instalado. O ambiente virtual da aula 6 guarda o
Locust, o pip-audit e tudo de que eles precisam:

```
ana@nft:~/audit$ ~/venv/bin/pip-audit; echo "exit $?"
Found 12 known vulnerabilities in 1 package
Name Version ID              Fix Versions
---- ------- --------------- ------------
pip  24.0    PYSEC-2026-1795 25.3
pip  24.0    PYSEC-2026-1796 26.0
pip  24.0    PYSEC-2026-2875 26.1
pip  24.0    PYSEC-2026-2876 26.1
pip  24.0    PYSEC-2026-196  26.1.2
pip  24.0    PYSEC-2026-1795 25.3
pip  24.0    PYSEC-2026-1796 26.0
pip  24.0    PYSEC-2026-196  26.1.2
pip  24.0    PYSEC-2026-2875 26.1
pip  24.0    PYSEC-2026-2876 26.1
pip  24.0    PYSEC-2026-3721 26.2
pip  24.0    PYSEC-2026-3721 26.2.0
exit 1
```

O Locust e cada biblioteca abaixo dele voltaram limpos. **O achado é o próprio pip**: a versão 24.0,
a que o `python3 -m venv` do Ubuntu pôs no ambiente quando a aula 6 o criou, com seis alertas, cada
um impresso duas vezes de novo. Nada neste curso importou o pip; ele é a ferramenta que instala todo
o resto, o que o põe na cadeia de suprimentos de cada pacote que veio depois dele. "Corrigindo, e
aceitando o que ainda não dá para corrigir" trata dele.
