---
title: Uma segunda opinião do Trivy, e por que duas ferramentas discordam
version: 1
---

Dois analisadores de composição apontados para o mesmo projeto raramente imprimem a mesma coisa, e a
primeira reação é decidir qual está errado. **Em geral nenhum está: eles coletaram listas diferentes
de pacotes, ou consultaram bancos diferentes, ou contaram de outro jeito.** Saber qual dos três
explica uma diferença é o que torna uma segunda ferramenta útil, e não confusa.

O Trivy é a segunda ferramenta aqui. É um scanner geral que a aula 8 aponta para imagens e a aula 11
compara com outros; o `trivy fs` varre um diretório. A seção anterior já o rodou no
`requirements.txt` da aula 1 e guardou o JSON. Os achados dele, um por linha:

```
ana@vm:~/linkbox$ jq -r ".Results[].Vulnerabilities[] | [.PkgName, .InstalledVersion, .VulnerabilityID, .Severity, .FixedVersion] | @tsv" /tmp/trivy.json
flask	3.0.0	CVE-2026-27205	LOW	3.1.3
gunicorn	21.2.0	CVE-2024-1135	HIGH	22.0.0
gunicorn	21.2.0	CVE-2024-6827	HIGH	22.0.0
jinja2	3.1.2	CVE-2024-22195	MEDIUM	3.1.3
jinja2	3.1.2	CVE-2024-34064	MEDIUM	3.1.4
jinja2	3.1.2	CVE-2024-56201	MEDIUM	3.1.5
jinja2	3.1.2	CVE-2024-56326	MEDIUM	3.1.5
jinja2	3.1.2	CVE-2025-27516	MEDIUM	3.1.6
werkzeug	3.0.1	CVE-2024-34069	HIGH	3.0.3
werkzeug	3.0.1	CVE-2024-49766	MEDIUM	3.0.6
werkzeug	3.0.1	CVE-2024-49767	MEDIUM	3.0.6
werkzeug	3.0.1	CVE-2025-66221	MEDIUM	3.1.4
werkzeug	3.0.1	CVE-2026-102598	MEDIUM	3.1.9
werkzeug	3.0.1	CVE-2026-21860	MEDIUM	3.1.5
werkzeug	3.0.1	CVE-2026-27199	MEDIUM	3.1.6
ana@vm:~/linkbox$ trivy fs -q --scanners vuln requirements-dev.txt

Report Summary

┌────────┬──────┬─────────────────┐
│ Target │ Type │ Vulnerabilities │
├────────┼──────┼─────────────────┤
│   -    │  -   │        -        │
└────────┴──────┴─────────────────┘
Legend:
- '-': Not scanned
- '0': Clean (no security findings detected)
```

**Quinze achados, os mesmos quinze CVEs a que as vinte e nove linhas do pip-audit se reduziram**,
cada um com uma gravidade que o pip-audit não imprime. Na pergunta que as duas ferramentas
receberam, elas concordam. O segundo comando é onde deixam de concordar: o Trivy nem varreu o
`requirements-dev.txt`. O resumo dele diz `-`, não varrido, que é diferente de `0`, limpo.

### De onde vêm as listas

As duas ferramentas discordam sobre o pytest porque coletam pacotes de jeitos diferentes, e um
arquivo de uma linha só mostra a diferença com mais clareza:

```
ana@vm:~/linkbox$ mkdir -p /tmp/one && echo "flask==3.0.0" > /tmp/one/requirements.txt
ana@vm:~/linkbox$ pip-audit -r /tmp/one/requirements.txt -f json 2>/dev/null | jq -r ".dependencies[] | \"\(.name) \(.version)\""
flask 3.0.0
blinker 1.9.0
click 8.5.0
itsdangerous 2.2.0
jinja2 3.1.6
markupsafe 3.0.4
werkzeug 3.1.9
ana@vm:~/linkbox$ trivy fs -q --scanners vuln --list-all-pkgs -f json /tmp/one | jq -r ".Results[].Packages[] | \"\(.Name) \(.Version)\""
flask 3.0.0
```

O pip-audit **resolveu** o arquivo: perguntou ao pip o que instalar `flask==3.0.0` instalaria hoje e
auditou os sete pacotes, cada transitivo na versão mais nova que o Flask 3.0.0 aceita. O Trivy **leu**
o arquivo: uma linha, um pacote. Nenhum está errado, e eles respondem a duas perguntas.

- **O Trivy audita o que o arquivo diz.** É rápido, não precisa de rede para resolver nada e relata só
  o que está escrito. Ele reconhece arquivos pelo nome, e é por isso que o `requirements.txt` é lido
  e o `requirements-dev.txt` não, e não enxerga um pacote transitivo que o arquivo não fixa.
- **O pip-audit audita o que seria instalado.** Ele vê todo pacote transitivo, mas na versão que o
  índice oferece hoje, então o mesmo arquivo pode passar limpo na segunda e sujo na quinta, ou o
  contrário, sem commit nenhum no meio.

