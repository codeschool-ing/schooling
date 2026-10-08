---
title: Conferindo citações
version: 2
---

Uma citação é uma afirmação: *esta frase vem daquela fonte.* Como qualquer afirmação de um modelo, ela
pode estar errada, e diferente da maioria, pode ser conferida mecanicamente, porque as duas metades são
texto que o programa tem. O `verify.py` confere cada frase de uma resposta contra a fonte que ela cita:

```schooling-example
{
  "language": "python",
  "file": "verify.py",
  "parts": [
    {
      "code": "import re\n\nfrom vectors import embed\n\nCLOSE = 0.75\nnorm = lambda t: \" \".join(t.split())",
      "note": "`CLOSE` é a similaridade acima da qual uma frase conta como uma versão fiel de uma frase da fonte. É um julgamento, e 0,75 é o deste curso."
    },
    {
      "code": "def claims(reply):\n    \"\"\"(sentence, source number or None) for every sentence of a reply. A model told to cite like\n    [1] may put the number anywhere: \"... [1]\", \"According to [1], ...\", \"[2] states that ...\".\"\"\"\n    out = []\n    for sentence in re.split(r\"(?<=[.!?\\]])\\s+(?=[A-Z])\", reply.strip()):\n        numbers = re.findall(r\"\\[(\\d+)\\]\", sentence)\n        if not numbers:\n            out.append((sentence, None))\n            continue\n        text = re.sub(r\"^According to (source )?\\[\\d+\\],?\\s*\", \"\", sentence)\n        text = norm(re.sub(r\"\\s*\\[\\d+\\]\", \"\", text))\n        out.append((text[:1].upper() + text[1:], int(numbers[0])))\n    return out",
      "note": "Uma resposta dividida em frases, cada uma com o número da fonte que ela cita, ou `None` quando não cita nenhuma. A instrução mostra o número no fim, *like [1]*, e o llama3.2:3b o põe onde quer: no começo, *According to [1], ...*, ou no meio, *[2] states that ...*. Então o número é procurado em qualquer lugar da frase, o primeiro vale, e os números e o *According to* saem, com a maiúscula de volta, para que o que sobra possa ser procurado na fonte."
    },
    {
      "code": "def check(reply, sources):\n    \"\"\"A verdict for every sentence: quoted, close, unsupported, uncited, no such source, or quoted\n    in another source than the one cited.\"\"\"\n    verdicts = []\n    for sentence, n in claims(reply):\n        if n is None:\n            verdicts.append((sentence, n, \"uncited\"))\n            continue\n        if not 0 < n <= len(sources):\n            verdicts.append((sentence, n, \"no such source\"))\n            continue\n        text = norm(sources[n - 1][\"text\"])\n        if norm(sentence) in text:\n            verdicts.append((sentence, n, \"quoted\"))\n            continue\n        elsewhere = [m for m, other in enumerate(sources, 1) if norm(sentence) in norm(other[\"text\"])]\n        if elsewhere:\n            verdicts.append((sentence, n, f\"in [{elsewhere[0]}], not [{n}]\"))\n            continue\n        parts = [p for p in re.split(r\"(?<=[.!?])\\s+\", text) if p]\n        best = float((embed(parts) @ embed(sentence)[0]).max())\n        verdicts.append((sentence, n, f\"close ({best:.2f})\" if best >= CLOSE else f\"unsupported ({best:.2f})\"))\n    return verdicts",
      "note": "Para cada frase, na ordem do teste mais barato: tem citação; a fonte existe; está citada palavra por palavra; está citada palavra por palavra em outra fonte; e, por último, alguma frase da fonte tem sentido próximo."
    }
  ]
}
```

## Uma resposta com dois erros

Um verificador precisa ser visto dando cada um dos seus vereditos antes de receber a resposta de um
modelo. Então a resposta abaixo **foi escrita pelo curso, não por modelo nenhum**, para pôr num lugar só
dois erros que modelos cometem. Ela é conferida contra as fontes reais que a busca devolveu para a
pergunta do reembolso:

