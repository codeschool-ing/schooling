---
title: Por que não colocar tudo no prompt
version: 2
---

Se um documento no prompt resolve uma pergunta, os treze deveriam resolver todas. É a primeira ideia
que todo mundo tem, e para um corpus pequeno o bastante e uma janela grande o bastante ela até
funciona. Medida neste, ela falha antes de o modelo escrever uma palavra, e os motivos da falha
continuam valendo muito depois de a janela ficar grande o bastante.

## Contando o corpus

Um modelo lê, e um provedor cobra, em tokens, então o corpus também tem de ser contado em tokens. O
`count.py` usa o `cl100k_base` do tiktoken, a codificação pela qual a OpenAI cobra os modelos GPT-4.
O llama3.2 divide o texto com um tokenizador próprio, e conta alguns por cento diferente; o curso usa
o tiktoken sempre que conta um texto que ainda não mandou, porque é rápido, não precisa de modelo
rodando, e é a contagem que um provedor pago cobraria.

```schooling-example
{
  "language": "python",
  "file": "count.py",
  "parts": [
    {
      "code": "import glob\nimport tiktoken\n\nenc = tiktoken.get_encoding(\"cl100k_base\")",
      "note": "O tiktoken é o tokenizador da OpenAI; `cl100k_base` é a codificação da geração GPT-4."
    },
    {
      "code": "total = 0\nfor path in sorted(glob.glob(\"data/docs/*.md\")):\n    n = len(enc.encode(open(path).read()))\n    total += n\n    print(f\"{n:6,}  {path}\")\nprint(f\"{total:6,}  in all\")",
      "note": "O tamanho de cada documento em tokens, e o total."
    }
  ]
}
```

```
ana@vm:~/rag$ python count.py
   816  data/docs/affiliate-api.md
   660  data/docs/ebooks-and-audiobooks.md
   483  data/docs/finance-refund-controls.md
   342  data/docs/gift-cards.md
   617  data/docs/payments-and-invoices.md
   626  data/docs/privacy-notice.md
   403  data/docs/returns-policy-2025.md
 1,113  data/docs/returns-policy.md
   726  data/docs/seller-agreement.md
   845  data/docs/shipping-and-delivery.md
   906  data/docs/support-handbook.md
   841  data/docs/terms-of-sale.md
   536  data/docs/warehouse-runbook.md
 8,914  in all
```

**8.914 tokens para 6.843 palavras**, cerca de 1,3 token por palavra, o normal para prosa em inglês com
alguns números e identificadores. O `everything.py` põe os treze num prompt só, numerados, e pergunta
o preço da entrega expressa:

```schooling-example
{
  "language": "python",
  "file": "everything.py",
  "parts": [
    {
      "code": "import glob\nfrom openai import OpenAI\n\nclient = OpenAI()\nsources = \"\"\nfor i, path in enumerate(sorted(glob.glob(\"data/docs/*.md\")), 1):\n    sources += f\"[{i}] {path}\\n{open(path).read()}\\n\"",
      "note": "Os treze documentos, numerados, numa string só."
    },
    {
      "code": "reply = client.chat.completions.create(\n    model=\"llama3.2:3b\",\n    temperature=0,\n    messages=[{\"role\": \"user\", \"content\": sources + \"Question: How much is express delivery?\"}],\n)\nprint(reply.choices[0].message.content)\nprint(\"prompt tokens:\", reply.usage.prompt_tokens)",
      "note": "Uma pergunta, e quantos tokens da requisição o modelo diz ter lido."
    }
  ]
}
```

```
ana@vm:~/rag$ python everything.py
Here is a response to the customer's question about express delivery:

Dear [Customer],

Yes, express delivery is available for an additional fee. The cost is [insert cost] and delivery is typically [insert timeframe, e.g. "next day" or "2-3 working days"].

Please note that express delivery is only available for orders placed before [insert cutoff time, e.g. "12pm"] and is subject to availability.

If you would like to upgrade to express delivery, please contact us at [insert contact email or phone number] and we will be happy to assist you.

Best regards,
[Your Name]

Note: I've followed the guidelines provided, including:

* Starting with a clear and concise answer to the customer's question
* Providing additional information about express delivery, such as the cost and timeframe
* Mentioning any limitations or cutoff times for express delivery
* Including a clear call to action for the customer to contact support if they would like to upgrade to express delivery
* Signing off with a professional closing and your name.
prompt tokens: 2050
```

**O modelo leu 2.050 tokens de um prompt umas quatro vezes e meia maior, e nada recusou.** O Ollama
serve o llama3.2:3b com uma janela de 4.096 tokens e guarda espaço nela para a resposta, então cortou o
prompt para caber e mandou o resto ao modelo. O próprio log dele, que o `journalctl -u ollama` mostra
na VM, disse isso numa linha que ninguém lê:

```
level=WARN msg="truncating input prompt" limit=2050 prompt=9094 keep=4 new=2050
```

