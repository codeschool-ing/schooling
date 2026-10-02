---
title: Cortar uma conversa para caber
version: 1
---

Quando uma conversa passa do orçamento, a maioria das pessoas supõe que o modelo perde os detalhes
ao acaso, ou perde os menos importantes. Não é nenhum dos dois. **Um programa decide o que cortar,
antes de o modelo ver qualquer coisa, e a regra comum é descartar primeiro as vezes mais antigas.**
Se isso perde algo importante ou não depende de onde a coisa importante foi dita.

Eis uma conversa curta com o assistente do café, como a lista de mensagens que uma aplicação
enviaria:

```
ana@lab:~/pe$ cat chat.json
[
  {"role": "system", "content": "You answer questions from Café Aurora's customers in two sentences or fewer. Opening hours: Monday to Saturday 07:00 to 18:00; Sundays and public holidays 08:00 to 12:00. The kitchen uses nuts."},
  {"role": "user", "content": "Hi, I'm Bruno. I'm allergic to nuts, so please keep that in mind."},
  {"role": "assistant", "content": "Thanks, Bruno. I'll keep your nut allergy in mind in everything I suggest."},
  {"role": "user", "content": "Are you open on Sunday morning?"},
  {"role": "assistant", "content": "Yes, on Sundays we open at 08:00 and close at 12:00."},
  {"role": "user", "content": "And on a public holiday?"},
  {"role": "assistant", "content": "Public holidays follow the Sunday hours: 08:00 to 12:00."},
  {"role": "user", "content": "Great. Which cake would you recommend for me?"}
]
```

O `tok fit` aplica a regra comum a um arquivo como esse, contra um orçamento em tokens: a primeira
mensagem é o prompt de sistema e é sempre mantida; depois dela, as vezes são mantidas da mais nova
para trás, até a próxima não caber. A contagem de cada vez inclui 4 tokens para o papel e os
separadores, uma aproximação, já que cada provedor marca as vezes do seu jeito. Com espaço para
tudo:

```
ana@lab:~/pe$ tok fit chat.json -b 200
budget 200, system prompt 53
  kept     1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  kept     2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  kept     3 user        11  Are you open on Sunday morning?
  kept     4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 173 tokens, 7 of 7 turns
```

A conversa inteira tem 173 tokens. Agora dê 120 a ela:

```
ana@lab:~/pe$ tok fit chat.json -b 120
budget 120, system prompt 53
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  kept     5 user        10  And on a public holiday?
  kept     6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 98 tokens, 3 of 7 turns
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Duas fileiras de blocos, um bloco por mensagem, cada um tão largo quanto a contagem de tokens dele. A fileira de cima é a conversa inteira, 173 tokens: o prompt de sistema, 53, e depois as vezes 1 a 7. As vezes 1 a 4 estão marcadas como descartadas, as mais antigas primeiro, e com elas a alergia do Bruno. A fileira de baixo é o que é enviado com orçamento de 120: o prompt de sistema e as vezes 5, 6 e 7, 98 tokens, com o resto do orçamento vazio.\"><text x=\"40\" y=\"26\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">a conversa inteira: 173 tokens</text><rect x=\"40\" y=\"38\" width=\"190.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">system</text><text x=\"135.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">53</text><rect x=\"230.8\" y=\"38\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"268.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">1</text><text x=\"268.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"306.4\" y=\"38\" width=\"72.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"342.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">2</text><text x=\"342.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">20</text><rect x=\"378.4\" y=\"38\" width=\"39.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"398.2\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">3</text><text x=\"398.2\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">11</text><rect x=\"418.0\" y=\"38\" width=\"82.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"459.4\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--amber)\">4</text><text x=\"459.4\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">23</text><rect x=\"500.8\" y=\"38\" width=\"36.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"518.8\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"518.8\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><rect x=\"536.8\" y=\"38\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"574.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"574.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"612.4\" y=\"38\" width=\"50.4\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"637.6\" y=\"50\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"637.6\" y=\"63\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><path d=\"M232.8 80 L232.8 86 L498.8 86 L498.8 80\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"365.8\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">descartadas, as mais antigas primeiro, e a alergia do Bruno junto</text><text x=\"40\" y=\"140\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o que é enviado com orçamento de 120: 98 tokens</text><rect x=\"40\" y=\"152\" width=\"190.8\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"135.4\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">system</text><text x=\"135.4\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">53</text><rect x=\"230.8\" y=\"152\" width=\"36.0\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"248.8\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">5</text><text x=\"248.8\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">10</text><rect x=\"266.8\" y=\"152\" width=\"75.6\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"304.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">6</text><text x=\"304.6\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">21</text><rect x=\"342.4\" y=\"152\" width=\"50.4\" height=\"34\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"367.6\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">7</text><text x=\"367.6\" y=\"177\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9\" fill=\"var(--paper-dim)\">14</text><rect x=\"392.8\" y=\"152\" width=\"79.2\" height=\"34\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"2 3\"></rect><path d=\"M40 200 L40 206 L472.0 206 L472.0 200\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.2\" fill=\"none\"></path><text x=\"256.0\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">orçamento 120</text></svg>", "caption": "tok fit com orçamento de 120. O prompt de sistema é mantido, as vezes são mantidas da mais nova para trás, e as quatro mais antigas são descartadas, inclusive aquela em que o Bruno disse que tem alergia a nozes."}
```

