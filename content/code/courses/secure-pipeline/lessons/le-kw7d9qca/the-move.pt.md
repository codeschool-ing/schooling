---
title: O menor movimento que limpa a lista, e o estágio que a mantém limpa
version: 1
---

Todo achado tem versão corrigida, então a correção é uma atualização. A pergunta é até onde.
"Atualizar tudo para a última versão" é o movimento a que as pessoas recorrem, e num serviço real é
uma mudança grande: versões major novas, recursos removidos, uma revisão que ninguém faz numa tarde.
**O movimento mínimo é levar cada pacote apontado à menor versão que corrige todos os avisos dele, e
depois só o que essas versões novas exigem.** É a menor mudança que faz a auditoria passar, então é a
mais fácil de revisar e a que tem menos chance de quebrar algo que ninguém testou.

A aula 15 pesa as escolhas maiores, atualizar, fixar e substituir, para o longo prazo. Esta seção
limpa a lista.

### As versões-alvo

Para cada pacote, a maior versão corrigida nas linhas dele é a que limpa todas:

| pacote | fixado | versões corrigidas na auditoria | mover para |
|---|---|---|---|
| flask | 3.0.0 | 3.1.3 | 3.1.3 |
| werkzeug | 3.0.1 | 3.0.3, 3.0.6, 3.1.4, 3.1.5, 3.1.6, 3.1.9 | 3.1.9 |
| jinja2 | 3.1.2 | 3.1.3, 3.1.4, 3.1.5, 3.1.6 | 3.1.6 |
| gunicorn | 21.2.0 | 22.0.0 | 22.0.0 |

Troque essas quatro linhas e, antes de instalar qualquer coisa, leia o que o Flask novo pede. O PyPI
publica os requisitos de cada versão no mesmo JSON que trouxe os avisos:

```
ana@vm:~/linkbox$ sed -i -e "s/^flask==.*/flask==3.1.3/" -e "s/^werkzeug==.*/werkzeug==3.1.9/" -e "s/^jinja2==.*/jinja2==3.1.6/" -e "s/^gunicorn==.*/gunicorn==22.0.0/" requirements.txt
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/flask/3.1.3/json | jq -r ".info.requires_dist[]"
blinker>=1.9.0
click>=8.1.3
importlib-metadata>=3.6.0; python_version < "3.10"
itsdangerous>=2.2.0
jinja2>=3.1.2
markupsafe>=2.1.1
werkzeug>=3.1.0
asgiref>=3.2; extra == "async"
python-dotenv; extra == "dotenv"
```

**Duas das versões fixadas deixaram de servir.** O Flask 3.1.3 pede `itsdangerous` 2.2.0 ou mais, e o
arquivo fixa 2.1.2; pede `blinker` 1.9.0 ou mais, e o arquivo fixa 1.7.0. Instale o arquivo como está
e o uv o recusa, apontando a primeira contradição que encontra. Essa é a metade "depois só o que as
versões novas exigem" do movimento, e é por isso que um arquivo de versões transitivas fixadas não
pode ser editado uma linha por vez sem conferir o que cada versão nova pede. O texto depois de um `;`
é uma condição: o `importlib-metadata` só é necessário em Python anterior ao 3.10, e as duas últimas
linhas só quando alguém instala o Flask com um extra opcional, então nenhuma das três pede nada ao
linkbox em Python 3.13. Click e MarkupSafe já atendem ao que o Flask e o Werkzeug novo pedem, então
essas duas linhas ficam como estão.

O arquivo ao fim do movimento, como `requirements.txt`:

```
flask==3.1.3
werkzeug==3.1.9
jinja2==3.1.6
markupsafe==2.1.3
itsdangerous==2.2.0
click==8.1.7
blinker==1.9.0
gunicorn==22.0.0
```

### Provando que nada quebrou

O diff é a mudança inteira, seis linhas. Depois o mesmo ambiente, os testes e a auditoria de novo:

```
ana@vm:~/linkbox$ git diff requirements.txt
diff --git a/requirements.txt b/requirements.txt
index 544b9a2..3ce38e7 100644
--- a/requirements.txt
+++ b/requirements.txt
@@ -1,8 +1,8 @@
-flask==3.0.0
-werkzeug==3.0.1
-jinja2==3.1.2
+flask==3.1.3
+werkzeug==3.1.9
+jinja2==3.1.6
 markupsafe==2.1.3
-itsdangerous==2.1.2
+itsdangerous==2.2.0
 click==8.1.7
-blinker==1.7.0
-gunicorn==21.2.0
+blinker==1.9.0
+gunicorn==22.0.0
ana@vm:~/linkbox$ uv pip install -q -r requirements.txt -r requirements-dev.txt
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.49s
ana@vm:~/linkbox$ pip-audit -r requirements.txt; echo "exit status $?"
No known vulnerabilities found
exit status 0
```

