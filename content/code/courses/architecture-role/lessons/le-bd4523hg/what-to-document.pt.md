---
title: O que vale escrever, e para quem
version: 1
---

**Documente o que o código não consegue contar a um leitor, para um leitor que você consegue nomear.**
Todo o resto ou pertence ao código, ou é uma página que ninguém vai manter atualizada. A maior parte da
documentação de arquitetura falha num desses dois testes, e a falha vem de duas crenças opostas.

A primeira é que **o código é a documentação**. É verdade para o que o código faz, linha a linha, para
quem já sabe onde olhar. A segunda é que **tudo deve ser documentado**, o que produziu na Carreto, em
2021, um mutirão que deixou a wiki com 640 páginas. Cinco anos depois, Renata contou 410 que ninguém
editava havia dois anos. A primeira crença deixa um engenheiro novo sem mapa; a segunda o deixa com o
mapa de uma cidade que já foi reconstruída.

## O que o código não consegue dizer

O código do monólito da Carreto responde a qualquer pergunta sobre como uma cotação é calculada. Não
responde a nenhuma destas:

- **Por que ele é construído assim.** Por que Tracking tem banco de dados próprio e Pricing não, e o
  que foi considerado e descartado. É para isso que serve um registro de decisão de arquitetura, e a
  aula 5 mostrou um.
- **O que está fora dele.** Embarcadores, motoristas, a SEFAZ, o banco parceiro que envia os
  pagamentos por Pix, e qual time é dono de qual dos 14 serviços.
- **Como as partes se comportam juntas em execução.** O caminho de um comprovante de entrega do celular
  do motorista até um pagamento, por três serviços e um broker, não está em nenhum arquivo sozinho.
- **Que qualidades ele foi feito para atender.** A página única de requisitos da aula 7, com os números
  a que cada parte do desenho é cobrada.
- **O que fazer às três da manhã.** Um runbook para o repasse que travou, escrito por quem o destravou
  da última vez.

Cada item dessa lista é algo de que um leitor precisa e que não consegue recuperar lendo código, por
mais tempo que leia. **Esse é o teste para uma página existir.** Uma página que repete o que o código
diz com clareza é uma segunda cópia dele, e a cópia é que vai estar errada.

## Visões, porque nenhum desenho serve a todos

A ISO/IEC/IEEE 42010, cuja definição de arquitetura abriu a aula 1, traz um vocabulário para isso. Um
sistema tem **partes interessadas**, cada uma com **preocupações**: as perguntas que traz para ele. Uma
**visão** é uma descrição do sistema que responde a algumas preocupações de algumas partes interessadas.
Daí decorre que **nenhum desenho sozinho pode ser o diagrama da arquitetura**, porque as
perguntas são diferentes.

Na Carreto os leitores são fáceis de nomear, e as perguntas deles também:

- Sílvio, o diretor financeiro: quais são as peças grandes, de que terceiros dependemos e para onde vai
  o dinheiro?
- Helena: o que pode mudar depressa, e o que levaria um trimestre?
- Ícaro Nunes, desenvolvedor júnior de Payments: qual serviço é dono das entregas, e onde ficam os
  dados?
- Paula Reis, de Platform, de plantão: o que roda onde, e o que para se isto cair?

Um desenho que tentasse responder aos quatro levaria todas as caixas e todas as setas, e nenhum dos
quatro acharia sua resposta nele. Quatro desenhos menores, cada um para uma pergunta, atendem a todos,
e duas famílias de visões ajudam a escolher esses desenhos.

## O modelo C4: quatro níveis de zoom

