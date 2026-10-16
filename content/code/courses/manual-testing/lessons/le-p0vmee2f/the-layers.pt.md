---
title: As camadas do teste
version: 1
---

Uma crença comum de quem começa em teste é que teste de unidade é assunto dos desenvolvedores,
escrito numa linguagem que o testador não lê, e que nada nele muda o dia de um testador manual. A
primeira metade é mais ou menos verdade. A segunda não: **as camadas abaixo da sua decidem em que os
seus testes manuais devem gastar tempo**, e explicam um defeito de um jeito que a tela não explica.
Esta aula lê essas camadas como um testador que não vai escrevê-las como profissão, mas vai
trabalhar ao lado de quem escreve.

## Quatro camadas, uma aplicação

Toda camada faz a mesma pergunta, "isto faz o que deveria?", sobre um pedaço maior do programa. O
`qa-fundamentals` as chamou de níveis do modelo V; aqui elas aparecem no boxoffice.

**Um teste de unidade** confere um pedaço pequeno sozinho: uma função, sem servidor, sem navegador e
sem rede. `discount(student, member, tickets)` é a unidade óbvia do boxoffice. Ela recebe três fatos
e devolve uma porcentagem, então um teste pode chamá-la com um estudante e um ingresso e conferir
que volta 50. Ele roda num milésimo de segundo e nada mais precisa estar rodando.

**Um teste de integração** confere que os pedaços funcionam juntos. Reservar no boxoffice envolve o
formulário, o código que o lê, a verificação da quantidade, a chamada a `discount`, a conta do total
e a página do pedido que o mostra. Um teste que envia o formulário à aplicação rodando e lê o total
de volta atravessa tudo isso, e acha os defeitos que moram nas emendas: um campo lido com o nome
errado, uma porcentagem aplicada duas vezes.

**Um teste de sistema** confere a aplicação inteira como um usuário a encontra, num navegador de
verdade, numa tela de verdade. É o que todas as aulas deste curso fizeram até aqui, à mão.

**Um teste de aceitação** pergunta se o cliente consegue tocar o negócio com ela. A aula 12 tratou
disso, e os critérios dela foram escritos nas palavras da gerente do teatro, não nas do código.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l13-reach\" aria-label=\"Cinco caixas em fila, na ordem em que uma reserva passa: navegador, servidor HTTP, book, que lê o formulário, discount, que dá a porcentagem, e a página do pedido. Abaixo, três chaves. O teste de unidade, test_discount.py, cobre só discount. O teste de integração, test_booking.py, cobre tudo do servidor HTTP até a página do pedido. O teste de sistema, uma pessoa num navegador, cobre as cinco.\"><defs><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"78.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">navegador</text><path d=\"M138.0 52.0 L155.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"158.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"216.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor HTTP</text><path d=\"M276.0 52.0 L293.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"296.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"354.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">book</text><text x=\"354.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">lê o formulário</text><path d=\"M414.0 52.0 L431.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"434.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"492.0\" y=\"44.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">discount</text><text x=\"492.0\" y=\"62.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a porcentagem</text><path d=\"M552.0 52.0 L569.0 52.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><rect x=\"572.0\" y=\"24.0\" width=\"116.0\" height=\"56.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"52.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">página do pedido</text><path d=\"M438.0 94.0 L438.0 104.0 L546.0 104.0 L546.0 94.0\" stroke=\"var(--amber)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"492.0\" y=\"118.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--amber)\">teste de unidade</text><text x=\"492.0\" y=\"133.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_discount.py</text><path d=\"M162.0 146.0 L162.0 156.0 L684.0 156.0 L684.0 146.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"423.0\" y=\"170.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--phosphor)\">teste de integração</text><text x=\"423.0\" y=\"185.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">test_booking.py</text><path d=\"M24.0 198.0 L24.0 208.0 L684.0 208.0 L684.0 198.0\" stroke=\"var(--paper)\" stroke-width=\"1.6\" fill=\"none\"></path><text x=\"354.0\" y=\"222.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">teste de sistema</text><text x=\"354.0\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">uma pessoa num navegador</text></svg>", "caption": "O que cada camada de teste alcança no boxoffice. Quanto mais baixa a camada, menos ela atravessa, mais rápido roda e mais exatamente uma falha aponta a causa."}
```

## Por que a base é larga

A imagem de costume é uma pirâmide, muitas vezes atribuída a Mike Cohn: **muitos testes de unidade
na base, menos testes de integração acima deles, e poucos testes pela interface do usuário no
topo**. A forma vem do custo. Um teste de unidade de `discount` roda em milissegundos e, quando
falha, aponta uma função. Um teste que conduz um navegador por cadastro, reserva e pagamento leva
segundos, precisa de um servidor rodando e de um navegador, quebra quando alguém renomeia um botão
e, quando falha, diz só que alguma coisa, em algum lugar, deu errado.

A forma é um conselho, não uma lei, e os times discutem sobre ela. O que importa para você é o
raciocínio por trás: **uma verificação pertence à camada mais baixa que consegue ver o problema**. Se
um estudante paga meia é uma regra dentro de uma função, e um teste de unidade é o lugar mais
barato para segurá-la. Se o total aparece na página do pedido em reais, com vírgula, é algo que só
uma camada que monta a página consegue ver.

## O que isso muda para um testador manual

Três coisas, e nenhuma pede que você escreva código.

**Você fica sabendo o que já está coberto.** Se os testes de unidade dos desenvolvedores rodam todas
as linhas da tabela de desconto a cada mudança, então o seu tempo manual com descontos rende mais
em outro lugar, no que esses testes não veem. Isso quer dizer a página do pedido, a caixa de estudante no celular, um membro que
esqueceu de confirmar a conta. Perguntar "o que os testes de unidade cobrem?" numa reunião de
planejamento é uma pergunta justa, e a resposta muda o plano da aula 1.

**Você lê uma falha com mais precisão.** Um teste de unidade que falha nomeia uma função e uma linha,
e um relatório de defeito que pode dizer "a regra do estudante falha também nos testes de unidade"
poupa uma tarde ao desenvolvedor.

**Você reconhece o que uma camada não pega.** Todos os testes de unidade de `discount` podem passar
enquanto a página mostra o total errado, porque o formulário manda a caixa com outro nome. Esses
defeitos são os que sobram para as camadas de cima, e para você.

As três seções seguintes mostram cada camada no boxoffice com um arquivo de teste de verdade, curto
o bastante para ler inteiro. Ninguém espera que você escreva um; espera-se que você leia um, rode e
diga o que o resultado significa.
