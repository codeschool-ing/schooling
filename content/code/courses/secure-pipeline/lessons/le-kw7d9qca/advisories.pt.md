---
title: Avisos de segurança, e por que uma falha tem três nomes
version: 1
---

Um **aviso de segurança** (advisory) é uma declaração publicada sobre um pacote: estas versões têm
esta falha, e esta versão a corrige. É a unidade de que toda análise de composição é feita. Um
scanner não acha uma falha no Werkzeug lendo o Werkzeug; ele descobre que a versão instalada cai
dentro de uma faixa que alguém já publicou.

Isso tem uma consequência que vale dizer antes de rodar qualquer coisa: **SCA só acha o que foi
divulgado.** Uma falha que ninguém relatou, ou uma relatada ontem e que ainda não chegou ao banco,
passa em toda auditoria. A auditoria responde "há algo sabidamente errado com estas versões", que é
uma pergunta mais estreita que "este código é seguro".

### Os nomes

Uma falha costuma ser publicada com vários identificadores, por organizações diferentes, em bancos
diferentes. Quatro importam num projeto Python:

| identificador | quem atribui | o que é |
|---|---|---|
| CVE-2026-27205 | uma CVE Numbering Authority, sob o CVE Program | um identificador por falha, em toda linguagem e todo produto |
| GHSA-68rp-wp8r-4726 | o GitHub, no GitHub Advisory Database | um aviso revisado para um ecossistema de pacotes, com as faixas de versão afetadas |
| PYSEC-2026-2151 | o banco de avisos da Python Packaging Authority | avisos para pacotes do PyPI, mantidos no formato OSV |
| OSV | o projeto open-source vulnerability, em osv.dev | um formato comum, e um serviço que reúne GHSA, PYSEC e outros bancos e registra quais ids são a mesma falha |

O CVE diz *qual* falha. Os registros GHSA e PYSEC dizem *quais versões de qual pacote*, que é o que
um scanner precisa, e cada um lista os outros como **aliases**.

### De onde o pip-audit os tira

O `pip-audit` instala os requisitos num ambiente temporário só dele, e assim conhece cada pacote que
seria instalado, os transitivos inclusive. Depois consulta cada pacote e versão num serviço de
vulnerabilidades. O padrão é **o próprio PyPI**: a descrição JSON de cada versão no pypi.org traz os
avisos que a afetam, vindos do OSV. O `-s osv` pergunta direto ao osv.dev; a máquina deste curso não
alcança o osv.dev, então toda auditoria aqui usa o padrão.

Rode-o nas versões fixadas da aula 1:

```
ana@vm:~/linkbox$ pip-audit --version
pip-audit 2.10.1
ana@vm:~/linkbox$ pip-audit -r requirements.txt; echo "exit status $?"
Found 29 known vulnerabilities in 4 packages
Name     Version ID              Fix Versions
-------- ------- --------------- ------------
flask    3.0.0   PYSEC-2026-2151 3.1.3
flask    3.0.0   PYSEC-2026-2151 3.1.3
werkzeug 3.0.1   PYSEC-2026-2043 3.0.3
werkzeug 3.0.1   PYSEC-2026-2045 3.0.6
werkzeug 3.0.1   PYSEC-2026-1860 3.0.6
werkzeug 3.0.1   PYSEC-2026-2046 3.1.4
werkzeug 3.0.1   PYSEC-2026-2044 3.1.5
werkzeug 3.0.1   PYSEC-2026-2320 3.1.6
werkzeug 3.0.1   PYSEC-2026-2045 3.0.6
werkzeug 3.0.1   PYSEC-2026-2046 3.1.4
werkzeug 3.0.1   PYSEC-2026-2044 3.1.5
werkzeug 3.0.1   PYSEC-2026-2043 3.0.3
werkzeug 3.0.1   PYSEC-2026-2320 3.1.6
werkzeug 3.0.1   PYSEC-2026-3417 3.0.6
werkzeug 3.0.1   PYSEC-2026-4312 3.1.9
jinja2   3.1.2   PYSEC-2026-1473 3.1.3
jinja2   3.1.2   PYSEC-2026-1474 3.1.4
jinja2   3.1.2   PYSEC-2026-1475 3.1.5
jinja2   3.1.2   PYSEC-2026-1472 3.1.5
jinja2   3.1.2   PYSEC-2026-1471 3.1.6
jinja2   3.1.2   PYSEC-2026-1473 3.1.3
jinja2   3.1.2   PYSEC-2026-1471 3.1.6
jinja2   3.1.2   PYSEC-2026-1474 3.1.4
jinja2   3.1.2   PYSEC-2026-1475 3.1.5
jinja2   3.1.2   PYSEC-2026-1472 3.1.5
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
gunicorn 21.2.0  PYSEC-2026-1434 22.0.0
gunicorn 21.2.0  PYSEC-2026-1433 22.0.0
exit status 1
```

Status de saída 1: algo foi achado, e um estágio de pipeline rodando este comando quebraria.

### Vinte e nove linhas, quinze falhas

