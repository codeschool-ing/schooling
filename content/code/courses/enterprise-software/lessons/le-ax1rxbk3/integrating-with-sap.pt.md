---
title: As portas do SAP, e a que fica fechada
version: 1
---

A aula 1 terminou com a regra de Joana para o Portal B2B: *o portal não lê as tabelas do SAP*. Essa
regra diz por onde não ir. Esta seção diz por onde ir. **O SAP publica quatro tipos de porta, e
cada uma serve a uma conversa diferente**: IDocs para documentos que viajam de forma assíncrona,
BAPIs chamadas por RFC para uma operação de negócio síncrona, serviços OData para clientes web, e
arquivos para lotes. O banco de dados não é uma porta, nem para escrever nem para ler. Escolher entre
as quatro é quase tudo o que integrar com o SAP significa, e a Serra Alta usa todas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 370\" role=\"img\" data-fig=\"l02-doors\" aria-label=\"O SAP ECC desenhado como uma caixa com quatro portas nas bordas. À esquerda, os pedidos dos supermercados chegam do provedor de EDI pelo barramento como IDocs, e o Coleta manda o arquivo noturno às 02:00. À direita, o Portal B2B cria pedidos chamando uma BAPI por RFC e consulta o disponível para promessa por um serviço OData. Toda porta leva ao código do próprio SAP, que calcula preço, verifica, numera, registra o fluxo de documentos e confere autorização, e só esse código escreve no banco. Embaixo, um cliente SQL tentando chegar ao banco diretamente está riscado: as tabelas são o modelo privado do SAP, não uma porta.\"><defs><marker id=\"l02-doors-es-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l02-doors-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"230.0\" y=\"40.0\" width=\"260.0\" height=\"260.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.6\"></rect><text x=\"360.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">SAP ECC</text><rect x=\"292.0\" y=\"110.0\" width=\"136.0\" height=\"80.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"130.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">o código do SAP:</text><text x=\"360.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">preço, verificações,</text><text x=\"360.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">números, fluxo de</text><text x=\"360.0\" y=\"169.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">documentos, autorização</text><rect x=\"285.0\" y=\"228.0\" width=\"150.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"241.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">banco de dados</text><text x=\"360.0\" y=\"254.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">modelo privado do SAP</text><path d=\"M360.0 191.0 L360.0 226.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"189.0\" y=\"112.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IDoc</text><path d=\"M272.0 125.0 L290.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"189.0\" y=\"162.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"230.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">arquivo</text><path d=\"M272.0 175.0 L290.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"449.0\" y=\"112.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BAPI / RFC</text><path d=\"M448.0 125.0 L430.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"449.0\" y=\"162.0\" width=\"82.0\" height=\"26.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"490.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">OData</text><path d=\"M448.0 175.0 L430.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"11.0\" y=\"104.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedidos dos supermercados,</text><text x=\"95.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI pelo barramento</text><path d=\"M179.0 125.0 L187.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"11.0\" y=\"154.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta, o arquivo</text><text x=\"95.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">toda noite às 02:00</text><path d=\"M179.0 175.0 L187.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"541.0\" y=\"104.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"118.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pedidos do Portal B2B,</text><text x=\"625.0\" y=\"131.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pelo barramento</text><path d=\"M541.0 125.0 L533.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"541.0\" y=\"154.0\" width=\"168.0\" height=\"42.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"625.0\" y=\"168.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><text x=\"625.0\" y=\"181.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">consulta de estoque</text><path d=\"M541.0 175.0 L533.0 175.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l02-doors-es-ah-phosphor)\"></path><rect x=\"285.0\" y=\"330.0\" width=\"150.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"360.0\" y=\"345.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">um cliente SQL</text><path d=\"M360.0 330.0 L360.0 304.0\" stroke=\"var(--amber)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l02-doors-es-ah-amber)\"></path><path d=\"M350.0 307.0 L370.0 323.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><path d=\"M370.0 307.0 L350.0 323.0\" stroke=\"var(--amber)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"560.0\" y=\"323.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">não é porta, nem para escrever</text><text x=\"560.0\" y=\"336.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">nem para ler</text></svg>", "caption": "Quatro portas publicadas, e todas passam pelo código do próprio SAP. O banco fica atrás desse código, não ao lado dele.", "same": ["BAPI / RFC", "IDoc", "OData", "Portal B2B", "SAP ECC"]}
```

## IDoc: um documento que viaja

Um *IDoc*, um documento intermediário, é o formato da SAP para um documento de negócio que se move
entre sistemas. Ele tem um registro de controle dizendo o que é, quem mandou e quem recebe; uma lista
de segmentos de dados com o conteúdo; e registros de status acrescentados conforme é processado.
**O que um IDoc carrega é dado pelo tipo de mensagem**, e os mais comuns são os documentos do
comércio: `ORDERS` para um pedido de compra, `DESADV` para um aviso de expedição, `INVOIC` para uma
fatura. Cada tipo de mensagem tem uma estrutura versionada por trás, como a `ORDERS05`, então um
parceiro pode ficar num leiaute mais antigo sem que os outros mudem.

As grandes redes de supermercado da Serra Alta fazem pedidos assim. O pedido de uma rede chega ao
provedor de EDI, que o passa ao barramento de integração, que o transforma num IDoc `ORDERS` e o
entrega ao SAP. O SAP cria uma ordem de venda a partir dele. Quando a mercadoria sai, o SAP manda um
`DESADV` de volta pelo mesmo caminho, e um `INVOIC` segue o faturamento.

**Um IDoc é assíncrono, e isso muda o que "enviado" quer dizer.** Quando o barramento entrega um
IDoc `ORDERS` ao SAP, o SAP o aceita e o guarda, e só então tenta lançá-lo. Se o lançamento dá certo,
o IDoc chega ao status `53`, documento de aplicação lançado. Se falha, porque um material está
bloqueado ou um cliente não tem função de parceiro para o endereço de entrega, o IDoc para no status
`51` e espera num monitor até uma pessoa corrigir a causa e reprocessá-lo. Ninguém avisou o
remetente de que algo deu errado, porque no momento em que ele enviou nada tinha dado. **Uma
integração construída sobre IDocs precisa de alguém que vigie o status `51`**, e na Serra Alta isso é
uma tarefa matinal do time de Rui Andrade, que passa para o pessoal de Edson quando a causa está
dentro do SAP.

## BAPI por RFC: uma operação de negócio, de forma síncrona

Uma *BAPI*, uma API de negócio, é uma função que a SAP publica num dos seus objetos de negócio: criar
uma ordem de venda, alterar um pedido de compra, ler um material. Ela roda dentro do SAP, então
aplica as mesmas verificações que a tela de um usuário: preço, crédito, disponibilidade,
autorização. Programas externos a chamam por *RFC*, o protocolo de chamada remota de função da SAP,
usando bibliotecas que a SAP fornece para Java, .NET e C.

A `BAPI_SALESORDER_CREATEFROMDAT2`, por exemplo, recebe o cabeçalho de uma ordem e os itens e devolve
o número da ordem nova, ou uma tabela de mensagens dizendo por que não há número. Dois hábitos pegam
quem vem de fora do SAP. **Uma BAPI que escreve não confirma sozinha**: quem chama precisa chamar a
`BAPI_TRANSACTION_COMMIT` em seguida, e um programa que esquece recebe o número de uma ordem que nunca
foi gravada. E uma BAPI informa a falha nessa tabela de mensagens devolvida, e não como exceção,
então quem lê só o número da ordem lê uma string vazia como sucesso.

Os pedidos do Portal B2B chegam ao SAP assim. O portal põe cada pedido numa fila do barramento, e um
fluxo o retira e chama a BAPI; a aula 10 é sobre essa fila. O número do pedido volta pelo mesmo
caminho, em geral em segundos, e a tela da padaria o mostra quando chega. O preço é o quarto ponto da
aula 1: nas noites de domingo, entre 01:00 e 05:00, não há quem responda, então os pedidos esperam na
fila e a tela avisa que serão confirmados depois.

## OData: o SAP sobre HTTP

O SAP Gateway expõe serviços sobre HTTP seguindo o protocolo OData, com payloads em JSON e URLs que
endereçam entidades e coleções. É a porta que a interface web da própria SAP, o Fiori, usa, e a mais
familiar para um desenvolvedor que só conhece REST. No S/4HANA a SAP publica muitas APIs OData padrão
e as lista no seu catálogo de APIs na internet. No ECC há bem menos APIs padrão, e a empresa costuma
construir as suas no Gateway.

Foi o que o time de Edson fez para a consulta de disponível para promessa da aula 1: um serviço OData
pequeno que responde, por material e centro, quanto pode ser prometido para uma data. Ele roda o
cálculo da própria SAP, então o portal recebe o número da SAP e não um palpite sobre ele. Escrevê-lo
levou três semanas e dois transportes do time de Edson; consumi-lo levou uma tarde do time do portal.

## Arquivos: a porta mais antiga, ainda aberta

Algumas conversas são lotes, e um arquivo é o formato certo para um lote. Duas das integrações mais
antigas da Serra Alta são arquivos. Toda noite o Coleta escreve uma linha de largura fixa por fazenda
coletada, cerca de 1.900, e às 02:00 um programa ABAP lê o arquivo e cria uma entrada de mercadoria
para cada linha. E o programa de pagamentos do SAP escreve um arquivo CNAB 240 para o banco com os
pagamentos de fazendas e fornecedores, e depois lê o arquivo de retorno do banco para saber quais
foram pagos.

**Um arquivo é uma porta publicada quando é um programa do próprio SAP que o lê**, porque esse
programa lança pela mesma lógica que um usuário usaria. O que falta a um arquivo é uma resposta: o
Coleta não fica sabendo que a linha 1.412 foi rejeitada, a não ser que alguém construa um jeito de
contar a ele. A aula 9 desmonta o arquivo do Coleta e mostra o que uma interface por arquivo precisa
ter para merecer confiança.

## Escolher uma porta

| porta | estilo | use quando | cuidado com |
|---|---|---|---|
| IDoc | assíncrono, um documento por vez | um documento de negócio viaja entre empresas ou sistemas, e o remetente não precisa esperar | falhas paradas no status `51` que ninguém vigia |
| BAPI por RFC | chamada síncrona | quem chama precisa do resultado agora, como um número de pedido na tela | o commit explícito, erros devolvidos como dados e as paradas do SAP |
| OData | síncrono, sobre HTTP | um cliente web ou mobile, ou um time sem as bibliotecas da SAP | no ECC, a maior parte dos serviços é você quem constrói e mantém |
| arquivo | lote | o volume de um dia inteiro se move de uma vez, num horário | nenhuma resposta ao remetente, e cargas parciais |

A Serra Alta chega à maioria dessas portas pelo seu barramento de integração, o IBM Integration Bus,
que tem adaptadores para IDocs e RFC. A SAP vende o seu próprio middleware para o mesmo trabalho, o
Process Orchestration no ambiente local e a Integration Suite na nuvem dela, e muitos clientes SAP o
usam. A Serra Alta escolheu o da IBM em 2015, e a aula 8 é sobre conviver com esse barramento.

## A porta que fica fechada: escrever nas tabelas

Escrever nas tabelas do SAP com SQL é a única regra aqui sem exceção na Serra Alta. O instinto de
fintech de Joana era que um `INSERT` é um `INSERT`, e Edson respondeu com o que faltaria a uma ordem
de venda criada assim.

**Uma linha escrita direto nas tabelas do SAP pula tudo o que o SAP faz quando cria um documento.**
Nada de preço nem de verificação de crédito. Nenhum número tirado do intervalo de numeração do SAP,
então uma ordem posterior pode receber o mesmo número. Nenhum bloqueio, então um funcionário na
`VA01` pode estar alterando o mesmo cliente naquele instante. Nenhuma entrada no fluxo de
documentos, então a remessa, o faturamento e a NF-e nunca vêm depois. Nenhum documento de
modificação, então a trilha de auditoria mostra uma ordem que ninguém criou. E nenhuma verificação de
autorização, então um programa fez o que nenhuma pessoa na Serra Alta tem permissão para fazer. O
suporte da SAP não ajuda com dados criados desse jeito, e a próxima atualização está livre para mudar
a tabela por baixo deles.

## Por que ler também é uma armadilha

A aula 1 deu dois motivos para não ler as tabelas do SAP: a estrutura é o modelo privado da SAP e
ela muda, e o significado vive no código, não nas linhas. De perto há mais:

- **toda tabela de negócio carrega o mandante** como primeira coluna da chave, e uma consulta que o
  esquece soma os dados de treinamento do mandante `300` aos da produção;
- **os valores ficam guardados na forma interna do SAP**, então o cliente `12345` é o texto
  `0000012345`, uma data são os oito caracteres `20261023`, e o que um código de status significa
  está no customizing;
- **algumas tabelas não são tabelas comuns no ECC**: nos bancos para os quais o ECC foi desenhado,
  os itens contábeis da `BSEG` ficam num cluster que o SQL não consegue ler como linhas, e é assim
  que o ECC da Serra Alta os guarda;
- **as autorizações do SAP são conferidas na camada de aplicação**, então uma conta de banco de
  dados vê todas as linhas, inclusive as que nenhum usuário da Serra Alta tem permissão de ver.

Cada um desses problemas é resolvido por uma porta, porque a porta roda o código da SAP.

## A licença, contada por porta

A aula 1 contou a história de *SAP v Diageo* e a mudança da SAP para cobrar o uso indireto pelos
documentos criados, e não pelas pessoas. **Para um arquiteto, isso transforma cada integração numa
linha de um registro: que documentos do SAP ela cria, e quantos por mês?** Só o arquivo do Coleta
cria uma entrada de mercadoria para cada fazenda coletada, cerca de 1.900 por dia, o que dá por volta
de 57.000 por mês. Os pedidos de EDI dos supermercados, os pedidos do Portal B2B e o arquivo de
retorno do banco acrescentam as suas próprias linhas.

Se cada um deles conta, e a que preço, depende do contrato que a Serra Alta assinou, e essa é uma
pergunta para o time de contratos e para a SAP, não para este curso. O que o arquiteto deve a eles é
a contagem, mantida em dia, porque uma integração nova que cria documentos no SAP muda uma conta que
ninguém no time do projeto vai ver.
