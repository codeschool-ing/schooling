---
title: Quatro jeitos de dois sistemas se encontrarem
version: 1
---

No terceiro mês na Serra Alta, Joana fez uma pergunta que ninguém soube responder: quantas
integrações a empresa tem? O Rui conhecia os fluxos do ESB. O Edson sabia quais programas ABAP liam
arquivos. A Talita sabia o que chegava ao Salesforce. Ninguém tinha o quadro inteiro, então ela
montou a lista sozinha, numa planilha, uma linha por integração: de onde, para onde, o que passa,
com que frequência, quem é o dono, e como alguém perceberia que aquilo parou.

Levou cinco semanas e deu **110 linhas**. Os 70 fluxos do ESB foram a parte fácil, porque o ESB tem
um console que lista todos. As outras 40 apareceram perguntando: um arquivo que o Coleta empurra
toda noite, um relatório de Power BI que lê um banco diretamente, uma tabela que o Rota grava e um job ABAP consulta. **Em 38 das 110 linhas, ninguém soube dizer como uma falha seria notada.**
Essa coluna acabou sendo a mais útil da planilha.

A outra coluna útil era o *estilo*. Toda linha do mapa move dados de um entre quatro jeitos, e o
jeito como move decide a maior parte do que pode dar errado.

## Os quatro estilos

Gregor Hohpe e Bobby Woolf, em *Enterprise Integration Patterns* (2003), abrem o livro com quatro
estilos de integração. Continuam sendo os quatro certos, vinte anos e várias tecnologias depois,
porque cada um responde a uma pergunta diferente sobre como dois sistemas se encontram.

- *Transferência de arquivo.* Um sistema grava um arquivo; o outro lê depois. O arquivo noturno
  do Coleta para o SAP, os arquivos CNAB trocados com os bancos, as mensagens EDI com as redes de
  supermercado.
- *Banco de dados compartilhado.* Dois sistemas leem e gravam as mesmas tabelas. Na Serra Alta isso
  é quase sempre um sistema lendo direto as tabelas de outro, ou uma tabela de passagem que um lado
  grava e o outro consulta de tempos em tempos.
- *Invocação remota de procedimento*, que esta aula chama de *por API*. Um sistema chama o outro e
  espera a resposta: uma chamada SOAP pelo ESB, uma requisição REST do Portal B2B.
- *Mensageria*, que esta aula chama de *por evento*, porque o uso que mais importa aqui é publicar
  um fato. Um sistema manda uma mensagem a um broker, e quem tiver interesse a recebe. Na Serra Alta
  é o IBM MQ que carrega essas mensagens.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 340\" role=\"img\" data-fig=\"l09-four-styles\" aria-label=\"Quatro linhas, uma por estilo de integração, cada uma com um exemplo da Serra Alta e uma coluna dizendo se os dois lados precisam estar no ar ao mesmo tempo. Transferência de arquivo: o Coleta grava um arquivo, às 23:30, e o SAP o lê às 02:00; os dois no ar ao mesmo tempo: não. Banco compartilhado: o Coleta grava as próprias tabelas e o Rota as lê diretamente; só o banco precisa estar no ar. API: o Portal B2B manda uma requisição ao SAP e espera a resposta, que volta; os dois no ar ao mesmo tempo: sim. Evento: o SAP publica uma mensagem num broker, e qualquer número de assinantes a recebe; os dois no ar ao mesmo tempo: não, o broker guarda a mensagem.\"><defs><marker id=\"l09-four-styles-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l09-four-styles-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><text x=\"655.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">os dois no ar juntos?</text><text x=\"14.0\" y=\"70.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">arquivo</text><rect x=\"153.0\" y=\"53.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><rect x=\"448.0\" y=\"53.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><text x=\"655.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não</text><rect x=\"297.0\" y=\"53.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um arquivo</text><path d=\"M258.0 70.0 L295.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M408.0 70.0 L446.0 70.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"97.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">gravado 23:30, lido 02:00</text><path d=\"M10.0 106.0 L710.0 106.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"142.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco compartilhado</text><rect x=\"153.0\" y=\"125.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Coleta</text><rect x=\"448.0\" y=\"125.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Rota</text><text x=\"655.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">só o banco</text><rect x=\"297.0\" y=\"125.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"142.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">tabelas do Coleta</text><path d=\"M258.0 142.0 L295.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M446.0 142.0 L409.0 142.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"169.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o Rota as lê direto</text><path d=\"M10.0 178.0 L710.0 178.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API</text><rect x=\"153.0\" y=\"197.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">Portal B2B</text><rect x=\"448.0\" y=\"197.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><text x=\"655.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">sim</text><path d=\"M258.0 207.0 L446.0 207.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M446.0 221.0 L258.0 221.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l09-four-styles-es-ah-paper-dim)\"></path><text x=\"352.0\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">requisição</text><text x=\"352.0\" y=\"233.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">quem chama espera a resposta</text><path d=\"M10.0 250.0 L710.0 250.0\" stroke=\"var(--wire)\" stroke-width=\"0.8\" fill=\"none\" stroke-dasharray=\"2 4\"></path><text x=\"14.0\" y=\"286.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">evento</text><rect x=\"153.0\" y=\"269.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"205.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">SAP</text><rect x=\"456.0\" y=\"261.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"452.0\" y=\"265.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"448.0\" y=\"269.0\" width=\"104.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"500.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">assinantes</text><text x=\"655.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">não</text><rect x=\"297.0\" y=\"269.0\" width=\"110.0\" height=\"34.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"352.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">broker</text><path d=\"M258.0 286.0 L295.0 286.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><path d=\"M408.0 286.0 L446.0 286.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l09-four-styles-es-ah-phosphor)\"></path><text x=\"352.0\" y=\"313.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o broker guarda a mensagem</text></svg>", "caption": "Os quatro estilos de Hohpe e Woolf, cada um com uma integração da Serra Alta. Só a API precisa dos dois lados no ar no mesmo momento.", "same": ["API", "Coleta", "Portal B2B", "Rota", "SAP", "broker"]}
