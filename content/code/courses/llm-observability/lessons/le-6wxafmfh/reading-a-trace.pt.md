---
title: Lendo um trace
version: 1
---

A árvore diz para onde foi o tempo. Os atributos dizem com o que cada etapa estava trabalhando, e é
neles que se resolve a maior parte das perguntas sobre uma resposta ruim.

```
ana@lab:~/obs$ python tree.py --attrs
trace 1a218c3902fa97519a4b28d0bd1f155f   start(ms) took(ms)
      0     785 ms  ask
                     app.feature = "help"
                     app.release = "2026.10.1"
                     gen_ai.request.model = "extract-1"
                     user.hash = "d89d2eeb16257c0f"
                     session.id = ""
                     app.question = "Above what order value is standard delivery free?"
                     app.outcome = "answered"
                     app.reply = "Express delivery is not free at any order value. [1]"
      0      56 ms    embed
                       gen_ai.operation.name = "embeddings"
                       gen_ai.request.model = "lab-minilm"
                       gen_ai.usage.input_tokens = 9
     56       4 ms    search
                       db.system.name = "postgresql"
                       app.search.k = 3
                       app.search.floor = 0.62
                       app.search.returned = 3
                       app.search.kept = 1
                       app.search.top_score = 0.637
                       app.search.chunks = ["shipping-and-delivery:ca3796df6832"]
     61     723 ms    generate
                       app.attempts = 1
     61     723 ms      chat extract-1
                         gen_ai.operation.name = "chat"
                         gen_ai.provider.name = "openai"
                         gen_ai.request.model = "extract-1"
                         gen_ai.request.max_tokens = 300
                         app.time_to_first_token_ms = 325
                         gen_ai.usage.input_tokens = 143
                         gen_ai.usage.output_tokens = 13
                         gen_ai.response.model = "extract-1"
                         gen_ai.response.finish_reasons = ["stop"]
    784       0 ms    check_citations
                       app.citations.count = 1
                       app.citations.dangling = 0
```

Volte à resposta: *Express delivery is not free at any order value.* A entrega expressa não é grátis
em valor nenhum. O cliente perguntou sobre a entrega **padrão**, e os documentos dizem que ela é
grátis acima de 40. A resposta está errada, e o trace mostra por quê, um span de cada vez.

- **`search`**: três trechos voltaram (`app.search.returned`), e **um** passou do piso
  (`app.search.kept`). O melhor teve 0,637 contra um piso de 0,62. Um trecho, do documento de entregas.
- **`chat extract-1`**: 143 tokens de entrada, 13 de saída. Um prompt desse tamanho cabe as
  instruções, um trecho e a pergunta, e nada mais.
- **`ask`**: a versão era a `2026.10.1`, a que subiu o piso.

Então o modelo recebeu um trecho, e esse trecho era sobre entrega expressa. O extract-1 copiou a frase
mais próxima da pergunta, como as suas regras mandam. A busca achou mais do que isso, e o piso jogou
fora. Se um piso de 0,62 é um erro não se decide com um trace; a aula 5 conta o que ele fez em uma
semana.

Repare no que precisou estar no span para isso ser legível. Um trace só com nomes e durações teria
dito "785 ms, nada falhou". **Os atributos que explicam uma resposta errada são os das entradas**:
quantos trechos, quais, quão perto, quais configurações. Registrar só as saídas, os tokens e a
latência, dá um trace que consegue explicar uma resposta lenta e nunca uma ruim.

## Um trace com uma etapa faltando

```
ana@lab:~/obs$ python assistant.py "Is there a student discount?"
I could not find that in our documents.
trace ce0b5661415f1a83fc75d4de2668184a
ana@lab:~/obs$ python tree.py
trace ce0b5661415f1a83fc75d4de2668184a   start(ms) took(ms)
      0      46 ms  ask
      0      40 ms    embed
     41       4 ms    search
     45       0 ms    check_citations
```

Quatro spans, não seis. **Não há `generate`**: nada passou do piso, então o assistente devolveu a sua
recusa sem chamar o modelo, como a aula 7 do `rag` o projetou. O trace levou 46 ms em vez de 785, e
não custou nenhum token de modelo.

```
ana@lab:~/obs$ python tree.py --attrs | sed -n "/search/,/check_citations/p"
     41       4 ms    search
                       db.system.name = "postgresql"
                       app.search.k = 3
                       app.search.floor = 0.62
                       app.search.returned = 3
                       app.search.kept = 0
                       app.search.top_score = 0.354
                       app.search.chunks = []
     45       0 ms    check_citations
```

O melhor trecho teve 0,354, muito abaixo do piso, e os documentos de fato não mencionam desconto para
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
  não textos: o id do trecho acha o texto sempre que for preciso.
- **Tudo pelo que você quiser filtrar**: se uma pergunta vai ser "me mostre todo trace em que X", X
  tem de ser um atributo.

A pergunta e a resposta já estão na raiz, passadas por uma função chamada `redact()` que a aula 2
abre. O que não está em span nenhum é o prompt inteiro: as instruções e as fontes como o modelo as
recebeu. Ele faria todo trace se explicar sozinho, e é também onde dados pessoais vão morar por tanto
tempo quanto os traces durarem. A aula 2 decide quanto dele guardar.
