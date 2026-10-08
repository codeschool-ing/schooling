---
title: Citação literal, para respostas que obrigam
version: 2
---

A aula 2 disse que um leitor jurídico precisa do texto que obriga, localizado com exatidão, na versão que
estava em vigor. Quase tudo isso já existe: a busca pode ser filtrada para os documentos certos, toda
fonte leva a data, e o verificador confirma que uma frase foi citada palavra por palavra. Falta uma peça,
o número da cláusula. Na aula 2 o modelo calhou de copiá-lo para a resposta, *section 2.2*, porque ele
estava no texto que leu, enquanto a citação em si nomeava só o título, *2. Placing an order*. Um número
que o modelo calha de copiar não é uma citação em que um programa possa confiar.

O número está no texto da fonte, logo antes da cláusula. O `clause.py` o procura ali:

```schooling-example
{
  "language": "python",
  "file": "clause.py",
  "parts": [
    {
      "code": "import re\nimport sys\n\nfrom answer import answer\nfrom verify import claims, norm\n\nreply, sources = answer(sys.argv[1])",
      "note": "A resposta e as fontes que ela recebeu."
    },
    {
      "code": "for sentence, n in claims(reply):\n    print(f\"\\\"{sentence}\\\"\")\n    if n is None or not 0 < n <= len(sources):\n        print(\"  cites no source, so no clause\")\n        continue\n    source = sources[n - 1]\n    text = norm(source[\"text\"])\n    at = text.find(norm(sentence)[:30])\n    if at < 0:\n        print(f\"  {source['path']}: not quoted, so no clause\")\n        continue\n    numbers = re.findall(r\"(?:^|\\s)(\\d+\\.\\d+)\\s\", text[:at])\n    print(f\"  {source['path']}, clause {numbers[-1] if numbers else '?'}, updated {source['updated']}\")",
      "note": "Para cada frase, onde os primeiros trinta caracteres dela começam na fonte que ela cita, e o último número de cláusula no texto antes desse ponto. Uma frase que não cita nada, ou que não está na fonte palavra por palavra, não tem lugar no texto antes do qual procurar, e o programa diz isso em vez de adivinhar."
    }
  ]
}
```
```
ana@vm:~/rag$ python clause.py "When is the contract of sale formed?"
"According to the sources, the contract of sale is formed when the customer sends the email confirming that their order has been dispatched, as stated in."
  Terms of sale > 11. Changes to these terms: not quoted, so no clause
"This is because the email confirming receipt of the order is not an acceptance, but rather the acceptance is implied when the order is dispatched, as stated in."
  Terms of sale > 11. Changes to these terms: not quoted, so no clause
```

**O modelo parafraseou, e errou a parte de novo.** Na aula 2 ele disse que o vendedor manda o
e-mail; aqui diz que *the customer* manda. A cláusula 2.2 diz *we*, que é a Marginalia. Nenhuma das
frases está na fonte palavra por palavra, então o `clause.py` não tem lugar no texto antes do qual
procurar, e diz isso em vez de adivinhar. As duas citam a seção dos termos de venda sobre mudanças nos
termos, que não é onde está a resposta.

O programa funciona quando a resposta cita literalmente. Ele olha o texto da fonte antes da frase
citada e pega o último número de cláusula que encontra ali, e funciona porque os documentos numeram as
cláusulas de modo consistente; em documentos que não numeram, o número tem de ser acrescentado aos
metadados do pedaço quando o documento é cortado, do jeito que a aula 5 acrescenta o caminho. E uma
resposta que parafraseia uma cláusula, como esta, falhou antes de qualquer número ser procurado.

## Literal, e conferido

Para um uso em que a redação importa, o prompt pede citações em vez de respostas: *cite literalmente a
cláusula que responde à pergunta, com o número dela*. Um modelo real em geral obedece, e de vez em quando
troca uma palavra ao citar, *may* por *must*, *delivered* por *dispatched*, porque a paráfrase é o que o
treinamento dele recompensa. Então a verificação de antes nesta aula fica estrita: **uma resposta
jurídica só passa se toda frase citada aparecer na fonte caractere por caractere**, e uma frase só
próxima é uma falha, não uma paráfrase.

## Suporte do provedor a citações

A Messages API da Anthropic consegue fazer parte disso sozinha. Fontes mandadas como blocos `document`
com citações ativadas voltam com cada parte da resposta presa a um intervalo de caracteres num
documento, então o programa recebe o trecho exato em vez de um número para procurar. O endpoint do
Ollama compatível com a Anthropic não implementa isso, e a aula 9 mostra a recusa com que ele responde.
Onde um provedor implementa, a verificação continua não sumindo: um intervalo diz de onde o provedor
afirma que o texto veio, e um programa que importa ainda confirma que o texto está lá.
