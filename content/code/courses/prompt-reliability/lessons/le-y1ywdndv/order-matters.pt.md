---
title: A ordem importa
version: 1
---

Dois prompts do laboratório dizem exatamente a mesma coisa em ordem diferente. O
`v17-static-first.txt` põe o guia longo e fixo primeiro e a mensagem por último; o
`v17-message-first.txt` põe a mensagem primeiro e o guia depois:

```
ana@lab:~/triage$ head -n 4 prompts/v17-static-first.txt
cache: on
---
You sort customer messages for Folio, an online bookshop, so that the right
person answers each one and the urgent ones are answered first.
ana@lab:~/triage$ head -n 6 prompts/v17-message-first.txt
cache: on
---
<message>
{{message|xml}}
</message>
```

Os dois ligam o cache no cabeçalho. Rode cada um sobre as quarenta mensagens de dev e conte o que o
cache fez:

```
ana@lab:~/triage$ pl run prompts/v17-static-first.txt cases/dev.jsonl --out runs/static.jsonl
40 calls, prompt b04095b1, written to runs/static.jsonl
ana@lab:~/triage$ pl run prompts/v17-message-first.txt cases/dev.jsonl --out runs/first.jsonl
40 calls, prompt 3eaa1caa, written to runs/first.jsonl
ana@lab:~/triage$ pl cost runs/static.jsonl
tokens          count   per call
input             827       20.7
cache_read       8736      218.4
cache_write       576       14.4
output           1536       38.4

cost of these 40 calls: 3.0302 cents
cost of a million calls like them: 75,755 cents
ana@lab:~/triage$ pl cost runs/first.jsonl
tokens          count   per call
input             827       20.7
cache_read          0        0.0
cache_write      9312      232.8
output           1521       38.0

cost of these 40 calls: 6.0216 cents
cost of a million calls like them: 150,540 cents
```

O `input` comum é 827 tokens nos dois: as sobras no fim de cada prompt que não completaram um bloco.
Todo o resto passou pelo cache, e **os dois prompts o usaram de jeitos opostos**.

## Guia primeiro

O `v17-static-first` leu 8736 tokens do cache, que são 39 × 224. A primeira chamada não tinha o que
ler; cada chamada depois dela leu sete blocos de 32, a parte do guia que todas compartilham. Ele
gravou 576 tokens: os sete blocos da primeira chamada, 224 tokens, e mais onze blocos que alcançavam
uma mensagem. Esses onze foram gravados e nunca lidos, porque nenhuma outra chamada tem a mesma
mensagem.

## Mensagem primeiro

O `v17-message-first` não leu nada e gravou 9312 tokens, cada bloco inteiro de cada chamada. O
primeiro bloco dele contém `<message>` e o começo do texto do cliente, então duas chamadas não
compartilham nem esse, e **um bloco só é lido quando todos os blocos antes dele bateram**. O guia
atrás dele é igual em toda chamada, e o cache não alcança uma palavra dele.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 270\" role=\"img\" aria-label=\"O prompt de uma chamada longa o bastante para oito blocos inteiros de 32 tokens e uma sobra. v17-static-first: os sete primeiros blocos são o guia fixo e são lidos do cache; o oitavo alcança a mensagem, então é gravado e nunca mais lido; a sobra é entrada comum. v17-message-first: a mensagem vem primeiro, então cada bloco inteiro difere dos de todas as outras chamadas e é gravado, e nenhum é lido.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o prompt de uma chamada, em blocos de 32 tokens</text><text x=\"168\" y=\"85.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v17-static-first</text><rect x=\"180\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"238\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"296\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"354\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"412\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"470\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"528\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--phosphor)\"></rect><rect x=\"586\" y=\"70\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"644\" y=\"70\" width=\"26\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M604 56 L604 67\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M604 103 L604 108\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"604\" y=\"118\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a mensagem começa aqui</text><text x=\"168\" y=\"175.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">v17-message-first</text><rect x=\"180\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"238\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"296\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"354\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"412\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"470\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"528\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"586\" y=\"160\" width=\"54\" height=\"30\" rx=\"2\" fill=\"var(--amber)\"></rect><rect x=\"644\" y=\"160\" width=\"26\" height=\"30\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><path d=\"M180 146 L180 157\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><path d=\"M180 193 L180 198\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"180\" y=\"208\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">a mensagem começa aqui</text><rect x=\"180\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--phosphor)\"></rect><text x=\"198\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">lido do cache</text><rect x=\"350\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--amber)\"></rect><text x=\"368\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">gravado, nunca mais lido</text><rect x=\"520\" y=\"240\" width=\"12\" height=\"12\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"538\" y=\"246\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">entrada comum</text></svg>", "caption": "Sete blocos do mesmo guia são um prefixo que toda chamada compartilha. Ponha a mensagem na frente deles e duas chamadas não compartilham nem o primeiro bloco, então o cache grava tudo e não lê nada."}
```

A regra sai direto daí: **ponha no começo o que é igual em toda chamada, e no fim o que varia**.
Instruções, o guia, exemplos e qualquer texto fixo de referência vêm primeiro; a mensagem do cliente,
e tudo o mais que muda a cada chamada, vem por último.
