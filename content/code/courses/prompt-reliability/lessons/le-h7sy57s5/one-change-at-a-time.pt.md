---
title: Uma mudança de cada vez
version: 2
---

O jeito óbvio de comparar duas maneiras de escrever um prompt é rodar as duas e ficar com a que
pontua mais. **Isso só funciona quando a redação é a única coisa que difere entre as duas
execuções.** Um experimento muda uma coisa, no mesmo conjunto de teste, com os mesmos parâmetros, ou
o número que ele produz não consegue dizer qual mudança o produziu.

Veja o que acontece quando essa regra escorrega. O `prompts/v6-escaped.txt`, da aula 4, lista os
campos em tópicos, e o `prompts/v7-prose.txt`, o prompt da próxima seção, diz as mesmas coisas num
parágrafo. Alguém roda a versão em prosa para ver se o modelo a lê melhor, e por acaso deixa uma
temperatura de amostragem de 0,8 no comando de um experimento anterior:

```
ana@lab:~/triage$ pl run prompts/v6-escaped.txt cases/all.jsonl --out runs/v6.jsonl
70 calls, prompt fbc4c9b1, llama3.2:3b, written to runs/v6.jsonl
ana@lab:~/triage$ pl run prompts/v7-prose.txt cases/all.jsonl --set temperature=0.8 --out runs/v7-warm.jsonl
70 calls, prompt 7864b0b5, llama3.2:3b, written to runs/v7-warm.jsonl
ana@lab:~/triage$ pl compare runs/v6.jsonl runs/v7-warm.jsonl
runs/v6.jsonl            passes 26/70
runs/v7-warm.jsonl       passes 24/70
fixed 5, broken 7
broken: t04 t11 t12 t17 h13 h15 h19
sign test on the 12 that changed: p = 0.774
```

Sete mensagens quebraram e cinco foram consertadas, e o teste do sinal diz p = 0.774: nada que uma
moeda não faria. Então o prompt em prosa não fez mal? **A comparação não consegue dizer**, em
nenhuma direção. Duas coisas mudaram, e uma diferença pequena no total pode esconder dois efeitos
puxando um contra o outro tanto quanto pode significar que nenhum fez nada. A temperatura é assunto
da aula 8; por ora basta saber que ela faz o modelo tirar a resposta ao acaso, e que esta execução
são duas mudanças com o nome de uma.

A armadilha é fácil de cair porque o arquivo da execução não a registra:

```
ana@lab:~/triage$ head -n 1 runs/v7-warm.jsonl
{"case": "t01", "sample": 0, "cases": "cases/all.jsonl", "prompt": "7864b0b5", "text": "{\"category\": \"billing\", \"urgency\": \"high\", \"summary\": \"Refund the second payment for order 4471\"}", "stop": "stop", "tokens_in": 153, "tokens_out": 29, "seconds": 4.45}
```

Cada linha de uma execução guarda o id do caso, o id do prompt, o conjunto de teste, a resposta, o
motivo da parada, os tokens e o tempo. **Ela não guarda os parâmetros passados com `--set`.** O id
`7864b0b5` é um hash do arquivo de prompt, então é idêntico para o prompt em prosa com temperatura 0
e com 0,8. A aula 4 disse o mesmo sobre uma configuração digitada na linha de comando; a aula 14
versiona prompts direito. Até lá, anote o comando junto com a execução.

## O que fica fixo

- O conjunto de teste. As duas execuções leem o `cases/all.jsonl`, as setenta mensagens. Duas
  execuções em mensagens diferentes comparam as mensagens tanto quanto os prompts.
- Os parâmetros. Temperatura, o limite de saída e tudo o mais que se pode passar com `--set`.
- Tudo no prompt menos a mudança. Os mesmos rótulos, na mesma ordem, com os mesmos exemplos ou
  nenhum.
- A comparação é mensagem por mensagem. O `pl compare` alinha os dois resultados de cada mensagem,
  porque dois totais que diferem por dois podem esconder uma dúzia de mensagens se mexendo em
  direções opostas.

A próxima seção roda o experimento de novo, com a temperatura no lugar dela.
