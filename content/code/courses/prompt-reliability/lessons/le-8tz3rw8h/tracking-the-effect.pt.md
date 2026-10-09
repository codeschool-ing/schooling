---
title: Acompanhando o efeito de cada mudança
version: 2
---

Com um arquivo, uma história e um id que significa algo, o próximo passo óbvio é rodar cada versão
contra as mesmas mensagens. Este programa faz isso num comando só: para cada commit que mexeu no
`prompts/triage.txt`, do mais antigo para o mais novo, ele pega o arquivo como era, grava-o em
`runs/triage-<commit>.txt`, roda-o sobre um conjunto de teste e imprime dois números. Salve-o como
`log.py`:

```python
"""log: every version of a prompt in git, run over one test set: what it
scored and how many tokens the run took."""
import subprocess
import sys

from pl import DEFAULTS, call, judge, read_jsonl, read_prompt, render, values_of

PATH = "prompts/triage.txt"


def git(*args):
    return subprocess.run(["git", *args], capture_output=True, text=True, check=True).stdout


cases_path = sys.argv[1] if len(sys.argv) > 1 else "cases/dev.jsonl"
cases = read_jsonl(cases_path)
print("commit   date        all tokens  subject")
for line in git("log", "--reverse", "--date=short", "--format=%h %ad %s", "--", PATH).splitlines():
    sha, date, subject = line.split(" ", 2)
    old = "runs/triage-%s.txt" % sha
    with open(old, "w", encoding="utf-8") as f:
        f.write(git("show", "%s:%s" % (sha, PATH)))
    params, template = read_prompt(old)
    params = {**DEFAULTS, **params}
    passed = tokens = 0
    for case in cases:
        row = call(render(template, values_of(case, {})), params)
        passed += judge(row, case["expect"])[0] is None
        tokens += row["tokens_in"] + row["tokens_out"]
    print("%s  %s %2d/%d %6d  %s" % (sha, date, passed, len(cases), tokens, subject))
```

Ele usa o `call()`, o `render()` e o `judge()` do próprio harness, então uma aprovação aqui é uma
aprovação no `pl check`. Sobre as quarenta mensagens do dev:

```
ana@lab:~/triage$ python3 log.py
commit   date        all tokens  subject
341f8f8  2026-08-03  0/40   6692  First triage prompt
61d470e  2026-08-04 22/40   5476  Ask for JSON, name the fields and list the labels
ab97290  2026-08-05 28/40  11152  Add three examples of the answer
5b2d8d0  2026-08-07 26/40  11726  Ask for the JSON object and nothing else
a0f1d2a  2026-08-10 24/40  13408  Put the message in tags and say it is data
c8f1927  2026-08-11 24/40  13408  Escape the message so it cannot close its own tags
86913c0  2026-08-14 27/40  11553  Make the examples easier to read
85dfa4e  2026-08-17 24/40  13408  Put the examples back in JSON
```

`all` é a contagem de respostas que passaram em todas as verificações. `tokens` é tudo o que as
quarenta chamadas consumiram, entrada e saída somadas. Leia as duas colunas de cima para baixo em vez
de ler as linhas, porque **o útil é como cada número se mexeu em relação ao commit de cima**.

## Os commits que mereceram o lugar

O `61d470e` levou a nota de 0 a 22 pedindo JSON, e os tokens *caíram*, de 6692 para 5476, porque as
respostas longas e falantes do prompt seco custavam mais do que a lista de campos. O `ab97290` levou
a nota de 22 a 28 acrescentando exemplos, a mudança que a aula 1 mediu, e dobrou os tokens para
11152. É assim que fica nesta tabela uma mudança que mereceu o custo: um número sobe, o outro sobe, e
há um motivo para achar que o primeiro valeu o segundo.

## Os commits que custaram tokens e foram para o outro lado

O `5b2d8d0`, *"Ask for the JSON object and nothing else"*, acrescentou 574 tokens em quarenta
chamadas e a nota foi de 28 para 26. O `a0f1d2a`, as tags e a frase dizendo que a mensagem é dado,
acrescentou mais 1682 e a nota foi para 24. Duas linhas cada, então o aviso da aula 11 vale, e vale
saber para que eles serviam antes de alguém revertê-los. **Uma nota que cai no dev não quer dizer que
a mudança não fez nada**; pode querer dizer que o dev não testa aquilo para que a mudança servia. As
tags eram sobre instruções escondidas numa mensagem, e o conjunto de ataques é onde elas moram:

