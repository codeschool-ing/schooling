---
title: Validação nativa
version: 1
---

Antes de enviar uma requisição, o navegador consegue conferir os valores contra regras escritas como atributos. É a **validação nativa**: sem script, sem nada para instalar, e com mensagens na língua do próprio leitor. Aqui está o formulário de encomenda do sebo com cinco regras:

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
        <label for="name">Name</label>
        <input id="name" name="name" required>

        <label for="email">Email</label>
        <input id="email" name="email" type="email" required>

        <label for="cep">CEP (postcode)</label>
        <input id="cep" name="cep" pattern="[0-9]{5}-[0-9]{3}">

        <label for="copies">Copies</label>
        <input id="copies" name="copies" type="number" min="1" max="5" value="1">

        <label for="title">Title</label>
        <input id="title" name="title" required minlength="2">

        <button>Send the order</button>
      </form>
    </main>
  </body>
</html>
```

Apertando o botão com tudo vazio:

```
ana@laptop:~/site$ probe order.html send button
nothing was sent
  invalid name: Please fill out this field.
  invalid email: Please fill out this field.
  invalid title: Please fill out this field.
```

**Nada foi enviado.** Os três campos `required` estão vazios, e o navegador se recusou a montar a requisição. Os outros dois passam: o CEP é opcional, e o número de exemplares começa em 1. Agora com um valor em cada campo, cada um errado do seu jeito, e `validity` imprimindo o que o navegador concluiu sobre cada um:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' 'ana@' fill '#cep' 05422000 fill '#copies' 9 fill '#title' V validity input
input#name  value "Ana Souza"  valid
input#email  value "ana@"  typeMismatch
  message: Please enter a part following '@'. 'ana@' is incomplete.
input#cep  value "05422000"  patternMismatch
  message: Please match the requested format.
input#copies  value "9"  rangeOverflow
  message: Value must be less than or equal to 5.
input#title  value "V"  tooShort
  message: Please lengthen this text to 2 characters or more (you are currently using 1 character).
```

Cada atributo produziu o seu resultado:

| atributo | a regra | o que estava errado | a indicação |
| --- | --- | --- | --- |
| `required` | não pode ficar vazio | (agora passa) | `valueMissing` |
| `type="email"` | com cara de endereço | nada depois do `@` | `typeMismatch` |
| `pattern` | casa com uma expressão regular, inteira | sem hífen | `patternMismatch` |
| `min`, `max` | um número dentro da faixa | 9 contra um máximo de 5 | `rangeOverflow` |
| `minlength` | pelo menos tantos caracteres | 1 contra 2 | `tooShort` |

As mensagens são escritas pelo navegador, e cada uma nomeia o defeito específico. Estas foram impressas por um Chromium rodando em inglês; um navegador configurado em português as escreve em português, sem nenhuma mudança na página. E com tudo certo:

```
ana@laptop:~/site$ probe order.html fill '#name' 'Ana Souza' fill '#email' ana@example.com fill '#cep' 05422-000 fill '#copies' 2 fill '#title' 'Vidas Secas' send button
POST /order
Content-Type: application/x-www-form-urlencoded
name=Ana+Souza&email=ana%40example.com&cep=05422-000&copies=2&title=Vidas+Secas
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"A sequência quando um formulário é enviado. O leitor aperta o botão ou Enter. O navegador confere todos os campos. Se todos são válidos, a requisição é montada e enviada ao action. Se algum é inválido, nada é enviado, o primeiro campo inválido ganha o foco e a mensagem dele aparece.\"><defs><marker id=\"ah5\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"70\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"85\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o leitor aperta</text><text x=\"85\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o botão ou Enter</text><rect x=\"190\" y=\"70\" width=\"150\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265\" y=\"87\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o navegador confere</text><text x=\"265\" y=\"103\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todos os campos</text><rect x=\"390\" y=\"10\" width=\"300\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"27\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todos válidos: a requisição é</text><text x=\"540\" y=\"43\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">montada e enviada ao action</text><rect x=\"390\" y=\"130\" width=\"300\" height=\"64\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"540\" y=\"146\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">algum inválido: nada é enviado,</text><text x=\"540\" y=\"162\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o primeiro campo inválido ganha o foco</text><text x=\"540\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e a mensagem dele aparece</text><line x1=\"150\" y1=\"95\" x2=\"186\" y2=\"95\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></line><path d=\"M340 88 C 365 88, 365 35, 386 35\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></path><path d=\"M340 102 C 365 102, 365 162, 386 162\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#ah5)\"></path></svg>", "caption": "A validação nativa roda no momento do envio, e só consegue barrar a requisição; ela nunca muda um valor."}
```

## Escreva regras verdadeiras

Uma regra escrita num formulário é uma afirmação sobre o mundo, e uma errada barra quem não fez nada de errado. Um `pattern` para nomes que só aceita letras recusa *D'Ávila* e *Ana-Luísa*; um `maxlength` de 20 numa rua recusa ruas de verdade. Confira nomes e endereços o mínimo possível: `required`, e talvez um comprimento máximo que o banco de dados de fato tenha. Padrões são para coisas com um formato que alguém definiu, como um CEP.

O `pattern` é comparado com o valor **inteiro**, como se estivesse escrito entre `^` e `$`, então `[0-9]{5}-[0-9]{3}` aceita `05422-000` e recusa `05422-0001`. Expressões regulares têm uma aula própria no curso `javascript`; os padrões de um formulário costumam ser curtos o bastante para ler.
