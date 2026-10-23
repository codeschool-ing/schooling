---
title: Verdadeiro, falso, e o assert num teste
version: 1
---

Todo achado é uma afirmação, e uma afirmação pode estar certa ou errada. Um silêncio também. Quatro
termos cobrem os casos, e um time que os usa com precisão discute as coisas certas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" data-fig=\"sp-l03-matrix\" aria-label=\"Os quatro desfechos de uma checagem, numa tabela dois por dois. Colunas: há um defeito real, ou não há. Linhas: a ferramenta aponta algo, ou fica calada. Um verdadeiro positivo é um apontamento sobre um defeito real, como o B608 na busca do linkbox. Um falso positivo é um apontamento sobre algo que não é defeito, como o B101 num assert de teste. Um falso negativo é um defeito real sobre o qual a ferramenta se cala, como create() comparando o token com uma comparação comum de strings. Um verdadeiro negativo é um silêncio correto, como follow(), cuja consulta já recebe um parâmetro.\"><defs></defs><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">um defeito real</text><text x=\"570\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">nenhum defeito</text><text x=\"100\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a ferramenta aponta</text><text x=\"100\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">a ferramenta se cala</text><rect x=\"215\" y=\"40\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"330.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verdadeiro positivo</text><text x=\"330.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">B608 na busca</text><rect x=\"460\" y=\"40\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">falso positivo</text><text x=\"575.0\" y=\"91.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">B101 num assert de teste</text><rect x=\"215\" y=\"140\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"330.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">falso negativo</text><text x=\"330.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o token comparado com !=</text><rect x=\"460\" y=\"140\" width=\"230\" height=\"84\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"575.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">verdadeiro negativo</text><text x=\"575.0\" y=\"191.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">follow() com um ?</text></svg>", "caption": "Ajustar move achados entre as caixas que você enxerga e a que você não enxerga. Uma regra desligada não tem falso positivo e tem todos os falsos negativos dela."}
```

- Um **verdadeiro positivo** é um achado sobre um defeito real: o B608 na busca.
- Um **falso positivo** é um achado sobre algo que não é defeito: os próximos parágrafos.
- Um **falso negativo** é um defeito que a ferramenta não apontou. É o caro, porque nada aponta para
  ele, e toda ferramenta tem os seus: o Bandit não sabe que o `create()` do linkbox compara o token
  com `!=`, que é o assunto da seção 05 desta aula.
- Um **verdadeiro negativo** é um silêncio correto: `follow()` monta a consulta com um `?`, e o Bandit
  não diz nada sobre ela.

**Ajustar troca um tipo de erro pelo outro.** Uma regra desligada não produz falso positivo, e deixa
passar todo defeito que ela pegaria. O trabalho é tirar os falsos positivos sem pagar por isso na
caixa que você não enxerga.

### B101, o falso positivo clássico

Seis dos nove achados do Bandit são o mesmo, `B101` em cada `assert` de `tests/test_app.py`. A
checagem está certa sobre o Python. Rodando com `-O`, o interpretador descarta todo comando `assert`,
então um código que depende de um para uma decisão de segurança, como `assert user.is_admin`, deixa de
conferir qualquer coisa num deploy otimizado. **Em código de aplicação, o B101 é um verdadeiro
positivo que vale a pena ter.** Num teste ele está errado: o pytest é construído em cima do `assert`,
ninguém roda testes com `-O`, e um assert num teste é o próprio teste.

Há três jeitos de fazê-lo parar, e só um está certo:

| a jogada | o que custa |
|---|---|
| ignorar o B101 em todo lugar, `skips: [B101]` | a checagem some também do `app.py`, onde importa: um falso negativo esperando o primeiro `assert` numa rota |
| um `# nosec` em cada uma das seis linhas | seis comentários nos testes, e mais um em cada assert que alguém escrever daqui em diante |
| **ignorar o B101 nos testes, e só ali** | nada: a regra continua vigiando o código para o qual foi escrita |

O arquivo de configuração do Bandit faz a terceira. Salve como `bandit.yaml`:

```yaml
# Bandit's settings for linkbox.
exclude_dirs:
  - .venv
# B101 flags every assert, because Python drops them under -O. In a test an
# assert is the whole point, so it is skipped there and nowhere else.
assert_used:
  skips:
    - "*/tests/*.py"
```

`exclude_dirs` torna permanente o escopo da seção anterior, para ninguém precisar lembrar do `-x`, e
`assert_used` é a configuração do próprio B101: os arquivos em que ele não se aplica. Rode com o
arquivo:

