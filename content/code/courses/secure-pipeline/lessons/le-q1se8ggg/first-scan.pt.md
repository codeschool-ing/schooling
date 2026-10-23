---
title: A primeira execução do Bandit, e como ler um achado
version: 1
---

O Bandit é o analisador estático da Python Code Quality Authority, o grupo que também mantém o
`flake8`. Ele transforma cada arquivo na árvore sintática do Python e roda sobre ela um conjunto de
checagens, cada uma com um id como `B608`. **Ele conhece Python e nada sobre o seu projeto**, o que é
a força dele no primeiro dia e o limite dele depois.

### Instale

Como toda ferramenta deste curso, ele é instalado numa versão exata, para que uma execução no mês que
vem leia as mesmas regras que esta. O `uv tool install` o põe num ambiente só dele, fora do caminho
do projeto, com o comando em `~/.local/bin`:

```
ana@vm:~/linkbox$ uv tool install bandit==1.9.4
Resolved 7 packages in 642ms
Installed 7 packages in 291ms
 + bandit==1.9.4
 + markdown-it-py==4.2.0
 + mdurl==0.1.2
 + pygments==2.21.0
 + pyyaml==6.0.3
 + rich==15.0.0
 + stevedore==5.9.1
Installed 3 executables: bandit, bandit-baseline, bandit-config-generator
ana@vm:~/linkbox$ bandit --version
bandit 1.9.4
  python version = 3.13.16 (main, Oct  1 2026, 15:40:24) [GCC 13.3.0]
```

### A primeira execução lê demais

Aponte para o projeto e conte o que ele diz:

```
ana@vm:~/linkbox$ bandit -q -r . --format custom --msg-template "{relpath}" | wc -l
436
ana@vm:~/linkbox$ bandit -q -r . --format custom --msg-template "{relpath}" | cut -d/ -f1-2 | sort | uniq -c | sort -rn
    427 .venv/lib
      6 tests/test_app.py
      2 app.py
      1 settings.py
```

**Quatrocentos e trinta e seis achados, num serviço de 69 linhas.** O segundo comando diz onde estão:
427 deles ficam dentro de `.venv`, o ambiente virtual que a aula 1 criou. Flask, Werkzeug, pytest e o
resto foram lidos como se você os tivesse escrito. O Bandit recebeu a ordem de ler tudo debaixo de
`.`, e leu.

Essa é a primeira execução mais comum de qualquer scanner, e a mais danosa. Um desenvolvedor que vê
quatrocentos achados para uma mudança de três linhas conclui que a ferramenta é ruído, e essa
conclusão dura mais que a configuração que a causou. **A primeira coisa a ajustar é o escopo: o que a
ferramenta lê.** Código de terceiros tem o próprio scanner, a auditoria de dependências da aula 5, que
lê avisos de segurança publicados em vez de adivinhar pelo código.

Leia só o projeto:

```
ana@vm:~/linkbox$ bandit -q -r . -x ./.venv --format custom --msg-template "{relpath}:{line} {test_id} {severity}/{confidence} {msg}"
app.py:46 B608 MEDIUM/MEDIUM Possible SQL injection vector through string-based query construction.
app.py:59 B201 HIGH/MEDIUM A Flask app appears to be run with debug=True, which exposes the Werkzeug debugger and allows the execution of arbitrary code.
settings.py:4 B105 LOW/MEDIUM Possible hardcoded password: 'lbx_7Rq2mK9vT4wZ8nP3sL6yH1cJ5dF0gB2x'
tests/test_app.py:14 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:20 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:23 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:24 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:31 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
tests/test_app.py:32 B101 LOW/HIGH Use of assert detected. The enclosed code will be removed when compiling to optimised byte code.
```

Nove, em três arquivos, com quatro ids diferentes. O template pôs cada um numa linha: o arquivo e a
linha, o id da checagem, a severidade e a confiança, e a mensagem.

### Um achado, inteiro

A saída padrão diz mais sobre cada achado. Peça o da busca:

```
ana@vm:~/linkbox$ bandit -q -r . -x ./.venv -t B608
Run started:2026-10-23 12:27:16.778693+00:00

Test results:
>> Issue: [B608:hardcoded_sql_expressions] Possible SQL injection vector through string-based query construction.
   Severity: Medium   Confidence: Medium
   CWE: CWE-89 (https://cwe.mitre.org/data/definitions/89.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b608_hardcoded_sql_expressions.html
   Location: ./app.py:46:26
45	    q = request.args.get("q", "")
46	    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall()
47	    return render_template_string(PAGE, q=q, rows=rows)

--------------------------------------------------

Code scanned:
	Total lines of code: 69
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

Cada campo está ali por um motivo:

| campo | o que ele diz |
|---|---|
| `B608:hardcoded_sql_expressions` | a checagem que disparou; o nome é a página da documentação |
| Severity: Medium | quão grave seria se for real, na escala do próprio Bandit de baixa, média e alta |
| Confidence: Medium | quão segura a checagem está de que este é um caso real do que ela procura |
| CWE-89 | a classe de fraqueza na Common Weakness Enumeration da MITRE, aqui injeção de SQL |
| Location: `./app.py:46:26` | arquivo, linha e coluna, com as linhas em volta |

**Severidade e confiança são duas perguntas diferentes.** A severidade é sobre a consequência; a
confiança é sobre a evidência. Uma checagem pode ter certeza de algo inofensivo, como um comando
`assert`, que é severidade baixa e confiança alta, ou ter dúvida sobre algo sério, que é este caso: o
Bandit não consegue ver o que `q` contém, então diz média. A seção depois da próxima usa as duas
separadas, porque um pipeline que quebra por uma e ignora a outra está fazendo uma escolha.

### Os três que não são sobre testes

Seis dos nove são `B101` em `tests/test_app.py`, e a próxima seção trata deles. Os outros três estão
no próprio serviço:

| id | onde | severidade | o que diz |
|---|---|---|---|
| B608 | `app.py:46`, a busca | média | uma consulta montada formatando uma string |
| B201 | `app.py:59`, a última linha | **alta** | o Flask rodando com `debug=True`, que expõe o depurador do Werkzeug |
| B105 | `settings.py:4` | baixa | uma string com cara de senha, atribuída a um nome com cara de senha |

Os três são reais. **A busca é a injeção de SQL da aula 1**, a que a seção anterior desenhou. O
depurador é um jeito de rodar código no servidor a partir de um navegador, se aquela linha um dia
rodar onde outra pessoa consiga alcançá-la. E o token em `settings.py` é o próprio token de
administração, commitado no repositório. Esta aula corrige os dois primeiros, com um teste para cada.
O terceiro é outro tipo de problema, porque o token já está no histórico e mudar o código não o tira
de lá, e ele é da aula 6.