O **modelo C4** de Simon Brown descreve um sistema de software em quatro níveis, cada um um zoom numa
única caixa do nível de cima, como os níveis de um mapa on-line.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"Quatro painéis da esquerda para a direita, cada um um zoom numa caixa do painel anterior. Contexto: o embarcador, o motorista, a SEFAZ e o banco parceiro em volta da Carreto, que está destacada; lido por todos. Contêiner: dentro da Carreto, o app web do embarcador, o app do motorista, Matching (destacado), Pricing e Tracking, 14 serviços ao todo; lido por engenheiros. Componente: dentro de Matching, o despacho de ofertas (destacado), o ranking de motoristas, a reserva de cargas e o prazo das ofertas; desenhado onde ajuda. Código: a classe OfferDispatcher e seus métodos offer, claim e expire; gerado quando preciso.\"><defs><marker id=\"l8c4-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">1 · Contexto</text><text x=\"90.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lido por todos</text><path d=\"M172 165.0 L188 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"190\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">2 · Contêiner</text><text x=\"270.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">lido por engenheiros</text><path d=\"M352 165.0 L368 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"370\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">3 · Componente</text><text x=\"450.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">desenhado onde ajuda</text><path d=\"M532 165.0 L548 165.0\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#l8c4-ah)\"></path><rect x=\"550\" y=\"40\" width=\"160\" height=\"250\" rx=\"3\" fill=\"var(--ink)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"630.0\" y=\"24\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12.5\" font-weight=\"600\" fill=\"var(--paper)\">4 · Código</text><text x=\"630.0\" y=\"274\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">gerado quando preciso</text><rect x=\"22\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Embarcador</text><rect x=\"22\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"90.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Carreto</text><rect x=\"22\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Motorista</text><rect x=\"22\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SEFAZ</text><rect x=\"22\" y=\"198\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"90.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Banco parceiro</text><rect x=\"202\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">App web do embarcador</text><rect x=\"202\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">App do motorista</text><rect x=\"202\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"270.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Matching</text><rect x=\"202\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Pricing</text><rect x=\"202\" y=\"198\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"212\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Tracking</text><text x=\"270.0\" y=\"248\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">14 serviços ao todo</text><rect x=\"382\" y=\"54\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"2\"></rect><text x=\"450.0\" y=\"68\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">Despacho de ofertas</text><rect x=\"382\" y=\"90\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Ranking de motoristas</text><rect x=\"382\" y=\"126\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"140\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Reserva de cargas</text><rect x=\"382\" y=\"162\" width=\"136\" height=\"28\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"450.0\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Prazo das ofertas</text><text x=\"564\" y=\"70\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">class OfferDispatcher</text><text x=\"564\" y=\"92\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def offer(load)</text><text x=\"564\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def claim(driver)</text><text x=\"564\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper)\">  def expire(offer)</text></svg>", "caption": "Os quatro níveis do modelo C4 na Carreto. Cada painel abre a caixa destacada do anterior, e cada nível tem seus próprios leitores. A maioria dos times precisa só dos dois primeiros.", "same": ["Carreto", "SEFAZ", "Matching", "Pricing", "Tracking"]}
```

- **Contexto.** O sistema como uma caixa, com as pessoas que o usam e os outros sistemas com que fala.
  É o desenho para Sílvio e Helena, e para o primeiro dia de qualquer engenheiro.
- **Contêiner.** Dentro da caixa do sistema: as coisas que rodam separadas — apps web, apps móveis,
  serviços, bancos de dados, o broker — e como falam entre si. Contêiner aqui quer dizer uma unidade que
  executa, não um contêiner Docker, embora possa rodar num. É o desenho para Ícaro e Paula.
- **Componente.** Dentro de um contêiner: suas partes principais e as responsabilidades delas.
- **Código.** Dentro de um componente: classes e funções.

**O próprio Brown aconselha que a maioria dos times precisa só dos dois primeiros.** Diagramas de
componente valem a pena para um contêiner cujo interior é difícil de entender, e o nível de código é
melhor gerado por uma ferramenta no dia em que alguém precisar, porque muda a cada commit. Para a
Carreto isso quer dizer um diagrama de contexto, um diagrama de contêineres mostrando os 14 serviços e
diagramas de componente para dois contêineres: Matching e Payments, cujo interior é onde engenheiros
novos se perdem. São quatro desenhos para uma empresa de cinquenta engenheiros. O C4 também tem alguns
diagramas complementares, entre eles um de implantação e um dinâmico para um fluxo, usados quando uma
pergunta pede.

A aula 3 de `architecture-modeling` ensina a notação direito. Aqui, o ponto é a escolha: **escolha o
nível pela pergunta do leitor**, e pare no nível em que a pergunta está respondida.

## As visões 4+1

Philippe Kruchten publicou o **modelo de visões 4+1** em 1995, a partir de outro ponto de partida:
quatro visões, cada uma respondendo a um tipo de preocupação, e uma quinta que as amarra.

- A **visão lógica**: o que o sistema faz para os usuários, decomposto nas abstrações principais.
- A **visão de processos**: o que roda ao mesmo tempo, como as partes se comunicam em execução e como o
  sistema se comporta sob carga.
- A **visão de desenvolvimento**: como o código se organiza em módulos e repositórios, e qual time
  trabalha em qual.
- A **visão física**: o que roda em quais máquinas e redes.
- Os **cenários**, o "+1": alguns casos de uso importantes percorridos pelas quatro, que ao mesmo tempo
  explicam as visões e conferem que elas concordam.

As duas famílias se sobrepõem mais do que diferem. O diagrama de contêineres do C4 cobre boa parte das
visões de desenvolvimento e física; o diagrama dinâmico é uma pequena visão de processos. **O 4+1 vale
o lugar onde a concorrência ou a implantação são a parte difícil.** Tracking recebe posições de GPS de
milhares de celulares ao mesmo tempo. A pergunta que importa ali é o que acontece quando chega uma
rajada de posições mais depressa do que dá para gravar, e essa é uma pergunta de visão de processos
que um diagrama de contêineres não responde. Os diagramas UML que costumam ser desenhados dentro das visões
4+1 ficam para a aula 2 de `architecture-modeling`.

## Quanto basta

A lista inicial de Renata para a Carreto foi curta de propósito. Um diagrama de contexto e um de
contêineres. Os ADRs, e a página única de requisitos da aula 7. Um README para cada serviço dizendo
para que serve, quem é dono e como rodá-lo. E runbooks para os incidentes que já aconteceram uma vez.
**Um conjunto menor mantido verdadeiro vale mais do que um maior que está meio certo**, e as próximas
duas seções tratam de como mantê-lo.

Como lista para conferir o que pode estar faltando, o **arc42**, um modelo de Gernot Starke e Peter
Hruschka, organiza doze seções, de objetivos e restrições, passando pelos blocos de construção e o
comportamento em execução, até riscos, dívida técnica e um glossário. Funciona bem como lista de
perguntas a fazer sobre a sua documentação. Preenchido inteiro, seção por seção, vira de novo a wiki de
2021.
