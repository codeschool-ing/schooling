---
title: Uma configuração no código que decide o que o comprador vê
version: 1
---

A divisão de trabalho de sempre parece arrumada: produto decide o que é construído, engenharia decide
como. Ela vale para a maioria das decisões. Que índice uma tabela ganha, que biblioteca de filas um
serviço usa, como um módulo é dividido — ninguém fora da engenharia percebe a resposta, e ninguém
deveria ser consultado.

Algumas decisões parecem exatamente essas e não são. Elas são tomadas numa revisão de código ou num
arquivo de configuração, por engenheiros, em palavras de engenharia, e mudam o que um comprador vive
ou o que o negócio arrisca. **Uma decisão técnica é uma decisão de produto quando o resultado é
sentido por um usuário ou carregado pelo negócio, seja quem for que a digite.** Tomada só pela
engenharia, é uma decisão de produto tomada por gente que não foi chamada a tomá-la e que talvez não
veja quanto ela custa.

## A reserva de assento

A aula 1 ligou as piores falhas da Coreto ao módulo de reservas, que segura um assento enquanto o
comprador paga. Sob a carga de uma abertura de vendas, as travas de linha por trás dessas reservas
fazem fila, o checkout estoura o tempo e os compradores veem assentos sumirem. Uma proposta no
backlog do time de Checkout, do Mateus Araújo, era encurtar a reserva: cada assento ficaria travado
por menos tempo, menos travas se acumulariam às 10:00, e o banco de dados respiraria.

