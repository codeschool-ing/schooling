---
title: Conferindo citações
version: 1
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
      "code": "import re\n\nfrom minilm import embed\n\nCLOSE = 0.75\nnorm = lambda t: \" \".join(t.split())",
      "note": "`CLOSE` é a similaridade acima da qual uma frase conta como uma versão fiel de uma frase da fonte. É um julgamento, e 0,75 é o deste laboratório."
    },
    {
      "code": "def claims(reply):\n    \"\"\"(sentence, source number or None) for every sentence of a reply.\"\"\"\n    out = []\n    for sentence in re.split(r\"(?<=[.!?\\]])\\s+(?=[A-Z])\", reply.strip()):\n        m = re.match(r\"(.*?)\\s*\\[(\\d+)\\]$\", sentence)\n        out.append((m.group(1), int(m.group(2))) if m else (sentence, None))\n    return out",
      "note": "Uma resposta dividida em frases, cada uma com o número no fim, ou `None` quando não tem."
    },
    {
      "code": "def check(reply, sources):\n    \"\"\"A verdict for every sentence: quoted, close, unsupported, uncited, no such source, or quoted\n    in another source than the one cited.\"\"\"\n    verdicts = []\n    for sentence, n in claims(reply):\n        if n is None:\n            verdicts.append((sentence, n, \"uncited\"))\n            continue\n        if not 0 < n <= len(sources):\n            verdicts.append((sentence, n, \"no such source\"))\n            continue\n        text = norm(sources[n - 1][\"text\"])\n        if norm(sentence) in text:\n            verdicts.append((sentence, n, \"quoted\"))\n            continue\n        elsewhere = [m for m, other in enumerate(sources, 1) if norm(sentence) in norm(other[\"text\"])]\n        if elsewhere:\n            verdicts.append((sentence, n, f\"in [{elsewhere[0]}], not [{n}]\"))\n            continue\n        parts = [p for p in re.split(r\"(?<=[.!?])\\s+\", text) if p]\n        best = float((embed(parts) @ embed(sentence)[0]).max())\n        verdicts.append((sentence, n, f\"close ({best:.2f})\" if best >= CLOSE else f\"unsupported ({best:.2f})\"))\n    return verdicts",
      "note": "Para cada frase, na ordem do teste mais barato: tem citação; a fonte existe; está citada palavra por palavra; está citada palavra por palavra em outra fonte; e, por último, alguma frase da fonte tem sentido próximo."
    }
  ]
}
```

## Uma resposta com dois erros

O extract-1 não consegue errar uma citação: ele copia uma frase e acrescenta o número da fonte de onde a
copiou. Então, para ver o verificador pegar alguma coisa, a resposta abaixo **foi escrita pelo curso, não
por modelo nenhum**, para imitar dois erros que modelos reais cometem. Ela é conferida contra as fontes
reais que a busca devolveu para a pergunta do reembolso:

```
ana@lab:~/rag$ python made_up.py
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

```
ana@lab:~/rag$ python check_reply.py "How long after my return arrives will I get the refund?"
We refund within three working days of the return reaching our warehouse. [1] Every seller must accept returns for at least 14 days from delivery, and many accept them for longer. [3] If a seller does not answer a return request within two working days, open a claim from the order and we decide it. [3]
  quoted             [1] We refund within three working days of the return reaching o
  quoted             [3] Every seller must accept returns for at least 14 days from d
  quoted             [3] If a seller does not answer a return request within two work
```

As três frases do extract-1 estão citadas, que é o que copiar frases garante. Rodado nas respostas de um
modelo real, o mesmo programa acha os casos acima numa taxa que vale medir; a aula 8 chama essa taxa de
**fidelidade** e a mede sobre o conjunto de teste.

## O que fazer com uma verificação que falhou

Três respostas, da mais barata à mais cuidadosa: **tirar a frase** que falhou e mostrar o resto; **mostrar
a resposta com um aviso** na frase; ou **gerar de novo**, pedindo ao modelo outra vez com a falha
apontada. Qual delas depende do uso, e a tabela da aula 2 vale aqui: um assistente jurídico nunca deveria
mostrar uma frase sem apoio, uma central de ajuda pode mostrar uma paráfrase marcada como *próxima*.
