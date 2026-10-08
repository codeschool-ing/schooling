---
title: Contando o que sobreviveu
version: 2
---

Um resumo não pode ser conferido lendo, porque o que falta é invisível. Ele pode ser conferido contra
uma lista do que precisa estar lá. Para a conversa da Beatriz, a lista são seis fatos, escritos por
alguém que leu a conversa e sabe do que um atendente precisaria:

```schooling-example
{
  "language": "python",
  "file": "essentials.py",
  "parts": [
    {
      "code": "import json",
      "note": "Os turnos da conversa da Beatriz, lidos dos dados do curso."
    },
    {
      "code": "# What a support agent picking up Beatriz's conversation must still know, each as words that have to\n# appear. Written by a person who read the conversation; that is what makes it a test.\nESSENTIALS = {\n    \"order number\": [\"MG-20481937\"],\n    \"contact by email only\": [\"email only\"],\n    \"replacement for Persuasion\": [\"Persuasion\", \"replacement\"],\n    \"wrong book received\": [\"Mansfield Park\"],\n    \"money back for Middlemarch\": [\"Middlemarch\", \"money back\"],\n    \"new address\": [\"Rua das Flores 120\"],\n}\nTURNS = [json.loads(line)[\"text\"] for line in open(\"data/chat-a.jsonl\")]",
      "note": "Seis fatos, cada um como as palavras que um texto precisa conter para carregá-lo. Uma pessoa que leu a conversa os escreveu, e é isso que os torna um teste do resumidor, e não dele mesmo."
    },
    {
      "code": "def kept(text):\n    \"\"\"The essentials TEXT still carries: every word of each one has to be there.\"\"\"\n    return [name for name, words in ESSENTIALS.items() if all(w.lower() in text.lower() for w in words)]",
      "note": "Um fato sobrevive quando cada uma das suas palavras está no texto, sem diferenciar maiúsculas."
    }
  ]
}
```

Depois cada resumo é pontuado contra a lista, em quatro tamanhos, ao lado dos próprios turnos:

```schooling-example
{
  "language": "python",
  "file": "summaries.py",
  "parts": [
    {
      "code": "from compact import summarise, tokens\nfrom essentials import ESSENTIALS, TURNS, kept\n\nolder = TURNS[:11]\nprint(f\"{'':10} {'tokens':>6}  essentials\")\nprint(f\"{'all turns':10} {tokens(' '.join(older)):6}  {len(kept(' '.join(older)))}/{len(ESSENTIALS)}\")\nfor words in (20, 40, 60, 100):\n    summary = summarise(older, words)\n    print(f\"{words:3} words  {tokens(summary):6}  {len(kept(summary))}/{len(ESSENTIALS)}  lost: {', '.join(n for n in ESSENTIALS if n not in kept(summary))}\")",
      "note": "Os onze turnos resumidos em quatro tamanhos, e para cada tamanho quantos tokens o resumo ocupa e quantos dos essenciais ele ainda leva."
    }
  ]
}
```
```
ana@vm:~/rag$ python summaries.py
           tokens  essentials
all turns     182  6/6
 20 words      23  0/6  lost: order number, contact by email only, replacement for Persuasion, wrong book received, money back for Middlemarch, new address
 40 words      53  2/6  lost: contact by email only, wrong book received, money back for Middlemarch, new address
 60 words      75  4/6  lost: contact by email only, money back for Middlemarch
100 words      95  3/6  lost: contact by email only, wrong book received, money back for Middlemarch
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um gráfico de dispersão de seis jeitos de manter os onze primeiros turnos da Beatriz: tokens mantidos contra essenciais que sobreviveram, de seis. Resumo em 20 palavras: 23 tokens, 0. Em 40 palavras: 53, 2. Em 60: 75, 4. Em 100: 95, 3. Frases fixadas com um resumo e os três últimos turnos: 141, 6. Todos os turnos: 182, 6.\"><path d=\"M70 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 260 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 260 L70.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 260 L212.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M355.0 260 L355.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"355.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M497.5 260 L497.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M640.0 260 L640.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M65 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 223.33333333333334 L70 223.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M65 186.66666666666669 L70 186.66666666666669\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"186.66666666666669\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M65 150.0 L70 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M65 113.33333333333334 L70 113.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"113.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M65 76.66666666666666 L70 76.66666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens do que é mantido</text><text x=\"70\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">essenciais que sobreviveram, de 6</text><circle cx=\"135.6\" cy=\"260.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"143.6\" y=\"246.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">20 palavras</text><circle cx=\"221.1\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"229.1\" y=\"200.7\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">40 palavras</text><circle cx=\"283.8\" cy=\"113.3\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"291.8\" y=\"127.3\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">60 palavras</text><circle cx=\"340.8\" cy=\"150.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"348.8\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 palavras</text><circle cx=\"471.9\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"461.9\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixadas + resumo + recentes</text><circle cx=\"588.7\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"580.7\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todos os turnos</text></svg>", "caption": "Um resumo sozinho nunca chegou a seis, fosse qual fosse o tamanho, e nenhum manteve o pedido de só e-mail; com 100 palavras manteve menos que com 60. Fixar manteve as seis com 41 tokens a menos que os próprios turnos."}
```

**Nenhum resumo manteve os seis, e nenhum manteve o pedido de só e-mail.** Com 20 palavras, nada; com
60, quatro de seis em 75 tokens, o melhor dos quatro; com 100 palavras, três. Um resumo mais longo não
é um resumo mais seguro: passar de 60 para 100 palavras perdeu o livro errado. E a linha de 40 palavras
manteve dois de seis, onde o mesmo pedido na seção anterior manteve o número do pedido, o endereço e os
dois livros: o mesmo programa, os mesmos turnos, temperatura 0, e um resumo diferente. Um resumo
conferido uma vez foi conferido uma vez.

A verificação também é rígida. Ela procura as palavras *money back*, e um resumo que diz *a refund for
Middlemarch*, como o da seção anterior, reprova. A última seção desta aula volta a quão rígida deve ser
a verificação de cada fato; aqui, leia a coluna *lost* como o que o resumo não disse com as palavras do
cliente.

A lista é o que torna isso mensurável, e escrevê-la é o trabalho. É um conjunto de teste no sentido da
aula 8, feito de conversas em vez de perguntas: para cada conversa, os fatos que quem a assume precisa
saber. Um punhado de conversas reais, cada uma com a sua lista, transforma "os resumos parecem bons" num
número que muda quando o resumidor muda.
