---
title: Escolher uma tecnologia, e quanto cuidado a escolha merece
version: 1
---

A imagem comum de uma decisão de tecnologia é uma disputa. Alguém lista as candidatas, lê os
benchmarks, conta as estrelas de cada repositório, e a melhor ferramenta ganha. **Não existe melhor
ferramenta, existe uma ferramenta que se encaixa num conjunto específico de atributos de qualidade,
num time específico e num custo específico de sair dela depois.** A aula 2 mostrou que uma
tecnologia não é uma arquitetura; esta seção trata das escolhas que sobram depois que a arquitetura
disse do que o sistema precisa.

Trata também da outra metade do trabalho, que é mais fácil de esquecer. **O arquiteto responde por
quanto cuidado cada decisão recebe**, e gastar uma semana numa escolha que se desfaz numa tarde é
uma falha tão grande quanto decidir numa tarde algo que vai levar um ano para desfazer.

## Seis perguntas para fazer a cada candidata

Na Carreto, o time de Tracking precisa decidir onde guardar as posições GPS. Na hora mais movimentada
da semana há cerca de 3.000 caminhões na estrada, cada um informando a posição a cada 30 segundos.
São 3.000 / 30 = 100 posições por segundo, ou 8.640.000 por dia, e as posições ficam guardadas por
um ano, porque um embarcador pode contestar uma entrega, e o trajeto do caminhão é a evidência.

Três candidatas apareceram na primeira conversa do time: um banco de séries temporais dedicado, que
um engenheiro tinha usado no emprego anterior, o PostgreSQL que o time já roda, com a tabela de
posições dividida por mês, e um serviço gerenciado de séries temporais do provedor de nuvem. A
Renata não escolheu nenhuma. Ela fez as seis perguntas que faz a qualquer candidata, e o time
respondeu:

| pergunta | o que pergunta | a resposta do Tracking, em resumo |
|---|---|---|
| **encaixe** | atende aos atributos de qualidade de que este sistema precisa? | as três aguentam 100 escritas por segundo; o ano de histórico e as consultas de contestação são o teste |
| **habilidade** | este time consegue construir, operar e depurar isso às três da manhã? | o time conhece bem o PostgreSQL; uma pessoa conhece o banco dedicado |
| **ecossistema** | é maduro, documentado, tem suporte, dá para contratar gente que conheça? | o PostgreSQL ganha fácil; o serviço gerenciado está preso às ferramentas de um provedor |
| **licença** | o que podemos fazer com ela, e isso pode mudar? | confira a licença da versão atual, e não a do post no blog |
| **custo** | quanto custa para rodar, contando as pessoas? | um segundo motor de banco significa mais uma coisa no plantão |
| **saída** | quanto custaria sair daqui a três anos? | alto para o serviço gerenciado, cuja linguagem de consulta é só dele |

**O encaixe vem primeiro e decide menos do que se espera.** No volume do Tracking, as três
candidatas se encaixam: 100 escritas por segundo é uma carga modesta para qualquer uma delas. Quando
o encaixe não separa as opções, quem decide são as outras cinco perguntas, e elas tratam do time e da
empresa, e não da ferramenta.

**A habilidade é a pergunta mais pulada**, porque soa como confissão. Ela é um atributo de qualidade
disfarçado: um banco que ninguém no time consegue depurar é um banco cuja disponibilidade depende
das férias de uma pessoa. O engenheiro que conhecia o banco de séries temporais dedicado estava
animado e certo sobre os pontos fortes dele, e também era a única pessoa num time de seis que sabia
operá-lo.

**A licença merece uma frase só para ela.** Vários bancos de dados muito usados passaram de licenças
de código aberto para licenças mais restritivas nos últimos anos, o MongoDB em 2018 e o
Elasticsearch em 2021 entre eles, o que mudou o que os provedores de nuvem podem oferecer e, para
algumas empresas, o que elas podem construir. A licença a ler é a da versão que você instalaria, e a
pergunta a fazer é o que acontece com você se ela mudar de novo.

**A saída é a pergunta que transforma uma decisão de tecnologia numa decisão de arquitetura.** Uma
ferramenta barata de substituir pode ser escolhida rápido e corrigida depois. Uma ferramenta cujo
formato de dados, linguagem de consulta ou API se espalha pelo código é um compromisso, e a hora de
pôr preço na saída é antes da entrada.

O Tracking escolheu o PostgreSQL, particionado por mês, com a decisão escrita e uma nota para olhar
de novo se a frota passar de dez vezes o tamanho atual. Ninguém achou que fosse a opção mais
interessante. Era a que o time conseguia operar, numa carga que as três aguentavam, com a saída mais
barata.

## Portas de mão única e portas de mão dupla

Jeff Bezos, na carta aos acionistas da Amazon de 2015, dividiu as decisões em dois tipos. Algumas são
**portas de mão única**: têm consequências grandes e são quase irreversíveis, e depois de passar por
elas não dá para voltar. A maioria são **portas de mão dupla**: se a escolha sair ruim, você volta
pela porta e tenta outra coisa. O ponto dele era que as organizações tendem a usar o processo pesado,
próprio do primeiro tipo, para os dois, e ficam lentas; o erro oposto, tratar uma porta de mão única
como de mão dupla, é mais raro e mais caro.

