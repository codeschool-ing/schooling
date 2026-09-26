---
title: Perguntando como o usuário
version: 1
---

As mesmas duas perguntas, feitas como o Bruno com `sudo -u bruno`:

```
ana@pc1:~$ sudo -u bruno lpstat -d
system default destination: pdf
ana@pc1:~$ sudo -u bruno bash -c "cd ~ && lp report.txt"
request id is pdf-4 (1 file(s))
```

**Para o Bruno, o padrão é `pdf`**, e o documento dele foi para a fila `pdf`, que grava um arquivo e nunca
toca papel. Nada está quebrado: a impressora funciona, a fila funciona, e os documentos dele estão indo
exatamente para onde as configurações dele mandam.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 190\" role=\"img\" aria-label=\"Dois padrões, e qual cada pessoa recebe. O padrão do sistema é office, a impressora. O Bruno tem um padrão próprio, pdf, no arquivo lpoptions dele, e ele vale para ele. Então quando a ana imprime, o trabalho vai para office; quando o bruno imprime, vai para pdf, que gera um arquivo e nenhum papel.\"><defs><marker id=\"df-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"30\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">a ana imprime</text><rect x=\"20\" y=\"120\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"32\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o bruno imprime</text><rect x=\"250\" y=\"30\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o padrão do sistema: office</text><rect x=\"250\" y=\"120\" width=\"220\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"262\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o padrão do próprio bruno: pdf</text><rect x=\"530\" y=\"30\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"542\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">office: a impressora</text><rect x=\"530\" y=\"120\" width=\"170\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"542\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pdf: um arquivo, não papel</text><path d=\"M192 50 L248 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M472 50 L528 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M192 140 L248 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path><path d=\"M472 140 L528 140\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#df-ah)\"></path></svg>", "caption": "O padrão próprio de um usuário vale mais que o do sistema, só para aquele usuário. Por isso a página de teste do técnico saiu e os documentos do Bruno não: nunca foram mandados para o mesmo lugar."}
```

Esse é o tipo de causa que a explicação do usuário esconde. "A impressora quebrou" nomeou a última coisa
que ele conseguia ver, a impressora que ficou quieta. O defeito estava um passo antes, numa escolha que
ele fez numa caixa de diálogo. No laboratório, o que essa escolha fez foi feito com `lpoptions -d pdf`,
rodado como o Bruno, e o cabeçalho da captura diz isso: os computadores do laboratório não têm área de
trabalho para mostrar a janela.
