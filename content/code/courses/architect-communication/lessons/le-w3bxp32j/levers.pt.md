---
title: Quatro alavancas, e a que não é alavanca
version: 1
---

**Toda negociação sobre o prazo de um software é uma negociação sobre quatro coisas: escopo, prazo,
pessoas e qualidade. Três delas podem ser trocadas. A quarta só pode ser escondida, e escondê-la é
pegar um empréstimo contra o futuro sem avisar quem empresta.** Gerentes de projeto desenham as três
primeiras como o triângulo de ferro; quase tudo o que dá errado numa conversa sobre prazo é alguém
mexendo na quarta sem dizer nada.

## O pedido

Na segunda-feira, 5 de outubro, Renata leva ao time de logística de Henrique um pedido da Boa Praça e
dos próprios clientes da Marola: **entregas agendadas**, para que o cliente possa fazer o pedido na
segunda e receber na quinta, num horário escolhido. Ela quer isso no ar em 1º de dezembro, para a
temporada de Natal. A estimativa do time, depois de uma manhã quebrando o trabalho em partes, é de
cerca de **dez semanas**. O calendário de 5 de outubro a 1º de dezembro tem cerca de **oito**.

## As alavancas

| alavanca | o que significa mexer nela | para as entregas agendadas |
|---|---|---|
| **escopo** | fazer menos, ou uma versão menor primeiro | entregas até 7 dias à frente, sem pedidos recorrentes, sem edição depois da confirmação |
| **prazo** | mudar a data | lançar em 14 de dezembro em vez de 1º de dezembro |
| **pessoas** | pôr mais gente | pegar emprestado um engenheiro de outro time |
| **qualidade** | fazer com menos cuidado | pular testes, pular o teste de carga, nenhum plano de rollback |

Cada uma das três primeiras tem um custo real que alguém consegue pesar. **Escopo** custa
funcionalidades; **prazo** custa duas semanas da temporada de Natal; **pessoas** custa o que o outro
time ia fazer, e rende menos do que parece, porque pôr gente num projeto atrasado o atrasa ainda mais
antes de adiantá-lo. Fred Brooks observou isso em *The Mythical Man-Month* em 1975, e todo time
observou desde então.

## Qualidade não é alavanca

**Qualidade parece uma alavanca porque ninguém a vê se mexer.** A funcionalidade sai em 1º de
dezembro, a demonstração funciona, e o custo chega em janeiro: um bug na forma como os pedidos
agendados interagem com o fluxo de substituição, uma página lenta porque ninguém teve tempo de olhar
a consulta, um rollback que não existe quando é preciso. A essa altura, ninguém liga o problema à
decisão de outubro.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 290\" role=\"img\" aria-label=\"Um triângulo com escopo, prazo e pessoas nos cantos e qualidade no meio, marcada como não alavanca. Ao lado: os três cantos podem ser trocados, e cada troca tem um custo visível; a qualidade só parece alavanca, mexer nela é pegar emprestado escondido, e a conta chega em janeiro.\"><defs><marker id=\"levers-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><polygon points=\"200,30 60,250 340,250\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></polygon><text x=\"200\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">escopo</text><text x=\"40\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">prazo</text><text x=\"360\" y=\"270\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--phosphor)\">pessoas</text><text x=\"200\" y=\"180\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--amber)\">qualidade</text><text x=\"200\" y=\"198\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">(não é alavanca)</text><text x=\"420\" y=\"50\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">os três cantos podem ser trocados,</text><text x=\"420\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e cada troca tem um custo visível</text><text x=\"420\" y=\"150\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">a qualidade só parece alavanca:</text><text x=\"420\" y=\"168\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">mexer nela é pegar emprestado escondido,</text><text x=\"420\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">e a conta chega em janeiro</text></svg>", "caption": "O triângulo de ferro, com a quarta coisa que se troca desenhada onde ela pertence: dentro, segurando as outras."}
```

Por isso a regra da aula 4 vale aqui: **um custo escondido é um risco que outra pessoa carrega sem
ter concordado.** Se o time vai aceitar um atalho, diga isso em voz alta, ponha um preço nele e
registre-o como dívida (a quarta seção desta aula). Se ninguém concordaria com o atalho em voz alta,
o time não deveria tomá-lo em silêncio.

## Quem mexe em qual alavanca

O time não escolhe a troca sozinho, e o produto também não. **Renata é dona do escopo e da data,
porque é dona da promessa aos clientes; Henrique é dono da estimativa e da qualidade, porque o time
dele vai viver com o resultado.** A negociação acontece entre esses dois tipos de responsabilidade, e
o resto desta aula mostra como conduzi-la.
