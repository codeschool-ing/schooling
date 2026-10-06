---
title: Contando o que sobreviveu
version: 1
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

```
ana@lab:~/rag$ python summaries.py
           tokens  essentials
all turns     182  6/6
 20 words      23  2/6  lost: order number, contact by email only, money back for Middlemarch, new address
 40 words      51  2/6  lost: order number, contact by email only, money back for Middlemarch, new address
 60 words      73  3/6  lost: order number, contact by email only, new address
100 words     129  4/6  lost: contact by email only, new address
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 320\" role=\"img\" aria-label=\"Um gráfico de dispersão de seis jeitos de manter os onze primeiros turnos da Beatriz: tokens mantidos contra essenciais que sobreviveram, de seis. Resumo em 20 palavras: 23 tokens, 2. Em 40 palavras: 51, 2. Em 60: 73, 3. Em 100: 129, 4. Frases fixadas com um resumo e os três últimos turnos: 148, 6. Todos os turnos: 182, 6.\"><path d=\"M70 260 L640 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70 260 L70 40\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M70.0 260 L70.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"70.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M212.5 260 L212.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"212.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">50</text><path d=\"M355.0 260 L355.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"355.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">100</text><path d=\"M497.5 260 L497.5 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"497.5\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">150</text><path d=\"M640.0 260 L640.0 265\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"640.0\" y=\"277\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">200</text><path d=\"M65 260.0 L70 260.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"260.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M65 223.33333333333334 L70 223.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"223.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">1</text><path d=\"M65 186.66666666666669 L70 186.66666666666669\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"186.66666666666669\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">2</text><path d=\"M65 150.0 L70 150.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"150.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">3</text><path d=\"M65 113.33333333333334 L70 113.33333333333334\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"113.33333333333334\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">4</text><path d=\"M65 76.66666666666666 L70 76.66666666666666\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"76.66666666666666\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">5</text><path d=\"M65 40.0 L70 40.0\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\"></path><text x=\"61\" y=\"40.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><text x=\"355.0\" y=\"302\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tokens do que é mantido</text><text x=\"70\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">essenciais que sobreviveram, de 6</text><circle cx=\"135.6\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"143.55\" y=\"174.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">20 palavras</text><circle cx=\"215.3\" cy=\"186.7\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"223.35\" y=\"200.66666666666669\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">40 palavras</text><circle cx=\"278.1\" cy=\"150.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"286.05\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">60 palavras</text><circle cx=\"437.6\" cy=\"113.3\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"445.65\" y=\"127.33333333333334\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">100 palavras</text><circle cx=\"491.8\" cy=\"40.0\" r=\"5\" fill=\"var(--phosphor)\"></circle><text x=\"481.8\" y=\"56.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fixadas + resumo + recentes</text><circle cx=\"588.7\" cy=\"40.0\" r=\"5\" fill=\"var(--paper-dim)\"></circle><text x=\"580.7\" y=\"26.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todos os turnos</text></svg>", "caption": "Um resumo sozinho nunca chegou a seis, fosse qual fosse o tamanho; o número do pedido, o pedido de só e-mail e o endereço novo foram as frases que ele largou primeiro. Fixá-las manteve as seis com 34 tokens a menos que os próprios turnos."}
```

**Nenhum resumo manteve os seis.** Com 20 e 40 palavras, dois de seis; com 100 palavras, 129 tokens de
um original de 182, quatro de seis, e ainda sem o pedido de só e-mail nem o endereço novo. Passar de 40
palavras para 100 trouxe de volta o reembolso de *Middlemarch* e o número do pedido, e nunca o pedido de
só e-mail nem o endereço, cada um uma frase num turno. O tamanho não é o botão: um resumo mais longo
mantém mais daquilo de que a conversa mais trata, e os detalhes que mais importam para o próximo turno
muitas vezes são os ditos uma única vez.

A lista é o que torna isso mensurável, e escrevê-la é o trabalho. É um conjunto de teste no sentido da
aula 8, feito de conversas em vez de perguntas: para cada conversa, os fatos que quem a assume precisa
saber. Um punhado de conversas reais, cada uma com a sua lista, transforma "os resumos parecem bons" num
número que muda quando o resumidor muda.
