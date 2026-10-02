---
title: Acompanhando o efeito de cada mudança
version: 1
---

Com um arquivo, uma história e um id que significa alguma coisa, o próximo passo óbvio é rodar cada
versão contra as mesmas mensagens. O `pl log` faz isso num comando só: para cada commit que mexeu em
`prompts/triage.txt`, do mais antigo para o mais novo, ele pega o arquivo como era, roda sobre um
conjunto de teste e imprime dois números.

```
ana@lab:~/triage$ pl log
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/40   2366  First triage prompt
90a013e  2026-08-04 24/40   4734  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05 36/40  11036  Add three examples of the answer
9683448  2026-08-07 36/40  11636  Ask for the JSON object and nothing else
931c548  2026-08-10 36/40  13356  Put the message in tags and say it is data
c8470c9  2026-08-11 36/40  13356  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/40   9739  Make the examples easier to read
03e1151  2026-08-17 36/40  13356  Put the examples back in JSON
```

`all` é a contagem de respostas que passaram em todas as verificações, das quarenta mensagens de dev
por padrão. `tokens` é tudo o que as quarenta chamadas consumiram, entrada e saída somadas. Leia as
duas colunas de cima para baixo, não as linhas de lado a lado, porque **o que serve é como cada
número se moveu em relação ao commit de cima**.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 275\" role=\"img\" aria-label=\"A nota de prompts/triage.txt nas quarenta mensagens de dev em cada um dos seus oito commits, em ordem: 0, 24, 36, 36, 36, 36, 0, 36. Os tokens de cada execução: 2366, 4734, 11036, 11636, 13356, 13356, 9739, 13356. O sétimo commit, Make the examples easier to read, derruba a nota para 0 e gasta menos tokens que qualquer commit desde 4 de agosto; o oitavo devolve as duas coisas.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">aprovações em dev, de 40, a cada commit</text><path d=\"M80 200 L694 200\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\"></path><rect x=\"90\" y=\"196\" width=\"48\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"114.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"114.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">8ec39c2</text><text x=\"114.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2366</text><rect x=\"168\" y=\"113.6\" width=\"48\" height=\"86.4\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"192.0\" y=\"101.6\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">24</text><text x=\"192.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">90a013e</text><text x=\"192.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4734</text><rect x=\"246\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"270.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"270.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">f361c0a</text><text x=\"270.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11036</text><rect x=\"324\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"348.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"348.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">9683448</text><text x=\"348.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">11636</text><rect x=\"402\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"426.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"426.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">931c548</text><text x=\"426.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><rect x=\"480\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"504.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"504.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">c8470c9</text><text x=\"504.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><rect x=\"558\" y=\"196\" width=\"48\" height=\"4\" rx=\"1\" fill=\"var(--amber)\"></rect><text x=\"582.0\" y=\"188.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">0</text><text x=\"582.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">31a6a59</text><text x=\"582.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">9739</text><rect x=\"636\" y=\"70.4\" width=\"48\" height=\"129.6\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"660.0\" y=\"58.400000000000006\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">36</text><text x=\"660.0\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">03e1151</text><text x=\"660.0\" y=\"236\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">13356</text><text x=\"74\" y=\"236\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">tokens</text><text x=\"582.0\" y=\"258\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o mais barato desde 4 de agosto</text></svg>", "caption": "Cada commit do prompt rodado contra as mesmas quarenta mensagens. Dois commits custaram tokens e não mexeram na nota; um deixou o prompt mais barato e quebrou as trinta e seis mensagens que ele acertava.", "same": ["tokens"]}
```

## Os commits que mereceram o lugar

O `90a013e` levou a nota de 0 para 24 pedindo JSON, e o `f361c0a` de 24 para 36 acrescentando
exemplos, as duas mudanças que a aula 1 mediu. A segunda mais que dobrou os tokens, de 4734 para
11036, e comprou doze mensagens com eles. É assim que uma mudança que pagou o próprio custo aparece
nesta tabela: um número sobe, o outro sobe, e há motivo para achar que o primeiro valeu o segundo.

## Os commits que custaram tokens e não mexeram em nada

O `9683448`, *"Ask for the JSON object and nothing else"*, acrescentou 600 tokens em quarenta
chamadas e deixou a nota em 36. A aula 1 já mostrou por quê: com os exemplos no prompt, o substituto
escreve JSON puro, então uma instrução contra blocos de código não tem mais o que corrigir. O
`931c548` acrescentou outros 1720 tokens e a nota também não se mexeu. **Uma nota parada em dev não
quer dizer que a mudança não fez nada**; quer dizer que dev não testa aquilo para que a mudança
serve. Aquele commit tratava de instruções escondidas numa mensagem, e é no conjunto de ataques que
elas moram:

```
ana@lab:~/triage$ pl log cases/attacks.jsonl
commit   date        all tokens  subject
8ec39c2  2026-08-03  0/10    571  First triage prompt
90a013e  2026-08-04  2/10   1090  Ask for JSON, name the fields and list the labels
f361c0a  2026-08-05  1/10   2668  Add three examples of the answer
9683448  2026-08-07  1/10   2818  Ask for the JSON object and nothing else
931c548  2026-08-10  6/10   3302  Put the message in tags and say it is data
c8470c9  2026-08-11  6/10   3329  Escape the message so it cannot close its own tags
31a6a59  2026-08-14  0/10   2472  Make the examples easier to read
03e1151  2026-08-17  6/10   3329  Put the examples back in JSON
```

Nos dez ataques o mesmo commit levou a nota de 1 para 6, então os tokens dele compraram alguma coisa,
afinal. O `9683448` continua parado aqui, 1 de 10 antes e depois, e o `c8470c9`, o commit do escape,
não mexe na nota de nenhum dos dois conjuntos. Seja qual for o modelo, **uma mudança que nenhum
conjunto de teste enxerga é uma mudança aceita na confiança**. Ou você acrescenta o caso que mostra o
que ela corrige, ou anota que ela não corrige nada que dê para medir.

## O commit que levou a nota a zero

O `31a6a59`, *"Make the examples easier to read"*, levou a nota de 36 para 0. Os tokens caíram também,
para 9739, a execução mais barata desde 4 de agosto, e quem olhasse só o custo chamaria aquilo de
melhoria. O `git show` imprime o commit com o diff:

```
ana@lab:~/triage$ git show 31a6a59
commit 31a6a59807c0050e0601d00ab92d82761d8c0dd7
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

