---
title: Qual palavra, e o que ela promete
version: 1
---

A primeira palavra de uma requisição diz o que fazer. Há um punhado em uso comum, e a diferença
entre elas não é bem sobre o que o servidor faz — um servidor faz o que quiser — mas sobre o que
todo mundo mais tem direito de supor.

## As palavras

| método | pede | costuma levar corpo |
|---|---|---|
| `GET` | uma cópia de algo | não |
| `HEAD` | os cabeçalhos que um `GET` daria, sem corpo | não |
| `POST` | isto, processado — enviar, criar, disparar | sim |
| `PUT` | isto posto neste endereço, no lugar do que havia | sim |
| `PATCH` | esta parte da coisa alterada | sim |
| `DELETE` | a coisa deste endereço removida | raramente |
| `OPTIONS` | o que é permitido aqui | não |

Dois deles merecem uma frase antes do resto. O `HEAD` dá só os cabeçalhos: é como se pergunta *isto
mudou?* ou *qual o tamanho?* sem mover o arquivo. O `OPTIONS` pergunta o que um servidor permite, e
você vai encontrá-lo de novo como a pergunta que um navegador faz antes de deixar um site chamar
outro.

## Seguro, e idempotente

Essas duas palavras são como a diferença é de fato descrita, e não são sinônimos.

**Seguro** quer dizer que a requisição não pretende mudar nada. `GET` e `HEAD` são seguros. Qualquer
coisa que não peça para mudar o mundo pode ser feita livremente por qualquer um: um navegador pode
buscar um link antes de você clicar, um proxy pode guardar a resposta, um rastreador pode visitar
tudo que encontrar.

**Idempotente** quer dizer que fazer duas vezes deixa o mundo como ficou depois de fazer uma. O
`PUT` é idempotente — ponha o preço em dez, ponha de novo em dez, o preço é dez. O `DELETE` é
idempotente; a coisa sumiu de qualquer jeito. O `POST` não é, e o `PATCH` em geral também não: some
um à contagem, duas vezes, e a contagem subiu dois.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Um quadrado dividido em quatro. Seguro e idempotente contém GET, HEAD e OPTIONS. Idempotente mas não seguro contém PUT e DELETE. Nenhum dos dois contém POST e PATCH. O canto restante, seguro mas não idempotente, está vazio porque não pode existir.\"> <text x=\"230\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">idempotente — duas vezes é igual a uma</text> <text x=\"580\" y=\"24\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">não idempotente</text> <rect x=\"60\" y=\"36\" width=\"340\" height=\"108\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"230\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">GET HEAD OPTIONS</text> <text x=\"230\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">buscar antes, guardar cópia, seguir</text> <text x=\"230\" y=\"120\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">sem pedir permissão a ninguém</text> <rect x=\"410\" y=\"36\" width=\"250\" height=\"108\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-dasharray=\"4 3\"></rect> <text x=\"535\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">vazio, e tem que ser</text> <text x=\"535\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">não mudar nada não muda nada duas vezes</text> <rect x=\"60\" y=\"156\" width=\"340\" height=\"108\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"230\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">PUT DELETE</text> <text x=\"230\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">muda coisas, e repetir não faz mal</text> <text x=\"230\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">então dá para repetir se a resposta sumir</text> <rect x=\"410\" y=\"156\" width=\"250\" height=\"108\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\"></rect> <text x=\"535\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"14\" fill=\"var(--paper)\">POST PATCH</text> <text x=\"535\" y=\"216\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">repetir faz de novo</text> <text x=\"535\" y=\"240\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">e esse é o caso difícil</text> <text x=\"30\" y=\"94\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">seguro</text> <text x=\"30\" y=\"216\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">não</text> <text x=\"360\" y=\"288\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">o quadrante de baixo à esquerda é o que se esquece, e é onde repetir vira possível</text> </svg>", "caption": "Seguro é sobre mudar alguma coisa. Idempotente é sobre fazer duas vezes importar ou não."}
```

Todo método seguro é idempotente, porque uma requisição que não muda nada não muda nada duas vezes.
O contrário não vale, e o quadrante interessante é o que tem `PUT` e `DELETE`.

## Por que a distinção tem dentes

Ela decide o que acontece quando algo dá errado, que é a única hora em que alguém descobre.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"Uma requisição é enviada e nenhuma resposta volta. Duas possibilidades são desenhadas: a requisição nunca chegou, ou foi executada e a resposta se perdeu. Do lado do cliente as duas são idênticas.\"> <rect x=\"20\" y=\"34\" width=\"140\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\"></rect> <text x=\"90\" y=\"57\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">você envia</text> <text x=\"200\" y=\"30\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper-dim)\">e nada volta, o que pode ser qualquer um destes</text> <rect x=\"200\" y=\"40\" width=\"500\" height=\"70\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\"></rect> <text x=\"450\" y=\"62\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--paper)\">nunca chegou, e nada aconteceu</text> <text x=\"450\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">ou chegou, foi executado, e a resposta se perdeu</text> <text x=\"360\" y=\"140\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">de onde você está, os dois são a mesma imagem</text> <rect x=\"20\" y=\"158\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--phosphor)\" fill-opacity=\".18\" stroke=\"var(--phosphor)\"></rect> <text x=\"185\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">PUT, DELETE, GET</text> <text x=\"185\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--phosphor)\">mande de novo; a segunda vez não custa nada</text> <rect x=\"370\" y=\"158\" width=\"330\" height=\"76\" rx=\"3\" fill=\"var(--amber)\" fill-opacity=\".18\" stroke=\"var(--amber)\"></rect> <text x=\"535\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"12\" fill=\"var(--paper)\">POST</text> <text x=\"535\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" fill=\"var(--amber)\">pode pagar duas vezes, ou não pagar nenhuma</text> </svg>", "caption": "A escolha do método é uma decisão sobre o que acontece no dia em que uma resposta sumir."}
```

