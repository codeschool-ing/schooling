---
title: Um segredo, um falso positivo e código que ninguém chama
version: 1
---

Os outros três casos vêm dos outros estágios, e cada um testa uma metade diferente da regra. Um segredo
testa o que "consegue corrigir" quer dizer. Um falso positivo testa se vale a pena manter um alerta.
Código que ninguém chama testa o "agora", e se um achado pode ser descartado na conversa.

### Caso 4: um segredo, passando pelo hook

Alguém escreve a verificação do webhook à mão, afinal, cola o segredo compartilhado num arquivo e faz o
commit com `--no-verify` porque o hook "estava lento hoje". O valor é inventado e não abre nada; a CI
não tem como saber, e nem deveria tentar:

```
ana@vm:~/linkbox$ git switch -q main && git switch -q -c webhook
ana@vm:~/linkbox$ printf "WEBHOOK_SECRET = \"Zr4tq8LmW2xK9vB6nP3sH7yC1dF5gJ0a\"\n" >webhook.py
ana@vm:~/linkbox$ git add webhook.py && git commit -q --no-verify -m "verify incoming webhooks"
ana@vm:~/linkbox$ git push ci webhook
remote: run 5: webhook at 595d2f1        
remote: secrets: FAILED in 1s, the end of secrets.log:        
remote:   Finding:     WEBHOOK_SECRET = "REDACTED"        
remote:   Secret:      REDACTED        
remote:   RuleID:      generic-api-key        
remote:   Entropy:     5.000000        
remote:   File:        webhook.py        
remote:   Line:        1        
remote:   Commit:      595d2f1dfdf2e74bcc9bbcc5fcbd8b08829ed087        
remote:   Author:      Ana Lima        
remote:   Email:       ana@example.org        
remote:   Date:        2026-10-23T12:53:39Z        
remote:   Fingerprint: 595d2f1dfdf2e74bcc9bbcc5fcbd8b08829ed087:webhook.py:generic-api-key:1        
remote:           
remote:   9:53AM INF 11 commits scanned.        
remote:   9:53AM INF scanned ~15320 bytes (15.32 KB) in 222ms        
remote:   9:53AM WRN leaks found: 1        
remote: run 5: failed, the logs are in ~/ci/runs/5/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      webhook -> webhook
```

**Decisão: quebrar, sem nível de alerta e sem arquivo de exceções.** O caso cumpre a regra com folga:
quem fez o push pode agir na hora, revogando o segredo, e ninguém mais pode. As únicas entradas que o
`.gitleaksignore` aceita são segredos já revogados, o que é uma afirmação sobre o passado, não uma
permissão. E a execução parou no primeiro estágio, então nenhuma imagem e nenhum estágio seguinte
copiou o valor para lugar nenhum.

A resposta é a da aula 6, na ordem da aula 6: revogar, substituir, remover, e depois decidir sobre o
histórico. Apagar o branch no servidor é arrumação, não correção:

```
ana@vm:~/linkbox$ git push -q ci --delete webhook
ana@vm:~/linkbox$ git switch -q main && git branch -q -D webhook
```

O branch sumiu, e o commit continua no armazenamento de objetos do servidor até o Git recolher
os objetos inalcançáveis, além de no clone da execução em `~/ci/runs`. É o argumento das cópias da aula
6 de novo, e o motivo de a revogação vir primeiro.

### Caso 5: um alerta que é falso positivo

A aula 4 viu que a regra 10031 do ZAP, *User Controllable HTML Element Attribute*, dispara na página de
busca, e que a resposta prova que é falso: o Jinja escapa o valor refletido. Ela não está listada em
`ci/zap-rules.conf`, então alerta. A aula 2 roda as checagens noturnas à mão do jeito que o agendador
rodaria, num clone limpo de `main`:

```
ana@vm:~/linkbox$ rm -rf /tmp/nightly && git clone -q ~/ci/linkbox.git /tmp/nightly
ana@vm:~/linkbox$ /tmp/nightly/ci/pipeline.sh && /tmp/nightly/ci/pipeline.sh ci/nightly
secrets: passed in 1s
test: passed in 2s
sast: passed in 3s
sca: passed in 9s
build: passed in 1s
pipeline passed with 0 warning(s)
rebuild: passed in 13s
dast: WARNING in 21s, the end of dast.log:
  PASS: Sub Resource Integrity Attribute Missing [90003]
  PASS: Charset Mismatch [90011]
  PASS: Application Error Disclosure [90022]
  PASS: WSDL File Detection [90030]
  PASS: Loosely Scoped Cookie [90033]
  WARN-NEW: User Controllable HTML Element Attribute (Potential XSS) [10031] x 1 
  	http://linkbox-staging-3656-app:8000/search?q=ZAP (200 OK)
  FAIL-NEW: 0	FAIL-INPROG: 0	WARN-NEW: 1	WARN-INPROG: 0	INFO: 0	IGNORE: 0	PASS: 60
pipeline passed with 1 warning(s)
```