Como mudança de engenharia, é um número num arquivo de configuração. Como mudança de produto, decide
duas coisas que não têm nada a ver com banco de dados.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 304\" role=\"img\" aria-label=\"Uma linha horizontal de uma reserva de assento mais curta, à esquerda, a uma mais longa, à direita. Sob a ponta curta: melhora porque há menos assentos presos sob trava no pico das 10:00; piora porque quem ainda digita o número do cartão perde o assento antes de pagar. Sob a ponta longa: melhora porque quem é lento, ou cujo banco pede uma confirmação, mantém o assento; piora porque assentos ficam presos por quem desistiu, e o show parece esgotado sem estar.\"><defs><marker id=\"hold16-pt-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"360\" y=\"28\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"14\" font-weight=\"600\" fill=\"var(--paper)\">A duração da reserva de assento: uma configuração no módulo de reservas</text><path d=\"M64 60 L656 60\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\" marker-start=\"url(#hold16-pt-ah)\" marker-end=\"url(#hold16-pt-ah)\"></path><text x=\"40\" y=\"86\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">reserva mais curta</text><text x=\"680\" y=\"86\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">reserva mais longa</text><rect x=\"20\" y=\"102\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"124\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">melhora</text><text x=\"36\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">menos assentos presos sob trava</text><text x=\"36\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">no pico das 10:00</text><rect x=\"20\" y=\"190\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"36\" y=\"212\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">piora</text><text x=\"36\" y=\"234\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem ainda digita o número do cartão</text><text x=\"36\" y=\"252\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">perde o assento antes de pagar</text><rect x=\"370\" y=\"102\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"124\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">melhora</text><text x=\"386\" y=\"146\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">quem é lento, ou cujo banco pede</text><text x=\"386\" y=\"164\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma confirmação, mantém o assento</text><rect x=\"370\" y=\"190\" width=\"330\" height=\"74\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"386\" y=\"212\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">piora</text><text x=\"386\" y=\"234\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">assentos presos por quem desistiu:</text><text x=\"386\" y=\"252\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o show parece esgotado, e não está</text><text x=\"360\" y=\"290\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">todo ponto da linha é tecnicamente correto; escolher um decide quem perde</text></svg>", "caption": "Uma configuração, duas falhas. Todo ponto da linha é tecnicamente correto; escolher um ponto decide quais compradores perdem, e essa não é uma pergunta de banco de dados."}
```

**Uma reserva mais curta** quer dizer menos assentos presos sob trava quando a corrida chega ao pico.
Quer dizer também que um comprador que ainda está digitando o número do cartão, ou cujo banco pede
uma confirmação extra, pode perder o assento antes de pagar — e num show concorrido, quando ele
tenta de novo o assento já foi de vez.

**Uma reserva mais longa** protege esse comprador lento. Quer dizer também que assentos ficam presos
por gente que abriu um checkout e foi embora. O mapa de assentos mostra o show esgotado, os fãs
desistem, e depois os assentos voltam à venda quando as reservas expiram, para quem por acaso estiver
atualizando a página naquele momento. A casa de shows vê um esgotamento que não era, seguido de um
fio de vendas tardias que ela não planejou.

Nenhuma das pontas está errada em termos de engenharia. Escolher entre elas decide **qual comprador a
Coreto decepciona, e como a abertura de vendas de uma casa aparece vista de fora** — e essa é uma
pergunta para a Júlia Sato, a head de produto, tanto quanto para o Mateus.

## Mais quatro com o mesmo disfarce

A reserva de assento é o caso mais claro na Coreto, e não é o único. Cada um destes foi levantado
primeiro como uma questão técnica:

| levantado como | o que de fato decide |
|---|---|
| por quanto tempo o Catálogo guarda em cache a disponibilidade de assentos | se o comprador vê assentos que já se foram, e clica neles |
| por quanto tempo os dados do comprador são guardados antes de apagar | o que a Coreto arrisca perante a lei de proteção de dados, e se o comprador consegue ver os ingressos do ano passado |
| a meta de disponibilidade do checkout | o que a Coreto promete às casas, e quanto tempo de engenharia vai para cumprir essa promessa |
| se a Bilheteria lê ingressos sem rede | se uma porta continua andando quando o Wi-Fi da casa cai, ao risco de um ingresso entrar duas vezes |

O **cache de disponibilidade** é uma questão de desempenho com um comprador na outra ponta. Com cache
mais longo, o mapa de assentos carrega mais rápido e poupa o banco; com cache mais longo, ele também
mostra assentos vendidos instantes atrás. O comprador que escolhe um deles descobre isso na etapa de
pagamento, que é o pior lugar para descobrir.

A **retenção de dados** parece faxina de armazenamento. É uma decisão sobre exposição legal de um
lado e uma funcionalidade do outro: o comprador que quer o comprovante de um show que viu no ano
passado está pedindo dados que um prazo curto de retenção apagou.

A **meta de disponibilidade** estava na primeira versão do Davi na aula 1, como "chegar a 99,99%".
Qualquer que seja o número, é uma promessa às casas e um compromisso do tempo da engenharia, porque
cada nove a mais custa trabalho que poderia ter ido para funcionalidades. A aula 16 de
`delivery-metrics` mostra como orçamentos de erro transformam essa meta num acordo entre produto e
engenharia; o ponto aqui é só que a meta não é da engenharia escolher sozinha.

O **modo offline na porta** é o caso em que o disfarce é mais fino. O app da Bilheteria confere cada
ingresso no servidor. Quando o Wi-Fi de uma casa cai, a escolha é entre parar a entrada até ele
voltar e ler contra uma cópia no aparelho, que não enxerga um ingresso já usado em outra porta. Uma
opção forma fila do lado de fora; a outra deixa um ingresso copiado entrar duas vezes. É uma escolha
sobre a noite da casa, e a casa deveria ouvir falar dela antes da noite em que acontece.

## Por que o disfarce funciona

Essas decisões passam por produto sem ser vistas por causa do jeito como chegam. Vêm com vocabulário
técnico — TTL, timeout de trava, job de retenção, SLO, estratégia de sincronização —, então caem na
fila da engenharia. Têm um padrão sensato, então ninguém sente que está fazendo uma escolha. E o
custo é pago depois, por outra pessoa: o comprador na etapa de pagamento, a casa na porta, a empresa
numa carta jurídica. A próxima seção trata de reconhecê-las antes disso.
