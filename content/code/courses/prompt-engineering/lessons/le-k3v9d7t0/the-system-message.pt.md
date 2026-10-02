---
title: Três papéis, e o que fica acima dos outros
version: 1
---

Uma janela de chat mostra a conversa como duas vozes: a sua e a do assistente. O que um programa
envia a um modelo tem uma terceira. **Cada mensagem carrega um papel, e um dos papéis, `system`,
guarda instruções para a conversa inteira**, e não um turno dentro dela.

A lição 1 descreveu uma conversa como um único texto com os turnos marcados, e o modelo escrevendo o
próximo pedaço. Os papéis são essas marcas:

| papel | quem escreve | para que serve |
|---|---|---|
| `system` | quem desenvolve a aplicação | as instruções permanentes: propósito, regras, tom, formato |
| `user` | a pessoa que usa a aplicação | cada pergunta ou pedido |
| `assistant` | o modelo | cada resposta, mantida na lista para o próximo pedido ter o histórico |

## Como é um pedido

Esta é a forma geral de um pedido à API de um modelo de chat, escrita em JSON. Ele não foi
executado, já que a bancada não tem chave nem provedor para onde enviá-lo, e `MODEL-NAME` está no
lugar do modelo que você escolher:

```json
{
  "model": "MODEL-NAME",
  "messages": [
    {"role": "system", "content": "You are the assistant on the website of Café Aurora. Answer in at most three sentences."},
    {"role": "user", "content": "Do you have oat milk?"},
    {"role": "assistant", "content": "Yes, oat, soya and lactose-free milk are available for every coffee at no extra cost."},
    {"role": "user", "content": "And on Sundays?"}
  ]
}
```

Os detalhes mudam entre provedores. Alguns põem o texto de sistema num campo próprio ao lado das
mensagens, e não como a primeira mensagem; os nomes dos campos e dos papéis também variam. Tire-os
da documentação do provedor, que também diz quais modelos aceitam mensagem de sistema. **O que se
mantém é a forma**: instruções permanentes primeiro, depois os turnos em ordem.

## Instruções permanentes, enviadas toda vez

O modelo não guarda nada entre pedidos. Para continuar uma conversa, a aplicação envia a conversa
**inteira** de novo, com a nova mensagem do usuário no fim, e a mensagem de sistema no topo de cada
pedido:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três pedidos lado a lado. O pedido 1 envia a mensagem de sistema e a primeira mensagem do usuário. O pedido 2 envia a mensagem de sistema, a primeira troca e a segunda mensagem do usuário. O pedido 3 envia a mensagem de sistema, as duas trocas e a terceira mensagem do usuário. A mensagem de sistema é o primeiro bloco nos três.\"><text x=\"127\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pedido 1</text><rect x=\"20\" y=\"34\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"127\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">system: regras fixas</text><rect x=\"20\" y=\"68\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"28\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: Vocês têm leite de aveia?</text><text x=\"362\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pedido 2</text><rect x=\"255\" y=\"34\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">system: regras fixas</text><rect x=\"255\" y=\"68\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"263\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: Vocês têm leite de aveia?</text><rect x=\"255\" y=\"102\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"263\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assistant: Sim, sem custo extra.</text><rect x=\"255\" y=\"136\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"263\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: E aos domingos?</text><text x=\"597\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">pedido 3</text><rect x=\"490\" y=\"34\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"597\" y=\"48\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">system: regras fixas</text><rect x=\"490\" y=\"68\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"82\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: Vocês têm leite de aveia?</text><rect x=\"490\" y=\"102\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assistant: Sim, sem custo extra.</text><rect x=\"490\" y=\"136\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: E aos domingos?</text><rect x=\"490\" y=\"170\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"184\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assistant: Sim, todo dia.</text><rect x=\"490\" y=\"204\" width=\"215\" height=\"28\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"498\" y=\"218\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">user: Posso ter reembolso?</text></svg>", "caption": "Cada pedido leva a conversa inteira até ali, e a mensagem de sistema está no topo de todos. Ela não é lembrada entre pedidos; é enviada de novo."}
```

É por isso que a mensagem de sistema é o lugar para o que precisa valer em todo turno. Uma regra dada
uma vez na primeira mensagem do usuário ainda está no histórico no terceiro turno, e agora é uma
mensagem entre muitas, escrita na mesma voz que as perguntas do cliente. A mensagem de sistema vem
primeiro, toda vez, e no seu próprio papel.

Isso também quer dizer que **a mensagem de sistema é paga a cada pedido**, como os exemplos da
lição 21. A próxima seção de leitura conta uma.

## A precedência é treinada, não imposta

A crença comum é que a mensagem de sistema é um conjunto de regras que o modelo não consegue
quebrar. **Não existe mecanismo que a imponha.** A mensagem de sistema é texto no mesmo contexto que
todo o resto, e o modelo a trata como mais autorizada porque foi treinado com conversas em que
segui-la era o comportamento certo.

Esse treinamento é forte, e não é garantia. Uma mensagem do usuário que discute com o prompt de
sistema, ou um texto dentro de um documento que se diz uma nova instrução, pode vencer. A lição 7
trata exatamente disso, e de por que as defesas que funcionam estão fora do prompt: uma ferramenta
que o modelo não consegue chamar, dados que nunca lhe foram dados, uma ação que espera uma pessoa.

Então escreva a mensagem de sistema como se o modelo fosse segui-la, e **projete a aplicação como
se às vezes ele não fosse**. Nada que o assistente nunca deve fazer pode depender só da mensagem de
sistema.
