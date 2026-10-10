---
title: Atributos de qualidade puxam uns contra os outros
version: 1
---

Pergunte a qualquer time o que ele quer de um sistema e a resposta é uma lista de coisas boas:
rápido, sempre disponível, seguro, barato, fácil de mudar. **Cada decisão estrutural compra algumas
delas gastando outras**, e não existe arranjo que maximize todas. O trabalho do arquiteto não é
achar o desenho sem trocas, que não existe, e sim tornar a troca visível, pôr números dos dois lados
e conseguir que as pessoas donas de cada lado concordem com ela.

## As trocas que aparecem sempre

Quatro pares respondem pela maioria das discussões na Carreto, e cada um tem um caso concreto.

**Disponibilidade contra consistência.** O Matching poderia oferecer uma carga nova a cinco
motoristas ao mesmo tempo e ficar com o primeiro aceite, o que faz as cargas andarem mais rápido.
Também poderia acabar com dois motoristas indo ao mesmo armazém pela mesma carga. Oferecer a um
motorista por vez, durante sessenta segundos, é consistente e mais lento. O curso `architecture` deu
a teoria disso na aula 8, o teorema CAP; na Carreto, é uma decisão sobre quantas vezes um motorista
se frustra contra quanto tempo um embarcador espera.

**Desempenho contra facilidade de mudança.** O adaptador que esconde o banco parceiro do resto do
Payments custa uma camada de indireção e algum código que só traduz. Ele compra a capacidade de
trocar de banco em semanas, e não em meses. No volume do Payments, o custo em velocidade é
invisível; num sistema que responde em microssegundos, talvez não fosse.

**Disponibilidade contra custo.** Um segundo banco parceiro para o Pix deixaria os pagamentos
continuarem quando o primeiro cai, o que protege a promessa das 24 horas. Também dobraria o trabalho
de integração, a conciliação e os contratos. Se vale a pena depende de quantas vezes o primeiro
parceiro cai, e isso é um número, não uma opinião.

**Segurança contra usabilidade.** O Driver app poderia pedir um login novo antes de cada mudança nos
dados de pagamento, o que torna um celular roubado menos útil e irrita todo motorista toda vez. A
decisão é sobre qual incômodo sai mais barato.

Nenhuma delas tem resposta certa em geral. **Cada uma tem resposta certa para um conjunto específico
de requisitos**, e o problema é que os requisitos costumam chegar como adjetivos.

## Um adjetivo não se troca

"O Payments precisa ser confiável" soa como requisito. Não resolve uma única decisão. Confiável quer
dizer nunca fora do ar, nunca errado, nunca atrasado, ou nunca pagando duas vezes? Fora do ar por
quanto tempo, com que frequência, medido como? Dois engenheiros podem concordar com a frase e
desenhar sistemas opostos, e nenhum consegue mostrar que o outro está errado.

