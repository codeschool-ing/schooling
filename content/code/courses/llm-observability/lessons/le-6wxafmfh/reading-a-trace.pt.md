---
title: Lendo um trace
version: 2
---

A árvore diz para onde foi o tempo. Os atributos dizem com o que cada etapa estava trabalhando, e é
neles que se resolve a maior parte das perguntas sobre uma resposta ruim.

```
ana@dev:~/obs$ python tree.py --attrs
trace 5ea30205e6a9ef29c4b98b45d1595ab9   start(ms) took(ms)
      0   3,021 ms  ask
                     app.feature = "help"
                     app.release = "2026.10.1"
                     gen_ai.request.model = "llama3.2:3b"
                     user.hash = "ed56759c27bf4d29"
                     session.id = ""
                     app.question = "Who pays for the return postage?"
                     app.outcome = "answered"
                     app.reply = "According to [1], the customer pays for the return postage."
      0      25 ms    embed
                       gen_ai.operation.name = "embeddings"
                       gen_ai.request.model = "all-minilm"
                       gen_ai.usage.input_tokens = 9
     26       4 ms    search
                       app.search.k = 3
                       app.search.floor = 0.55
                       app.search.returned = 3
                       app.search.kept = 1
                       app.search.top_score = 0.563
                       app.search.chunks = ["returns-policy:how-to-start-a-return"]
     31   2,990 ms    generate
                       app.attempts = 1
     31   2,990 ms      chat llama3.2:3b
                         gen_ai.operation.name = "chat"
                         gen_ai.provider.name = "ollama"
                         gen_ai.request.model = "llama3.2:3b"
                         gen_ai.request.max_tokens = 300
                         gen_ai.request.temperature = 0
                         app.time_to_first_token_ms = 1663
                         gen_ai.usage.input_tokens = 165
                         gen_ai.usage.output_tokens = 14
                         gen_ai.response.model = "llama3.2:3b"
                         gen_ai.response.finish_reasons = ["stop"]
  3,021       0 ms    check_citations
                       app.citations.count = 1
                       app.citations.dangling = 0
```

Volte à resposta: *the customer pays for the return postage*, o cliente paga a postagem da
devolução. Os documentos dizem o contrário: as devoluções são gratuitas, e a loja manda por e-mail uma
etiqueta pré-paga. A resposta está errada, e o trace diz onde o erro foi cometido, um span de cada
vez.

- **`search`**: três trechos voltaram (`app.search.returned`), e **um** passou do piso
  (`app.search.kept`), com 0,563 contra um piso de 0,55. O id dele está em `app.search.chunks`:
  `returns-policy:how-to-start-a-return`, justamente a seção que diz que as devoluções são gratuitas.
- **`chat llama3.2:3b`**: 165 tokens de entrada, 14 de saída. Um prompt desse tamanho cabe as
  instruções, um trecho e a pergunta, e nada mais.
- **`ask`**: a versão era a `2026.10.1`, a que subiu o piso.

Então a busca fez o seu trabalho: o único trecho que o modelo recebeu é o que responde à pergunta, e
responde em três palavras simples, *Returns are free*. **O erro é do modelo**, cometido ao ler uma
fonte que dizia o contrário, e isso muda onde procurar uma correção: não na busca nem no piso, mas
no prompt, no modelo, ou em quantas fontes ele recebe. Qual dessas ajudaria não se decide com um
trace. As aulas 8 a 14 medem o modelo e o piso sobre muitas perguntas, e a aula 5 conta o que o piso
mais alto fez em uma semana.

Repare no que precisou estar no span para isso ser legível. Um trace só com nomes e durações teria
dito "3.021 ms, nada falhou". **Os atributos que explicam uma resposta errada são os das entradas**:
quantos trechos, quais, quão perto, quais configurações. Registrar só as saídas, os tokens e a
latência, dá um trace que consegue explicar uma resposta lenta e nunca uma ruim. E foi o id do trecho
que mandou alguém ao parágrafo certo do documento certo, onde o erro do modelo pôde ser visto.

## Um trace com uma etapa faltando

```
ana@dev:~/obs$ python assistant.py "Is there a student discount?"
I could not find that in our documents.
trace b0f29bf4b40469cb859c35e290b1bcec
ana@dev:~/obs$ python tree.py
trace b0f29bf4b40469cb859c35e290b1bcec   start(ms) took(ms)
      0      44 ms  ask
      1      42 ms    embed
     43       0 ms    search
     44       0 ms    check_citations
```

Quatro spans, não seis. **Não há `generate`**: nada passou do piso, então o assistente devolveu a sua
recusa sem chamar o modelo. O trace levou 44 ms em vez de 3.021, e não custou nenhum token de
modelo.

```
ana@dev:~/obs$ python tree.py --attrs | sed -n "/search/,/check_citations/p"
     43       0 ms    search
                       app.search.k = 3
                       app.search.floor = 0.55
                       app.search.returned = 3
                       app.search.kept = 0
                       app.search.top_score = 0.244
                       app.search.chunks = []
     44       0 ms    check_citations
```

O melhor trecho teve 0,244, muito abaixo do piso, e os documentos de fato não mencionam desconto para
estudantes: a recusa está certa.

Duas recusas podem parecer idênticas na tela e ser diferentes no trace. Uma não tem span `generate`,
porque a busca não achou nada perto o bastante. A outra tem um span `generate` cuja resposta é a frase
de recusa, porque o modelo leu as fontes e decidiu que elas não respondiam. O `ask` registra as duas
como `app.outcome = refused`, e a presença do span filho diz de que tipo foi. Isso importa, porque a
primeira não custa nada e se conserta na busca, e a segunda custa uma chamada inteira ao modelo e se
conserta no prompt ou nas fontes.

## O que pôr num span

Uma lista curta, a partir dos dois traces acima:

- **Na raiz**: para que era o pedido (funcionalidade, versão, modelo), e quem e qual sessão, numa
  forma que a aula 2 vai tornar segura. O resultado, quando for conhecido.
- **Numa chamada a modelo**: os atributos `gen_ai.*` do pedido e da resposta, as contagens de tokens,
  e o tempo até o primeiro token se a resposta vier em streaming.
- **Numa etapa de recuperação**: quantos resultados, quantos mantidos, a melhor nota, e quais. Ids,
  não textos: o id do trecho acha o texto sempre que for preciso, como achou para a pergunta da
  postagem.
- **Tudo pelo que você quiser filtrar**: se uma pergunta vai ser "me mostre todo trace em que X", X
  tem de ser um atributo.

A pergunta e a resposta já estão na raiz, passadas por uma função chamada `redact()` que a aula 2
abre. O que não está em span nenhum é o prompt inteiro: as instruções e as fontes como o modelo as
recebeu. Ele faria todo trace se explicar sozinho, e é também onde dados pessoais vão morar por tanto
tempo quanto os traces durarem. A aula 2 decide quanto dele guardar.
