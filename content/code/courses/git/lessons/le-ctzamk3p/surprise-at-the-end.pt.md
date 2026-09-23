---
title: A surpresa no fim
version: 1
---

O ticket #38 pedia **vale-presente**: um cliente compra um, dá para alguém, e essa pessoa gasta na padaria.
A Ana o construiu ao longo do sprint e mostrou na review. Três pessoas se surpreenderam, de três jeitos
diferentes:

- A **Marta**: o vale-presente era para ser usado **só na loja**. O dono não quer pedidos online pagos com
  ele, porque o caixa não vê saldos online. Isso foi dito numa reunião em que a Ana não estava.
- O **Paulo**: o design dele mostrava o saldo numa tela própria, depois de digitado o código. A Ana pôs na
  página de pedidos, porque o ticket não dizia onde, e o desenho estava numa pasta que nunca tinham mandado
  para ela.
- O **Diego**: gastar 10 num vale com 8 de saldo leva o saldo a **-2**. Ele achou em dez minutos, no último
  dia.

Cada surpresa é pequena. Juntas, fazem voltar a maior parte do trabalho do sprint, e ninguém cometeu um
erro que qualquer um deles pudesse ter visto sozinho.

## Por que no fim

Cada um desses fatos existia no começo do sprint. O que deu errado foi **quando as pessoas se
encontraram**:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 366\" role=\"img\" aria-label=\"Dois jeitos de uma funcionalidade passar por quatro papéis ao longo do tempo. Em cima, um revezamento: produto trabalha sozinho, passa para design, que passa para desenvolvimento, que passa para QA; cada barra começa onde a anterior termina, e as surpresas caem todas no fim. Embaixo, juntos: as quatro barras correm lado a lado desde o começo, com pequenas voltas entre elas marcadas toda semana, onde surpresas pequenas são achadas.\"><defs><marker id=\"rl-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"20\" y=\"20\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um revezamento: cada um passa e sai</text><text x=\"20\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produto</text><rect x=\"140\" y=\"44\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"79\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">design</text><rect x=\"270\" y=\"70\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"105\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenvolvimento</text><rect x=\"400\" y=\"96\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"131\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"530\" y=\"122\" width=\"130\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><path d=\"M672 40 L672 150\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><text x=\"700\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">as surpresas caem todas aqui</text><path d=\"M20 186 L700 186\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"20\" y=\"210\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">juntos: todo mundo desde o começo</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">produto</text><rect x=\"140\" y=\"232\" width=\"420\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"267\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">design</text><rect x=\"160\" y=\"258\" width=\"400\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"293\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenvolvimento</text><rect x=\"180\" y=\"284\" width=\"380\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"20\" y=\"319\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">QA</text><rect x=\"200\" y=\"310\" width=\"360\" height=\"18\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><circle cx=\"240\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"340\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"440\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><circle cx=\"540\" cy=\"334\" r=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></circle><text x=\"140\" y=\"354\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">surpresas pequenas, achadas toda semana</text></svg>", "caption": "O trabalho é o mesmo nos dois. O que muda é quando cada pessoa o vê pela primeira vez.", "same": ["design", "QA"]}
```

Num **revezamento**, cada papel termina a sua parte e passa para o próximo: produto escreve o ticket, design
desenha, desenvolvimento constrói, QA testa. Parece eficiente, porque ninguém espera ninguém. Mas cada
passagem perde alguma coisa, e nada do que se perdeu é notado até a última pessoa da fila tentar usar o
resultado. As surpresas caem todas no fim, onde custam mais, e cada uma chega parecendo culpa de outra
pessoa.

Quando todo mundo participa **desde o começo**, os mesmos mal-entendidos acontecem, mas cada um é achado
poucos dias depois de começar, enquanto se corrige com uma frase: *"só na loja? então não construo a parte
online."* Esse é o argumento inteiro desta aula, e é o mesmo que a aula 17 fez sobre a escada: **quanto mais
cedo um problema é pego, menos custa.**