Uma requisição é enviada e nenhuma resposta volta. É tudo que o cliente sabe. A requisição pode ter
se perdido na ida, ou pode ter sido executada perfeitamente e a resposta se perdido na volta — e do
lugar onde você está as duas são idênticas.

Se o método era idempotente, não há o que decidir: mande de novo. Na pior das hipóteses é feito uma
segunda vez, e sobreviver a ser feito duas vezes é o que idempotente quer dizer.

Se era um `POST`, você tem uma escolha de verdade. Mande de novo e o pagamento pode passar duas
vezes. Não mande, e pode não ter passado nenhuma. Esse dilema é por que toda página de pagamento
pede para você não apertar o botão duas vezes, e por que sistemas sérios anexam um identificador à
tentativa para o servidor reconhecer uma repetição.

## A promessa não é imposta

Nada impede um servidor de apagar um registro ao receber um `GET`. O protocolo descreve o que a
palavra *deveria* significar; ele não fiscaliza.

O que parece inofensivo até você reparar em quem depende da promessa. Um rastreador segue links —
todos eles, sem pedir — porque links são `GET`s e `GET`s são seguros. Um navegador busca uma página
antes de você clicar, pelo mesmo motivo. Um proxy guarda uma cópia.

Então uma página de administração cujos botões de apagar eram links comuns é uma página em que algo
vai acabar visitando cada um deles. Isto não é uma história de advertência inventada para uma aula:
aconteceu com aplicações reais, mais de uma vez, e o primeiro sinal foi um banco de dados se
esvaziando durante a noite sem ninguém logado.

A regra que segue é curta. **Se muda alguma coisa, não é um `GET`.**

## Escolhendo, na prática

Na maioria dos dias a decisão é pequena. Buscar qualquer coisa é um `GET`. Um formulário que cria
algo é um `POST`. Substituir um registro inteiro num endereço conhecido é um `PUT`; mudar um campo
dele é um `PATCH`; removê-lo é um `DELETE`.

Onde os times discutem é na borda: marcar um pedido como enviado é um `PATCH` no pedido, ou um
`POST` em algo que representa o envio? Os dois são defensáveis, e a pergunta que vale é a que abriu
esta seção — o que eu gostaria que um proxy, um navegador e uma repetição supusessem? O método é um
recado para software que você não escreveu e nunca vai conhecer, e é isso que você está escolhendo
ao escolher a palavra.
