---
title: Revogar primeiro, limpar depois
version: 1
---

O instinto, ao achar um segredo no código, é apagar a linha e fazer push, e esse é o primeiro passo
errado. **Apagar a linha não protege nada que já foi copiado**, e as duas últimas seções mostraram
quantas cópias existem. O que protege o sistema é tornar o valor inútil, então a resposta segue
esta ordem, e a ordem é o ponto:

1. Revogar. O valor para de funcionar, onde quer que esteja. Enquanto este passo não é feito, todo
   o resto é arrumação, então ele vem primeiro, e em minutos, não na próxima reunião de
   planejamento.
2. Substituir. O que precisa de acesso recebe um valor novo, entregue num lugar que não é o
   repositório.
3. Tirar do código, para que o próximo commit não carregue valor nenhum, vivo ou morto.
4. Olhar a janela. Da data do commit até a revogação, o valor foi usado, e por quem? A pergunta
   precisa de logs, e é ela que decide se isto é uma arrumação ou um incidente.
5. Decidir sobre o histórico, que é a próxima seção, e é a última decisão, não a primeira.
6. Dificultar o próximo: um hook no laptop e um estágio no pipeline, as duas últimas seções desta
   aula.

**A janela abre no commit e fecha na revogação, e nada entre os dois a fecha.** Apagar a linha é um
commit dentro da janela, não o fim dela:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l06-window\" aria-label=\"Uma linha do tempo do token. Ele entra num commit em 5 de outubro, depois é enviado, clonado e forkado; mais tarde uma varredura o encontra; mais tarde ainda um commit apaga a linha; só quando o token é revogado a janela se fecha. Do commit à revogação, qualquer pessoa com uma cópia pode usá-lo; depois da revogação as cópias não abrem nada.\"><defs><marker id=\"sp-l06-window-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l06-window-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"60\" y=\"100\" width=\"545\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"332\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">a janela: qualquer um com uma cópia pode usar o token</text><text x=\"662\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">as cópias não abrem nada</text><path d=\"M30 160 L700 160\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\" marker-end=\"url(#sp-l06-window-ah-paper-dim)\"></path><line x1=\"60\" y1=\"150\" x2=\"60\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"60\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">no commit</text><text x=\"60\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">5 de outubro</text><line x1=\"190\" y1=\"150\" x2=\"190\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"190\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">enviado, clonado,</text><text x=\"190\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">forkado</text><line x1=\"330\" y1=\"150\" x2=\"330\" y2=\"170\" stroke=\"var(--paper)\" stroke-width=\"2\"></line><text x=\"330\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">uma varredura</text><text x=\"330\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">o encontra</text><line x1=\"465\" y1=\"150\" x2=\"465\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"465\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">um commit</text><text x=\"465\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">apaga a linha</text><line x1=\"605\" y1=\"150\" x2=\"605\" y2=\"170\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></line><text x=\"605\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">revogado</text><text x=\"605\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a janela se fecha</text><text x=\"465\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--amber)\">settings.py: -1 +1</text><path d=\"M465 78 L465 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l06-window-ah-amber)\"></path></svg>", "caption": "Só a revogação fecha a janela. O commit que apaga a linha cai dentro dela, e toda cópia feita antes dele continua igual."}
```

### Quando outra pessoa emitiu o segredo

A maioria dos segredos é emitida por um provedor: uma chave de acesso de nuvem, um token do GitHub,
uma chave de API de pagamentos. Revogar um deles se faz no provedor, no console ou pela API dele, e
todo provedor documenta como; leva um minuto e não exige mudança nenhuma no código. Faça isso antes
de qualquer outra coisa, até antes de avisar alguém. A documentação do GitHub também descreve um
programa de parceiros em que tokens de provedores conhecidos encontrados em repositórios públicos
são informados ao provedor que os emitiu, para que ele os revogue. Esse programa não foi usado neste
curso, e não é motivo para esperar: quando ele age, o token já foi público.

### Quando você emitiu: o linkbox

O linkbox confere o token sozinho, contra `settings.ADMIN_TOKEN`. Não existe console onde revogá-lo.
**Revogar significa o serviço em execução parar de aceitar o valor antigo, e isso significa que o
valor não pode mais morar no código**, porque o que está no código é o que o serviço compara. Então,
no linkbox, os passos 1 a 3 são uma mudança só: o token vai para o ambiente do serviço, onde cada
implantação define o seu.

As novas configurações o leem de `LINKBOX_TOKEN` e se recusam a subir sem ele. `os.environ[...]`
levanta um erro quando a variável não existe, que é o comportamento desejado: um serviço que cai num
token padrão é um serviço cujo token padrão acaba em produção. Salve as novas configurações como
`settings.py`:

```python
import os

