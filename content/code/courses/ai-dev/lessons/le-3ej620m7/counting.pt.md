---
title: Contar antes de enviar
version: 1
---

Para saber se uma requisição cabe, e quanto vai custar, você precisa da contagem de tokens **antes**
de ela sair. A aula 1 seção 03 mostrou que uma contagem pertence a um tokenizador, e que só a
OpenAI publica os tokenizadores dela. Então há dois jeitos de contar, e eles respondem perguntas
um pouco diferentes:

- **localmente, com uma biblioteca de tokenizador**: rápido, de graça, sem rede, e exato só para os
  modelos a que esse tokenizador pertence;
- **perguntando ao provedor**: o endpoint `count_tokens` da Anthropic recebe o mesmo corpo de uma
  requisição e devolve o número que a cobrança vai usar, sem gerar nada. A API do Google também tem
  uma chamada de contagem. Custa uma ida e volta pela rede, e chamadas de contagem têm limites de
  taxa próprios.

## A diferença não é só o tokenizador

O `lab/count.py` conta uma pergunta com o `tiktoken`, e depois pergunta ao endpoint de contagem do
labllm sobre a mesma pergunta de três jeitos: sozinha, com o `CONVENTIONS.md` do projeto como
prompt de sistema, e com uma definição de ferramenta.

```
ana@dev:~/shop$ python lab/count.py
tiktoken on the question alone: 15
   18  question only
  392  with the conventions as system prompt
   71  with one tool definition
```

O labllm usa a mesma codificação do `tiktoken`, e as respostas ainda diferem em 3. É o acréscimo
que o labllm põe por mensagem, no lugar dos marcadores de papel e separadores que uma API real põe
em volta de cada mensagem antes de o modelo ler. Provedores reais têm acréscimos assim, eles não
são documentados, e é por isso que **a contagem do provedor é a confiável**. Contar o texto você
mesmo dá uma boa estimativa do texto e deixa o embrulho de fora.

As outras duas linhas são as que surpreendem:

- **O prompt de sistema é pago em toda requisição.** 374 tokens a mais pelo `CONVENTIONS.md`, que é
  uma página de texto, em cada pergunta que alguém faz. A aula 2 seção 07 mostra como pagar menos
  por um prompt de sistema que nunca muda.
- **Ferramentas também são texto.** Uma ferramenta com um parâmetro acrescentou 53 tokens: o nome,
  a descrição e o esquema JSON dela são todos serializados no prompt. Um agente com trinta
  ferramentas (aula 7) pode gastar milhares de tokens descrevendo-as antes de a conversa começar.

## Onde a contagem fica no código

Conte uma vez, na função que envia a requisição, e guarde o número:

- **antes de enviar**, para recusar uma requisição que não cabe ou passa de um orçamento (aula 2
  seção 09);
- **depois da resposta**, leia o `usage` da resposta em vez de contar de novo. É o número do próprio
  provedor para o que foi cobrado, incluindo a saída, que nada conseguiria contar antes.

```python
r = client.messages.create(model=model, max_tokens=300, messages=messages)
log.info("tokens", extra={"in": r.usage.input_tokens, "out": r.usage.output_tokens})
```

**Registre o `usage` em toda chamada desde o primeiro dia.** Quando a fatura chega, a pergunta é
que funcionalidade gastou, e o único dado que responde isso é o uso que você registrou por
requisição.