**A maioria das falhas aparece duas vezes nessa tabela**, e isso não é defeito do projeto. O PyPI
publica dois registros para a maioria das falhas, o do GHSA e o do PYSEC, e o pip-audit imprime uma
linha para cada registro, chamando os dois pelo id PYSEC. Pergunte ao PyPI sobre o Flask 3.0.0
diretamente e os dois registros estão lá, cada um citando o outro como alias, e cada um dizendo que
veio do OSV:

```
ana@vm:~/linkbox$ curl -s https://pypi.org/pypi/flask/3.0.0/json | jq ".vulnerabilities[] | {id, aliases, fixed_in, source}"
{
  "id": "GHSA-68rp-wp8r-4726",
  "aliases": [
    "CVE-2026-27205",
    "PYSEC-2026-2151"
  ],
  "fixed_in": [
    "3.1.3"
  ],
  "source": "osv"
}
{
  "id": "PYSEC-2026-2151",
  "aliases": [
    "CVE-2026-27205",
    "GHSA-68rp-wp8r-4726"
  ],
  "fixed_in": [
    "3.1.3"
  ],
  "source": "osv"
}
```

Então a contagem que uma ferramenta imprime é de registros, não de problemas. Contar os ids CVE
distintos dá o número de falhas. O `-f json -o` grava o relatório em JSON para o `jq` ler:

```
ana@vm:~/linkbox$ pip-audit -r requirements.txt -f json -o /tmp/audit.json
Found 29 known vulnerabilities in 4 packages
ana@vm:~/linkbox$ jq "[.dependencies[].vulns[]] | length" /tmp/audit.json
29
ana@vm:~/linkbox$ jq -r "[.dependencies[].vulns[].aliases[] | select(startswith(\"CVE-\"))] | unique[]" /tmp/audit.json > /tmp/cves.txt
ana@vm:~/linkbox$ wc -l < /tmp/cves.txt
15
```

**Quinze falhas em quatro pacotes**: uma no Flask, sete no Werkzeug, cinco no Jinja e duas no
gunicorn. A lista de ids CVE em `/tmp/cves.txt` volta a ser usada na seção sobre as notas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l05-names\" aria-label=\"Uma falha do Flask 3.0.0 com os seus nomes. CVE-2026-27205 identifica a falha. Ela é publicada duas vezes, como GHSA-68rp-wp8r-4726 no banco de avisos do GitHub e como PYSEC-2026-2151 no da Python Packaging Authority, cada um citando o outro como alias. O osv.dev reúne os dois; o JSON do PyPI para a versão serve os dois registros; o pip-audit imprime uma linha para cada, e uma falha vira duas linhas.\"><defs><marker id=\"sp-l05-names-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"sp-l05-names-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"sp-l05-names-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20\" y=\"100\" width=\"150\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">CVE-2026-27205</text><text x=\"95.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a falha</text><rect x=\"210\" y=\"30\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">GHSA-68rp-wp8r-4726</text><text x=\"305.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">banco de avisos do GitHub</text><rect x=\"210\" y=\"170\" width=\"190\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"305.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">PYSEC-2026-2151</text><text x=\"305.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">banco de avisos da PyPA</text><path d=\"M170 115 L190 115 L190 55 L208 55\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-phosphor)\"></path><path d=\"M170 135 L190 135 L190 195 L208 195\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-phosphor)\"></path><line x1=\"305\" y1=\"80\" x2=\"305\" y2=\"170\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" stroke-dasharray=\"3 3\"></line><text x=\"312\" y=\"125\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">aliases um do outro</text><rect x=\"440\" y=\"100\" width=\"110\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"495.0\" y=\"117.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">osv.dev</text><text x=\"495.0\" y=\"134.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">reúne os dois</text><path d=\"M400 55 L420 55 L420 115 L438 115\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><path d=\"M400 195 L420 195 L420 135 L438 135\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><rect x=\"575\" y=\"30\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"47.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pypi.org</text><text x=\"640.0\" y=\"64.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dois registros</text><path d=\"M550 115 L565 115 L565 55 L573 55\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-paper-dim)\"></path><rect x=\"575\" y=\"170\" width=\"130\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"640.0\" y=\"187.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">pip-audit</text><text x=\"640.0\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">duas linhas, uma falha</text><path d=\"M640 80 L640 168\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-names-ah-amber)\"></path></svg>", "caption": "Conte ids CVE, não linhas: a mesma falha chega duas vezes à auditoria."}
```

### O que a tabela não diz

A tabela tem um pacote, uma versão, um id e uma versão corrigida. Não tem gravidade, nem descrição,
nem uma palavra sobre se o linkbox faz algo de que a falha precisa. Quinze linhas que parecem iguais
não são quinze problemas do mesmo tamanho, e tratá-las assim é como um time ou entra em pânico ou
para de ler. A próxima seção lê um aviso inteiro e depois os outros catorze, contra o que o linkbox
realmente faz.

Dois hábitos saem daqui. **Cite o CVE** quando falar de um achado, porque é o id que toda outra
ferramenta e todo outro time vão reconhecer. E **conte falhas, não linhas**, antes de um número ir
para um relatório: a aula 20 mede os achados do pipeline, e uma contagem que dobra porque um banco
publicou duas vezes é uma medida do banco.
