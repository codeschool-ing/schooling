---
title: Thought, Action, Observation, e depois uma Answer
version: 1
---

A lição 6 deu ferramentas a um modelo: ele escreve uma linha com o nome de uma ferramenta, um
programa a executa, e o resultado volta para o texto. Aquela lição deixou em aberto como o modelo
decide o que chamar, e em que ordem. A imagem tentadora é a de um agente que planeja o trabalho na
cabeça e depois o executa. **O ReAct faz o contrário: o modelo raciocina às claras, um passo pequeno
de cada vez, e pergunta ao mundo depois de cada um.** O nome vem de *reasoning and acting*,
raciocinar e agir, de um artigo de 2022, "ReAct: Synergizing Reasoning and Acting in Language
Models".

O formato tem quatro tipos de linha:

| linha | quem escreve | o que ela traz |
|---|---|---|
| `Thought:` | o modelo | o que ele sabe até ali, e do que precisa em seguida |
| `Action:` | o modelo | uma ferramenta, e o que entregar a ela: `search[...]`, `calculator[...]` |
| `Observation:` | **o programa que roda o laço** | o que a ferramenta devolveu, palavra por palavra |
| `Answer:` | o modelo | a resposta, quando não falta mais nada |

Thought, Action e Observation se repetem quantas vezes a tarefa pedir, e uma Answer encerra. O
`Thought` é a cadeia de pensamento da lição 26, cortada em pedaços. **O que o ReAct acrescenta é que
cada pedaço de raciocínio é seguido de um fato que o modelo não inventou.**

## Por que as duas metades

Cada metade falha sozinha, e de um jeito que você já viu. Raciocinar sem ferramentas chega a uma
resposta a partir do que o modelo acha provável, e uma regra lembrada pela metade vira um passo
confiante (lição 5). Ferramentas sem raciocínio dão uma lista de chamadas e nenhum registro do
porquê de cada uma, então, quando a resposta sai errada, não dá para saber qual chamada a enganou.

Juntas, o pensamento diz o que falta, a ação busca, e o pensamento seguinte parte do que voltou.
Quem lê o registro depois consegue apontar a linha exata em que as coisas deram errado, e isso vale
mais do que parece num sistema que ninguém acompanha enquanto roda.

O prompt que prepara isso descreve as ferramentas e o formato, e depois entrega a pergunta. Este foi
escrito pelo curso como ilustração:

```localised
Responda à pergunta. Você pode usar estas ferramentas:
  search[palavras]     a linha do manual da equipe do café que mais combina
  calculator[conta]    aritmética com números e + - * /
Use este formato, e escreva uma Action de cada vez:
Thought: o que você sabe e do que precisa em seguida
Action: uma chamada de ferramenta
Observation: (a resposta da ferramenta é escrita aqui para você)
... repita quanto precisar, e então:
Answer: a resposta final

Pergunta: quatro sopas do dia, R$ 27,90 cada, pagas no cartão, todas servidas frias.
Quanto volta, como, e alguém precisa aprovar?
```

## Uma execução completa

O `agent` é o laço da lição 6. Os turnos que ele reproduz estão num arquivo, separados por `---`, e
as linhas que começam com `#` são notas que ele pula. **Os turnos abaixo foram escritos pelo curso,
sabendo o que as ferramentas iam devolver**, porque nenhum modelo é alcançável da bancada. Tudo o
que aparece depois de `tool>` é real: a busca no manual e a conta foram executadas de fato.

```
ana@lab:~/pe$ cat runs/refund.txt
# Question: four soups of the day, R$ 27.90 each, paid by card, all served
# cold. How much goes back, how, and does anybody have to approve it?
Thought: The handbook has the rules for refunds. I need the one about approval.
Action: search[refund approval manager]
---
Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
Action: calculator[4 * 27.90]
---
Thought: 111.6 is above 100, so the manager approves it. How does the money go back?
Action: search[refund card cash]
---
Thought: Back to the card they paid with, not in cash.
Answer: R$ 111.60, refunded to the card, once the shift manager has approved it.
ana@lab:~/pe$ agent runs/refund.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Thought: The handbook has the rules for refunds. I need the one about approval.
  model> Action: search[refund approval manager]
  tool>  refunds.md     A refund above R$ 100 needs the shift manager's approval.
step 2
  model> Thought: Above R$ 100 needs the shift manager. Now the total for four soups.
  model> Action: calculator[4 * 27.90]
  tool>  111.6
step 3
  model> Thought: 111.6 is above 100, so the manager approves it. How does the money go back?
  model> Action: search[refund card cash]
  tool>  refunds.md     Refunds are made to the card or method used to pay, never in cash for a card payment.
step 4
  model> Thought: Back to the card they paid with, not in cash.
  model> Answer: R$ 111.60, refunded to the card, once the shift manager has approved it.
done: an answer after 4 steps
```