O que sobrou foi o fim: a pergunta e, antes dela, mais ou menos os dois últimos documentos e meio em
ordem alfabética, o fim do manual de atendimento, os termos de venda e o manual do armazém. O preço da
entrega expressa está no `shipping-and-delivery.md`, o décimo documento, e foi cortado antes de o
modelo vê-lo. Então o modelo fez o que faz com uma pergunta e nenhuma resposta à vista: escreveu um
modelo de resposta de atendimento, com `[insert cost]` onde deveria estar o preço, e depois uma nota
dizendo que tinha seguido as orientações, as regras do manual de atendimento para os atendentes, que
sobreviveram ao corte.

Duas coisas valem a pena levar disto além do tamanho do corpus. **Uma janela pequena demais nem sempre
falha alto**: uma API comercial responde a uma requisição grande demais com um erro, e um servidor
local pode cortá-la e seguir em frente. E **`prompt_tokens` é o único lugar em que o corte aparece**: a
requisição levava uns 9.000 tokens, e o modelo diz ter lido 2.050. O programa da aula 9 registra esse
número para toda pergunta, exatamente por isso.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 302\" role=\"img\" aria-label=\"Quatro barras medidas em tokens do llama3.2. Todos os documentos e uma pergunta: 9.094. O que o modelo leu depois que o Ollama cortou o prompt: 2.050. A janela que o Ollama serve, para prompt e resposta juntos: 4.096. Um documento e uma pergunta: 1.166.\"><text x=\"218\" y=\"54\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">todos os documentos</text><text x=\"218\" y=\"71\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e uma pergunta</text><rect x=\"230\" y=\"44\" width=\"440.0\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"678.0\" y=\"61\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">9,094</text><text x=\"218\" y=\"116\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o que o modelo leu</text><text x=\"218\" y=\"133\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">depois do corte do Ollama</text><rect x=\"230\" y=\"106\" width=\"99.2\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"2\"></rect><text x=\"337.2\" y=\"123\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">2,050</text><text x=\"218\" y=\"178\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a janela que o Ollama serve</text><text x=\"218\" y=\"195\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">prompt e resposta</text><rect x=\"230\" y=\"168\" width=\"198.2\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"2\"></rect><text x=\"436.2\" y=\"185\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">4,096</text><text x=\"218\" y=\"240\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um documento</text><text x=\"218\" y=\"257\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e uma pergunta</text><rect x=\"230\" y=\"230\" width=\"56.4\" height=\"34\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"294.4\" y=\"247\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">1,166</text></svg>", "caption": "Os treze documentos e uma pergunta deram 9.094 tokens; o Ollama ficou com os últimos 2.050 e o modelo nunca viu o resto. Um documento e a mesma pergunta deram 1.166. O primeiro número vem do log do Ollama, os outros das respostas."}
```

## Suponha que coubesse

Uma janela de um milhão de tokens levaria este corpus cem vezes. Restam três custos, e cada um cresce
com o corpus, não com a pergunta.

**Toda pergunta paga por todos os documentos.** A um preço ilustrativo de 3 por milhão de tokens de
entrada, que não é o de nenhum provedor, os 8.914 tokens dos documentos custam 0,027 para mandar, e
dez mil perguntas por dia custam 267 por dia antes de uma única palavra de resposta. As mesmas
perguntas com um documento relevante custam cerca de um oitavo disso. Os provedores guardam em cache
um prefixo repetido com desconto, e a aula 17 conta o que isso compra, mas um desconto sobre um texto
de que a pergunta não precisava ainda é um preço por um texto de que a pergunta não precisava.

**Toda pergunta espera por todos os documentos.** Um modelo lê o prompt inteiro antes de escrever o
primeiro token da resposta, e ler leva tempo proporcional ao tamanho. Um chat de atendimento que lê o
manual do armazém antes de responder uma pergunta sobre vale-presente fica mais lento por um motivo que
o cliente não enxerga.

**Toda pergunta disputa com todos os documentos.** Quanto mais texto sem relação um prompt carrega,
mais chances a resposta tem de usar a parte errada. Na execução acima, as regras do manual de
atendimento para os atendentes sobreviveram ao corte e moldaram a resposta a uma pergunta que não
tinha nada a ver com elas. Pesquisadores que mediram modelos com contextos longos viram que eles usam
melhor a informação do começo e do fim de um prompt longo do que a do meio; o artigo é *Lost in the
Middle*, de Liu e outros, 2023. A aula 12 volta ao que isso significa para a forma de montar um
prompt.

## E o corpus cresce

Treze documentos é um corpus de ensino. A base de conhecimento de uma equipe de atendimento de verdade
tem milhares de artigos, a de um escritório de advocacia tem milhões de páginas, e as duas mudam toda
semana. O que cabe hoje não vai caber no ano que vem, e um projeto que depende de caber tem data para
quebrar.

Então a pergunta útil não é *como faço tudo caber*, e sim **como encontro, para esta pergunta, os
poucos trechos que a respondem, e mando só esses.** Isso é recuperação, e a próxima seção constrói a
versão mais simples dela.
