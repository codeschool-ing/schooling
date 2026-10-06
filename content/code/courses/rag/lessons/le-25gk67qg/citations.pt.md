---
title: Citações
version: 1
---

Uma resposta com `[1]` e `[3]` é meia citação. A outra metade é o que o leitor vê: um link ou uma nota
dizendo que documento, que seção e quão atual. Transformar os números nisso é trabalho do programa,
porque o modelo só conhece os números que recebeu.

```schooling-example
{
  "language": "python",
  "file": "answer.py",
  "parts": [
    {
      "code": "def ask(question, sources):\n    reply = client.chat.completions.create(model=\"extract-1\", messages=[\n        {\"role\": \"system\", \"content\": SYSTEM},\n        {\"role\": \"user\", \"content\": prompt(question, sources)}])\n    return reply.choices[0].message.content",
      "note": "Uma chamada, a mensagem de sistema e as fontes numeradas. Qualquer modelo compatível com a OpenAI pode entrar no lugar, pelo nome."
    },
    {
      "code": "def answer(question, **filters):\n    \"\"\"The reply and its sources; with no source above the floor, the refusal, and no model call.\"\"\"\n    sources = sources_for(question, **filters)\n    if not sources:\n        return REFUSAL, []\n    return ask(question, sources), sources",
      "note": "Sem nada acima do piso, a recusa é devolvida pelo código e o modelo nem é chamado. A seção sobre recusar mostra por que a instrução sozinha não basta."
    },
    {
      "code": "def citations(reply, sources):\n    \"\"\"Each [n] in the reply, with the source it points at, or None if there is no such source.\"\"\"\n    return [(int(n), sources[int(n) - 1] if 0 < int(n) <= len(sources) else None)\n            for n in re.findall(r\"\\[(\\d+)\\]\", reply)]",
      "note": "Cada `[n]` da resposta, emparelhado com a fonte para que aponta. Um número sem fonte por trás fica como `None`, porque uma citação para nada é um achado, não algo a descartar."
    },
    {
      "code": "if __name__ == \"__main__\":\n    reply, sources = answer(sys.argv[1])\n    print(reply)\n    shown = set()\n    for n, s in citations(reply, sources):\n        if n not in shown:\n            shown.add(n)\n            print(f\"  [{n}] {s['path']}, updated {s['updated']}\" if s else f\"  [{n}] points at no source\")",
      "note": "Rodado como programa: a resposta, depois cada fonte citada, uma vez, com caminho e data."
    }
  ]
}
```

## Duas respostas, com suas fontes

```
ana@lab:~/rag$ python answer.py "How long after my return arrives will I get the refund?"
We refund within three working days of the return reaching our warehouse. [1] Every seller must accept returns for at least 14 days from delivery, and many accept them for longer. [3] If a seller does not answer a return request within two working days, open a claim from the order and we decide it. [3]
  [1] Returns and refunds policy > Refunds, updated 2026-02-02
  [3] Returns and refunds policy > Items sold by marketplace sellers, updated 2026-02-02
```

**A resposta é a primeira frase, de `[1]`, a seção de reembolsos.** As duas frases seguintes são sobre
vendedores do marketplace, de `[3]`: verdadeiras, citadas, e sem nada a ver com a pergunta. O extract-1
as escolheu porque falam de devoluções e prazos, e um modelo real com as mesmas três fontes teria mais
chance de deixá-las de fora. As citações tornam o problema visível: quem lê vê que dois terços da
resposta vieram de uma seção sobre vendedores do marketplace e pode julgar.

As notas impressas são o que um assistente de atendimento mostraria como links. Elas levam o caminho e a
data, então um cliente que lê *updated 2026-02-02* sabe que a regra é deste ano, e um líder de
atendimento lendo uma reclamação consegue abrir a seção exata.

## O que uma citação deveria identificar

| parte | por quê |
| --- | --- |
| o documento | para o leitor poder abri-lo |
| a seção, ou a cláusula | para o leitor não ter de procurar no documento |
| a versão ou a data | para o leitor saber que estava em vigor |
| um link que funciona | para a citação ser usada, e não admirada |

Uma citação que só nomeia um documento é melhor que nada e muito pior que uma que nomeia a seção: a aula
2 viu que leitores jurídicos precisam da cláusula, e a seção sobre citação literal mais abaixo a encontra.

## Citação não é enfeite

Dois hábitos transformam citações em algo em que as pessoas confiam e depois param de ler. **Citar uma
fonte que a resposta não usou**, falha comum quando se manda um modelo citar e ele enche a lista. E
**citar a fonte certa para a frase errada**, que parece perfeito na tela. Os dois podem ser detectados por
um programa, e a próxima seção o escreve.