Cinco testes passam com Flask 3.1 e Werkzeug 3.1, e a auditoria das dependências do serviço está
limpa. **Um movimento sem a rodada de testes é um palpite**, e num projeto sem testes o movimento
mínimo é o único defensável, porque é o que tem menos coisa para dar errado. O gunicorn fica na
22.0.0 por enquanto; a aula 15 o leva à 26, uma decisão que pede a leitura do changelog.

### O estágio

A auditoria pertence ao pipeline, em todo push: leva segundos, e uma dependência sabidamente
vulnerável deveria parar antes de uma imagem ser construída com ela. Salve o estágio como
`ci/sca.sh`:

```sh
# Composition analysis: every dependency the two requirements files pin,
# against the advisories PyPI publishes. A dependency with a known
# vulnerability breaks the build, and so does one pip-audit could not check.
set -euo pipefail
pip-audit --strict -r requirements.txt -r requirements-dev.txt
```

Duas escolhas nele. **Os dois arquivos são auditados**, o do serviço e o dos testes, pelo motivo que a
primeira seção desta aula deu. E **o `--strict` faz a auditoria falhar se o pip-audit não conseguiu
coletar uma dependência**: sem ele, um pacote que não pôde ser resolvido é pulado com um aviso e o
estágio passa, o que transforma "não consegui conferir" em "conferi e não achei nada".

O estágio vai depois da análise estática e antes do build, como `ci/stages`:

```
test
sast
sca
build
```

### A primeira execução falha, num arquivo que ninguém tinha auditado

Faça commit dos requisitos movidos e do estágio, e o push:

```
ana@vm:~/linkbox$ git add requirements.txt ci
ana@vm:~/linkbox$ git commit -q -m "dependencies moved past their advisories, and composition analysis in the pipeline"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at e9589de        
remote: test: passed in 1s        
remote: sast: passed in 2s        
remote: sca: FAILED in 8s, the end of sca.log:        
remote:   Found 2 known vulnerabilities in 1 package        
remote:   Name   Version ID              Fix Versions        
remote:   ------ ------- --------------- ------------        
remote:   pytest 8.4.2   PYSEC-2026-1845 9.0.3        
remote:   pytest 8.4.2   PYSEC-2026-1845 9.0.3        
remote: run 1: failed, the logs are in ~/ci/runs/1/logs        
To /home/ana/ci/linkbox.git
   d1186df..e9589de  main -> main
```

As dependências do serviço estão limpas, e o build quebra mesmo assim: **o pytest 8.4.2 tem um
aviso**, corrigido na 9.0.3. Ele estava nas versões da primeira aula o tempo todo; ninguém tinha
auditado o segundo arquivo antes. Leia o aviso antes de decidir qualquer coisa:

```
ana@vm:~/linkbox$ pip-audit -r requirements-dev.txt -f json 2>/dev/null | jq -r ".dependencies[] | select(.name == \"pytest\") | .vulns[0].description"
pytest through 9.0.2 on UNIX relies on directories with the `/tmp/pytest-of-{user}` name pattern, which allows local users to cause a denial of service or possibly gain privileges.
```

A condição é outro usuário local na mesma máquina. Isso não preocupa dentro da imagem do linkbox, que
não contém o pytest. Preocupa numa máquina de CI que roda jobs de mais de um projeto ou de mais de uma
pessoa, que é exatamente onde o pytest roda, ao lado das credenciais do pipeline.

O movimento é o mesmo: a menor versão corrigida. Salve-o como `requirements-dev.txt`:

```
pytest==9.0.3
```

O pytest 9 é uma versão major, então os testes rodam antes do commit, não depois:

```
ana@vm:~/linkbox$ uv pip install -q -r requirements-dev.txt && .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.14s
ana@vm:~/linkbox$ git commit -qam "pytest moved past its advisory"
ana@vm:~/linkbox$ git push ci main
remote: run 2: main at cf8828c        
remote: test: passed in 1s        
remote: sast: passed in 3s        
remote: sca: passed in 7s        
remote: build: passed in 1s        
remote: pipeline passed        
remote: run 2: passed        
To /home/ana/ci/linkbox.git
   e9589de..cf8828c  main -> main
```

A execução 2 passa: testes, análise estática, análise de composição e build. Daqui em diante todo
push é auditado contra o que o PyPI sabe naquele dia, o que quer dizer que **um push que não muda
nada pode falhar amanhã**, quando sair um aviso para uma versão já fixada. É o estágio fazendo o
trabalho dele, e é também a primeira coisa que faz times desligarem um estágio. A aula 7 decide o
que o portão faz com um achado sem correção, ou com um que ninguém consegue corrigir hoje.
