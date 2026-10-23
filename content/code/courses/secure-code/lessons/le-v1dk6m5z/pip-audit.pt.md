---
title: pip-audit, contra uma trava de verdade
version: 1
---

O **pip-audit** lê uma lista de pacotes e versões e pergunta aos dados de alertas do PyPI sobre cada
um. É mantido pela Python Packaging Authority, não precisa de conta e roda num segundo. Instale no
ambiente do curso:

```
(.venv) ana@vm:~/sc/deps$ pip install --progress-bar off pip-audit==2.10.1
Collecting pip-audit==2.10.1
  Downloading pip_audit-2.10.1-py3-none-any.whl.metadata (28 kB)
Collecting CacheControl>=0.13.0 (from CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading cachecontrol-0.14.4-py3-none-any.whl.metadata (3.1 kB)
Collecting cyclonedx-python-lib<12,>=5 (from pip-audit==2.10.1)
  Downloading cyclonedx_python_lib-11.12.0-py3-none-any.whl.metadata (6.9 kB)
Requirement already satisfied: packaging>=23.0.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from pip-audit==2.10.1) (26.3)
Collecting pip-api>=0.0.28 (from pip-audit==2.10.1)
  Downloading pip_api-0.0.35-py3-none-any.whl.metadata (17 kB)
Collecting pip-requirements-parser>=32.0.0 (from pip-audit==2.10.1)
  Downloading pip_requirements_parser-32.0.1-py3-none-any.whl.metadata (9.3 kB)
Collecting requests>=2.31.0 (from pip-audit==2.10.1)
  Downloading requests-2.34.2-py3-none-any.whl.metadata (4.8 kB)
Collecting rich>=12.4 (from pip-audit==2.10.1)
  Downloading rich-15.0.0-py3-none-any.whl.metadata (18 kB)
Collecting tomli>=2.2.1 (from pip-audit==2.10.1)
  Downloading tomli-2.5.0-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (10 kB)
Collecting tomli-w>=1.2.0 (from pip-audit==2.10.1)
  Downloading tomli_w-1.2.0-py3-none-any.whl.metadata (5.7 kB)
Collecting platformdirs>=4.2.0 (from pip-audit==2.10.1)
  Downloading platformdirs-4.13.5-py3-none-any.whl.metadata (5.5 kB)
Collecting license-expression<31,>=30 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading license_expression-30.4.4-py3-none-any.whl.metadata (11 kB)
Collecting packageurl-python<2,>=0.11 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading packageurl_python-0.17.6-py3-none-any.whl.metadata (5.1 kB)
Collecting py-serializable<3.0.0,>=2.1.0 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading py_serializable-2.1.0-py3-none-any.whl.metadata (4.3 kB)
Collecting sortedcontainers<3.0.0,>=2.4.0 (from cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading sortedcontainers-2.4.0-py2.py3-none-any.whl.metadata (10 kB)
Collecting boolean.py>=4.0 (from license-expression<31,>=30->cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading boolean_py-5.0-py3-none-any.whl.metadata (2.3 kB)
Collecting defusedxml<0.8.0,>=0.7.1 (from py-serializable<3.0.0,>=2.1.0->cyclonedx-python-lib<12,>=5->pip-audit==2.10.1)
  Downloading defusedxml-0.7.1-py2.py3-none-any.whl.metadata (32 kB)
Collecting msgpack<2.0.0,>=0.5.2 (from CacheControl>=0.13.0->CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading msgpack-1.2.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (8.3 kB)
Collecting filelock>=3.8.0 (from CacheControl[filecache]>=0.13.0->pip-audit==2.10.1)
  Downloading filelock-4.2.4-py3-none-any.whl.metadata (2.0 kB)
Requirement already satisfied: pip in /home/ana/sc/.venv/lib/python3.13/site-packages (from pip-api>=0.0.28->pip-audit==2.10.1) (26.2.1)
Collecting pyparsing (from pip-requirements-parser>=32.0.0->pip-audit==2.10.1)
  Downloading pyparsing-3.3.3-py3-none-any.whl.metadata (5.9 kB)
Collecting charset_normalizer<4,>=2 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading charset_normalizer-3.5.2-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl.metadata (46 kB)
Collecting idna<4,>=2.5 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading idna-3.20-py3-none-any.whl.metadata (7.2 kB)
Collecting urllib3<3,>=1.26 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading urllib3-2.8.0-py3-none-any.whl.metadata (7.4 kB)
Collecting certifi>=2023.5.7 (from requests>=2.31.0->pip-audit==2.10.1)
  Downloading certifi-2026.10.23-py3-none-any.whl.metadata (2.5 kB)
Collecting markdown-it-py>=2.2.0 (from rich>=12.4->pip-audit==2.10.1)
  Downloading markdown_it_py-4.2.0-py3-none-any.whl.metadata (7.4 kB)
Requirement already satisfied: pygments<3.0.0,>=2.13.0 in /home/ana/sc/.venv/lib/python3.13/site-packages (from rich>=12.4->pip-audit==2.10.1) (2.21.0)
Collecting mdurl~=0.1 (from markdown-it-py>=2.2.0->rich>=12.4->pip-audit==2.10.1)
  Downloading mdurl-0.1.2-py3-none-any.whl.metadata (1.6 kB)
Downloading pip_audit-2.10.1-py3-none-any.whl (62 kB)
Downloading cyclonedx_python_lib-11.12.0-py3-none-any.whl (529 kB)
Downloading license_expression-30.4.4-py3-none-any.whl (120 kB)
Downloading packageurl_python-0.17.6-py3-none-any.whl (36 kB)
Downloading py_serializable-2.1.0-py3-none-any.whl (23 kB)
Downloading defusedxml-0.7.1-py2.py3-none-any.whl (25 kB)
Downloading sortedcontainers-2.4.0-py2.py3-none-any.whl (29 kB)
Downloading boolean_py-5.0-py3-none-any.whl (26 kB)
Downloading cachecontrol-0.14.4-py3-none-any.whl (22 kB)
Downloading msgpack-1.2.3-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (466 kB)
Downloading filelock-4.2.4-py3-none-any.whl (162 kB)
Downloading pip_api-0.0.35-py3-none-any.whl (123 kB)
Downloading pip_requirements_parser-32.0.1-py3-none-any.whl (35 kB)
Downloading platformdirs-4.13.5-py3-none-any.whl (32 kB)
Downloading requests-2.34.2-py3-none-any.whl (73 kB)
Downloading charset_normalizer-3.5.2-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (254 kB)
Downloading idna-3.20-py3-none-any.whl (69 kB)
Downloading urllib3-2.8.0-py3-none-any.whl (135 kB)
Downloading certifi-2026.10.23-py3-none-any.whl (135 kB)
Downloading rich-15.0.0-py3-none-any.whl (310 kB)
Downloading markdown_it_py-4.2.0-py3-none-any.whl (91 kB)
Downloading mdurl-0.1.2-py3-none-any.whl (10.0 kB)
Downloading tomli-2.5.0-cp313-cp313-manylinux2014_x86_64.manylinux_2_17_x86_64.manylinux_2_28_x86_64.whl (283 kB)
Downloading tomli_w-1.2.0-py3-none-any.whl (6.7 kB)
Downloading pyparsing-3.3.3-py3-none-any.whl (126 kB)
Installing collected packages: sortedcontainers, boolean.py, urllib3, tomli-w, tomli, pyparsing, platformdirs, pip-api, packageurl-python, msgpack, mdurl, license-expression, idna, filelock, defusedxml, charset_normalizer, certifi, requests, py-serializable, pip-requirements-parser, markdown-it-py, rich, cyclonedx-python-lib, CacheControl, pip-audit
Successfully installed CacheControl-0.14.4 boolean.py-5.0 certifi-2026.10.23 charset_normalizer-3.5.2 cyclonedx-python-lib-11.12.0 defusedxml-0.7.1 filelock-4.2.4 idna-3.20 license-expression-30.4.4 markdown-it-py-4.2.0 mdurl-0.1.2 msgpack-1.2.3 packageurl-python-0.17.6 pip-api-0.0.35 pip-audit-2.10.1 pip-requirements-parser-32.0.1 platformdirs-4.13.5 py-serializable-2.1.0 pyparsing-3.3.3 requests-2.34.2 rich-15.0.0 sortedcontainers-2.4.0 tomli-2.5.0 tomli-w-1.2.0 urllib3-2.8.0
```

