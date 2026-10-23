---
title: Análise estática no pipeline, e o primeiro build quebrado
version: 1
---

Rodado à mão, um scanner é uma opinião. **No pipeline ele é uma regra**: todo push é lido do mesmo
jeito, um achado para a mudança antes de ela chegar à `main`, e ninguém precisa lembrar de rodar nada.
O estágio é um script como os outros, com uma decisão dentro que importa mais que o resto: quais
achados quebram o build.

### O estágio

Salve como `ci/sast.sh`:

```sh
# Static analysis: Semgrep with this project's own rules, then Bandit with
# its built-in ones. A finding of medium severity or worse breaks the build.
set -euo pipefail
semgrep scan --metrics=off --quiet --error --emacs --config .semgrep.yml .
bandit -q -r . -c bandit.yaml --severity-level medium
```

Cada flag está ali por um motivo:

| flag | o que faz |
|---|---|
| `--metrics=off` | o Semgrep não envia dados de uso para lugar nenhum; um job de CI não deve chamar um fornecedor de que não precisava |
| `--quiet` | só os achados, sem o progresso e o resumo |
| `--emacs` | uma linha por achado: arquivo, linha, coluna, regra e mensagem, que se lê bem num log e é fácil de filtrar com `grep` |
| `--error` | sai com 1 quando há um achado; sem ela o Semgrep aponta e sai com 0, e o estágio passa |
| `--config .semgrep.yml` | as regras do próprio projeto e nenhuma outra, para o resultado não mudar quando um registro muda |
| `-c bandit.yaml` | o ajuste das seções anteriores: sem `.venv`, sem B101 nos testes |
| `--severity-level medium` | aponta, e falha, só com média e alta |

**`--error` é a flag que as pessoas esquecem**, e esquecê-la é silencioso: o log se enche de achados,
o estágio imprime "passed", e o pipeline parece ter conferido alguma coisa. O Bandit não tem essa
armadilha, porque sai com 1 sempre que aponta um achado.

### Onde quebrar, e onde só apontar