Para um arquiteto, a versão útil acrescenta um segundo eixo. **Importa quanto custa reverter a
decisão, e importa também até onde as consequências dela chegam**: ao código de um time, a vários
times, ou a uma parte de fora da empresa cujos sistemas você não controla.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 380\" role=\"img\" aria-label=\"Dois eixos. Na horizontal, até onde a decisão chega, de um time a vários times ou a uma parte de fora. Na vertical, o custo de reverter, de baixo a alto. Quatro quadrantes: embaixo à esquerda, o time decide e segue rápido, com a biblioteca de log do Pricing; em cima à esquerda, o time decide devagar e registra, com o armazenamento de posições do Tracking; embaixo à direita, combinar o contrato e seguir, com um novo campo opcional num evento; em cima à direita, uma porta de mão única que pede o arquiteto e um registro de decisão, com o jeito como o Payments sabe das provas e a API que os sistemas dos embarcadores chamam.\"><defs><marker id=\"door-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M80 330 L696 330\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></path><path d=\"M80 330 L80 30\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#door-ah)\"></path><path d=\"M385 36 L385 326\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><path d=\"M84 180 L690 180\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 4\"></path><text x=\"88\" y=\"22\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo de reverter</text><text x=\"72\" y=\"50\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">alto</text><text x=\"72\" y=\"320\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">baixo</text><text x=\"92\" y=\"350\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um time</text><text x=\"690\" y=\"350\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">vários times, ou fora</text><text x=\"690\" y=\"372\" text-anchor=\"end\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">até onde chega</text><text x=\"94\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">o time decide devagar e registra</text><text x=\"399\" y=\"52\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--amber)\">mão única: arquiteto e um ADR</text><text x=\"94\" y=\"316\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">o time decide e segue rápido</text><text x=\"399\" y=\"316\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--phosphor)\">combinar o contrato e seguir</text><circle cx=\"180\" cy=\"110\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"192\" y=\"114\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">posições do Tracking</text><circle cx=\"180\" cy=\"258\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"192\" y=\"262\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">biblioteca de log do Pricing</text><circle cx=\"440\" cy=\"250\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"452\" y=\"254\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">campo opcional num evento</text><circle cx=\"440\" cy=\"100\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"452\" y=\"104\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">como o Payments sabe das provas</text><circle cx=\"470\" cy=\"140\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"482\" y=\"144\" text-anchor=\"start\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">a API que os embarcadores chamam</text></svg>", "caption": "Quanto cuidado uma decisão merece depende de duas coisas ao mesmo tempo: quanto custa desfazê-la, e até onde ela chega além de um time. Só o canto de cima à direita pede o arquiteto por padrão."}
```

Quatro decisões da Carreto ficam nos quatro cantos:

- **Qual biblioteca de log o Pricing usa** é uma porta de mão dupla dentro de um time. Se
  decepcionar, o Pricing troca em um dia. O time decide numa conversa e segue em frente.
- **Onde o Tracking guarda as posições** fica dentro de um time, mas custa caro reverter, porque um
  ano de dados teria de ser movido. O time continua decidindo, e decide devagar: as seis perguntas, um
  registro, uma revisão por alguém de fora do time.
- **Acrescentar um campo opcional a um evento** chega a outro time e é barato de desfazer, porque
  quem consome e não lê o campo não é afetado. Os dois times combinam o contrato e seguem.
- **Como o Payments fica sabendo que uma entrega foi provada, e a API que os sistemas dos próprios
  embarcadores chamam**, chegam além de um time e custam caro para reverter. A primeira prende dois
  times a um contrato e ao comportamento em falha um do outro; a segunda prende empresas de fora, cujos
  projetos de integração a Carreto não consegue agendar. Essas são as portas de mão única, e é para
  elas que a atenção da Renata vai por padrão.

A próxima seção mostra a primeira dessas decisões escrita por inteiro.

## Transformar uma porta em mão dupla

O melhor movimento com uma porta de mão única às vezes é transformá-la em mão dupla antes de passar
por ela. **A maior parte do custo de reverter uma escolha de tecnologia é o código que sabe dela**, e
isso dá para conter:

- pôr a tecnologia atrás de uma interface que o resto do código controla, como o Pricing fez com o
  provedor de rotas na aula 4;
- guardar os dados em formatos que outras ferramentas leem, para que sair não comece com um projeto de
  conversão;
- versionar um contrato público desde a primeira versão, para que a segunda possa conviver com ela;
- fazer um teste pequeno e real antes do compromisso, o que a aula 14 chama de spike.

Nada disso é de graça, e aplicar tudo a cada decisão é o excesso de engenharia que a aula 17
descreve. **Vale pagar por isso justamente onde a porta seria, de outro jeito, de mão única.**

## Quem decide o quê

Situar uma decisão nos dois eixos também responde quem deveria tomá-la. Uma porta de mão dupla dentro
de um time é do time, e um arquiteto pedindo para ser consultado sobre ela é um gargalo. Uma porta de
mão única que chega a vários times ou a quem está de fora é uma em que a Renata participa, pelo
processo de aconselhamento da aula 3: quem decide ouve os afetados e quem entende do assunto, e
escreve o que foi decidido e por quê. Escrever é o assunto do resto desta aula.