Quatro passos e três chamadas de ferramenta. Leia a resposta contra o registro e **cada parte dela
tem uma fonte**. A regra da aprovação é uma linha de `refunds.md` (acima de R$ 100, o gerente do
turno aprova), o valor é o `111.6` da calculadora, e "no cartão" é a segunda linha do manual. A
única contribuição do modelo foi a ordem das perguntas e a comparação de 111,6 com 100, e as duas
estão escritas onde você pode conferir.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um diagrama de sequência com três colunas: o modelo, o laço e as ferramentas. No passo 1 o modelo escreve Action: search refund approval manager. O laço confere se a ferramenta é permitida e a executa. A ferramenta devolve a linha do manual, um reembolso acima de R$ 100 precisa da aprovação do gerente. O laço junta isso ao texto como Observation e devolve ao modelo. Os passos 2 e 3 fazem o mesmo com a calculadora e a busca. No passo 4 o modelo escreve uma Answer sem Action, e o laço para. O laço também conta os passos.\"><defs><marker id=\"react-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"40\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"110\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><path d=\"M110 48 L110 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M110 227 L110 315\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"290\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o laço</text><path d=\"M360 48 L360 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M360 227 L360 271\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"540\" y=\"18\" width=\"140\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"610\" y=\"33\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">as ferramentas</text><path d=\"M610 48 L610 199\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><path d=\"M610 227 L610 315\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"75\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--amber)\">passo 1</text><text x=\"235\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Action: search[refund approval manager]</text><path d=\"M110 98 L358 98\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"485\" y=\"112\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">permitida? então executa</text><path d=\"M360 122 L608 122\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"485\" y=\"148\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">A refund above R$ 100 needs…</text><path d=\"M610 158 L362 158\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><text x=\"235\" y=\"172\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">Observation: juntada ao texto</text><path d=\"M360 182 L112 182\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><rect x=\"40\" y=\"200\" width=\"640\" height=\"26\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></rect><text x=\"360\" y=\"213\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">passos 2 e 3: o mesmo, com calculator e search</text><text x=\"235\" y=\"250\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper)\">Answer: R$ 111.60, refunded to…</text><path d=\"M110 260 L358 260\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#react-ah)\"></path><rect x=\"265\" y=\"272\" width=\"190\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"360\" y=\"286\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">fim: sem Action, uma Answer</text><text x=\"468\" y=\"286\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">e conta os passos</text></svg>", "caption": "A execução como sequência. O modelo só escreve texto; o laço lê a linha Action, executa a ferramenta e devolve o que ela retornou. Quem decide quando parar é o laço, não o modelo."}
```

## A Observation nunca é do modelo

Na tabela acima, uma linha é escrita por outro autor. Isso é de propósito, e os sistemas reais
garantem isso. Um modelo a quem se pede para continuar um registro ReAct pode seguir adiante depois
da própria Action e escrever também uma `Observation:`, com o resultado que parecer provável, e
depois raciocinar a partir desse resultado inventado. Por isso o programa define `Observation:` como sequência de
parada (lição 16): **a geração para no instante em que o modelo começa a escrever o que a ferramenta
disse**, o laço executa a ferramenta e escreve a Observation ele mesmo.

O `agent` chega ao mesmo efeito por outro caminho: lê uma Action por vez e imprime sob `tool>` o que
a ferramenta devolveu, nunca o que o turno afirma. De um jeito ou de outro, a regra é a que faz o
método valer a pena: os fatos do registro vêm de fora do modelo.
