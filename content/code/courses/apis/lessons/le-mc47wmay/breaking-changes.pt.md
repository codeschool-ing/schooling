---
title: Enxergando uma mudança que quebra
version: 1
---

**Com o contrato num arquivo, uma mudança na API é uma mudança nesse arquivo, e dá para lê-la antes
de ela ir para produção.** A aula 1 traçou a linha: você pode acrescentar a uma API, e não pode
tirar sem quebrar os clientes que usavam o que você tirou. Um documento transforma essa regra, de
algo que quem revisa precisa lembrar, em algo que duas versões de um arquivo conseguem mostrar.

De que lado da linha uma mudança cai depende de duas coisas ao mesmo tempo. Uma é a direção: uma
resposta é lida pelo cliente, uma requisição é escrita por ele. A outra é se o servidor agora dá mais
ou pede mais:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 290\" role=\"img\" aria-label=\"Uma grade com dois eixos. Colunas: o servidor promete ou aceita mais, e o servidor promete menos ou exige mais. Linhas: uma resposta, que o cliente lê, e uma requisição, que o cliente envia. Resposta e mais: seguro, por exemplo um campo novo em Book. Resposta e menos: quebra, por exemplo price_cents removido ou renomeado. Requisição e aceita mais: seguro, por exemplo um campo opcional novo ou um pattern mais frouxo. Requisição e exige mais: quebra, por exemplo um campo obrigatório novo ou um pattern de ISBN mais rígido.\"><text x=\"330\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor promete ou aceita mais</text><text x=\"565\" y=\"22\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">o servidor promete menos ou exige mais</text><text x=\"100\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma resposta</text><text x=\"100\" y=\"117\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cliente lê</text><text x=\"100\" y=\"210\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">uma requisição</text><text x=\"100\" y=\"227\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o cliente envia</text><rect x=\"214\" y=\"46\" width=\"232\" height=\"118\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">seguro</text><text x=\"330\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um campo novo em Book</text><text x=\"330\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cover_url: {type: string}</text><text x=\"330\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">valor novo de enum ou status: pergunte antes</text><rect x=\"450\" y=\"46\" width=\"232\" height=\"118\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"566\" y=\"72\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">quebra</text><text x=\"566\" y=\"100\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um campo removido ou renomeado</text><text x=\"566\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">price_cents → price</text><rect x=\"214\" y=\"168\" width=\"232\" height=\"104\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"330\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\" font-weight=\"600\">seguro</text><text x=\"330\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um campo opcional novo</text><text x=\"330\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">uma regra mais frouxa</text><rect x=\"450\" y=\"168\" width=\"232\" height=\"104\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"566\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\" font-weight=\"600\">quebra</text><text x=\"566\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um campo obrigatório novo</text><text x=\"566\" y=\"244\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um pattern mais rígido em isbn</text></svg>", "caption": "Se uma mudança quebra depende de duas coisas ao mesmo tempo: para que lado os dados vão, e se o servidor dá mais ou pede mais."}
```

As duas linhas são espelhos uma da outra. **Numa resposta, o servidor pode dar mais e não pode dar
menos**, porque o cliente lê o que lhe foi prometido. **Numa requisição, ele pode aceitar mais e não
pode exigir mais**, porque o cliente envia o que lhe disseram para enviar. Um pattern de ISBN mais
rígido é uma promessa de mais numa resposta, que nenhum leitor se incomoda de receber, e uma
exigência de mais numa requisição, em que algum cliente em algum lugar manda hífens.

## Uma mudança, como diff

A versão 2 da aula 1 trocou `price_cents` por um objeto `price`. Suponha que alguém fizesse uma
mudança menor do mesmo tipo no documento da versão 1, renomeando o campo para `price` com um `sed`,
num arquivo novo:

```
ana@api:~/shelf$ sed 's/price_cents/price/' openapi.yaml > next.yaml
ana@api:~/shelf$ diff openapi.yaml next.yaml
153c153
<       required: [isbn, title, author_id, year, price_cents]
---
>       required: [isbn, title, author_id, year, price]
159c159
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
169c169
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
173c173
<       required: [id, isbn, title, author_id, year, price_cents, stock]
---
>       required: [id, isbn, title, author_id, year, price, stock]
180c180
<         price_cents: {type: integer, minimum: 0}
---
>         price: {type: integer, minimum: 0}
```

O `diff` aponta cinco linhas mudadas. O documento continua válido, e o validador confirma:

```
ana@api:~/shelf$ .venv/bin/openapi-spec-validator next.yaml
next.yaml: OK
```

**Um documento válido pode ser uma mudança que quebra**, e este quebra clientes do shelf de três
jeitos diferentes. As linhas 153 e 159 pertencem a `NewBook`, que é uma requisição: um cliente que
cria ou substitui um livro manda `price_cents`, que o `additionalProperties: false` agora recusa, e
não manda `price`, que o `required` agora exige. A linha 169 é `BookChange`, outra requisição, então
um PATCH que muda um preço para de funcionar. As linhas 173 e 180 são `Book`, uma resposta, e todo
cliente que lê um preço não acha nada onde procura.

Para saber disso, você precisou do nome do schema em que cada linha está, e de saber se esse schema é
enviado ou recebido. Nenhuma das duas coisas está na linha. **O `diff` vê texto, e a pergunta é sobre
a estrutura**: `Book` é uma resposta porque as operações em `paths` o usam nas suas `responses`, bem
acima, no arquivo, da linha que mudou.

## Ferramentas que seguem as referências

Um verificador de mudanças que quebram lê os dois documentos, segue cada `$ref` a partir de cada
operação e classifica cada diferença com as duas perguntas da figura acima. O oasdiff é um bastante
usado, escrito em Go, e o openapi-diff é outro; nenhum dos dois está no repositório do Ubuntu, e
nenhum foi rodado para esta aula. Diante destes dois arquivos, um verificador desse tipo é feito
para apontar como quebra a propriedade removida da resposta e a nova propriedade obrigatória da
requisição, operação por operação. É dessa lista que quem revisa precisa.

O lugar de rodar um é o mesmo do validador, no CI. Ele compara o documento de um pull request com o
da branch principal, e faz o build falhar numa mudança que quebra e não vem com uma versão nova.
É o hábito que a versão 2 da aula 1 pediu, transformado em conferência: uma mudança que quebra é
permitida, num endereço novo, e a ferramenta garante que ela não aconteceu em nenhum outro lugar.
