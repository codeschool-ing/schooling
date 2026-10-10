---
title: O aceite
version: 1
---

**O aceite (o *sign-off*) é a declaração escrita do cliente de que uma versão foi aceita**: de que
ela cumpre os critérios de aceitação combinados, ou os cumpre o bastante, e pode ir ao ar. É fácil
lê-lo como formalidade, uma assinatura no pé de um relatório de teste. Ele é o único momento do
projeto em que a pessoa que carrega o risco de uma versão diz, por escrito, que aceita esse risco,
e vale exatamente tanto quanto os critérios a que se refere.

## O que um aceite diz

O formato vai de um e-mail a um anexo de contrato, e o conteúdo não muda. Um aceite do boxoffice
nomeia:

- **a build**, exatamente: boxoffice 1.1, a que a sessão usou, e não "a versão nova";
- **os critérios** e o resultado de cada um, aprovado ou reprovado, como a sessão registrou;
- **os defeitos em aberto**, cada um com a decisão do cliente: precisa ser corrigido antes, ou fica
  aceito por enquanto;
- **as condições**, se houver, sob as quais o aceite vale;
- **quem** aceita, e **quando**.

Num projeto feito sob contrato, o aceite costuma ser o que libera um pagamento, e é por isso que
critérios vagos causam mais estrago aqui. "Estudantes pagam um preço justo" convida a uma discussão
no dia em que o dinheiro muda de mão; "o total é R$ 80,00" encerra uma.

## A decisão da gerente sobre a 1.1

Depois da tarde da seção 04 desta aula, os critérios ficaram assim: o cenário do estudante
falhou, os outros três passaram. A gerente tinha três jeitos de responder, e são os três que um
cliente sempre tem.

**Aceitar.** Assinar, e a 1.1 vai ao ar como está. Fora de questão aqui, pelas palavras dela:
estudantes são uma parte grande do público do teatro, e ela não vai reembolsá-los na mão.

**Aceitar com condições.** Assinar, desde que algo seja feito. Ela poderia aceitar a 1.1 com a caixa
de estudante retirada do formulário até a correção, e vender meia-entrada no balcão na mão
enquanto isso. Um aceite condicional é uma decisão de verdade, e as condições dele são escritas com
o mesmo cuidado que os critérios, porque cada uma é uma promessa que alguém precisa cumprir.

**Rejeitar.** Não assinar; a versão volta para ser corrigida. Foi o que ela escolheu, e o motivo
que deu é a coisa mais útil do documento: "as escolas reservam na terça".

**Nenhuma das três cabe ao testador escolher.** A parte da Ana foi fazer a decisão ser informada:
todo critério rodado, todo achado anotado nas palavras da gerente, todo defeito em aberto listado
com a sua consequência. Um testador que diz "eu não soltaria isso" na reunião não fez nada de
errado, e a decisão continua não sendo dele.

## O que acontece depois de um não

Uma rejeição não é o fim do UAT; ela começa um ciclo pelo qual a maioria das versões passa ao menos
uma vez.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l12-signoff-loop\" aria-label=\"Um ciclo de caixas. Sessão de UAT, o cliente conduz, leva a o cliente decide, e assina, ou não. Aceita leva à direita para vai ao ar, com suas condições. Rejeita leva para baixo a Rui corrige, uma nova build, 1.2, depois à esquerda a sanidade, depois regressão, aulas 9 e 10, e de volta para cima à sessão de UAT, para refazer os critérios que falharam. Uma seta tracejada sai da decisão para uma caixa à parte, pedido de mudança, critérios próprios, outra versão.\"><defs><marker id=\"mt-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"mt-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"mt-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sessão de UAT</text><text x=\"105.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">o cliente conduz</text><rect x=\"265.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">o cliente decide</text><text x=\"350.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">e assina, ou não</text><rect x=\"510.0\" y=\"30.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"48.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">vai ao ar</text><text x=\"595.0\" y=\"63.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">com suas condições</text><rect x=\"265.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Rui corrige</text><text x=\"350.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">uma nova build, 1.2</text><rect x=\"20.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"105.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">sanidade, depois regressão</text><text x=\"105.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">aulas 9 e 10</text><rect x=\"510.0\" y=\"168.0\" width=\"170.0\" height=\"52.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"595.0\" y=\"186.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">pedido de mudança</text><text x=\"595.0\" y=\"201.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">critérios próprios, outra versão</text><path d=\"M192.0 56.0 L262.0 56.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M437.0 56.0 L507.0 56.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"472.5\" y=\"45.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">aceita</text><path d=\"M350.0 84.0 L350.0 165.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-amber)\"></path><text x=\"358.0\" y=\"125.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">rejeita</text><path d=\"M263.0 194.0 L193.0 194.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-paper-dim)\"></path><path d=\"M105.0 166.0 L105.0 85.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#mt-ah-phosphor)\"></path><text x=\"113.0\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">refaz os critérios</text><text x=\"113.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">que falharam</text><path d=\"M425.0 84.0 L530.0 165.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#mt-ah-paper-dim)\"></path></svg>", "caption": "O que vem depois de uma versão rejeitada. A correção dá a volta no ciclo e retorna ao cliente; um pedido de mudança sai dele e começa o seu."}
```

O Rui corrige `discount` e a build vira 1.2. O time confere a correção em si com um teste de
sanidade (aula 9), depois roda a suíte de regressão (aula 10), porque uma correção na função que
decide todos os preços é o tipo de mudança que quebra uma vizinha. Só então a build volta para a
gerente, e ela não repete a tarde inteira: refaz o critério que falhou, mais o que a mudança possa
ter tocado, que aqui são os quatro, já que todos tratam de preço.

O pedido de mudança sobre o balcão segue em separado. É um requisito novo, então ganha critérios
próprios, escritos com a gerente do mesmo jeito que na seção 03 desta aula, e a sua própria volta
pelo ciclo numa versão posterior. Misturá-lo à correção seguraria o desconto de estudante por
causa de uma discussão sobre o balcão, e as escolas reservam na terça.

## O que uma assinatura não quer dizer

**Um aceite não diz que a versão não tem defeitos.** Ele diz que o cliente sabe quais ela tem e os
aceita. A 1.2 pode ainda carregar as mensagens com erro de ortografia e o reembolso fora de hora que
a aula 11 achou, listados como abertos e aceitos. Esse é um aceite normal, e honesto: a gerente não
vai se surpreender com eles, porque estão escritos acima do nome dela.

Ele também não encerra o teste. A produção traz clientes de verdade, celulares de verdade e uma
terça-feira de verdade, e a aula 15 começa pelo jeito de relatar o que eles acham.
