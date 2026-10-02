---
title: O começo de um texto que o modelo continua
version: 1
---

A imagem cotidiana de um prompt é a de uma ordem: você diz o que quer, e um programa que entendeu a
ordem a executa. Ela explica as vezes em que um prompt funciona e nenhuma das vezes em que ele
falha. **Um prompt é o começo de um texto, e a resposta é a continuação desse texto pelo modelo.** A
lição 1 mostrou o passo que está por baixo: o modelo dá nota a cada próximo pedaço possível do texto
que recebeu, e nada mais entra.

Então a menor mudança no texto é uma mudança na previsão. A lição 1 perguntou ao `toylm` sobre
`the café opens at` ("o café abre às") e recebeu `seven` com 75% e `eight` com 25%. Troque uma
palavra:

```
ana@lab:~/pe$ toylm next "the café closes at"
context: trigram after 'closes at'
  six       66.7%  ###########################
  noon      33.3%  #############
```

Ninguém mandou o modelo falar do horário de fechar. **A palavra `closes` ("fecha") moveu a
distribuição inteira**, dos horários da manhã para `six` e `noon` (seis e meio-dia), porque é isso
que vinha depois dela no texto com que o modelo aprendeu.

## O formato faz parte do prompt

O corpus tem algumas linhas escritas como pergunta e resposta, no formato `question : ... answer :
...`. Dê ao `toylm` uma pergunta nesse formato e ele responde nesse formato:

```
ana@lab:~/pe$ toylm next "question : when does the café open ? answer :"
context: trigram after 'answer :'
  yes       50.0%  ####################
  at        33.3%  #############
  tomato    16.7%  #######
ana@lab:~/pe$ toylm generate "question : when does the café open ? answer :" --temperature 0
yes.
-- finish: end, prompt 10 tokens, output 2 tokens
```

`yes.` ("sim.") é uma péssima resposta para "quando", e vale ver por que ela saiu. A janela do modelo
é de duas palavras (lição 1), então ele nunca viu `when` nem `open`; **tudo o que ele viu foi
`answer :`**, e depois de `answer :` o texto com que ele aprendeu traz uma resposta curta seguida de
ponto final. O formato chegou ao modelo e a pergunta não.

Um modelo grande vê a pergunta inteira, então não cometeria esse erro. Mas ele segue a mesma regra
em escala maior: **ele continua o documento que você deu, no idioma, no registro e no formato desse
documento.** Um prompt escrito como uma lista seca tende a receber uma lista seca de volta; um
prompt que abre um objeto JSON tende a receber o resto dele (lição 18). Cada parte do texto é uma
instrução, inclusive as partes que você não pretendia que fossem.

## Um chat é um documento com vezes

Uma janela de chat parece ser algo diferente de continuar um texto. A lição 1 mostrou que é a mesma
coisa com as vezes marcadas. Na época em que este curso foi escrito (2026), as APIs por trás dos
assistentes de chat recebem uma conversa como uma lista de mensagens, cada uma com um papel e o seu
texto. Os nomes dos campos mudam de um fornecedor para outro; o formato é este (uma ilustração, não
uma requisição que foi enviada):

```json
[
  {"role": "system", "content": "You answer questions from Café Aurora's customers. Keep replies to two sentences."},
  {"role": "user", "content": "When do you open on Sunday?"}
]
```

Antes de o modelo vê-la, a lista é disposta como um só texto, com marcadores que dizem onde cada vez
começa e quem está falando, e termina com uma vez do assistente que foi aberta e não escrita. **A
resposta do modelo é a continuação dessa única vez em aberto.**

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" aria-label=\"Um só documento com três vezes empilhadas. Uma vez de system, escrita por quem desenvolve: You answer questions from Café Aurora&#x27;s customers. Uma vez de user, escrita pela pessoa: When do you open on Sunday? Depois uma vez de assistant, aberta e vazia, marcada: o modelo escreve a partir daqui.\"><defs><marker id=\"chat-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"20\" width=\"680\" height=\"245\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"40\" y=\"38\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">um só texto, enviado inteiro</text><rect x=\"40\" y=\"55\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"80\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">system</text><rect x=\"170\" y=\"55\" width=\"510\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"74\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">You answer questions from Café Aurora's customers.</text><text x=\"185\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">Keep replies to two sentences.</text><rect x=\"40\" y=\"115\" width=\"120\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--phosphor)\">user</text><rect x=\"170\" y=\"115\" width=\"510\" height=\"50\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"185\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">When do you open on Sunday?</text><rect x=\"40\" y=\"175\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"100\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--amber)\">assistant</text><rect x=\"170\" y=\"175\" width=\"510\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><path d=\"M190 210 L240 210\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#chat-ah)\"></path><text x=\"250\" y=\"210\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">o modelo escreve a partir daqui</text></svg>", "caption": "O que o modelo recebe. A lista de mensagens vira um só texto com cada vez marcada, e termina dentro de uma vez do assistente que foi aberta e não escrita."}
```

Vale distinguir os três papéis desde o começo, porque o resto do curso volta a eles o tempo todo:

| papel | quem escreve | para que serve |
|---|---|---|
| `system` | quem desenvolve a aplicação | quem o assistente é, as regras, o formato; o usuário não vê (lição 22) |
| `user` | a pessoa que usa a aplicação | o pedido em si |
| `assistant` | o modelo, uma vez de cada vez | as respostas até aqui, enviadas de novo a cada nova requisição |

A última linha tem uma consequência que surpreende. **O modelo não tem memória entre uma requisição
e outra**; a conversa parece contínua porque a aplicação envia tudo de novo a cada vez. E como as
vezes anteriores do assistente são só texto na lista, um programa pode escrever uma delas por conta
própria. A lição 21 usa isso de propósito.