```
ana@vm:~/linkbox$ bandit -q -r . -c bandit.yaml --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
app.py:46 B608 MEDIUM/MEDIUM Possible SQL injection vector through string-based query construction.
app.py:59 B201 HIGH/MEDIUM A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
```

Três achados, os três que são sobre o serviço. **Cada linha do `bandit.yaml` diz por que está ali**,
porque um ajuste que ninguém consegue explicar é removido pela próxima pessoa para quem ele atrapalha,
ou mantido para sempre pela próxima que tem medo de mexer.

### Uma supressão numa linha, com o motivo

Às vezes o achado está errado sobre uma linha e certo sobre todas as outras. Uma consulta cujo nome de
tabela precisa ser inserido no SQL é o caso comum, porque um `?` pode representar um valor e nunca uma
tabela. Aqui está uma, num diretório de rascunho, fora do projeto:

```
ana@vm:~/linkbox$ mkdir -p /tmp/scratch && cd /tmp/scratch
ana@vm:/tmp/scratch$ cat counts.py
import sqlite3

TABLES = ("links",)


def counts(db):
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}
ana@vm:/tmp/scratch$ bandit -q counts.py
Run started:2026-10-23 12:27:17.278153+00:00

Test results:
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Medium
   CWE: CWE-89 (https://cwe.mitre.org/data/definitions/89.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b608_hardcoded_sql_expressions.html
   Location: ./counts.py:7:28
6	def counts(db):
7	    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}

--------------------------------------------------

Code scanned:
	Total lines of code: 4
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0

Run metrics:
	Total issues (by severity):
		Undefined: 0
		Low: 0
		Medium: 1
		High: 0
	Total issues (by confidence):
		Undefined: 0
		Low: 0
		Medium: 1
		High: 0
Files skipped (0):
```

O B608 está errado aqui: `t` só pode ser um nome de `TABLES`, uma constante no mesmo arquivo. A
resposta é uma supressão naquela linha, nomeando a checagem e dizendo por quê. A primeira tentativa
põe o motivo no mesmo comentário:

```
ana@vm:/tmp/scratch$ tail -n 1 counts.py
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608: t is one of TABLES
ana@vm:/tmp/scratch$ bandit -q counts.py; echo "exit $?"
[manager]	WARNING	Test in comment: t is not a test name or id, ignoring
[manager]	WARNING	Test in comment: is is not a test name or id, ignoring
[manager]	WARNING	Test in comment: one is not a test name or id, ignoring
[manager]	WARNING	Test in comment: of is not a test name or id, ignoring
[manager]	WARNING	Test in comment: TABLES is not a test name or id, ignoring
exit 0
```

O Bandit leu cada palavra depois de `nosec` como o id de uma checagem a ignorar, e avisou sobre cada
uma. O achado foi suprimido, e **o motivo virou ruído**. O Bandit quer só os ids depois de `nosec`,
então o motivo vai na linha de cima:

```
ana@vm:/tmp/scratch$ tail -n 2 counts.py
    # A table name cannot be a ? parameter, and t only ever comes from TABLES.
    return {t: db.execute(f"SELECT count(*) FROM {t}").fetchone()[0] for t in TABLES}  # nosec B608
ana@vm:/tmp/scratch$ bandit counts.py 2>/dev/null | grep -i 'issues identified\|skipped'
	No issues identified.
	Total lines skipped (#nosec): 0
	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 1
Files skipped (0):
ana@vm:/tmp/scratch$ cd ~/linkbox && rm -rf /tmp/scratch
```

"No issues identified", e o resumo ainda conta **um problema ignorado de propósito**, então um revisor
ou um script consegue achar cada supressão no código.

### Por que uma supressão nua é mau sinal

Um `# nosec` sem id desliga toda checagem naquela linha, inclusive as escritas no ano que vem. Uma
supressão sem motivo não pode ser revisada: ninguém distingue uma decisão pensada de um desenvolvedor
que queria que um build vermelho ficasse verde. Três regras mantêm as supressões honestas:

- **nomeie a checagem**, `# nosec B608`, nunca um `# nosec` nu; a forma do Semgrep é
  `# nosemgrep: rule-id`;
- **diga por quê, com palavras que um revisor consiga conferir**, ao lado;
- **conte-as**. O resumo do Bandit já conta; uma supressão acrescentada num pull request é uma linha
  sobre a qual o revisor deve ser perguntado, como uma mudança nos testes.
