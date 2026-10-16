---
title: O que um fluxo de confirmação promete
version: 1
---

A primeira ideia que a maioria das pessoas tem de testar e-mail é conferir se a mensagem chegou.
Chegar é a parte fácil. **Um e-mail de confirmação é um passo num fluxo com estado**: uma conta
esperando confirmação, um segredo enviado a um endereço, um relógio correndo sobre esse segredo e
regras para o que acontece quando alguém pede outro. A maior parte do que dá errado mora nessas
regras, e nada disso aparece na mensagem em si.

## Por que uma aplicação confirma um endereço

Quando alguém digita um endereço de e-mail num formulário de cadastro, a aplicação não tem ideia se
o endereço é dessa pessoa. Ele pode ter um erro de digitação, que manda toda mensagem futura para um
estranho. Pode ser de outra pessoa, digitado de propósito. Mandar um link ao endereço e esperar que
alguém o abra prova uma coisa: **quem se cadastrou consegue ler aquela caixa de entrada.** No
boxoffice isso também decide dinheiro, porque o R5 dá a uma conta confirmada, um membro, 10% de
desconto.

## As partes do fluxo

O R3 descreve o fluxo do boxoffice em duas frases: uma conta nova recebe um e-mail com um link que a
confirma, válido por 24 horas, e pedir um link novo faz o antigo parar de funcionar. Lido por um
testador, isso são cinco coisas a conferir.

**O link carrega um token**, uma sequência aleatória que representa "esta conta, este endereço".
Quem tem o token consegue confirmar a conta, então o token é um pequeno segredo. Ele precisa ser
longo o bastante para ninguém adivinhar, e deve existir num lugar só, o e-mail.

**O token expira.** Um link que funcionasse para sempre seria um segredo que nunca deixa de ser
segredo, parado numa caixa de entrada por anos. O R3 dá a ele 24 horas.

**Pedir de novo substitui o link.** As pessoas pedem um segundo link quando o primeiro não chegou, ou
chegou e se perdeu, ou foi para uma caixa que elas dividem com alguém. Em todos esses casos o primeiro
link agora está num lugar que ninguém vigia, e a segunda frase do R3 existe para desligá-lo.

**Usar um link pode ou não encerrá-lo.** Muitos produtos fazem o link de confirmação valer uma vez
só: depois que confirmou a conta, abri-lo de novo diz que ele não é mais válido. O R3 não diz nada
sobre isso, o que é um achado diferente de um defeito, como mostra a próxima seção.

**As respostas dizem só o necessário.** A página que recebe o pedido de um novo link responde a mesma
frase exista ou não uma conta para aquele endereço. Se respondesse "essa conta não existe", o
formulário diria a qualquer um que perguntasse se determinada pessoa tem conta no teatro, e isso é
uma informação sobre essa pessoa. O testador confere se as duas respostas são idênticas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l22-two-links\" aria-label=\"Uma linha do tempo com três barras. Eventos ao longo da base: o cadastro, quando o link A é enviado; o pedido de um novo link, quando o link B é enviado; 24 horas depois do A; e 24 horas depois do B. A primeira barra, o link A como diz o R3, fica viva do cadastro até o pedido do novo link, e para de funcionar ali. A segunda, o link A no boxoffice 1.1, fica viva até 24 horas depois do cadastro, então do pedido do novo link até lá há dois links vivos ao mesmo tempo, que é o defeito 10. A terceira, o link B, fica viva do pedido até 24 horas depois dele.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M190.0 26.0 L190.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M280.0 26.0 L280.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M640.0 26.0 L640.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M550.0 26.0 L550.0 128.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><path d=\"M550.0 152.0 L550.0 180.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"20.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link A, como diz o R3</text><text x=\"20.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link A, no boxoffice 1.1</text><text x=\"20.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">link B</text><rect x=\"190.0\" y=\"32.0\" width=\"90.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M280.0 40.0 L550.0 40.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"290.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">para de funcionar</text><rect x=\"190.0\" y=\"82.0\" width=\"90.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"280.0\" y=\"82.0\" width=\"270.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"415.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">dois links vivos: defeito 10</text><rect x=\"280.0\" y=\"132.0\" width=\"360.0\" height=\"16.0\" rx=\"3\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><path d=\"M180.0 180.0 L670.0 180.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><text x=\"670.0\" y=\"168.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">tempo</text><text x=\"190.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">cadastro:</text><text x=\"190.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">link A enviado</text><text x=\"280.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">novo link pedido:</text><text x=\"280.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">link B enviado</text><text x=\"550.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 horas</text><text x=\"550.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">depois do A</text><text x=\"640.0\" y=\"198.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">24 horas</text><text x=\"640.0\" y=\"211.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">depois do B</text></svg>", "caption": "Quanto tempo cada link de confirmação vive. O R3 encerra o link A quando o link B é enviado; o boxoffice 1.1 o deixa correr as 24 horas inteiras.", "same": ["link B"]}
```

## Casos, a partir do requisito

Cada uma dessas partes vira um ou mais casos, e todo resultado esperado vem do R3, ou fica marcado
como pergunta quando o R3 se cala. Essa marcação é a honesta: **um caso cujo resultado esperado
ninguém escreveu é uma pergunta para o cliente**, e a aula 12 trata de como fazê-la.

| # | caso | esperado |
|---|---|---|
| 1 | cadastrar, abrir o link em menos de 24 horas | a conta é confirmada (R3) |
| 2 | abrir o link com um caractere do token trocado | o link não é válido |
| 3 | abrir o link mais de 24 horas depois do envio | o link não é válido (R3) |
| 4 | pedir um novo link e abrir o antigo | o link não é válido (R3) |
| 5 | pedir um novo link e abrir o novo | a conta é confirmada (R3) |
| 6 | abrir um link que já confirmou a conta | não está escrito: perguntar ao teatro |
| 7 | pedir um novo link para um endereço sem conta | a mesma resposta de um que tem conta, e nenhum e-mail |
| 8 | pedir um novo link para uma conta já confirmada | nenhum e-mail |
| 9 | ler o próprio e-mail | o endereço certo, o nome da conta, um link para o site certo |

O caso 9 esconde um clássico. **O link do e-mail é montado pela aplicação a partir das próprias
configurações**, e o boxoffice o monta com `127.0.0.1` e a porta dele. No servidor do teatro ele
teria de citar o endereço real do teatro. Um link que aponta para uma máquina de teste, ou para a
porta errada, parece perfeitamente normal na mensagem e só falha quando alguém clica nele de casa. É
o tipo de defeito de que trata a aula 21, que mora no ambiente e não no código.

## Para onde vai o e-mail enquanto você testa

Todos os casos acima exigem que você leia o e-mail. Em produção isso significa uma caixa de entrada
real, e ninguém quer uma rodada de teste mandando links de confirmação a clientes reais. Por isso os
ambientes de teste param o e-mail antes de ele sair e o guardam onde o testador consegue ler. O
boxoffice faz isso com a caixa de saída, e a próxima seção roda os casos ali.
