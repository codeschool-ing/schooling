---
title: Regras escritas para este projeto
version: 1
---

As checagens do Bandit foram escritas para todo programa Python, então não sabem nada sobre este.
Elas não têm como saber que o linkbox tem um token de administração, que toda rota que grava precisa
conferi-lo, nem como o time decidiu fazer isso. **As regras que pegam os erros próprios de um projeto
precisam ser escritas pelo projeto**, e muitas vezes são as mais valiosas que ele tem, porque guardam
uma decisão que ninguém mais poderia ter tomado por ele.

O Semgrep é uma ferramenta exatamente para isso. Uma regra é um pedaço de código com buracos:
`$DB.execute(...)` casa com qualquer chamada a `execute` em qualquer coisa, e o buraco `$DB` aceita o
que estiver ali. As regras são YAML, moram no repositório ao lado do código e são revisadas como ele.

### Instale

O Semgrep traz dezenas de pacotes junto, então o `tail` guarda só as três últimas linhas da
instalação:

```
ana@vm:~/linkbox$ uv tool install semgrep==1.182.1 2>&1 | tail -n 3
 + wrapt==1.17.3
 + zipp==4.1.2
Installed 2 executables: pysemgrep, semgrep
ana@vm:~/linkbox$ semgrep --version
1.182.1
```

A ferramenta de linha de comando do Semgrep e o motor de padrões dele são código aberto. A empresa por
trás dele também mantém um registro de regras e uma plataforma paga; este curso não usa nenhum dos
dois, e toda regra que ele roda está escrita abaixo.

### Duas regras

Salve como `.semgrep.yml`:

```yaml
rules:
  - id: sql-built-from-a-string
    languages: [python]
    severity: ERROR
    message: >-
      SQL text built from a string reaches execute(). Write a ? where the
      value goes and pass the value as a parameter.
    pattern-either:
      - pattern: $DB.execute(f"...", ...)
      - pattern: $DB.execute("..." + $X, ...)
      - pattern: $DB.execute("...".format(...), ...)
      - pattern: $DB.execute("..." % $X, ...)
  - id: writes-need-the-token
    languages: [python]
    severity: ERROR
    message: >-
      A POST route that never calls require_token() lets anybody write.
    patterns:
      - pattern: |
          @app.post(...)
          def $ROUTE(...):
              ...
      - pattern-not: |
          @app.post(...)
          def $ROUTE(...):
              ...
              require_token()
              ...
```

**A primeira regra é o B608 do Bandit, dito com as palavras do projeto.** Ela casa com uma chamada a
`execute` cujo primeiro argumento é uma string montada de qualquer uma das quatro maneiras do Python:
uma f-string, `+`, `.format()` ou `%`. Uma chamada com uma string simples e uma tupla de parâmetros,
como a de `follow()`, não casa com nenhuma delas. A mensagem diz o que escrever no lugar, o que uma
ferramenta genérica não consegue dizer com tanta precisão, porque não sabe que o banco deste projeto é
SQLite com marcadores `?`.

**A segunda regra é uma decisão por escrito.** Ela casa com toda função decorada com `@app.post`, e
depois tira dos resultados toda aquela cujo corpo chama `require_token()` em algum ponto. O que sobra
é uma rota que grava e nunca chama a função que confere o token. A função ainda não existe; a regra é
escrita primeiro, do jeito que um teste é.

### O que ela acha

```
ana@vm:~/linkbox$ semgrep scan --metrics=off --quiet --emacs --config .semgrep.yml .
app.py:32:1:error(writes-need-the-token):@app.post("/links"):A POST route that never calls require_token() lets anybody write.
app.py:46:12:error(sql-built-from-a-string):    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall():SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as a parameter.
```

Dois achados, um por regra, cada um numa linha: arquivo, linha, coluna, a regra e a mensagem. O
`--emacs` pede esse formato, que cabe num log e que o `grep` consegue pesquisar. Leia o primeiro com
atenção, porque é o mais interessante: `create()`, na linha 32, **confere o token, sim.** As duas primeiras linhas dela comparam o cabeçalho com `ADMIN_TOKEN` e
respondem 401 quando diferem, e o teste da aula 1 prova isso. Então é um falso positivo?

É um verdadeiro positivo **da regra**, que disse algo mais estreito que "esta rota está aberta". Ela
disse que esta rota não chama `require_token()`, e isso é exatamente verdade. A pergunta que o achado
levanta é se a regra tem razão em exigir a chamada, e há dois motivos para ter.

- **Uma checagem embutida é copiada, e uma cópia pode estar errada.** A próxima rota que gravar vai
  ser escrita copiando `create()`. A cópia que esquecer as duas linhas, ou errar o nome do cabeçalho,
  passa em todo teste que não foi escrito para ela. Uma função chamada por toda rota que grava tem um
  lugar só para estar certa, e a regra torna visível quem a esquece.
- **`!=` é a comparação errada para um segredo.** Uma comparação de strings para no primeiro caractere
  diferente, então leva um pouco mais de tempo quanto mais do começo de um palpite estiver certo. Com
  tentativas suficientes e uma rede quieta o bastante, essa diferença é mensurável, e vaza o token um
  caractere de cada vez. `secrets.compare_digest()` leva o mesmo tempo seja qual for a entrada, e é
  por isso que a documentação do Python a recomenda exatamente para isso.

Nenhuma das duas coisas o Bandit poderia saber. **Essa é a lacuna que as regras do próprio projeto
preenchem**: o Bandit achou a injeção pelo formato, e só uma regra que conhece o design do linkbox
acharia uma rota que pula a checagem do próprio projeto.

### Quando uma regra está errada sobre uma linha

A supressão do Semgrep é um comentário na linha que ela casa, nomeando a regra. A consulta com nome de
tabela da seção anterior a levaria assim, com o motivo em cima:

```python
# A table name cannot be a ? parameter, and t only ever comes from TABLES.
count = db().execute(f"SELECT count(*) FROM {t}").fetchone()[0]  # nosemgrep: sql-built-from-a-string
```

As regras da seção anterior valem palavra por palavra: o id da regra, nunca um `nosemgrep` nu, e o
motivo ao lado. **Uma regra que o time escreveu e depois suprime com frequência é uma regra para
reescrever**: ou o padrão dela é largo demais, ou a decisão que ela guarda mudou e ninguém a
atualizou.