```
ana@lab:~/triage$ python3 log.py cases/attacks.jsonl
commit   date        all tokens  subject
341f8f8  2026-08-03  0/10   1739  First triage prompt
61d470e  2026-08-04  1/10   1545  Ask for JSON, name the fields and list the labels
ab97290  2026-08-05  2/10   2804  Add three examples of the answer
5b2d8d0  2026-08-07  2/10   2982  Ask for the JSON object and nothing else
a0f1d2a  2026-08-10  3/10   3464  Put the message in tags and say it is data
c8f1927  2026-08-11  3/10   3473  Escape the message so it cannot close its own tags
86913c0  2026-08-14  3/10   3052  Make the examples easier to read
85dfa4e  2026-08-17  3/10   3473  Put the examples back in JSON
```

Nos dez ataques as tags levaram a nota de 2 para 3, o único commit depois dos exemplos a mexer nela.
O `c8f1927`, o commit do escape, não mexe nota nenhuma em nenhum dos dois conjuntos: a aula 9 mostrou
para que ele serve, uma mensagem que de outro modo quebraria a forma do prompt, e nenhum dos
conjuntos tem uma. **Uma mudança que nenhum conjunto de teste vê é uma mudança aceita na confiança.**
Ou acrescente o caso que mostra o que ela conserta, ou anote que ela não conserta nada que você
consiga medir.

## O commit que parece uma correção

O `86913c0`, *"Make the examples easier to read"*, reescreveu os três exemplos como linhas simples e
manteve a instrução de responder só com um objeto JSON. Parece imprudente: a aula 1 viu que a forma
dos exemplos é o que o modelo copia. A tabela diz que a nota foi de 24 para 27 e os tokens caíram
para 11553. Três dias depois o `85dfa4e`, *"Put the examples back in JSON"*, desfez isso, e a nota
voltou a 24. O `git show` imprime o commit que foi desfeito, com o diff:

```
ana@lab:~/triage$ git show 86913c0
commit 86913c05e4fd31c789427c8645c715c4eb13fdae
Author: Ana Lima <ana@example.org>
Date:   Fri Aug 14 17:45:00 2026 -0300

    Make the examples easier to read

diff --git a/prompts/triage.txt b/prompts/triage.txt
index 43dc42c..ea04ec1 100644
--- a/prompts/triage.txt
+++ b/prompts/triage.txt
@@ -11,17 +11,17 @@ Read the message and answer in JSON with three fields:
 
 <example>
 Message: I paid for express delivery but the order came by normal post.
-Output: {"category": "billing", "urgency": "normal", "summary": "Wants the express delivery charge back."}
+Output: billing, normal: wants the express delivery charge back
 </example>
 
 <example>
 Message: The book came with water damage on every page.
-Output: {"category": "returns", "urgency": "normal", "summary": "Wants a replacement for a damaged book."}
+Output: returns, normal: wants a replacement for a damaged book
 </example>
 
 <example>
 Message: Can I change the name on my account?
-Output: {"category": "account", "urgency": "low", "summary": "Asks how to change the account name."}
+Output: account, low: asks how to change the account name
 </example>
 
 Reply with only the JSON object: no code fence and no other text.
```

E esta é uma das respostas dele:

```
ana@lab:~/triage$ pl run runs/triage-86913c0.txt cases/dev.jsonl --out runs/86913c0.jsonl
40 calls, prompt 055cb22b, llama3.2:3b, written to runs/86913c0.jsonl
ana@lab:~/triage$ pl show runs/86913c0.jsonl t04
│ {"category": "account", "urgency": "low", "summary": "has trouble logging in and password reset email never arrives"}
stop: stop, tokens in 260, out 29, 4.2 s
```

JSON válido, a categoria certa, a urgência errada para um cliente que não consegue entrar, e um
resumo no estilo das linhas simples: minúsculas e sem ponto final. Com o `llama3.2:3b` o formato veio
da instrução e da lista de campos, e os exemplos contribuíram com os rótulos. **A reversão parece uma
correção** e a mensagem dela diz o que ela fez, não por quê. Alguém acreditava que os exemplos
precisam parecer exatamente com a resposta. Essa crença veio de um lugar razoável, e neste modelo,
neste dia, a tabela diz que ela custou três mensagens e 1855 tokens por execução. Se três mensagens
são reais é a pergunta da próxima seção.