A resposta do Software Engineering Institute, apresentada por Bass, Clements e Kazman em *Software
Architecture in Practice*, é o **cenário de atributo de qualidade**: um requisito escrito como uma
história curta em seis partes, específica o bastante para ser testada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 260\" role=\"img\" aria-label=\"As seis partes de um cenário de atributo de qualidade, desenhadas da esquerda para a direita com o exemplo da Carreto. Fonte: o banco parceiro. Uma seta com o rótulo estímulo: a API Pix para de responder. Uma caixa grande com o rótulo ambiente, sexta no pico das 18:00, contendo o artefato: o serviço de pagamentos do Payments. Uma seta com o rótulo resposta: pagamentos na fila e tentados de novo, sem duplicatas. Por último, a medida da resposta: todo pagamento feito em até 2 horas depois que o parceiro volta, nenhum pago duas vezes.\"><defs><marker id=\"qas-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker></defs><rect x=\"10\" y=\"90\" width=\"130\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75\" y=\"118\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Fonte</text><text x=\"75\" y=\"144\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o banco parceiro</text><path d=\"M142 135 L236 135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#qas-ah)\"></path><text x=\"190\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Estímulo</text><text x=\"190\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a API Pix para</text><text x=\"190\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de responder</text><rect x=\"240\" y=\"30\" width=\"220\" height=\"200\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></rect><text x=\"350\" y=\"56\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--paper)\">Ambiente</text><text x=\"350\" y=\"76\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">sexta, pico das 18:00</text><rect x=\"270\" y=\"100\" width=\"160\" height=\"96\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"350\" y=\"128\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">Artefato</text><text x=\"350\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o serviço de</text><text x=\"350\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">pagamentos</text><path d=\"M462 135 L556 135\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2\" marker-end=\"url(#qas-ah)\"></path><text x=\"510\" y=\"124\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">Resposta</text><text x=\"510\" y=\"156\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">fila e nova</text><text x=\"510\" y=\"170\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">tentativa, sem</text><text x=\"510\" y=\"184\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">duplicatas</text><rect x=\"560\" y=\"90\" width=\"150\" height=\"90\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"635\" y=\"112\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">Medida da resposta</text><text x=\"635\" y=\"136\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todo pagamento feito</text><text x=\"635\" y=\"152\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">até 2 h após a volta;</text><text x=\"635\" y=\"168\" text-anchor=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">nenhum pago duas vezes</text></svg>", "caption": "Um requisito em seis partes. Cada parte tira uma ambiguidade que o adjetivo \"confiável\" deixava aberta: quem causa o evento, que evento é, quando, em que parte do sistema, o que o sistema faz, e como alguém saberia que ele fez isso bem o bastante."}
```

As seis partes, com o exemplo do Payments:

- **Fonte**: quem ou o que causa o evento. Aqui, o banco parceiro. Poderia ser também um motorista,
  um desenvolvedor ou um atacante, e cada um faz um cenário diferente.
- **Estímulo**: o evento em si. A API Pix do banco para de responder.
- **Ambiente**: as condições no momento. Sexta-feira no pico das 18:00, quando é provada a maior
  parte das entregas da semana. A mesma falha às quatro da manhã é um problema menor.
- **Artefato**: a parte do sistema que recebe o estímulo. O serviço de pagamentos do Payments, e não
  "a plataforma".
- **Resposta**: o que o sistema faz. Os pagamentos entram numa fila e são tentados de novo; nada é
  pago duas vezes; o financeiro recebe um alerta se um pagamento continua pendente na hora 20.
- **Medida da resposta**: como alguém saberia que a resposta foi boa o bastante. Todo pagamento na
  fila concluído em até 2 horas depois que o parceiro volta, e zero pagamentos duplicados.

**A medida da resposta é a parte que transforma uma opinião num teste.** Sem ela, "tentado de novo"
fica satisfeito com uma tentativa por dia. Com ela, um desenho pode ser checado no papel agora e num
ambiente de testes depois, e uma discussão entre dois desenhos tem contra o que ser resolvida.

A forma não serve só para disponibilidade. Aqui vai um cenário de facilidade de mudança para o Pricing, escrito do mesmo jeito. Um
**desenvolvedor** do Pricing (fonte) recebe uma **nova tabela de piso da ANTT** (estímulo) durante o
**desenvolvimento normal** (ambiente), para a **etapa de piso da cotação** (artefato). A tabela é
carregada, testada e implantada (resposta), e **entra em produção em até dois dias úteis, sem código
alterado fora do módulo de piso** (medida da resposta). Esse cenário
é o motivo de a tabela ser dado e não código, e de a etapa de piso ser a única saída.

A aula 7 trata de extrair cenários assim do negócio, de pessoas que dizem "rápido" e "sempre". Esta
seção precisa deles por outro motivo: **uma troca só pode ser discutida entre dois cenários com
números dentro.**

## Pontos de troca

O método de avaliação de arquiteturas do SEI, o ATAM, tem um nome útil para o lugar onde as trocas
acontecem: um **ponto de troca** é uma única decisão que afeta dois atributos de qualidade em
direções opostas. Encontrá-los é a maior parte do trabalho de avaliar um desenho, porque cada um é
um lugar onde duas partes interessadas querem coisas diferentes.

O pagamento em 24 horas tem um bem claro, e ele não é técnico. **A janela de contestação do
embarcador protege a equipe financeira do Sílvio e custa tempo aos motoristas.** Doze horas protegem
a Carreto contra pagar por cargas que não chegaram; cada hora tirada dela faz o dinheiro chegar uma
hora antes na conta do motorista. Um cenário para cada lado deixa a troca explícita:

- *Cenário do motorista*: um motorista conclui uma entrega (estímulo) num dia de semana (ambiente); o
  pagamento (resposta) chega à conta dele em até 24 horas em 99% das entregas (medida).
- *Cenário do financeiro*: um embarcador contesta uma entrega que não aconteceu (estímulo); o
  pagamento dela fica retido (resposta) em todos os casos contestados dentro da janela (medida).

O tamanho da janela mexe nas duas medidas ao mesmo tempo. Com os números na mesa, a conversa entre a
Helena, que fala pelos motoristas, e o Sílvio, que fala pelo dinheiro, é sobre um número de horas, e
cada um consegue ver o que o outro abre mão.

As novas tentativas são um segundo ponto de troca, este técnico. **Mais tentativas melhoram o cenário
de disponibilidade e ameaçam a medida "nada pago duas vezes"**, a não ser que cada pagamento leve o
id da entrega como chave de idempotência, o que o registro 7 exige. Dar nome ao ponto de troca foi o
que levou a dar nome à proteção.

## O que o arquiteto faz com uma troca

O hábito da Renata com cada ponto de troca é sempre o mesmo, e é curto:

1. **Escrever os cenários dos dois lados**, com medidas de resposta.
2. **Dar nome a quem é dono de cada lado.** A rapidez para os motoristas é da Helena; a exposição
   financeira é do Sílvio; evitar pagamentos duplicados é do Bruno.
3. **Pôr as opções na frente dos donos, com os números**, e dizer quanto cada opção custa a cada lado.
4. **Escrever o que foi escolhido**, como registro de decisão, com os cenários no contexto.

O passo 3 é onde os arquitetos mais erram, em uma de duas direções: escolher no lugar dos donos
porque a troca parece técnica, ou apresentar tantas opções que os donos não conseguem escolher. A
aula 13 volta à apresentação de opções com custo, prazo e risco. A próxima seção passa ao caso em que
há vários critérios ao mesmo tempo, e uma única troca não basta.