```

A ideia errada para largar primeiro é que esses estilos sejam gerações, o arquivo sendo o antigo e o
evento o moderno, e que uma boa arquitetura já migrou tudo para o mais novo. **Cada estilo é a
resposta certa para algumas integrações e a errada para outras**, e o mapa da Serra Alta tem os
quatro por motivos que alguém um dia teve. O banco não se oferece para receber o pagamento dos
produtores como eventos. Uma padaria esperando no checkout não pode saber o estoque amanhã de manhã,
num arquivo.

## Um eixo: o que cada lado precisa saber do outro

Os quatro estilos diferem em muitos detalhes, mas uma pergunta os põe em ordem: **quanto cada lado
precisa saber do outro, e quando?** Esse conhecimento é o *acoplamento*, e na integração ele vem em
três tipos que vale manter separados.

**Acoplamento no formato.** O que quem recebe precisa entender dos dados de quem envia? Com um
arquivo, precisa conhecer o leiaute: em que colunas estão os litros, como é o header. Com um banco
compartilhado, precisa conhecer as tabelas, e não só as colunas que lê, mas o que quem envia quer
dizer com elas: que o status `E` é um erro, que uma linha com data de entrega nula ainda não saiu.
É o acoplamento de formato mais profundo dos quatro, porque o modelo interno de quem envia *é* a
interface. Com uma API ou um evento, quem recebe conhece um contrato que quem envia escolheu publicar,
e que pode ficar parado enquanto o interior de quem envia muda.

**Acoplamento no tempo.** Os dois precisam estar rodando no mesmo momento? Com uma API, sim: quem
chama espera, e quem é chamado precisa responder agora. Com um arquivo, não: o Coleta grava às 23:30,
o SAP carrega às 02:00, e qualquer um dos dois pode cair no intervalo sem o outro perceber. Com
mensageria, não: o broker guarda a mensagem até o consumidor voltar. Um banco compartilhado precisa
do banco no ar, mas não da outra aplicação.

**Acoplamento na localização.** Quem envia sabe onde está quem recebe, ou mesmo que ele existe? Quem
chama tem o endereço de quem é chamado na configuração. Um arquivo é gravado num diretório que os
dois lados combinaram. Quem publica conhece só o broker e o nome do tópico; **não sabe quem está
ouvindo, nem quantos**, e um ouvinte novo pode entrar sem que quem publica mude nada.

| | formato | tempo | localização |
|---|---|---|---|
| transferência de arquivo | o leiaute do arquivo | nenhum: gravado agora, lido depois | os dois conhecem o diretório |
| banco compartilhado | as tabelas do outro lado e o que elas significam | o banco precisa estar no ar, a outra aplicação não | os dois conhecem o banco |
| API | o contrato publicado | os dois no ar ao mesmo tempo | quem chama conhece o endereço de quem é chamado |
| evento | o contrato da mensagem | nenhum: o broker guarda | quem publica conhece só o broker |

Leia a coluna do tempo de cima para baixo e você tem o motivo de a maior parte da integração
corporativa não ser feita por API. **Sistemas que não podem estar todos no ar ao mesmo tempo não
podem ser todos chamados ao mesmo tempo**, e numa empresa com um ERP, um sistema de 1996 em IBM i,
um CRM na nuvem de outra empresa e dois bancos, estar no ar ao mesmo tempo é algo que se combina, não
algo que se supõe.

## Estilo é uma propriedade da linha, não do sistema

Um sistema costuma participar de vários estilos ao mesmo tempo. O SAP, na Serra Alta, recebe o
arquivo do Coleta, responde às consultas de estoque do Portal B2B pelo ESB, tem as tabelas lidas por
dois relatórios que ninguém assume, e põe mensagens no MQ quando uma remessa sai de uma fábrica.
Perguntar "como integramos com o SAP?" tem quatro respostas. Perguntar "como o Portal B2B deve saber
o estoque do SAP?" tem uma, e essa é a pergunta que um arquiteto consegue decidir.

O mapa da Joana conta **41 transferências de arquivo, 17 vínculos por banco, 33 chamadas de API e 19
fluxos de mensagem**. O ESB carrega 70 delas: 31 das chamadas, os 19 fluxos de mensagem e 20 dos
arquivos, que ele pega num diretório e deixa em outro. As outras 40 vão ponto a ponto, e é ali que
está a maior parte das 38 linhas sem resposta. A aula 8 explica por que um barramento foi instalado
justamente para frear esse crescimento; a última seção desta aula passa por seis das linhas e decide
qual estilo cada uma deveria ter.

As quatro seções seguintes tratam dos estilos um a um, do mais antigo para o mais novo. **Para cada
um, a pergunta é a mesma: o que ele acopla, e como ele falha?** A segunda metade da pergunta importa
mais, porque a falha de cada estilo tem um formato típico, e conhecer o formato é saber onde pôr o
alarme.
