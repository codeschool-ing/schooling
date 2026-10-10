---
title: Um diagrama é uma visão, não a arquitetura
version: 1
---

Quando alguém pede para ver a arquitetura de uma empresa, quase sempre recebe um diagrama, e os dois
lados agem como se o diagrama fosse a coisa pedida. **Um diagrama é uma visão de uma arquitetura: um
recorte feito por alguém, numa data, para um leitor.** A arquitetura é o que o sistema em execução
de fato é — o que chama o quê, o que lê qual tabela, o que falha quando outra coisa falha. Os dois
podem concordar. Muitas vezes não concordam, e é no diagrama que as pessoas acreditam.

## O slide da integração

Todo engenheiro novo na Carreto vê o mesmo slide na primeira semana. Ele foi desenhado em 2021,
quando a empresa planejava sair do monólito. O desenho é arrumado: os dois apps chamam um API
gateway, o gateway encaminha para seis serviços, cada serviço tem o próprio banco, e todos trocam
eventos pelo broker.

Na primeira semana como arquiteta, Renata decide conferir o slide contra o sistema, coisa que
ninguém fez desde que ele foi desenhado. De início ela não entrevista ninguém. Ela lê o que as
máquinas dizem: os manifestos de implantação dos 14 serviços, as credenciais de banco que cada um
recebe, a lista de tópicos e consumidores do broker e um dia de traces do sistema de tracing.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" aria-label=\"Dois painéis. À esquerda, o slide de 2021: dois apps chamam um API gateway, que encaminha para seis serviços, cada um com seu banco, todos ligados a um barramento de eventos. À direita, o que o sistema faz: o gateway nunca foi construído e os apps chamam os serviços diretamente; o monólito e seu banco PostgreSQL continuam lá, e cinco serviços se conectam direto a esse banco; só três serviços usam o broker.\"><defs><marker id=\"slide-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"10\" width=\"345\" height=\"320\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"182\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">o slide, desenhado em 2021</text><rect x=\"365\" y=\"10\" width=\"345\" height=\"320\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"537\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">o que o sistema faz</text><rect x=\"50\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"105\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"205\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"260\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Driver app</text><rect x=\"102\" y=\"110\" width=\"160\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"125\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">API gateway</text><path d=\"M105 80 L160 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M260 80 L205 108\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"24\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"48\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"48\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L48 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"78\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"102\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"102\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L102 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"132\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"156\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"156\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L156 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"186\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"210\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"210\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L210 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"240\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"264\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"264\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L264 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"294\" y=\"180\" width=\"48\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"318\" y=\"193\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><text x=\"318\" y=\"209\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper-dim)\">+ db</text><path d=\"M182 140 L318 178\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"24\" y=\"250\" width=\"318\" height=\"26\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"182\" y=\"263\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">todos no barramento de eventos</text><path d=\"M48 220 L48 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M102 220 L102 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M156 220 L156 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M210 220 L210 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M264 220 L264 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><path d=\"M318 220 L318 248\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><text x=\"182\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">seis serviços, seis bancos,</text><text x=\"182\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">e nenhum monólito à vista</text><rect x=\"405\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"460\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Shipper app</text><rect x=\"560\" y=\"50\" width=\"110\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"615\" y=\"65\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">Driver app</text><rect x=\"477\" y=\"96\" width=\"120\" height=\"26\" rx=\"4\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"537\" y=\"109\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">gateway: nunca feito</text><rect x=\"379\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"403\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"433\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"457\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"487\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"511\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"541\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"565\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"595\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"619\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><rect x=\"649\" y=\"150\" width=\"48\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"673\" y=\"165\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">svc</text><path d=\"M425 80 L403 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M445 80 L457 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M635 80 L619 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><path d=\"M655 80 L673 148\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#slide-ah)\"></path><rect x=\"379\" y=\"236\" width=\"120\" height=\"40\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"439\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">monólito</text><rect x=\"515\" y=\"236\" width=\"90\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"560\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">PostgreSQL</text><path d=\"M499 256 L515 256\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\"></path><rect x=\"621\" y=\"236\" width=\"76\" height=\"40\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"659\" y=\"256\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">broker</text><path d=\"M403 180 L525 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M457 180 L542 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M511 180 L559 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M565 180 L576 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M619 180 L593 234\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></path><path d=\"M517 180 L635 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><path d=\"M625 180 L667 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><path d=\"M679 180 L683 234\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" stroke-dasharray=\"3 3\"></path><text x=\"537\" y=\"295.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">contínuo: cinco serviços leem o banco do</text><text x=\"537\" y=\"309.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">monólito; tracejado: três usam o broker</text></svg>", "caption": "O slide da integração e o sistema que ele diz mostrar. Nada à esquerda é falso como plano; como descrição, esconde as conexões que decidem o que falha junto.", "same": ["Shipper app", "Driver app", "broker", "API gateway"]}
```

O que ela encontra difere do slide em quatro pontos:

- **não existe API gateway.** Ele foi planejado, uma prova de conceito foi feita, e o projeto foi
  abandonado quando o engenheiro responsável saiu. Os apps chamam os serviços diretamente, cada um
  com o próprio endereço e o próprio código de autenticação;
- **três serviços usam o broker**, não todos. O Tracking publica posições, o Matching as consome, e
  o Payments publica os resultados dos pagamentos. Todo o resto chama por HTTP ou compartilha o
  banco;
- **cinco serviços, além do monólito, se conectam direto ao banco do monólito**, entre eles o
  Payments, que lê a tabela `loads` para decidir o que pagar. Nenhuma dessas conexões aparece no
  slide;
- **o monólito continua sendo o maior componente**, e no slide ele nem aparece — a expectativa era
  que sumisse em um ano.

Ninguém mentiu quando o slide foi desenhado. Ele mostrava o que a empresa pretendia construir. **O
que ele mostra hoje é um plano em parte executado, apresentado como descrição**, e todo engenheiro
novo desde então começou por ele.

## Todo sistema tem uma arquitetura, desenhada ou não

A aula 1 terminou nesse ponto, e aqui ele tem uma consequência. A arquitetura real da Carreto — o
banco compartilhado, as chamadas diretas, as cinco conexões escondidas — existe quer alguém a
desenhe, quer não, e é ela que determina o que acontece num incidente. Quando o banco do monólito
fica lento, cinco serviços ficam lentos junto. Um engenheiro que aprendeu o sistema pelo slide vai
procurar em todo lugar menos ali.

Richard Taylor, Nenad Medvidović e Eric Dashofy, em *Software Architecture: Foundations, Theory, and
Practice*, dão nome às duas metades. **A arquitetura prescritiva é a pretendida; a arquitetura
descritiva é a construída.** A distância entre elas cresce de dois jeitos. *Deriva* (drift) é o
acréscimo de decisões que a arquitetura pretendida não incluía, sem contradizê-la: um serviço novo
que ninguém planejou. *Erosão* é o acréscimo de decisões que a violam: um serviço lendo as tabelas
de outro quando o plano dizia que cada um seria dono dos seus dados. O slide da Carreto sofreu as
duas, e o Payments lendo `loads` é erosão.

## Por que a distância se abre

Ninguém na Carreto decidiu deixar o slide errado. Ele ficou errado do jeito comum:

1. **o diagrama foi desenhado como intenção**, no começo de um plano, e planos mudam;
2. **o código muda todo dia e o diagrama muda quando alguém lembra**, o que na prática quer dizer
   nunca;
3. **atalhos são tomados sob pressão.** A conexão do Payments com `loads` foi criada durante um
   incidente em 2022, como correção temporária, e continua lá;
4. **ninguém é dono do diagrama**, então ninguém fica constrangido quando ele está errado.

O resultado é o pior tipo de documentação: **um documento desatualizado em que as pessoas
acreditam.** Um diagrama que falta faz as pessoas perguntarem. Um diagrama errado responde, com
confiança, a resposta errada. A aula 8 trata de manter a documentação viva — dar a ela um dono, uma
data e um lugar ao lado do código — e de apagá-la quando não dá para mantê-la verdadeira.

## Ler a arquitetura no próprio sistema

O que Renata fez na primeira semana é uma técnica que vale copiar, porque não depende da memória de
ninguém. O sistema em execução deixa evidências da sua estrutura em lugares que não podem derivar,
porque o sistema para de funcionar quando eles estão errados:

| evidência | o que ela mostra |
|---|---|
| manifestos de implantação | o que roda, quantas cópias, com que configuração |
| credenciais e strings de conexão | que componente alcança qual banco ou serviço |
| os tópicos e consumidores do broker | quem publica o quê, e quem escuta |
| traces | que chamadas de fato acontecem, e em que ordem |
| comandos de import no código | que módulos dependem de quais, dentro de um implantável |

**Nenhum deles é um diagrama, e juntos descrevem a arquitetura com mais verdade do que qualquer
diagrama.** Os traces vêm da instrumentação que você viu nas aulas 7 e 8 de `scale`; os imports são
o que a aula 9 deste curso transforma numa verificação automática.

## Para que serve um diagrama

Nada disso torna os diagramas inúteis. **Um diagrama é uma ferramenta para pensar e para explicar**,
e as duas coisas fazem parte do trabalho. A questão é desenhá-los sabendo o que eles são.

Um diagrama que vale guardar responde a quatro perguntas na própria face: **que pergunta ele
responde, para quem é, que data descreve e o que deixa de fora.** "O fluxo de uma carga da
publicação ao pagamento, para engenheiros novos, em março, sem o app Driver" é um diagrama em que
alguém pode confiar e que alguém pode corrigir. Ele também rotula as linhas com o tipo de conector,
como a aula 1 pediu — uma seta sem rótulo do Payments para o banco teria escondido o único fato que
importava.

Renata não redesenha o slide. Ela o tira do material de integração, põe no lugar a sua lista de
evidências e um desenho simples datado da semana em que o fez, e escreve no topo que ele vai estar
errado em poucos meses. A aula 8 mostra como escolher as visões de que um sistema precisa, e o curso
`architecture-modeling`, o terceiro desta trilha, ensina a desenhá-las direito.