DATABASE = os.environ.get("LINKBOX_DB", "linkbox.db")
ADMIN_TOKEN = os.environ["LINKBOX_TOKEN"]
```

Os testes importam as configurações, então agora falham antes de rodar um único teste, que é a
recusa funcionando:

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q 2>&1 | tail -n 4
=========================== short test summary info ============================
ERROR tests/test_app.py - KeyError: 'LINKBOX_TOKEN'
!!!!!!!!!!!!!!!!!!!! Interrupted: 1 error during collection !!!!!!!!!!!!!!!!!!!!
1 error in 0.52s
```

O pytest lê `tests/conftest.py` antes de importar qualquer módulo de teste, então um token definido
ali já está no lugar quando `settings.py` é importado. `setdefault` não mexe num token que já esteja
no ambiente. Salve como `tests/conftest.py`:

```python
import os

# The application refuses to start without a token. The tests bring one of
# their own, which opens nothing anywhere else.
os.environ.setdefault("LINKBOX_TOKEN", "a-token-for-the-tests-only")
```

```
ana@vm:~/linkbox$ .venv/bin/python -m pytest -q
.....                                                                    [100%]
5 passed in 0.23s
```

Esse valor de teste é uma string num arquivo do repositório, e não é um segredo. **O que faz de um
valor um segredo é o que ele abre**, e este abre um banco de dados num diretório temporário que
existe pelo tempo de um teste.

### A rotação, na tela

Um token novo, gerado pelo módulo `secrets` do Python e posto direto no ambiente, para nunca ser
impresso nem digitado num arquivo. Depois o serviço, iniciado com ele, e o token antigo tentado
contra o serviço novo:

```
ana@vm:~/linkbox$ export LINKBOX_TOKEN=$(python3 -c 'import secrets; print("lbx_" + secrets.token_urlsafe(24))')
ana@vm:~/linkbox$ .venv/bin/gunicorn --daemon --pid linkbox.pid --bind 127.0.0.1:8000 app:app
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x" -d url=https://example.org http://127.0.0.1:8000/links
401
ana@vm:~/linkbox$ curl -s -o /dev/null -w "%{http_code}\n" -X POST -H "X-Token: $LINKBOX_TOKEN" -d url=https://example.org http://127.0.0.1:8000/links
201
ana@vm:~/linkbox$ kill $(cat linkbox.pid)
```

**401 para o valor que está em cinco commits, 201 para o novo.** Esse é o momento em que o
histórico deixou de ser perigoso. Toda cópia do repositório ainda guarda `lbx_7Rq2…`, e ele não abre
nada. Numa implantação real, o valor novo iria para o cofre de segredos da plataforma, e não para
uma variável do shell, que é o que a aula 17 monta; o formato do passo é o mesmo.

O passo 4 é o que o linkbox não consegue responder. O gunicorn não escreve log de acesso a menos que
se peça com `--access-logfile`, e o linkbox não registra nada sobre quem criou um link, então não há
registro de se o token antigo foi usado enquanto valia. **Essa ausência já é um achado**: o próximo
vazamento vai fazer a mesma pergunta, e a resposta tem de existir antes dele.

### Faça o commit, e olhe de novo

```
ana@vm:~/linkbox$ git add settings.py tests/conftest.py
ana@vm:~/linkbox$ git commit -q -m "the token out of the code, and a token of their own for the tests"
```

Agora as duas varreduras discordam:

```
ana@vm:~/linkbox$ gitleaks dir --no-banner --no-color .
2:00AM INF scanned ~50638 bytes (50.64 KB) in 37.4ms
2:00AM INF no leaks found
ana@vm:~/linkbox$ gitleaks git --no-banner --no-color --redact -v .
2:00AM INF Unknown SCM platform. Use --platform to include links in findings. host=
Finding:     ADMIN_TOKEN = "REDACTED"
Secret:      REDACTED
RuleID:      generic-api-key
Entropy:     5.058814
File:        settings.py
Line:        4
Commit:      3f932db1ab33201959dc1dd9270d46dc0485e297
Author:      Ana Lima
Email:       ana@example.org
Date:        2026-10-05T13:00:00Z
Fingerprint: 3f932db1ab33201959dc1dd9270d46dc0485e297:settings.py:generic-api-key:4

2:00AM INF 6 commits scanned.
2:00AM INF scanned ~9214 bytes (9.21 KB) in 202ms
2:00AM WRN leaks found: 1
```

Os arquivos estão limpos e o histórico não, e isso vai continuar verdade por mais commits que
venham. `--redact` é novidade aqui: ele imprime `REDACTED` onde estaria o valor, e é assim que uma
varredura deve rodar em qualquer lugar onde a saída é lida por mais gente que o dono do valor, num
log de CI acima de tudo.
