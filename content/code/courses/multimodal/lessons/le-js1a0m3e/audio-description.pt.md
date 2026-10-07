---
title: Audiodescrição nas pausas
version: 2
---

A audiodescrição padrão, o critério 1.2.5, fala nas pausas da trilha sonora sem mudar a duração do vídeo. Então são três perguntas: o que dizer, onde estão as pausas, e se as palavras cabem.

```schooling-example
{
  "language": "python",
  "file": "describe.py",
  "parts": [
    {
      "code": "\"\"\"Audio description: speak what is shown and not said, in the pauses of the narration, if it fits.\"\"\"\nimport subprocess\n\nimport mmlab\nimport soundfile\n\n"
    },
    {
      "code": "# Written by the course, as a describer would write them: short, and only what the narration leaves out.\nDESCRIPTIONS = [(11.64, \"Reasons: damaged, wrong book, changed my mind.\"),\n                (20.72, \"Code: RETURN30.\"),\n                (26.44, \"The label is valid for seven days.\")]\n\n",
      "note": "**As descrições, escritas por uma pessoa** (aqui, pelo curso): quando cada coisa aparece na tela, e as menores palavras que a dizem. Escrevê-las é o ofício de quem descreve, e nada abaixo substitui isso."
    },
    {
      "code": "speech = mmlab.speech_segments(mmlab.read_audio(\"media/returns.mp4\"))\ngaps = [(a[1], b[0]) for a, b in zip(speech, speech[1:])] + [(speech[-1][1], 32.6)]\ntts = mmlab.piper(\"en_US-lessac-medium\")\n\n",
      "note": "**Onde a narração fica em silêncio**: o detector de fala da aula 5 sobre o som do vídeo, e as pausas entre os segmentos, mais o final depois do último."
    },
    {
      "code": "inputs, filters = [], []\nfor shown, text in DESCRIPTIONS:\n",
      "note": "**Uma voz para todas as descrições**, a voz Piper da aula 6, para soarem como uma só pessoa descrevendo."
    },
    {
      "code": "    gap = next((g for g in gaps if g[1] > shown), None)            # the first pause that ends after it appears\n",
      "note": "**A pausa que pertence a uma descrição** é a primeira que termina depois que a coisa aparece."
    },
    {
      "code": "    audio = tts.generate(text, sid=0, speed=1.0)\n    seconds = len(audio.samples) / audio.sample_rate\n    fits = gap[1] - gap[0] >= seconds + 0.2                      # a tenth of a second of air either side\n    print(\"%5.2f  %-48s %.2f s into a %.2f s pause at %.2f: %s\" % (shown, text, seconds, gap[1] - gap[0], gap[0],\n                                                                 \"fits\" if fits else \"does NOT fit\"))\n",
      "note": "**Falar, medir e comparar** com a pausa, deixando um décimo de segundo livre em cada ponta para a descrição não encostar na narração."
    },
    {
      "code": "    if fits:\n        name = f\"ad{len(inputs)}.wav\"\n        soundfile.write(name, audio.samples, audio.sample_rate)\n        filters.append(f\"[{len(inputs) + 1}]adelay={int((gap[0] + 0.1) * 1000)}:all=1[d{len(inputs)}]\")\n        inputs.append(name)\n\n",
      "note": "**Uma descrição que cabe é guardada**, gravada num arquivo e com um atraso que a começa um décimo de segundo depois do início da pausa."
    },
    {
      "code": "mix = \";\".join(filters) + \";[0]\" + \"\".join(f\"[d{i}]\" for i in range(len(inputs))) + \\\n      f\"amix=inputs={len(inputs) + 1}:normalize=0\"\nsubprocess.run([\"ffmpeg\", \"-nostdin\", \"-loglevel\", \"error\", \"-y\", \"-i\", \"media/returns.mp4\",\n                *sum(([\"-i\", n] for n in inputs), []), \"-filter_complex\", mix, \"-ac\", \"1\", \"described.wav\"], check=True)\nprint(\"described.wav:\", len(inputs), \"of\", len(DESCRIPTIONS), \"descriptions mixed in\")",
      "note": "**O ffmpeg mistura a narração e as descrições atrasadas** numa só faixa. O `normalize=0` mantém cada entrada no próprio volume; o amix, sem isso, abaixaria cada uma."
    }
  ]
}
```