Os requisitos do linkbox fixam à mão os pacotes transitivos, e por isso as duas concordaram sobre o
serviço. Um projeto que fixa só as dependências diretas teria duas respostas bem diferentes, e o
remédio é o lock file compilado da aula 15, em que todo pacote está escrito com a versão e as duas
ferramentas leem a mesma lista.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l05-tools\" aria-label=\"De onde cada ferramenta tira a lista de pacotes e os avisos. O pip-audit recebe os dois arquivos de requisitos com -r, resolve-os com o pip no que seria instalado hoje, transitivos inclusive, e consulta cada pacote no PyPI, que serve os avisos do OSV. O Trivy acha arquivos pelo nome, lê o requirements.txt linha a linha, não varre o requirements-dev.txt e consulta os pacotes no próprio banco baixado.\"><defs><marker id=\"sp-l05-tools-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">pip-audit</text><rect x=\"20\" y=\"36\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">requirements*.txt</text><text x=\"95.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">os dois arquivos, com -r</text><rect x=\"200\" y=\"36\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">resolvidos pelo pip</text><text x=\"285.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que seria instalado hoje</text><rect x=\"400\" y=\"36\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">todo pacote</text><text x=\"470.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">transitivos inclusive</text><rect x=\"570\" y=\"36\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">PyPI</text><text x=\"635.0\" y=\"73.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">serve o OSV</text><path d=\"M170 64 L198 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M370 64 L398 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M540 64 L568 64\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><text x=\"20\" y=\"128\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--phosphor)\">trivy fs</text><rect x=\"20\" y=\"142\" width=\"150\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">requirements.txt</text><text x=\"95.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">achado pelo nome</text><rect x=\"200\" y=\"142\" width=\"170\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"285.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">lido linha a linha</text><text x=\"285.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o que o arquivo diz</text><rect x=\"400\" y=\"142\" width=\"140\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"470.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as linhas fixadas</text><text x=\"470.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mais nada</text><rect x=\"570\" y=\"142\" width=\"130\" height=\"56\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"635.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">banco próprio</text><text x=\"635.0\" y=\"179.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">baixado</text><path d=\"M170 170 L198 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M370 170 L398 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><path d=\"M540 170 L568 170\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#sp-l05-tools-ah-paper-dim)\"></path><rect x=\"20\" y=\"210\" width=\"260\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"150.0\" y=\"225.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requirements-dev.txt: não varrido</text></svg>", "caption": "As duas ferramentas concordaram sobre o serviço do linkbox porque o arquivo fixa todo pacote transitivo; num arquivo que fixa só os diretos, não concordariam.", "same": ["PyPI"]}
```

### De onde vêm os avisos

O pip-audit consultou cada pacote no PyPI, que serve os avisos do OSV. O Trivy os consulta no **banco
próprio dele**, montado a partir dos avisos do GitHub, do NVD, dos feeds das distribuições Linux e de
outros, e baixado para a máquina. Nesta máquina o banco foi baixado uma vez, no dia da gravação, então
todo número do Trivy no curso vem do mesmo banco. Na sua, ele tem no máximo um dia, e as contagens que
você vir não serão estas.

As duas fontes costumam concordar sobre se uma versão é afetada, como aqui, e muitas vezes discordam
de tudo em volta: a gravidade, a versão corrigida quando a correção saiu em dois ramos, o dia em que
um aviso novo aparece. Uma falha publicada hoje de manhã pode estar num banco na hora do almoço e no
outro amanhã.

### Duas contagens para um achado

| | pip-audit | Trivy |
|---|---|---|
| o que coleta | os pacotes que o pip instalaria, resolvidos agora | as linhas dos arquivos que reconhece pelo nome |
| pacotes transitivos fora do arquivo | auditados, nas versões de hoje | não vistos |
| `requirements-dev.txt` | auditado, porque foi passado com `-r` | não varrido |
| avisos vêm de | o PyPI, que serve o OSV | o banco próprio, baixado |
| uma falha publicada duas vezes | duas linhas | uma linha |
| gravidade | não impressa | impressa, de uma fonte escolhida |

### O que fazer com duas ferramentas

Rodar as duas em todo push compra pouco: dois portões, dois conjuntos de exceções e o dobro do ruído
para, na maior parte, a mesma resposta. **Este pipeline usa uma como portão**, o pip-audit, porque ela
audita o que de fato vai ser instalado e lê os dois arquivos. O Trivy ganha o lugar dele onde vê o
que o pip-audit não vê: os pacotes do sistema operacional dentro de uma imagem, que a aula 8 varre.
Vale rodar uma segunda ferramenta de vez em quando sobre a mesma entrada, como esta seção fez, porque
as diferenças são onde um ponto cego aparece: aqui, um arquivo que uma ferramenta nunca abriu.