Os exemplos deixaram de ser JSON. Cada `Output:` virou uma linha de palavras que uma pessoa lê com
mais facilidade, e a instrução de responder só com o objeto JSON ficou onde estava. No substituto
**a forma do primeiro exemplo vence a descrição**, como a aula 1 mostrou com um número de pedido, e
desta vez ele copiou tudo:

```
ana@lab:~/triage$ git show 31a6a59:prompts/triage.txt > runs/triage-31a6a59.txt
ana@lab:~/triage$ pl run runs/triage-31a6a59.txt cases/dev.jsonl --out runs/31a6a59.jsonl
40 calls, prompt 055cb22b, written to runs/31a6a59.jsonl
ana@lab:~/triage$ pl show runs/31a6a59.jsonl t04
│ account, high: wants the express delivery charge back
stop: end, tokens in 233, out 10
```

`t04` é o cliente que não consegue entrar. A resposta tem a forma do exemplo, a categoria e a
urgência certas, e o resumo do primeiro exemplo palavra por palavra: no substituto, um exemplo cuja
resposta não é JSON é copiado como texto, trocando só os dois rótulos. Nenhuma das quarenta respostas é JSON válido. A mudança foi uma edição razoável, feita pensando num leitor, e
ficou no arquivo de 14 a 17 de agosto, quando o `03e1151` devolveu os exemplos.
