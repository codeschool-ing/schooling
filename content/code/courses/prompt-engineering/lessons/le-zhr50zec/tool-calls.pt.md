---
title: Um pedido escrito como texto, e um programa que o executa
version: 1
---

Assistentes que consultam a previsão do tempo, rodam código ou reservam uma mesa parecem fazer
essas coisas sozinhos. **Um modelo não consegue executar nada. Ele escreve texto, e parte desse
texto pode ser um pedido, num formato combinado antes, para um programa executar uma ferramenta.**
O programa em volta do modelo lê o pedido, executa a ferramenta e põe o resultado de volta no texto;
depois o modelo é chamado a continuar, com o resultado na frente dele.

Sem esse arranjo, duas coisas que você já viu dão errado. Perguntado sobre a data de hoje, um
modelo só consegue escrever uma data provável, que é o problema da lição 5; perguntado quanto é
3 × 42,50, ele faz conta com blocos de dígitos, que é o problema da lição 3. Uma ferramenta troca a
resposta provável por uma consultada ou calculada.

## Dizer ao modelo o que ele pode pedir

O modelo fica sabendo quais ferramentas existem pela entrada dele. Na forma mais simples, a
descrição faz parte do prompt, junto com o formato que o programa vai procurar. Esta foi escrita
pelo curso como ilustração, para as ferramentas da bancada:

```localised
Você pode pedir estas ferramentas. Escreva um pedido por vez, numa
linha só para ele, e espere o resultado:
  Action: today[]            a data de hoje
  Action: calculator[conta]  contas com números e + - * /
Quando tiver tudo o que precisa, escreva:
  Answer: a sua resposta ao cliente
```

No momento em que este curso foi escrito (2026), as APIs dos grandes provedores têm um campo para
isso, em vez de um parágrafo no prompt. Cada ferramenta é descrita por um nome, uma frase dizendo o
que ela faz e um JSON Schema para a entrada dela (a lição 19 trata de schemas). A resposta do modelo
então traz a chamada da ferramenta como uma parte separada e estruturada, e o seu código devolve o
resultado numa mensagem própria. Os nomes dos campos mudam entre provedores; uma definição para a
calculadora fica assim (não executada: a bancada não tem chave):

```json
{
  "name": "calculator",
  "description": "Arithmetic with numbers and + - * /. Returns the result as a number.",
  "input_schema": {
    "type": "object",
    "properties": {"expression": {"type": "string"}},
    "required": ["expression"]
  }
}
```

**A descrição também é um prompt.** O modelo decide se e como chamar uma ferramenta a partir dessa
única frase, então "Arithmetic with numbers and + - * /" faz um trabalho de verdade: diz ao modelo
quais operações ele pode mandar, e que `sqrt(2)` não vai funcionar.

## Uma execução na bancada

O `agent` é o programa que fica em volta do modelo. A entrada dele é um arquivo com as vezes do
modelo, um bloco por vez, separados por `---`; as linhas que começam com `#` são notas e são
puladas. **As vezes são escritas pelo curso, sabendo o que as ferramentas vão devolver, porque
nenhum modelo é alcançável da bancada.** Todo o resto é real: o `agent` lê cada vez, acha a linha
`Action:`, executa a ferramenta e imprime o que ela devolveu. Eis uma pergunta sobre uma encomenda
de bolos, e as vezes que um modelo poderia escrever para ela:

```
ana@lab:~/pe$ cat runs/order.txt
# Question: Bruno wants three whole cakes at R$ 42.50 each, to collect
# tomorrow. What day is tomorrow, and what is the total?
Action: today[]
---
Action: calculator[3 * 42.50]
---
Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
```

E a execução:

```
ana@lab:~/pe$ agent runs/order.txt
tools allowed: calculator, reviews, search, today
step 1
  model> Action: today[]
  tool>  Friday 2 October 2026
step 2
  model> Action: calculator[3 * 42.50]
  tool>  127.5
step 3
  model> Answer: Tomorrow is Saturday 3 October. Three cakes cost R$ 127.50.
done: an answer after 3 steps
```

Leia as linhas por quem as escreveu. As linhas `model>` são o arquivo de vezes. **As linhas `tool>`
foram impressas por ferramentas de verdade**: a data veio do `today`, e o `127.5` da calculadora,
que calculou `3 * 42.50`. A resposta então junta as duas, e esse último passo é do próprio modelo:
deduzir que o dia depois de sexta, 2 de outubro, é sábado, 3 de outubro, e escrever `127.5` como
`R$ 127.50`. A ferramenta fornece o fato; o modelo ainda decide o que pedir e o que o resultado
quer dizer.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três caixas da esquerda para a direita. Dentro de uma fronteira tracejada chamada o programa em volta do modelo estão o modelo, que só escreve texto, e o laço. O modelo manda ao laço a linha Action: calculator[3 * 42.50]. O laço confere se a ferramenta é permitida e a executa. Fora da fronteira estão as ferramentas, a única parte que age. A calculadora devolve 127.5 ao laço, e o laço junta o resultado ao texto que o modelo lê em seguida.\"><defs><marker id=\"tool-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"14\" y=\"30\" width=\"444\" height=\"200\" rx=\"4\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"5 4\"></rect><text x=\"28\" y=\"46\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o programa em volta do modelo</text><rect x=\"30\" y=\"90\" width=\"124\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"92\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"92\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">só escreve texto</text><rect x=\"330\" y=\"90\" width=\"112\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"386\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">o laço</text><text x=\"242\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">Action: calculator[3 * 42.50]</text><path d=\"M154 104 L328 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><path d=\"M328 146 L156 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"242\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">o resultado, juntado ao texto</text><rect x=\"586\" y=\"90\" width=\"120\" height=\"70\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"646\" y=\"115\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">as ferramentas</text><text x=\"646\" y=\"138\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">a única parte que age</text><path d=\"M442 104 L584 104\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">permitida?</text><text x=\"514\" y=\"84\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">então executa</text><path d=\"M584 146 L444 146\" stroke=\"var(--phosphor-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#tool-ah)\"></path><text x=\"514\" y=\"164\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--phosphor)\">127.5</text></svg>", "caption": "O que é uma chamada de ferramenta. O modelo só escreve uma linha pedindo uma ferramenta; o programa em volta dele decide se a executa, executa e põe o que voltou no texto que o modelo lê em seguida."}
```

## O que "agente" quer dizer aqui

A palavra é usada sem muito rigor, para qualquer coisa entre um chatbot com uma caixa de busca e um
sistema que roda por horas. Neste curso, **um agente é um modelo rodando num laço como este**: ele
pode pedir uma ferramenta, o programa a executa, e o laço dá voltas até o modelo escrever uma
resposta ou um limite ser atingido. O laço é o assunto da próxima seção, e é o programa, não o
modelo, que segura cada limite dele.