```schooling-example
{
  "language": "python",
  "file": "made_up.py",
  "parts": [
    {
      "code": "from answer import sources_for\nfrom verify import check\n\n# A reply WRITTEN BY THE COURSE, not by any model, imitating two mistakes real\n# models make: a true sentence cited to the wrong source, and a sentence no\n# source says.\nreply = (\"We refund within three working days of the return reaching our warehouse. [2] \"\n         \"Your bank may take another five to ten days to show it. [1] \"\n         \"Refunds are always paid as store credit. [1]\")",
      "note": "A resposta é escrita à mão, para que todo veredito que o verificador pode dar apareça numa execução só."
    },
    {
      "code": "sources = sources_for(\"How long after my return arrives will I get the refund?\")\nfor n, s in enumerate(sources, 1):\n    print(f\"[{n}] {s['path']}\")\nfor sentence, n, verdict in check(reply, sources):\n    print(f\"{verdict:20} [{n}] {sentence}\")",
      "note": "As fontes reais que a busca devolve para a pergunta do reembolso, e o veredito do verificador sobre cada frase."
    }
  ]
}
```
```
ana@vm:~/rag$ python made_up.py
[1] Returns and refunds policy > Refunds
[2] Returns and refunds policy > The return window
[3] Returns and refunds policy > Items sold by marketplace sellers
in [1], not [2]      [2] We refund within three working days of the return reaching our warehouse.
close (0.79)         [1] Your bank may take another five to ten days to show it.
unsupported (0.50)   [1] Refunds are always paid as store credit.
```

**A primeira frase é verdadeira e citada para a fonte errada.** Está citada palavra por palavra, mas de
`[1]`, não de `[2]`. É o tipo de erro mais convincente, porque a frase está certa e um leitor que confere
a afirmação, e não o ponteiro, fica satisfeito. O verificador o pega porque procura a frase em todas as
fontes, não só na citada.

**A segunda é uma paráfrase fiel.** *Your bank may take another five to ten days to show it* é parte de
uma frase mais longa em `[1]`, e a similaridade com essa frase é 0,79, acima dos 0,75 que o verificador
trata como próximo. Um modelo que parafraseia em vez de citar produz frases assim o tempo todo, e uma
verificação que só aceitasse citações exatas marcaria todas.

**A terceira não está em fonte nenhuma.** *Refunds are always paid as store credit* é uma frase plausível,
perto da regra do vale-presente, e falsa para todo pedido pago com cartão. A melhor similaridade dela com
a fonte citada é 0,50, e o verificador a marca como sem apoio.

## A mesma verificação numa resposta real

```schooling-example
{
  "language": "python",
  "file": "check_reply.py",
  "parts": [
    {
      "code": "import sys\n\nfrom answer import answer\nfrom verify import check\n\nreply, sources = answer(sys.argv[1])\nprint(reply)\nfor sentence, n, verdict in check(reply, sources):\n    print(f\"  {verdict:18} [{n}] {sentence[:60]}\")",
      "note": "A resposta do próprio modelo para uma pergunta, e o veredito sobre cada frase dela."
    }
  ]
}
```
```
ana@vm:~/rag$ python check_reply.py "How long after my return arrives will I get the refund?"
According to [1], the money goes back to the card or account you paid with, and your bank may take another five to ten days to show it. This means that the refund processing time is at least 5-10 days after the return reaches the warehouse.

However, [2] states that the return window starts on the day the carrier records the parcel as delivered, not on the day you placed the order. This implies that the refund processing time may be shorter than 5-10 days, as it depends on when the carrier records the parcel as delivered.

To clarify, I would recommend checking the seller's policy, as mentioned in [3], as they may have a different return window and refund processing time.
  quoted             [1] The money goes back to the card or account you paid with, an
  uncited            [None] This means that the refund processing time is at least 5-10 
  unsupported (0.70) [2] However, states that the return window starts on the day the
  uncited            [None] This implies that the refund processing time may be shorter 
  unsupported (0.73) [3] To clarify, I would recommend checking the seller's policy, 
```

**Uma frase citada literalmente e as outras quatro reprovadas**, que é a resposta que a última seção
leu a olho, agora lida por um programa. A citação literal é a dos cinco a dez dias do banco. As duas
conclusões que o modelo tirou, *at least 5-10 days* e *may be shorter*, não citam nada. O prazo de
devolução, citado para `[2]` no meio da frase, marca 0,70 contra as frases de `[2]`, perto da linha e
abaixo dela: é um relato justo da fonte com o *However, states that* do modelo na frente, e o
verificador não enxerga além das palavras. O conselho de conferir a política do vendedor marca 0,73
contra `[3]`, que não diz nada disso.

Rodado em muitas respostas, o mesmo programa dá uma taxa que vale medir. A aula 8 chama essa taxa de
**fidelidade** e a mede sobre o conjunto de teste.

## O que fazer com uma verificação que falhou

Três respostas, da mais barata à mais cuidadosa: **tirar a frase** que falhou e mostrar o resto; **mostrar
a resposta com um aviso** na frase; ou **gerar de novo**, pedindo ao modelo outra vez com a falha
apontada. Qual delas depende do uso, e a tabela da aula 2 vale aqui: um assistente jurídico nunca deveria
mostrar uma frase sem apoio, uma central de ajuda pode mostrar uma paráfrase marcada como *próxima*.