A última flag é uma decisão. Os três achados do Bandit no serviço, posicionados pelas duas notas:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"sp-l03-gate\" aria-label=\"As duas notas do Bandit numa grade, a severidade de baixa a alta subindo e a confiança de baixa a alta para a direita. As linhas de severidade média e alta são as que o ci/sast.sh aponta e pelas quais quebra o build; abaixo delas ele não aponta nada. O B201, o depurador do Flask, fica em severidade alta e confiança média; o B608, a busca, em média e média; o B105, o token em settings.py, em baixa e média, abaixo da linha; o B101, o assert de teste, em severidade baixa e confiança alta, e é ignorado nos testes pelo bandit.yaml.\"><defs></defs><rect x=\"140\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"30\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"65.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alta</text><rect x=\"140\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"100\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"135.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">média</text><rect x=\"140\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"265\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"390\" y=\"170\" width=\"125\" height=\"70\" rx=\"0\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"128\" y=\"205.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">baixa</text><text x=\"202.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">baixa</text><text x=\"327.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">média</text><text x=\"452.5\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">alta</text><text x=\"327.5\" y=\"276\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">confiança</text><text x=\"40\" y=\"135.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">severidade</text><line x1=\"140\" y1=\"170\" x2=\"535\" y2=\"170\" stroke=\"var(--amber)\" stroke-width=\"2\"></line><text x=\"543\" y=\"90\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">quebra o build</text><text x=\"543\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">abaixo: não aparece</text><rect x=\"270.5\" y=\"41.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B201</text><text x=\"327.5\" y=\"74.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o depurador</text><rect x=\"270.5\" y=\"111.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"127.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B608</text><text x=\"327.5\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a busca</text><rect x=\"270.5\" y=\"181.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"327.5\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B105</text><text x=\"327.5\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o token</text><rect x=\"395.5\" y=\"181.0\" width=\"114\" height=\"48\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"452.5\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">B101</text><text x=\"452.5\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">testes: ignorado</text></svg>", "caption": "O portão lê um eixo só. O que fica abaixo da linha não é falso; está esperando outro tipo de correção."}
```

Com `--severity-level medium`, a injeção e o depurador quebram o build, e o token em `settings.py`
nem aparece. Não é porque o B105 seja falso: é um verdadeiro positivo, e a aula 6 é sobre ele. É
porque a correção de um segredo commitado não é uma mudança de código, então **um portão que quebrasse
todo build por causa dele pararia todo push até o trabalho da aula 6 estar feito**, por um problema
que quem faz o push não consegue resolver na própria mudança. A aula 7 transforma isso numa regra
geral sobre para que serve um portão, e acrescenta a este pipeline o meio-termo, um alerta que é
contado.

A confiança é o outro eixo, e este estágio não a usa. O Bandit também filtra por ela, com
`--confidence-level`, e um time afogado em achados de baixa confiança às vezes faz isso. É trocar
ruído por falsos negativos, a mesma troca da seção anterior, e só vale a pena com os achados na sua
frente.

### Na lista

O estágio vai depois dos testes e antes do build. Os testes primeiro, porque uma mudança que os quebra
tem um problema que vem antes da segurança dela; o build por último, porque nada deve ser construído a
partir de código que uma checagem recusou. Salve a lista como `ci/stages`:

```
test
sast
build
```

### O primeiro build quebrado

Faça commit do que esta aula acrescentou até aqui, os dois arquivos de configuração e o estágio, e faça
push. O código em si ainda é o que a aula 1 entregou:

```
ana@vm:~/linkbox$ git add .semgrep.yml bandit.yaml ci
ana@vm:~/linkbox$ git commit -q -m "static analysis in the pipeline"
ana@vm:~/linkbox$ git push ci main
remote: run 1: main at f4992c6        
remote: test: passed in 1s        
remote: sast: FAILED in 3s, the end of sast.log:        
remote:   app.py:32:1:error(writes-need-the-token):@app.post("/links"):A POST route that never calls require_token() lets anybody write.        
remote:   app.py:46:12:error(sql-built-from-a-string):    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall():SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as a parameter.        
remote: run 1: failed, the logs are in ~/ci/runs/1/logs        
To /home/ana/ci/linkbox.git
   ed9bbb4..f4992c6  main -> main
```

**É o build quebrando como foi projetado para quebrar.** Os testes passaram, o estágio de análise
estática achou duas coisas, e a execução parou antes de construir uma imagem de um código que ela
recusou. O fim do log do estágio vem no próprio push: os dois achados do Semgrep, uma linha cada. Com
`set -e` o script parou ali, antes de o Bandit rodar. O log inteiro fica no servidor, e aqui ele não
é maior que isso:

```
ana@vm:~/linkbox$ cat ~/ci/runs/1/logs/sast.log
app.py:32:1:error(writes-need-the-token):@app.post("/links"):A POST route that never calls require_token() lets anybody write.
app.py:46:12:error(sql-built-from-a-string):    rows = db().execute(f"SELECT code, url FROM links WHERE url LIKE '%{q}%'").fetchall():SQL text built from a string reaches execute(). Write a ? where the value goes and pass the value as a parameter.
```

Os dois achados do Semgrep estão ali, a regra do token e a do SQL. O Bandit não rodou neste build,
então o B201 dele não está no log. É uma propriedade do script que vale conhecer: **um estágio que
para na primeira ferramenta só mostra os achados dela**, e os da ferramenta seguinte só aparecem
depois que os da primeira forem corrigidos. A alternativa, rodar as duas e falhar no fim, mostra tudo
de uma vez e custa algumas linhas a mais; as duas são defensáveis, desde que o time saiba qual tem.

Um build vermelho na `main` não é onde isso aconteceria num time com pull requests: a branch ficaria
vermelha, e o merge seria bloqueado. O linkbox tem um desenvolvedor e uma branch, então a `main` fica
vermelha por enquanto, e a próxima seção a deixa verde.