Uma ferramenta que verifica dependências também tem dependências, 24 delas, e isso é a primeira seção
desta aula numa transcrição só. Cada nome dessa lista agora é código no seu ambiente.

### Uma trava do ano passado

Eis o tipo de arquivo que um projeto acumula: um `requirements.txt` com versões exatas, escrito
quando cada uma era a atual e nunca mais mexido. Salve em `~/sc/deps` e faça commit:

```
# requirements.txt
flask==3.1.3
jinja2==3.1.4
requests==2.31.0
```

O `-r` audita o arquivo em vez do ambiente, então verifica exatamente as versões que o projeto diz
que instala:

```
(.venv) ana@vm:~/sc/deps$ pip-audit -r requirements.txt
Found 12 known vulnerabilities in 2 packages
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
jinja2   3.1.4   PYSEC-2026-1475 3.1.5
jinja2   3.1.4   PYSEC-2026-1472 3.1.5
jinja2   3.1.4   PYSEC-2026-1471 3.1.6
jinja2   3.1.4   PYSEC-2026-1471 3.1.6
jinja2   3.1.4   PYSEC-2026-1475 3.1.5
jinja2   3.1.4   PYSEC-2026-1472 3.1.5
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
requests 2.31.0  PYSEC-2026-1873 2.32.0
requests 2.31.0  PYSEC-2026-1872 2.32.4
requests 2.31.0  PYSEC-2026-2275 2.33.0
```

