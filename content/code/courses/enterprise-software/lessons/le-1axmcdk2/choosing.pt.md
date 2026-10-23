---
title: Escolhendo um estilo para cada integração
version: 1
---

Os quatro estilos não são um ranking, e escolher entre eles não é questão de gosto. **Cada integração
tem alguns fatos que decidem seu estilo: quão atuais os dados precisam ser, quanto dado existe, quem
precisa estar no ar, e como uma falha se mostraria.** Anote esses fatos para uma linha do mapa e o
estilo quase se escolhe sozinho. Quando não se escolhe, a discordância costuma ser sobre um fato, e
essa é uma discussão melhor de ter.

O mapa da Joana, quando ela terminou de classificá-lo, ficou assim. A parte em âmbar de cada barra são
as linhas para as quais ninguém soube dizer como uma falha seria notada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l09-map-count\" aria-label=\"Barras horizontais contando as 110 integrações do mapa da Joana por estilo. Transferência de arquivo, 41, 20 delas pelo ESB, 14 sem forma conhecida de notar uma falha. Banco compartilhado, 17, nenhuma pelo ESB, 15 sem forma conhecida de notar uma falha. API, 33, 31 pelo ESB, 4 sem forma conhecida de notar uma falha. Evento ou mensagem, 19, todas pelo ESB, 5 sem forma conhecida de notar uma falha. No total, 70 passam pelo ESB e 38 não têm forma conhecida de notar uma falha, desenhadas em âmbar no início de cada barra.\"><text x=\"14.0\" y=\"34.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">arquivo</text><text x=\"14.0\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">20 pelo ESB</text><rect x=\"190.0\" y=\"29.0\" width=\"410.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"29.0\" width=\"140.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"260.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">14</text><text x=\"610.0\" y=\"40.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">41</text><text x=\"14.0\" y=\"84.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">banco compartilhado</text><text x=\"14.0\" y=\"100.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">0 pelo ESB</text><rect x=\"190.0\" y=\"79.0\" width=\"170.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"79.0\" width=\"150.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"265.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">15</text><text x=\"370.0\" y=\"90.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">17</text><text x=\"14.0\" y=\"134.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">API</text><text x=\"14.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">31 pelo ESB</text><rect x=\"190.0\" y=\"129.0\" width=\"330.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"129.0\" width=\"40.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"210.0\" y=\"140.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">4</text><text x=\"530.0\" y=\"140.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">33</text><text x=\"14.0\" y=\"184.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">evento</text><text x=\"14.0\" y=\"200.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">19 pelo ESB</text><rect x=\"190.0\" y=\"179.0\" width=\"190.0\" height=\"22.0\" rx=\"2\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><rect x=\"190.0\" y=\"179.0\" width=\"50.0\" height=\"22.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"215.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">5</text><text x=\"390.0\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">19</text><rect x=\"190.0\" y=\"236.0\" width=\"22.0\" height=\"12.0\" rx=\"2\" fill=\"var(--ink)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"220.0\" y=\"242.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ninguém sabia dizer como uma falha seria notada</text><text x=\"190.0\" y=\"266.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">110 integrações no total; 70 pelo ESB, 40 ponto a ponto</text></svg>", "caption": "O mapa da Joana por estilo. O banco compartilhado é o menor grupo e o mais mal vigiado: quase nenhum desses vínculos foi desenhado como integração.", "same": ["API"]}
```

Os vínculos por banco são, de longe, o estilo mais mal vigiado: 15 de 17 não tinham como notar uma
falha, porque ninguém os desenhou como integrações, para começo de conversa. As chamadas eram as mais
bem vigiadas, 4 de 33, porque uma chamada que falha falha na hora e na frente de alguém.

## A tabela de decisão

| | arquivo | banco compartilhado | API | evento |
|---|---|---|---|---|
| atualidade que oferece | horas: tão velho quanto o último arquivo | tão atual quanto a tabela | agora | segundos, normalmente |
| volume que comporta | lotes grandes, barato | qualquer um, às custas do dono | um item por chamada | muitos fatos pequenos |
| quem precisa estar no ar | ninguém ao mesmo tempo | o banco | quem chama e tudo na cadeia | o broker |
| o que acopla | o leiaute do arquivo | as tabelas do dono e o que significam | o contrato publicado, e o tempo | o contrato da mensagem |
| como a falha aparece | um arquivo que não vem, ou vem incompleto | respostas erradas, ou uma consulta que quebra depois de uma mudança | um erro ou um timeout, na hora, para alguém esperando | um atraso que cresce, sem erro |
| quanto custa operar | um diretório, um agendamento e os controles | nada visível, até uma mudança | a disponibilidade de cada salto | um broker, e alguém dono de cada tópico |

Duas linhas merecem uma segunda olhada. *Como a falha aparece* é onde o alarme precisa ficar: no
arquivo que faltou, no timeout, no atraso. E *quanto custa operar* é o motivo de o estilo que parece
mais barato na tabela, o banco compartilhado, ser aquele de que a Joana queria menos: o custo dele não
aparece até o dia em que é pago todo de uma vez.

## Seis linhas do mapa

A Joana pegou seis linhas sobre as quais o pessoal da Serra Alta discutia, e decidiu cada uma com a
tabela.

**1. Coleta → SAP, os litros diários dos produtores. Continua arquivo.** O SAP precisa dos litros para
as entradas de mercadoria na manhã seguinte e para o pagamento dos produtores no dia 10; nada ali
precisa de segundos. O Coleta grava arquivos com facilidade e não chama nada com facilidade, e o
Sebastião se aposenta em 2028, então uma interface nova em IBM i seria código que ninguém vai manter.
O que muda são os controles: um trailer com a contagem e os litros, conferido antes da carga; uma
carga que recusa um arquivo já visto; um arquivo de rejeição de volta ao Coleta; e o alarme da 01:30.
A aula 13 substitui o próprio Coleta, e nesse momento este arquivo vai junto.

**2. Portal B2B → SAP, estoque no checkout. Continua chamada, com plano B.** Uma padaria está
esperando e a resposta precisa ser atual, então as três condições de uma chamada valem. O que mudou é
o da seção anterior: timeouts que diminuem para dentro, nenhuma nova tentativa contra um SAP em
dificuldade, e o comportamento de domingo usado sempre que o SAP estiver lento.

**3. SAP → Salesforce, notas fiscais. Vira evento.** Os representantes de grandes contas querem ver a
nota no cadastro do cliente, ninguém espera por ela naquele instante, e o Salesforce é um de três
consumidores do mesmo fato. O tópico de nota autorizada da seção anterior o atende, e o fluxo do ESB
que chamava o Salesforce para cada nota é aposentado.

**4. SAP ↔ bancos, CNAB 240. Continua arquivo, e não é a Serra Alta quem escolhe.** O banco define a
interface. Alguns bancos já oferecem APIs para parte das mesmas operações; para 1.900 pagamentos a
produtores uma vez por mês, um arquivo com totais por lote e uma resposta no arquivo de retorno é bem
conhecido pelos dois lados, e os controles que importam já estão no padrão. O que a Joana acrescentou
ao mapa foi o alarme que faltava: um arquivo de retorno que não chegou até as 10:00 do dia do
pagamento aciona o financeiro.

**5. SAP → Rota, quanto leite cada fábrica vai receber. Vira evento.** O Rota planeja os caminhões do
dia seguinte e, para planejá-los, precisa saber onde entregar o leite: quantos litros cada fábrica vai
receber, segundo o plano de produção no SAP. Hoje o SAP grava isso num arquivo às 16:00. O problema é
a noite: quando um secador quebrou em Barbacena em julho, a fábrica passou a poder receber 200.000
litros a menos, e os despachantes souberam por telefone, duas horas depois. Publicado como evento
sempre que o plano de recebimento de uma fábrica muda, trazendo o plano inteiro daquela fábrica, o
arquivo das 16:00 vira simplesmente o primeiro evento do dia. O secador vira outro, um minuto depois
de o planejador registrá-lo.

**6. Documentum → clientes, certificados de análise. Vira API.** Redes de supermercado pedem o
certificado de um lote, e hoje o time da Cláudia acha o PDF no Documentum e o manda por e-mail à mão,
umas 120 vezes por semana. Só alguns clientes querem certificados, de alguns lotes, em momentos que
ninguém prevê, então mandar todo certificado para todo mundo seria muito tráfego para nada. Uma chamada
que recebe o número do lote e devolve o certificado, servida por um pequeno serviço que lê o
Documentum pela interface dele (aula 5), deixa o sistema de uma rede, ou uma pessoa, pedir quando
precisar. Alguém está esperando, a resposta precisa ser o documento atual, e o volume é pequeno: as
três condições de novo.

| integração | hoje | decidido | o fato que decidiu |
|---|---|---|---|
| Coleta → SAP, litros | arquivo | arquivo, com controles | ninguém espera; o Coleta vai se aposentar |
| Portal → SAP, estoque | chamada | chamada, com plano B | uma padaria espera uma resposta atual |
| SAP → Salesforce, notas | chamadas encadeadas pelo ESB | evento | três consumidores de um fato, ninguém esperando |
| SAP ↔ bancos | arquivo CNAB | arquivo CNAB | o padrão do banco |
| SAP → Rota, recebimento das fábricas | arquivo às 16:00 | evento | o plano muda à noite |
| Documentum → clientes, certificados | e-mail à mão | API | pedido sob demanda, por lote |

## O que a tabela não resolve

Duas coisas ficam fora dela.

**Quem é dono da integração.** Toda linha do mapa precisa de um nome na coluna do dono, e um estilo
não fornece um. Um tópico de eventos sem dono é um esquema que muda quando alguém tem vontade; um
arquivo sem dono é aquele cuja senha vence.

**O custo de mudar.** Uma linha que funciona, num estilo que a tabela não escolheria, não vale
automaticamente a mudança. A Serra Alta tem 17 vínculos por banco, e o plano da Joana muda 4 deles no
próximo ano: os que leem as tabelas do SAP e quebrariam na migração para o S/4HANA de qualquer jeito.
Os outros ganham um dono, uma anotação no mapa e um alarme. **O mapa é uma lista de decisões a tomar,
não uma lista de coisas a reconstruir**, e a aula 15 trata de como pôr um custo nas que você
reconstrói.

Decididos os estilos, as próximas perguntas ficam dentro deles. A aula 10 desmonta o estilo de
mensageria: o que um broker promete e o que um consumidor precisa fazer a respeito. A aula 11 dá nome
aos padrões que aparecem dentro dos quatro estilos, como o tradutor que transforma uma linha num
evento de negócio e o roteador que decide qual consumidor recebe qual mensagem. Com esses nomes, o mapa
pode ser desenhado num vocabulário que todo o time de integração divide.
