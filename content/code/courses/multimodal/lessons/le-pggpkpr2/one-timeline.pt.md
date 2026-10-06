---
title: Os dois fluxos numa linha do tempo
version: 1
---

Quadros e palavras só servem juntos, e o relógio que eles compartilham é o que os une. O programa abaixo pega as cenas do detector, lê o título de cada uma e põe ao lado o que foi dito enquanto ela estava na tela:

```schooling-example
{
  "language": "python",
  "file": "timeline.py",
  "parts": [
    {
      "code": "\"\"\"One timeline from both streams: what was on screen, and what was said while it was.\"\"\"\nimport json\nimport subprocess\n\nfrom frames import sample, title\n\n"
    },
    {
      "code": "VIDEO, LENGTH = \"media/returns.mp4\", 32.6\nsaid = json.load(open(\"said.json\"))\n",
      "note": "**Os trechos da trilha**, como o `soundtrack.py` os salvou: um início, um fim e as palavras."
    },
    {
      "code": "cuts = sample(VIDEO, \"scene > 0.03\", \"/tmp/scenes\")\nsubprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-i\", VIDEO, \"-frames:v\", \"1\", \"/tmp/scenes/000.png\"])\nscenes = [(0.0, \"/tmp/scenes/000.png\")] + cuts\n\n",
      "note": "**As cenas**: os cortes que o detector achou com 0,03, mais o primeiro quadro, que nenhum corte precede."
    },
    {
      "code": "timeline = []\nfor (start, png), end in zip(scenes, [t for t, _ in cuts] + [LENGTH]):\n",
      "note": "**Uma entrada por cena**, do seu corte até o próximo, ou até o fim do vídeo."
    },
    {
      "code": "    words = \" \".join(s[\"text\"] for s in said if start <= (s[\"start\"] + s[\"end\"]) / 2 < end)\n",
      "note": "**Um trecho de fala pertence à cena em que cai o seu meio.** A fala atravessa cortes, e alguma regra tem de decidir; esta é simples e diz isso."
    },
    {
      "code": "    timeline.append({\"from\": start, \"to\": end, \"shown\": title(png), \"said\": words})\n    print(f\"{start:6.2f}-{end:5.2f}  shown: {timeline[-1]['shown']}\")\n    print(f\"{'':12}  said:  {words or '(nothing)'}\")\njson.dump(timeline, open(\"timeline.json\", \"w\"), indent=1)",
      "note": "**O que foi mostrado, lido pelo Tesseract no quadro da cena, e o que foi dito**, lado a lado, impressos e salvos."
    }
  ]
}
```

```
ana@lab:~/mm$ python timeline.py
  0.00- 5.92  shown: Returning a book to Marginalia
              said:  Here is how to return a book you bought from Marginelia. It takes four steps and the label is free.
  5.92-11.64  shown: 1. Open the order
              said:  First, sign and end open the order the book came in. You will find it under account then orders.
 11.64-15.68  shown: 2. Choose a reason
              said:  Second, press return this item and choose a reason from the list.
 15.68-20.72  shown: 3. Print the label
              said:  Third, print the prepared label we send you by email and tape it over the old address.
 20.72-21.12  shown: Code: RETURN3O
              said:  (nothing)
 21.12-26.44  shown: 4. Drop it off
              said:  Drop the parcel at any post office and keep the receipt until your refund arrives.
 26.44-32.60  shown: Refunds
              said:  Refunds go back to the card you paid with, a damage to book as refunded and full, shipping included.
```

Esta é a versão fiel mais compacta do vídeo: sete entradas, cada uma com o que foi mostrado e o que foi dito. Duas coisas nela merecem atenção.

**Cada fluxo pega o que o outro perde.** O cartão em 20,72 tem título e nenhuma fala. A fala do slide de reembolso diz *refunds go back to the card you paid with*, que não está em slide nenhum. Um resumo feito com um só dos fluxos perderia algo que a loja queria que os clientes soubessem.

**Os dois modelos erraram, e a linha do tempo guarda os erros.** O OCR leu o cartão como `Code: RETURN3O`, com a letra O onde o slide tem um zero; o *damage to book as refunded and full* do Whisper continua lá. Uma linha do tempo não corrige suas fontes. O que ela faz é deixar cada erro ao lado da versão que o outro fluxo tem do mesmo momento, onde uma pessoa ou um modelo depois consegue ver que o slide diz *Damaged books: refunded in full* e a fala diz algo embaralhado.

É também por isso que a linha do tempo guarda tempos, e não só texto: um erro achado depois pode ser conferido pulando para o segundo em que aconteceu.
