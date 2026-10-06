---
title: Erros que o leitor consegue achar e corrigir
version: 1
---

As mensagens do próprio navegador são um começo. Elas aparecem num balão ao lado do primeiro campo inválido e somem depois de alguns segundos, um campo por vez, com palavras do navegador e não suas. A maioria dos formulários de verdade acrescenta as próprias **dicas** e **mensagens de erro** na página, escritas para as perguntas reais do formulário, e o trabalho está em ligá-las ao campo para que todos as recebam, e não só quem consegue ver onde elas aparecem.

A ferramenta para isso é o **`aria-describedby`**, que aponta o `id` de um ou mais elementos cujo texto descreve o campo. Um leitor de tela lê o nome do campo e depois a descrição:

```html
<!doctype html>
<html lang="en">
  <head>
    <meta charset="utf-8">
    <title>Order · Andorinha Books</title>
  </head>
  <body>
    <main>
      <h1>Order a book</h1>
      <form action="order" method="post">
        <label for="cep">CEP (postcode)</label>
        <input id="cep" name="cep" pattern="[0-9]{5}-[0-9]{3}"
               aria-describedby="cep-hint cep-error" aria-invalid="true"
               value="05422000">
        <p id="cep-hint">Eight digits with a hyphen, as in 05422-000.</p>
        <p id="cep-error">This CEP is missing its hyphen.</p>
        <button>Send the order</button>
      </form>
    </main>
  </body>
</html>
```

```
ana@laptop:~/site$ probe order.html describe '#email'
role textbox, name "Email", required
ana@laptop:~/site$ probe errors.html describe '#cep'
role textbox, name "CEP (postcode)", description "Eight digits with a hyphen, as in 05422-000. This CEP is missing its hyphen.", invalid
```

O campo de email do formulário de encomenda tem um **nome** e é **required**, e é tudo o que o navegador consegue dizer dele. O campo de CEP da página de erro também tem uma **descrição**, feita dos dois parágrafos na ordem em que o `aria-describedby` os lista: a dica, depois o erro. E ele está marcado como **invalid**, por causa do `aria-invalid="true"`, que uma página define quando a própria verificação falha, para que o estado seja anunciado junto com a mensagem.

## O que torna uma mensagem de erro útil

**Diga o que está errado e como corrigir**, com as palavras da pergunta: *This CEP is missing its hyphen* é melhor que *Formato inválido*, que não diz ao leitor nada sobre o que fazer.

**Mostre-a ao lado do campo**, e mantenha-a até o campo ser corrigido. Uma mensagem só no topo do formulário faz o leitor procurar o campo; uma mensagem só num balão some antes de ele terminar de ler.

**Nunca dependa só da cor.** Uma borda vermelha não diz nada a quem não distingue vermelho de cinza; as palavras precisam estar lá também. A aula 5 mostra como o CSS consegue estilizar um campo que o navegador considera inválido, e a regra continua valendo: o estilo é um acréscimo à mensagem.

**Não apague o que o leitor digitou.** Um formulário que volta do servidor com todos os campos vazios porque um estava errado é o motivo mais comum para alguém desistir dele.