Antes desta aula, a mesma execução dizia `dast: passed` e o alerta era invisível. Agora **é um alerta
contado, e a decisão é mantê-lo assim**. Cada alternativa é pior do seu jeito:

| escolha | o que custa |
|---|---|
| FAIL | quebra toda execução noturna por um achado que todos concordam ser falso; o caminho mais curto para desligar a varredura |
| IGNORE | cala a regra 10031 em todas as páginas, inclusive na próxima que alguém escrever refletindo um valor sem escapá-lo |
| OUTOFSCOPE para `/search` | a ferramenta precisa, e o próximo passo: a configuração do ZAP aceita uma regra, `OUTOFSCOPE` e uma expressão regular para os endereços onde a regra não se aplica |
| WARN, como agora | uma linha conhecida num relatório lido toda manhã |

Enquanto é o único alerta, WARN custa uma linha por dia, e a linha diz que a regra ainda roda. No dia em
que o relatório noturno trouxer vinte alertas e este se perder entre eles, a regra sai do escopo de
`/search`, com o motivo, e todas as outras páginas a mantêm. **Vale dar nome a um orçamento de
alertas**: um relatório que alguém lê toda manhã só continua lido enquanto é curto.

### Caso 6: um achado em código que ninguém chama

Um branch acrescenta uma exportação para um relatório trimestral. Ela escreve um arquivo em `/tmp`, e
nada a chama ainda:

```
ana@vm:~/linkbox$ git switch -q -c export
ana@vm:~/linkbox$ git diff | grep '^+'
+++ b/app.py
+
+
+def export_links():
+    with open("/tmp/linkbox-export.csv", "w") as out:
+        for code, url in db().execute("SELECT code, url FROM links"):
+            out.write(f"{code},{url}\n")
ana@vm:~/linkbox$ git commit -q -am "an export of every link, for the quarterly report"
9:54AM INF 0 commits scanned.
9:54AM INF scanned ~187 bytes (187 bytes) in 189ms
9:54AM INF no leaks found
ana@vm:~/linkbox$ git push ci export
remote: run 6: export at 16308d4        
remote: secrets: passed in 0s        
remote: test: passed in 2s        
remote: sast: FAILED in 3s, the end of sast.log:        
remote:   	Total lines skipped (#nosec): 0        
remote:   	Total potential issues skipped due to specifically being disabled (e.g., #nosec BXXX): 0        
remote:           
remote:   Run metrics:        
remote:   	Total issues (by severity):        
remote:   		Undefined: 0        
remote:   		Low: 0        
remote:   		Medium: 1        
remote:   		High: 0        
remote:   	Total issues (by confidence):        
remote:   		Undefined: 0        
remote:   		Low: 0        
remote:   		Medium: 1        
remote:   		High: 0        
remote:   Files skipped (0):        
remote: run 6: failed, the logs are in ~/ci/runs/6/logs        
To /home/ana/ci/linkbox.git
 * [new branch]      export -> export
```

O fim do log é o resumo do Bandit, um problema de severidade média. O problema em si está mais
acima:

```
ana@vm:~/linkbox$ grep -A3 ">> Issue" ~/ci/runs/6/logs/sast.log
>> Issue: [B108:hardcoded_tmp_directory] Probable insecure usage of temp file/directory.
   Severity: Medium   Confidence: Medium
   CWE: CWE-377 (https://cwe.mitre.org/data/definitions/377.html)
   More Info: https://bandit.readthedocs.io/en/1.9.4/plugins/b108_hardcoded_tmp_directory.html
```

O B108 do Bandit tem severidade média: um caminho fixo em `/tmp` é um nome que qualquer outro usuário da
máquina pode criar antes, e aí a exportação escreve no arquivo dele. A resposta do desenvolvedor é que
nada chama a função, então nada fica exposto.

**Decisão: quebrar, e apagar a função.** "Ninguém chama" é uma afirmação sem checagem nenhuma por trás,
verdadeira hoje e falsa no dia em que alguém ligar a exportação a uma rota, e um analisador estático não
distingue os dois dias. Ao contrário do caso 2, este tem correção agora, por quem fez o push. Há três
jeitos, do mais barato ao mais caro: apagá-la até ser necessária; escrevê-la direito, com `tempfile`
escolhendo o caminho; ou, se o caminho for mesmo o certo, um `# nosec B108` na linha com o motivo, como a
aula 3 defendeu para toda supressão. Provar que um código é inalcançável custa mais que qualquer dos três.

### Os seis, lado a lado

| caso | veredito | o motivo, numa linha |
|---|---|---|
| um aviso com correção | quebra | um pin, no arquivo do próprio desenvolvedor |
| um aviso sem correção | alerta | nada nesta mudança o corrige; alguém o lê |
| uma correção que ainda não pode entrar | passa, até uma data | uma exceção: um aviso, uma data, um motivo, um nome |
| um segredo | quebra | o dono sempre pode agir, revogando, e cada minuto custa |
| um falso positivo no DAST | alerta | provado falso, mantido visível, tirado do escopo no dia em que virar ruído |
| um médio em código que ninguém chama | quebra | tem correção agora, e "ninguém chama" não é checado por nada |
