---
title: Quem falou quando
version: 1
---

A **diarização de falantes** responde *quem falou quando*, sem saber quem é quem. A saída é uma lista de intervalos de tempo, cada um com um rótulo como `speaker_0`; decidir que `speaker_0` é o atendente da loja é trabalho seu. São três modelos em fila: **segmentação** (o modelo do pyannote acha onde a fala troca de mãos, quadro a quadro), **embedding** (o ERes2Net do 3D-Speaker transforma cada pedaço de fala num vetor que descreve a voz, como um embedding de texto descreve o sentido), e **agrupamento** (pedaços cujos vetores estão próximos o bastante ficam sob um rótulo).

O laboratório pontua isso como pontua tudo, contra quem realmente falou:

```schooling-example
{
  "language": "python",
  "file": "who.py",
  "parts": [
    {
      "code": "\"\"\"Who spoke when, by pyannote and ERes2Net, scored against who really did.\"\"\"\nimport json\nimport sys\nfrom collections import Counter\n\nimport mmlab\n\n"
    },
    {
      "code": "path, threshold = sys.argv[1], float(sys.argv[2])\nknown = [int(a) for a in sys.argv[3:] if a.isdigit()]   # how many speakers, if somebody knows\nturns = json.load(open(\"media/truth/call-1042.json\"))[\"turns\"]\n",
      "note": "**As configurações vêm da linha de comando**: o arquivo, o limite de agrupamento e, se alguém souber, quantas pessoas falam."
    },
    {
      "code": "samples = mmlab.read_audio(path)\nfound = mmlab.diarizer(threshold=threshold, speakers=known[0] if known else -1).process(samples).sort_by_start_time()\nsegments = [(s.start, s.end, f\"speaker_{s.speaker}\") for s in found]\n",
      "note": "**O diarizador roda uma vez sobre a ligação inteira.** O pyannote acha onde a fala troca de mãos; o ERes2Net transforma cada pedaço num embedding de voz; o agrupamento junta os embeddings, e cada grupo ganha um rótulo."
    },
    {
      "code": "\n\ndef overlap(a, b, c, d):\n    return max(0.0, min(b, d) - max(a, c))\n\n\nvotes = Counter()  # seconds each found label spent over each real speaker\nfor s, e, label in segments:\n    for t in turns:\n        votes[label, t[\"who\"]] += overlap(s, e, t[\"start\"], t[\"end\"])\n",
      "note": "**Quantos segundos cada rótulo passou sobre cada pessoa real.** Os rótulos são `speaker_0`, `speaker_1` e assim por diante: o diarizador distingue vozes, não sabe de quem são."
    },
    {
      "code": "names = {label: max((\"caio\", \"bia\"), key=lambda w: votes[label, w]) for _, _, label in segments}\nright = sum(v for (label, who), v in votes.items() if names[label] == who)\nspeech = sum(t[\"end\"] - t[\"start\"] for t in turns)\n",
      "note": "**Cada rótulo recebe o nome da pessoa com quem mais se sobrepõe**, e a nota é a parte de toda a fala que ficou sob o nome certo."
    },
    {
      "code": "print(f\"{path} at {threshold}: {len(names)} speakers found, {len(segments)} segments, \"\n      f\"{right / speech:.1%} of the speech given to the right person\")\n",
      "note": "**O veredito numa linha**: quantos rótulos, quantos segmentos, quanta fala foi para a pessoa certa."
    },
    {
      "code": "if \"show\" in sys.argv:\n    for s, e, label in segments:\n        print(f\"  {s:6.2f} {e:6.2f}  {label} -> {names[label]}\")",
      "note": "**E, se pedido, cada segmento** com o rótulo e o nome que recebeu."
    }
  ]
}
```