Quatro vezes se foram, e **a primeira delas era a que importava**: o Bruno tem alergia a nozes. O
que o modelo recebe agora são as instruções do café, uma pergunta sobre feriados e "Which cake would
you recommend for me?". Nada do que ele vê diz quem é esse "me". Eis o que um modelo poderia
responder em cada caso, escrito pelo curso como ilustração:

```localised
Com as sete vezes:
  Nossa cozinha usa nozes, então não posso garantir que algum bolo seja
  seguro para a sua alergia. Pergunte à equipe no balcão antes de pedir.

Só com as três últimas vezes:
  O bolo de cenoura com nozes é o nosso favorito. Combina muito bem com
  um flat white.
```

A segunda resposta é educada, fluente e responde à pergunta que recebeu. **Nada falhou de um jeito
que um log mostraria**: o pedido era válido, o modelo respondeu, a aplicação ficou dentro do
orçamento. O único sintoma está no conteúdo, e só quem se lembra da primeira mensagem o veria.

Aperte mais e só a pergunta sobrevive:

```
ana@lab:~/pe$ tok fit chat.json -b 80
budget 80, system prompt 53
  dropped  1 user        21  Hi, I'm Bruno. I'm allergic to nuts, s
  dropped  2 assistant   20  Thanks, Bruno. I'll keep your nut alle
  dropped  3 user        11  Are you open on Sunday morning?
  dropped  4 assistant   23  Yes, on Sundays we open at 08:00 and c
  dropped  5 user        10  And on a public holiday?
  dropped  6 assistant   21  Public holidays follow the Sunday hour
  kept     7 user        14  Great. Which cake would you recommend 
sent: 67 tokens, 1 of 7 turns
```

## O prompt de sistema fica, de propósito

Nas três execuções, os 53 tokens do prompt de sistema passaram. Essa é uma escolha que o `tok fit`
faz e que a maioria das aplicações faz: **as instruções valem mais que qualquer vez isolada**,
porque sem elas o assistente esquece para que serve, de que tamanho devem ser as respostas e que a
cozinha usa nozes. Cortar a mensagem mais antiga primeiro, sem exceção, teria descartado as
instruções antes de tudo, já que elas vêm primeiro.

O preço é que as instruções ocupam parte do orçamento toda vez. Um prompt de sistema que ganha um
parágrafo a cada regra nova deixa menos espaço para a conversa em cada pedido, e as vezes que ele
empurra para fora são as que o usuário lembra de ter dito.