```
ana@lab:~/mm$ python describe.py
11.64  Reasons: damaged, wrong book, changed my mind.   2.82 s into a 1.15 s pause at 10.89: does NOT fit
20.72  Code: RETURN30.                                  1.45 s into a 1.82 s pause at 20.01: fits
26.44  The label is valid for seven days.               1.99 s into a 1.18 s pause at 25.70: does NOT fit
described.wav: 1 of 3 descriptions mixed in
ana@lab:~/mm$ python -c "from openai import OpenAI; print(OpenAI(base_url=\"http://localhost:8700/v1\").audio.transcriptions.create(model=\"whisper-base\", file=open(\"described.wav\", \"rb\"), response_format=\"text\"))" | cut -c1-400
Here is how to return a book you bought from Marginelia. It takes four steps and the label is free. First, sign and end open the order the book came in. You will find it under account then orders. Second, press return this item and choose a reason from the list. 3. Print the prepared label we send you by email and tape it over the old address. Code, return 30, 4. Drop the parcel at any post office
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Uma linha do tempo do vídeo de devoluções, de 32,6 segundos. A fileira de cima são os sete slides; o quinto, o cartão RETURN30, tem 0,4 segundo de largura. A do meio é a narração: seis trechos de fala com pausas de cerca de 1,2 segundo entre eles, e uma de 1,8 segundo em volta do cartão. A de baixo são as três descrições, cada uma desenhada na sua pausa com a própria duração: 2,82 segundos para os motivos, que transborda uma pausa de 1,15 segundo; 1,45 segundo para o código, que cabe na pausa de 1,82 segundo; e 1,99 segundo para a validade da etiqueta, que transborda uma pausa de 1,18 segundo.\"><text x=\"40\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">slides</text><rect x=\"41\" y=\"30\" width=\"116.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"46\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">1</text><rect x=\"159.4\" y=\"30\" width=\"112.4\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164.4\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">2</text><rect x=\"273.8\" y=\"30\" width=\"78.80000000000001\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"278.8\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">3</text><rect x=\"354.6\" y=\"30\" width=\"98.79999999999995\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"359.6\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">4</text><rect x=\"455.4\" y=\"30\" width=\"6.000000000000057\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"463.40000000000003\" y=\"30\" width=\"104.40000000000003\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"468.40000000000003\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><rect x=\"569.8000000000001\" y=\"30\" width=\"121.19999999999993\" height=\"26\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"574.8000000000001\" y=\"47\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"40\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">narração</text><rect x=\"48.4\" y=\"90\" width=\"95.4\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"166.8\" y=\"90\" width=\"91.0\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"280.79999999999995\" y=\"90\" width=\"58.80000000000007\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"362.0\" y=\"90\" width=\"78.20000000000005\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"476.59999999999997\" y=\"90\" width=\"77.40000000000003\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"577.8\" y=\"90\" width=\"100.40000000000009\" height=\"26\" rx=\"3\" fill=\"var(--phosphor-dim)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"40\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">descrições, desenhadas na sua pausa</text><rect x=\"259.8\" y=\"154\" width=\"56.4\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"259.8\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2,82 s</text><rect x=\"442.20000000000005\" y=\"154\" width=\"29.0\" height=\"26\" rx=\"3\" fill=\"var(--phosphor)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"442.20000000000005\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">1,45 s</text><rect x=\"556.0\" y=\"154\" width=\"39.8\" height=\"26\" rx=\"3\" fill=\"var(--amber)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"556.0\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1,99 s</text><text x=\"40\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">0 s</text><text x=\"656.0\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">32,6 s</text></svg>", "caption": "Uma descrição cabe numa pausa; as outras duas são mais longas que o silêncio que a narração deixa.", "same": ["slides"]}
```

**Uma das três cabe.** A narração deixa pausas de cerca de 1,2 segundo entre as frases, e os motivos precisam de 2,82 segundos mesmo em sete palavras. O cartão é a exceção: a pausa dele é de 1,82 segundo, porque o próprio cartão fica numa lacuna da narração, e "Code: RETURN30" leva 1,45. A última linha da captura é o Whisper ouvindo a faixa descrita: "Code, return 30" agora faz parte do que o vídeo diz.

As outras duas têm três saídas, e cada uma é uma decisão, não um cálculo:

- **Dizer menos.** "Seven-day label" talvez caiba em 1,18 segundo onde "The label is valid for seven days" não cabe; quem descreve decide se ainda diz o bastante.
- **Audiodescrição estendida**, o critério 1.2.7, de nível AAA: o player pausa o vídeo enquanto a descrição é falada. Num player web isso é um recurso a construir, não um arquivo a mixar.
- **Mudar o vídeo.** A correção mais barata está antes: uma narração que lê os motivos e o prazo em voz alta não precisa de descrição para eles. Para um vídeo que a própria loja faz, essa é a correção a preferir, e o raciocínio é o mesmo da seção anterior: **o roteiro é o lugar das palavras**.

Nada na WCAG pede uma voz humana, e uma sintética muda a cada edição sem custo. O que ela não faz é decidir o que descrever, e é por isso que o `DESCRIPTIONS` é escrito por uma pessoa no topo do programa.
