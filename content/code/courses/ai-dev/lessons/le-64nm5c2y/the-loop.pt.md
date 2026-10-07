---
title: Um agente é um laço
version: 2
---

"Agente" é usado para muitas coisas, e a definição útil é a mecânica. **Um agente é um modelo num
laço com ferramentas**: o modelo lê a tarefa, decide chamar uma ferramenta, o seu código a chama e
devolve o resultado, e o modelo decide de novo, até responder ou algo pará-lo. Nada disso é novo além
do laço. O modelo da aula 1 continua produzindo uma resposta por requisição; o agente é o código que
continua perguntando.

::: track ai
O `agents-mcp` construiu agentes com planejamento, memória e várias ferramentas trabalhando juntas.
Esta aula é a menor versão que ainda é honesta: um laço, três ferramentas, um servidor MCP, e as
quatro guardas de que todo agente em produção precisa, tenha ele o que mais tiver.
:::

::: track *
Você já usou um se usou o modo agente de um assistente (aula 3 seção 08). Esta aula constrói o laço
que fica atrás dele, para os limites dele deixarem de ser um mistério.
:::

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"O laço do agente. O host manda a conversa e as definições de ferramentas ao modelo. O modelo responde com uma resposta, que encerra o laço, ou com uma chamada de ferramenta. O host confere a chamada contra as guardas, chama a ferramenta no servidor MCP e acrescenta o resultado à conversa, e pergunta de novo.\"><defs><marker id=\"ag-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o modelo</text><text x=\"95.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">decide</text><rect x=\"285\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">o host</text><text x=\"360.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">age e vigia</text><rect x=\"550\" y=\"70\" width=\"150\" height=\"60\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"92.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">as ferramentas</text><text x=\"625.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">fazem o trabalho</text><path d=\"M283 84 L172 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"228\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">conversa + ferramentas</text><path d=\"M172 116 L283 116\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"228\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resposta, ou chamada</text><path d=\"M437 84 L548 84\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"492\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">chamada, se permitida</text><path d=\"M548 116 L437 116\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"492\" y=\"132\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">resultado</text><text x=\"360\" y=\"160\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">guardas: passos, repetições, aprovação</text><path d=\"M95 132 L95 196\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ag-ah)\"></path><text x=\"105\" y=\"206\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">uma resposta encerra o laço</text></svg>", "caption": "O modelo nunca roda nada. Todo efeito acontece no host, que é onde mora todo limite."}
```

## Quem faz o quê

- **O modelo decide.** Ele lê a conversa e as descrições das ferramentas, e a resposta dele é uma
  resposta ou um pedido para chamar uma ferramenta com certos argumentos. Ele não roda nada.
- **O host age.** O seu código recebe o pedido, decide se permite, chama a ferramenta e acrescenta o
  resultado à conversa. Todo efeito no mundo acontece aqui, em código que você escreveu e consegue
  ler.
- **As ferramentas fazem o trabalho.** Uma consulta de pedido, uma página do manual, um reembolso. São
  funções comuns, e a aula 7 seção 05 mostra como o MCP deixa um programa oferecê-las a qualquer host.

A divisão é o argumento de segurança de todo o desenho. **Um modelo não faz nada que um host não faça
por ele**, então todo limite de que um agente precisa (que ferramentas, que argumentos, quantos
passos, que chamadas precisam de uma pessoa) é uma linha de código no host, não uma frase no prompt.

## Quanto o laço custa

Cada passo é uma requisição completa, levando a conversa inteira até ali: a pergunta, toda chamada
de ferramenta, todo resultado. A conta da aula 2 seção 06 vale, e resultados de ferramentas
costumam ser longos. A aula 7 seção 09 mede laços de três passos em que cada requisição é maior que
a anterior.
