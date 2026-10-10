---
title: Tokens são a conta
version: 1
---

Um modelo é limitado e cobrado por tokens, nunca por palavras ou caracteres. **O contexto dele, o texto
que consegue ler de uma vez, é um número de tokens.** O tempo por passo cresce com o número de tokens, e
um fornecedor que vende acesso a um modelo cobra por token. Então a pergunta que importa sobre um
tokenizador é em quantos tokens o seu texto se transforma, e a resposta depende do texto em que o
tokenizador foi treinado.

O `tok.json` foi treinado em quarenta e cinco linhas de inglês. Salve isto como `~/dl/bill.py` para ver
o que ele faz com o português:

```schooling-example
{
  "language": "python",
  "file": "bill.py",
  "parts": [
    {
      "code": "\"\"\"bill: the same sentences in English and in Portuguese, counted in tokens.\"\"\"\nfrom tokenizers import Tokenizer\n\ntok = Tokenizer.from_file(\"tok.json\")\nPAIRS = [\n    (\"On Monday the baker sells bread.\", \"Na segunda-feira o padeiro vende pão.\"),\n    (\"The goat eats apples, and the cow eats hay.\", \"A cabra come maçãs, e a vaca come feno.\"),\n    (\"The weaver mends the blankets before winter.\", \"O tecelão remenda os cobertores antes do inverno.\"),\n]",
      "note": "Três frases e o português delas. As duas primeiras usam palavras do corpus; a terceira usa palavras que ele nunca conteve, em nenhuma das duas línguas."
    },
    {
      "code": "print(f\"{'':4}{'chars':>6}{'bytes':>6}{'tokens':>7}\")\ntotal = {\"en\": 0, \"pt\": 0}\nfor en, pt in PAIRS:\n    for lang, s in ((\"en\", en), (\"pt\", pt)):\n        n = len(tok.encode(s).ids)\n        total[lang] += n\n        print(f\"{lang:4}{len(s):6d}{len(s.encode()):6d}{n:7d}  {s}\")\nprint(\"tokens, en:\", total[\"en\"], \" pt:\", total[\"pt\"], f\" ratio: {total['pt'] / total['en']:.2f}\")\nprint(\"' pão' ->\", [tok.decode([i]) for i in tok.encode(\" pão\").ids])",
      "note": "Cada frase medida de três jeitos: caracteres, bytes em UTF-8 e tokens do `tok.json`."
    },
    {
      "code": "CONTEXT = 512   # tokens the model reads at once: an illustrative size\nPRICE = 2.00    # money per million tokens: an illustrative price, not anybody's\nfor lang in (\"en\", \"pt\"):\n    per = total[lang] / len(PAIRS)\n    print(f\"{lang}: {per:.1f} tokens a sentence, {int(CONTEXT // per)} sentences fit in {CONTEXT}, \"\n          f\"a million sentences cost {per * PRICE:.2f}\")",
      "note": "Os dois números que transformam uma contagem de tokens em consequências. Os dois foram inventados para a conta, e os comentários dizem isso."
    }
  ]
}
```

```
PENDING bill
```

## O mesmo sentido, o dobro de tokens

**O português custa 86 tokens onde o inglês custa 41, uma razão de 2,10**, para frases que dizem a
mesma coisa em mais ou menos o mesmo número de caracteres. O primeiro par é o extremo: 7 tokens em
inglês, porque cada palavra dele é uma entrada inteira, e 28 em português, três tokens a cada quatro
caracteres. Nenhuma fusão que o treinador aprendeu era sobre português, então `padeiro` cai em pedaços
pequenos de inglês.

Olhe a coluna de bytes. `pão` tem três caracteres e quatro bytes, porque o UTF-8 gasta dois bytes no
`ã`, e o tokenizador de bytes dá a cada um desses bytes um token próprio. Na linha que começa com
`' pão'`, os dois `�` são essas metades: cada um é um byte que não é um caractere sozinho, então não dá
para imprimi-lo isolado.

O terceiro par é mais justo, já que nenhuma das duas frases estava no corpus: 20 tokens contra 30. **O
inglês ainda ganha, sem frase nenhuma para ter decorado**, porque os pedaços em que ele se quebra,
` the`, `er`, ` w`, são pedaços que o treinador viu o tempo todo.

## Quanto a razão custa

As duas últimas linhas transformam tokens em consequências com dois números inventados, e o programa
diz que são inventados. Com um contexto de 512 tokens, o modelo lê 37 destas frases em inglês de uma
vez, e só 17 das em português. A um preço de 2,00 por milhão de tokens, um milhão de frases em inglês
custa 27,33 e um milhão em português, 57,33. Os números são inventados, a razão não. **Qualquer que seja
o preço e qualquer que seja o contexto, os dois crescem com a contagem de tokens.** Uma língua que o
tokenizador trata mal é lida em pedaços menores e cobrada mais pelo mesmo sentido.

Os tokenizadores de modelos de linguagem de verdade são treinados em muito mais texto e em muitas
línguas, então a diferença deles entre inglês e português é bem menor que esta. Ela raramente é zero, e
esta aula não mediu nenhum, porque o laboratório não consegue baixá-los. O jeito de saber para o seu
próprio texto é o usado aqui: codificar uma amostra e contar. A atenção da aula 15 compara cada token
com todos os outros, então o custo dela cresce com o quadrado da contagem. Um texto duas vezes mais
longo em tokens dá cerca de quatro vezes o trabalho nessa parte do modelo.
