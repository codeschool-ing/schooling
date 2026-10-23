---
title: Diretas e transitivas, o que o linkbox realmente roda
version: 1
---

Pergunte a um time de que o serviço dele depende, e a resposta de costume é a lista do arquivo de
requisitos. Essa lista é uma decisão sobre versões. **O que o serviço roda é cada pacote instalado
para satisfazê-la**, e a maioria deles foi escolhida pelos autores de outros pacotes, não pelo time.

O código do próprio linkbox é um arquivo. O código que roda quando ele responde a uma requisição é,
na maior parte, de outras pessoas: o roteamento do Flask, o parsing da requisição pelo Werkzeug, os
templates do Jinja, o tratamento da conexão pelo gunicorn. Uma falha em qualquer um deles é uma falha
no linkbox, exatamente como uma falha no `app.py` seria, porque roda no mesmo processo, com os mesmos
dados.

### Diretas e transitivas

Uma dependência **direta** é uma que o seu código usa pelo nome. O linkbox tem duas: o `app.py`
importa `flask`, e o Dockerfile inicia o `gunicorn`. Uma dependência **transitiva** é uma de que uma
dependência precisa: o Flask precisa do Werkzeug, do Jinja e de mais quatro, e o Jinja precisa do
MarkupSafe. Você não as escolheu, e roda todas mesmo assim.

O `uv pip tree` desenha tudo a partir do ambiente que os testes usam:

```
ana@vm:~$ cd linkbox
ana@vm:~/linkbox$ uv venv -q && uv pip install -q -r requirements.txt -r requirements-dev.txt
ana@vm:~/linkbox$ uv pip tree
flask v3.0.0
├── blinker v1.7.0
├── click v8.1.7
├── itsdangerous v2.1.2
├── jinja2 v3.1.2
│   └── markupsafe v2.1.3
└── werkzeug v3.0.1
    └── markupsafe v2.1.3
gunicorn v21.2.0
└── packaging v26.3
pytest v8.4.2
├── iniconfig v2.3.1
├── packaging v26.3
├── pluggy v1.7.0
└── pygments v2.21.0
```

Leia como uma lista de quem trouxe o quê. `flask` e `gunicorn` estão na margem esquerda porque nada
mais os exige; o mesmo vale para `pytest`, que vem do segundo arquivo de requisitos. Tudo o que está
recuado entrou porque um pacote acima pediu. O `markupsafe` aparece duas vezes porque dois pacotes
precisam dele, e é instalado uma vez.

Treze pacotes estão instalados, e os dois arquivos de requisitos citam nove. **A aula 1 fixou à mão
as dependências transitivas do Flask**, e é por isso que `werkzeug==3.0.1` está no `requirements.txt`
ao lado de `flask==3.0.0`, embora o `app.py` nunca importe o Werkzeug. Quatro pacotes não são citados
em lugar nenhum: o `packaging`, que o gunicorn e o pytest puxam, e o `iniconfig`, o `pluggy` e o
`pygments`, que o pytest puxa. As versões deles são as que o índice oferecia no dia em que o ambiente
foi criado. A aula 13 reencontra o `packaging` dentro da imagem, e a aula 15 o fixa com o resto num
lock file compilado.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l05-tree\" aria-label=\"Os treze pacotes instalados do linkbox em dois eixos. Diretos e fixados num arquivo de requisitos: flask, gunicorn e pytest. Diretos e citados em lugar nenhum: nenhum. Transitivos e fixados: werkzeug, jinja2, markupsafe, itsdangerous, click e blinker. Transitivos e citados em lugar nenhum: packaging, iniconfig, pluggy e pygments. Cinco têm avisos nas versões da aula 1: flask, gunicorn, pytest, werkzeug e jinja2.\"><defs></defs><text x=\"300\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">fixados num arquivo de requisitos</text><text x=\"595\" y=\"28\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">citados em lugar nenhum</text><rect x=\"140\" y=\"44\" width=\"320\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"44\" width=\"240\" height=\"60\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"140\" y=\"114\" width=\"320\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><rect x=\"470\" y=\"114\" width=\"240\" height=\"120\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"20\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">diretos</text><text x=\"20\" y=\"174\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">transitivos</text><rect x=\"150\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">flask</text><rect x=\"254\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">gunicorn</text><rect x=\"358\" y=\"59\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pytest</text><text x=\"590\" y=\"74\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhum</text><rect x=\"150\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">werkzeug</text><rect x=\"254\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">jinja2</text><rect x=\"358\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">markupsafe</text><rect x=\"150\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"198.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">itsdangerous</text><rect x=\"254\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"302.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">click</text><rect x=\"358\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"406.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">blinker</text><rect x=\"486\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">packaging</text><rect x=\"596\" y=\"129\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">iniconfig</text><rect x=\"486\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"534.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pluggy</text><rect x=\"596\" y=\"184\" width=\"96\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"644.0\" y=\"199.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pygments</text><rect x=\"140\" y=\"262\" width=\"22\" height=\"14\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"170\" y=\"269\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tem aviso nas versões da aula 1</text></svg>", "caption": "Nove pacotes estão fixados e treze estão instalados; dois dos cinco com avisos são pacotes que o linkbox nunca escolheu."}
```

### Por que a metade transitiva é o risco maior

Três coisas tornam os pacotes que você não escolheu mais difíceis de cuidar que os que você
escolheu.

- **Ninguém no time decidiu usá-los**, então ninguém acompanha as versões deles. Um time lê o
  changelog do Flask porque atualiza o Flask de propósito. Poucos times leem o do Werkzeug.
- **Eles mudam sem commit.** Um pacote transitivo sem versão fixa anda quando a faixa do pacote pai
  permite, na próxima vez que um ambiente ou uma imagem é construído. A imagem construída na segunda e
  a construída na quinta podem diferir sem que o repositório tenha mudado. O rebuild noturno da aula
  2 existe em parte por isso.
- **Eles são mais numerosos.** Aqui três pacotes diretos, o pytest incluído, trazem outros dez. Num
  serviço de tamanho comum a proporção costuma ser bem maior, e cada um deles pode ter um aviso.

### As dependências de desenvolvimento também contam

O pytest não está na imagem, então é tentador deixá-lo fora de uma auditoria. Ele roda, porém: no
laptop de cada desenvolvedor e no servidor de CI, com o repositório no disco e as credenciais que o
pipeline tiver por perto. Uma falha numa ferramenta de teste é uma falha na máquina de build, e a
aula 16 trata a máquina de build como um alvo por si só. **Esta aula audita os dois arquivos**, e a
primeira execução do estágio que ela acrescenta falha no pytest, não em nada que o linkbox entrega.

### O que um analisador de composição faz com isso

Análise de composição de software, SCA, é o nome de conferir essa lista contra o que se sabe
publicamente de errado em cada versão dela. A ferramenta coleta os pacotes e as versões, de um
arquivo de requisitos, de um lock file, de um ambiente ou de uma imagem, e consulta cada um num banco
de avisos. A qualidade da resposta depende das duas metades: uma ferramenta que coleta a lista errada
confere perfeitamente os pacotes errados, e a seção sobre o Trivy, perto do fim desta aula, mostra
duas ferramentas coletando listas diferentes do mesmo diretório.