```
ana@lab:~/mm$ python who.py media/call-1042.wav 0.5 show
media/call-1042.wav at 0.5: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
    0.03   5.33  speaker_0 -> caio
    6.02  11.98  speaker_1 -> bia
   11.98  14.34  speaker_3 -> bia
   14.98  23.93  speaker_0 -> caio
   24.89  29.21  speaker_1 -> bia
   29.98  38.30  speaker_0 -> caio
   39.11  41.34  speaker_1 -> bia
   41.88  49.56  speaker_0 -> caio
   50.30  51.47  speaker_1 -> bia
   52.09  55.25  speaker_0 -> caio
ana@lab:~/mm$ python who.py media/call-1042-noisy.wav 0.5
media/call-1042-noisy.wav at 0.5: 6 speakers found, 10 segments, 98.6% of the speech given to the right person
ana@lab:~/mm$ python who.py call-gtcrn.wav 0.5
call-gtcrn.wav at 0.5: 6 speakers found, 9 segments, 97.6% of the speech given to the right person
ana@lab:~/mm$ python who.py media/call-1042-phone.wav 0.5
media/call-1042-phone.wav at 0.5: 4 speakers found, 9 segments, 97.6% of the speech given to the right person
ana@lab:~/mm$ python who.py media/call-1042-noisy.wav 0.5 2
media/call-1042-noisy.wav at 0.5: 2 speakers found, 9 segments, 98.6% of the speech given to the right person
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Três faixas ao longo dos 55 segundos da ligação. Em cima, a verdade: nove falas alternando entre Caio e Bia. No meio, o diarizador na ligação limpa: dez segmentos que seguem as falas, com speaker 0 para toda fala do Caio e speaker 1 para as da Bia, exceto o fim da primeira fala dela, de 11,98 a 14,34 segundos, que ganha um terceiro rótulo, speaker 3. Embaixo, o detector de fala na ligação ruidosa: cinco trechos longos, cada um atravessando duas ou mais falas.\"><text x=\"20\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">verdade</text><rect x=\"150.0\" y=\"24\" width=\"52.756317689530675\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"176.37815884476532\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"209.7057761732852\" y=\"24\" width=\"83.99909747292423\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"251.7053249097473\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"298.6687725631769\" y=\"24\" width=\"89.32039711191334\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.3289711191336\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"396.9241877256318\" y=\"24\" width=\"44.704873646209364\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"419.27662454873644\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"447.58574007220216\" y=\"24\" width=\"82.86732851985573\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"489.01940433213\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"538.3953068592057\" y=\"24\" width=\"23.399819494585017\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"550.0952166064982\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"565.7662454873646\" y=\"24\" width=\"76.99007220216617\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"604.2612815884477\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><rect x=\"649.7057761732852\" y=\"24\" width=\"13.025270758122701\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"656.2184115523467\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">B</text><rect x=\"667.6949458483755\" y=\"24\" width=\"32.13628158844767\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"683.7630866425993\" y=\"36\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">C</text><text x=\"20\" y=\"86\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">diarizador, limpa</text><rect x=\"150.29783393501805\" y=\"74\" width=\"52.61732851985559\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"176.60649819494586\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"209.76534296028882\" y=\"74\" width=\"59.169675090252724\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"239.35018050541518\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"268.93501805054154\" y=\"74\" width=\"23.429602888086606\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--paper)\" stroke-width=\"1.5\"></rect><text x=\"280.64981949458485\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">3</text><rect x=\"298.71841155234654\" y=\"74\" width=\"88.85379061371845\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"343.1453068592058\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"397.10288808664257\" y=\"74\" width=\"42.88808664259932\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"418.5469314079422\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"447.63537906137185\" y=\"74\" width=\"82.59927797833939\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"488.93501805054154\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"538.2761732851986\" y=\"74\" width=\"22.138989169675142\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"549.3456678700362\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"565.7761732851986\" y=\"74\" width=\"76.24548736462089\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"603.8989169675091\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><rect x=\"649.3682310469314\" y=\"74\" width=\"11.615523465703973\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"655.1759927797834\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">1</text><rect x=\"667.1389891696751\" y=\"74\" width=\"31.37184115523462\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"682.8249097472924\" y=\"86\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">0</text><text x=\"281.0469314079422\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">speaker 3</text><text x=\"20\" y=\"146\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">VAD, ruidosa</text><rect x=\"153.27617328519855\" y=\"134\" width=\"141.9675090252708\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"299.0162454873646\" y=\"134\" width=\"207.39169675090255\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"509.3862815884477\" y=\"134\" width=\"26.70577617328513\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"538.8718411552347\" y=\"134\" width=\"108.41155234657037\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><rect x=\"650.0631768953069\" y=\"134\" width=\"49.53971119133564\" height=\"24\" rx=\"1\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"150.0\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 s</text><text x=\"249.27797833935017\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">10 s</text><text x=\"348.55595667870034\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 s</text><text x=\"447.83393501805057\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">30 s</text><text x=\"547.1119133574007\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">40 s</text><text x=\"646.389891696751\" y=\"182\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">50 s</text><text x=\"20\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">C é Caio e B é Bia; um número é o rótulo que o diarizador deu.</text></svg>", "caption": "Na ligação limpa as fronteiras do diarizador ficam a um décimo de segundo da verdade; na ruidosa o detector de fala nem encontra os intervalos."}
```

Na ligação limpa **98,1% da fala foi para a pessoa certa**, e cada fronteira fica a cerca de um décimo de segundo da verdade. Mas o diarizador achou **três pessoas numa ligação de duas**: o fim da primeira fala da Bia, de 11,98 a 14,34 segundos, virou `speaker_3`. A voz não mudou; o modelo do pyannote cortou a fala dela em duas e o embedding da segunda metade caiu longe o bastante do da primeira. Essa é a falha mais comum da diarização: **gente demais**, cada pessoa a mais sendo um fragmento de uma real.

O ruído piorou a contagem e não piorou o tempo. Na ligação ruidosa ele achou seis pessoas, depois do GTCRN seis, na linha telefônica quatro, e em todos os casos 97,6% ou mais da fala ainda foi para a pessoa certa, porque os rótulos a mais cobriam fragmentos curtos. O último comando diz ao diarizador que são duas pessoas, e ele acha exatamente duas.

## O limite, e o número que você talvez já saiba

```
ana@lab:~/mm$ for t in 0.3 0.5 0.7 0.9; do python who.py media/call-1042.wav $t; done
media/call-1042.wav at 0.3: 6 speakers found, 11 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.5: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.7: 3 speakers found, 10 segments, 98.1% of the speech given to the right person
media/call-1042.wav at 0.9: 2 speakers found, 9 segments, 98.1% of the speech given to the right person
```

O **limite** de agrupamento é quão distantes dois vetores de voz podem estar e ainda contar como uma pessoa. Subi-lo junta mais: com 0,3 seis pessoas, com 0,9 as duas certas. A nota quase não se move, porque as pessoas a mais desta ligação são fragmentos curtos, mas uma transcrição com seis pessoas numa ligação de duas está errada de um jeito que todo leitor percebe.

**Quando o número de pessoas é conhecido, entregue-o ao modelo.** Uma ligação de suporte tem duas pessoas; uma reunião tem as pessoas do convite. Com `speakers=2` o agrupamento deixa de adivinhar quantos grupos existem e só decide que pedaço vai para onde, e essa é a metade fácil do problema. Na ligação ruidosa ele achou exatamente duas, com 98,6% da fala atribuída corretamente.

E lembre a diarização mais barata de todas, da seção 02: **dois canais, um por pessoa**. Uma ligação gravada assim não precisa de nada disso.
