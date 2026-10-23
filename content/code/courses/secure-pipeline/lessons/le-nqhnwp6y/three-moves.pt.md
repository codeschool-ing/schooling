---
title: Três movimentos, e quando cada um é o certo
version: 1
---

A aula 5 tratou uma dependência como uma lista de avisos: um scanner aponta um pacote e uma versão,
e a correção é a versão que o aviso diz estar corrigida. Isso resolve o achado à sua frente. Não
responde à pergunta que decide a maior parte do risco de um serviço ao longo de um ano: **o que
fazemos com esta dependência daqui em diante?** Há três movimentos, e cada um é o certo numa
situação diferente.

| movimento | o que é | certo quando |
|---|---|---|
| **atualizar** | pegar uma versão mais nova, de propósito, com o changelog lido e os testes rodados | o projeto está saudável e a versão nova é a que os mantenedores suportam |
| **fixar** | travar a versão exata e o hash de cada arquivo, e mudar só de propósito | sempre, como base de onde todo outro movimento parte |
| **substituir** | deixar de depender dele, por outro pacote ou por código próprio | o projeto parou de corrigir o que importa para você |

**Fixar não é alternativa a atualizar; é o que faz de uma atualização uma decisão.** Um serviço
cujas dependências flutuam pega o que foi publicado ontem à noite, em produção, sem ninguém ter
lido uma palavra. Um serviço que fixa atualiza quando alguém escolhe, e as checagens do pipeline
rodam sobre a mudança. O resto da aula faz os três com o linkbox: o pin com hashes, uma atualização
do gunicorn atravessando quatro versões major, e uma substituição argumentada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" data-fig=\"sp-l15-moves\" aria-label=\"Os três movimentos para uma dependência. Fixar é a base sob todo pacote: versões exatas e hashes. Em cima disso, atualizar quando o projeto está saudável e a versão nova é suportada, ou substituir quando o projeto não vai corrigir o que importa para você.\"><defs><marker id=\"sp-l15-moves-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l15-moves-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"260\" y=\"20\" width=\"200\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"37.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">uma dependência</text><text x=\"360.0\" y=\"54.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a saúde dela lida antes</text><rect x=\"60\" y=\"100\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"175.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">atualizar</text><text x=\"175.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versão nova, lida e testada</text><rect x=\"430\" y=\"100\" width=\"230\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"545.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">substituir</text><text x=\"545.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">outro pacote, ou nenhum</text><rect x=\"60\" y=\"170\" width=\"600\" height=\"46\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">fixar</text><text x=\"360.0\" y=\"202.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versões exatas e hashes, mudados só de propósito</text><path d=\"M300 70 L300 85 L175 85 L175 98\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-moves-ah-phosphor)\"></path><path d=\"M420 70 L420 85 L545 85 L545 98\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l15-moves-ah-amber)\"></path><text x=\"170\" y=\"78\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">saudável, e corrigindo</text><text x=\"550\" y=\"78\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">não vai corrigir o que importa</text></svg>", "caption": "Fixar é o chão em que todo pacote pisa; atualizar e substituir são as duas decisões tomadas em cima dele."}
```

### Lendo a saúde de um pacote

Antes de escolher um movimento, olhe o pacote como projeto, e não como número de versão. Quatro
perguntas, cada uma com um lugar onde ler a resposta:

- **Ele é mantido?** O histórico de releases: quão recente, quão regular, e se majors antigos ainda
  recebem correções.
- **Quem o mantém?** Os commits recentes do repositório: uma pessoa ou várias, e se quem o escreveu
  ainda é quem faz merge.
- **O que ele puxa?** As dependências dele, que também são suas.
- **O que está aberto contra ele?** Avisos sem versão corrigida, e a resposta dos mantenedores a eles.

Quantos outros projetos dependem dele também importa, porque um pacote com muitos dependentes é
vigiado por muitos olhos e também é um prêmio maior. Serviços como deps.dev e libraries.io respondem
a essa pergunta; nenhum dos dois foi alcançável da máquina de gravação, então ela fica nomeada aqui e
não mostrada.

### Do que o linkbox realmente depende

O `requirements.txt` da aula 5 nomeia oito pacotes, e dois deles são o que o linkbox pediu. O `uv pip
tree` mostra quem puxa o quê, no ambiente virtual montado a partir desses pins:

```
ana@vm:~/linkbox$ uv pip tree --package gunicorn --package flask
flask v3.1.3
├── blinker v1.9.0
├── click v8.1.7
├── itsdangerous v2.2.0
├── jinja2 v3.1.6
│   └── markupsafe v2.1.3
├── markupsafe v2.1.3
└── werkzeug v3.1.9
    └── markupsafe v2.1.3
gunicorn v22.0.0
└── packaging v26.3
```

Duas árvores. O Flask traz seis pacotes, e **o gunicorn traz o `packaging`**, o pacote que a lista de
materiais da aula 13 achou na imagem embora nenhum arquivo de requisitos o nomeasse. Ele chegou lá
porque o gunicorn 22 o declara como dependência, e a lista plana de pins da aula 5 não tinha como
dizer isso.

### O gunicorn como projeto

O PyPI responde à primeira pergunta para qualquer pacote com um documento JSON. Os últimos doze
releases do gunicorn, pela data em que o primeiro arquivo foi enviado:

```
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/gunicorn/json | jq -r ".releases | to_entries[] | select(.value | length > 0) | \"\(.value[0].upload_time[:10]) \(.key)\"" | sort | tail -n 12
2026-01-23 24.1.0
2026-01-24 24.1.1
2026-02-01 25.0.0
2026-02-02 25.0.1
2026-02-06 25.0.2
2026-02-07 25.0.3
2026-02-13 25.1.0
2026-03-24 25.2.0
2026-03-27 25.3.0
2026-05-05 26.0.0
2026-08-18 26.1.0
2026-08-24 26.2.0
ana@vm:~/linkbox$ for v in 22.0.0 26.2.0; do echo "$v: $(curl -s https://pypi.org/pypi/gunicorn/$v/json | jq -c "[.info.requires_dist[] | select(contains(\"extra\") | not)]")"; done
22.0.0: ["packaging","importlib-metadata; python_version < \"3.8\""]
26.2.0: []
```

Quatro versões major desde o 22 que o linkbox fixa, a mais recente em agosto, e releases menores
regulares no meio. É um projeto em movimento, o que é boa notícia para a saúde dele e um custo para
quem fica para trás: **quanto mais um pin fica para trás, maior o salto quando um aviso o forçar.** O
segundo comando lista o que cada versão exige fora dos extras opcionais. O gunicorn 22 exige o
`packaging` diretamente; o gunicorn 26 não exige nada, e só cita o `packaging` em extras que o
linkbox não instala.

Então uma atualização do gunicorn tiraria um pacote da imagem, além de levar o servidor quatro majors
adiante. É uma decisão com um changelog para ler, e uma seção mais adiante desta aula a toma. Antes,
os pins precisam virar algo contra o que uma atualização possa ser medida.