**Leia os identificadores, não a contagem.** O pip-audit relata doze, e cada identificador aparece
duas vezes na lista, porque os dados de alertas responderam cada um duas vezes. São seis alertas
distintos, três para cada pacote, e para cada um a última coluna é a versão para onde ir. A maior
versão corrigida por pacote é a que resolve todos: `3.1.6` para o Jinja2 e `2.33.0` para o requests.

### A correção é uma nova versão fixada

Mude as duas linhas. O Jinja2 vai para `3.1.6`, a maior versão corrigida da lista. Para o requests,
o lançamento atual, `2.34.2`, é posterior a todas as versões corrigidas da lista, e ficar num
lançamento atual é melhor do que parar exatamente no mínimo:

```
# requirements.txt
flask==3.1.3
jinja2==3.1.6
requests==2.34.2
```

```
(.venv) ana@vm:~/sc/deps$ git diff
diff --git a/requirements.txt b/requirements.txt
index 00907dd..15dcfe2 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,4 +1,4 @@
 # requirements.txt
 flask==3.1.3
-jinja2==3.1.4
-requests==2.31.0
+jinja2==3.1.6
+requests==2.34.2
```

```
(.venv) ana@vm:~/sc/deps$ pip-audit -r requirements.txt
No known vulnerabilities found
```

Uma auditoria limpa diz que nenhum alerta **publicado** corresponde a essas versões hoje. Não diz
nada sobre falhas que ninguém relatou ainda, e só vale até o próximo alerta, e é por isso que a
auditoria pertence a uma rotina e não a uma verificação avulsa.

::: track devsecops
Na sua trilha, a aula 5 de `secure-pipeline` roda esta mesma auditoria no pipeline, a cada mudança,
e decide o que acontece com um build quando ela falha. Esta aula apresenta a ferramenta; aquela a
opera.
:::

::: track *
O lugar natural deste comando é o pipeline que testa cada mudança, para que um alerta novo derrube um
build no dia em que é publicado. A aula 19 o põe ao lado das outras verificações automáticas deste
curso.
:::
