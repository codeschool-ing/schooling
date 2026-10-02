---
title: Um número ou vários
version: 1
---

Com quatro tipos de métrica na mesa, a tentação é combiná-los: tanto para formato, tanto para acerto,
um pouco para tom, uma nota só para comparar versões. **Uma nota ponderada única deixa uma métrica
esconder outra**, e os dois prompts abaixo mostram como.

```
ana@lab:~/triage$ pl run prompts/v3-examples.txt cases/all.jsonl --out runs/v3-all.jsonl
70 calls, prompt 1d9c6ec4, written to runs/v3-all.jsonl
ana@lab:~/triage$ pl check runs/v3-all.jsonl
check      pass  fail
json         70     0
fields       70     0
labels       70     0
category     56    14
urgency      47    23
all          47    23
ana@lab:~/triage$ pl confusion runs/v3-all.jsonl
expected    billing delivery  returns  account    other    (bad)   recall
billing          14        0        1        1        0        0   0.88
delivery          2       12        0        0        0        0   0.86
returns           1        1       13        0        1        0   0.81
account           3        1        0       10        0        0   0.71
other             3        0        0        0        7        0   0.70
precision      0.61     0.86     0.93     0.91     0.88

accuracy 56/70 = 0.80
```

O `v3-examples.txt` e o `v6-escaped.txt` têm o mesmo acerto de categoria nas mesmas setenta
mensagens: 56 de 70, 0,80. Por baixo, são prompts diferentes. Toda resposta da `v3` é JSON válido,
contra 68 de 70 da `v6`. Mas a `v3` classificou 23 mensagens como billing e só 14 eram, uma precisão
de billing de 0,61 contra 0,87 da `v6`. O primeiro exemplo dela é uma mensagem de billing, e no
substituto todo exemplo puxa para o próprio rótulo as mensagens que se parecem com ele, o efeito que a
aula 1 encontrou em `t37`, aqui espalhado por setenta mensagens.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro métricas de dois prompts nas 70 mensagens. Respostas analisáveis: 1,00 com três exemplos, 0,97 com tags e escape. Acerto de categoria: 0,80 nos dois. Precisão de billing: 0,61 contra 0,87. Recall de account: 0,71 contra 0,64.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">dois prompts nas mesmas 70 mensagens</text><text x=\"178\" y=\"68\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">respostas analisáveis</text><rect x=\"190\" y=\"50\" width=\"420.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"57\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">1.00</text><rect x=\"190\" y=\"68\" width=\"408.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.97</text><text x=\"178\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">acerto de categoria</text><rect x=\"190\" y=\"104\" width=\"336.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"111\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.80</text><rect x=\"190\" y=\"122\" width=\"336.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"129\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.80</text><text x=\"178\" y=\"176\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">precisão de billing</text><rect x=\"190\" y=\"158\" width=\"255.7\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"165\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.61</text><rect x=\"190\" y=\"176\" width=\"364.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"183\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.87</text><text x=\"178\" y=\"230\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">recall de account</text><rect x=\"190\" y=\"212\" width=\"300.0\" height=\"14\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"624.0\" y=\"219\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.71</text><rect x=\"190\" y=\"230\" width=\"270.0\" height=\"14\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"624.0\" y=\"237\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0.64</text><path d=\"M190 44 L190 262\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\"></path><rect x=\"190\" y=\"272\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"208\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">três exemplos  (v3)</text><rect x=\"390\" y=\"272\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"408\" y=\"278\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tags e escape  (v6)</text></svg>", "caption": "O mesmo acerto, e dois prompts diferentes por baixo dele. Cada um vence em algum lugar, e só as métricas lado a lado dizem onde."}
```

Qualquer nota que dê peso ao formato escolheria a `v3`. A equipe de billing, recebendo nove chamados
por execução que são de outra pessoa, escolheria a `v6`. **Nenhuma das escolhas está errada; o erro é
escondê-la dentro de um número.**

## Lado a lado, com portões

Informe as métricas uma ao lado da outra, as mesmas toda vez:

- formato, como taxa própria;
- acerto, e recall e precisão dos rótulos de que alguém depende;
- as células caras pelo nome, como urgência high classificada como normal;
- falhas nas regras de tom, e as contagens de segurança nas duas direções.

Onde uma métrica não pode piorar, faça dela um **portão** em vez de um peso: uma versão que classifica
mais uma mensagem urgente como normal é recusada, aconteça o que acontecer com o acerto. Um portão é
um limite sobre uma métrica só, então não pode ser comprado de volta por um ganho em outro lugar. A
aula 14 guarda esses números ao lado de cada versão do prompt, para que uma mudança seja julgada
contra todos eles de uma vez.
