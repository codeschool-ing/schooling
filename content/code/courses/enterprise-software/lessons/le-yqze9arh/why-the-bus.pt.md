---
title: Por que as empresas compraram um barramento
version: 1
---

A história que a maioria dos engenheiros conta sobre o enterprise service bus é curta: um produto
grande, vendido a empresas grandes, que transformou cada integração num chamado para um time
sobrecarregado. A própria Joana contava essa história na fintech, onde ninguém tinha barramento e
ninguém sentia falta de um. Ela está meio certa. **O barramento respondia a um problema real — o
número de conexões possíveis cresce com o quadrado do número de sistemas — e a maior parte dos
problemas que ele trouxe veio do que as pessoas puseram dentro dele depois, não da ideia de um
hub.** Joana precisa das duas metades antes de mexer em qualquer um dos 70 fluxos de Rui Andrade,
porque quem comprou o barramento em 2015 não era ingênuo, e os motivos que tinha continuam
valendo.

## A aritmética do ponto a ponto

Ligue os sistemas diretamente, cada par que precisa conversar com a sua própria interface, e o
número de conexões possíveis entre *n* sistemas é *n*(*n* − 1)/2. Cada sistema pode conversar com
*n* − 1 outros, e a divisão por dois evita contar o mesmo par duas vezes, uma de cada ponta.

| sistemas | conexões ponto a ponto possíveis |
|---|---|
| 4 | 6 |
| 7 | 21 |
| 12 | 66 |
| 15 | 105 |
| 20 | 190 |

Doze não é um número escolhido para a tabela. Conte os sistemas em volta do barramento da Serra
Alta hoje — SAP ECC, BW com BusinessObjects, Business Central, Microsoft 365, Salesforce,
Documentum, IBM BPM, Coleta, Rota, o Portal B2B, os arquivos dos bancos e o provedor de EDI — e são
doze: 12 × 11 / 2 = 66. **Sessenta e seis é um teto, não uma contagem.** O Rota não tem nada a
dizer ao Documentum, e nem todo par conversa. Mas é o teto que cresce: mais três sistemas o levam a
105, ou seja, 39 interfaces possíveis a mais por três nomes novos no diagrama.

O que dói não são as linhas. É o que cada linha carrega. Uma interface direta é um pequeno acordo
particular entre dois sistemas: um layout de arquivo, um mapeamento de campos, um horário, um
hábito de novas tentativas, uma senha que alguém definiu em 2012. **A integração ponto a ponto não
falha de uma vez; ela falha como uma pilha crescente de acordos que ninguém consegue listar.**

A Serra Alta aprendeu isso antes do barramento. Em 2014 ela tinha sete sistemas e 17 interfaces
diretas entre eles, cada uma escrita por quem precisou dela na época, no que essa pessoa sabia:
programas ABAP lendo arquivos, um job Java consultando uma tabela de tempos em tempos, um script
copiando uma planilha para uma pasta compartilhada. Quando o time de SAP mudou os códigos de
material do leite em pó naquele ano, 5 das 17 quebraram. Três foram descobertas na manhã seguinte.
Duas foram descobertas por um cliente, cujos pedidos vinham chegando com o produto errado havia uma
semana.

## A promessa do hub

A resposta que o mercado oferecia era um hub. Em vez de ligar cada par, ligue cada sistema uma vez
só, a alguma coisa no meio, e deixe o meio fazer o trabalho: *n* conexões em vez de até
*n*(*n* − 1)/2. Para os doze da Serra Alta, são 12 em vez de 66.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l08-hub\" aria-label=\"Dois painéis com os mesmos doze sistemas num anel: SAP ECC, BW/BO, Dynamics BC, M365, Salesforce, Documentum, IBM BPM, Coleta, Rota, Portal B2B, os bancos e EDI. À esquerda, ponto a ponto, cada par está ligado por uma linha: 66 linhas, o máximo que doze sistemas podem precisar. À direita, cada sistema tem uma linha até um ESB no meio: 12 linhas. Uma nota embaixo dos dois diz que os mapeamentos e as regras que as 66 linhas carregariam agora ficam dentro do hub.\"><path d=\"M185.0 72.0 L235.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L271.6 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 72.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L271.6 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 85.4 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L285.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 122.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L271.6 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M285.0 172.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L235.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M271.6 222.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L185.0 272.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M235.0 258.6 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L135.0 258.6\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M185.0 272.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L98.4 222.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M135.0 258.6 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L85.0 172.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 222.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M85.0 172.0 L98.4 122.0\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M85.0 172.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M98.4 122.0 L135.0 85.4\" stroke=\"var(--wire)\" stroke-width=\"0.7\" fill=\"none\"></path><path d=\"M535.0 157.0 L535.0 72.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M543.7 157.0 L585.0 85.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M561.0 157.0 L621.6 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M565.0 172.0 L635.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M561.0 187.0 L621.6 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M543.7 187.0 L585.0 258.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M535.0 187.0 L535.0 272.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.3 187.0 L485.0 258.6\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M509.0 187.0 L448.4 222.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M505.0 172.0 L435.0 172.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M509.0 157.0 L448.4 122.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><path d=\"M526.3 157.0 L485.0 85.4\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\"></path><rect x=\"505.0\" y=\"157.0\" width=\"60.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"535.0\" y=\"172.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">ESB</text><circle cx=\"185.0\" cy=\"72.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"185.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><circle cx=\"235.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"245.0\" y=\"78.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BW/BO</text><circle cx=\"271.6\" cy=\"122.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"281.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dynamics BC</text><circle cx=\"285.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"295.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">M365</text><circle cx=\"271.6\" cy=\"222.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"281.6\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><circle cx=\"235.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"245.0\" y=\"265.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Documentum</text><circle cx=\"185.0\" cy=\"272.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"185.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM BPM</text><circle cx=\"135.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"125.0\" y=\"265.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><circle cx=\"98.4\" cy=\"222.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"88.4\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Rota</text><circle cx=\"85.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"75.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><circle cx=\"98.4\" cy=\"122.0\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"88.4\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bancos</text><circle cx=\"135.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--paper-dim)\"></circle><text x=\"125.0\" y=\"78.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><circle cx=\"535.0\" cy=\"72.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"535.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">SAP ECC</text><circle cx=\"585.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"595.0\" y=\"78.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">BW/BO</text><circle cx=\"621.6\" cy=\"122.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"631.6\" y=\"118.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Dynamics BC</text><circle cx=\"635.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"645.0\" y=\"172.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">M365</text><circle cx=\"621.6\" cy=\"222.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"631.6\" y=\"226.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Salesforce</text><circle cx=\"585.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"595.0\" y=\"265.5\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Documentum</text><circle cx=\"535.0\" cy=\"272.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"535.0\" y=\"286.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IBM BPM</text><circle cx=\"485.0\" cy=\"258.6\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"475.0\" y=\"265.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Coleta</text><circle cx=\"448.4\" cy=\"222.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"438.4\" y=\"226.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Rota</text><circle cx=\"435.0\" cy=\"172.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"425.0\" y=\"172.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Portal B2B</text><circle cx=\"448.4\" cy=\"122.0\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"438.4\" y=\"118.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">Bancos</text><circle cx=\"485.0\" cy=\"85.4\" r=\"4.5\" fill=\"var(--phosphor)\"></circle><text x=\"475.0\" y=\"78.5\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">EDI</text><text x=\"185.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">ponto a ponto: até 66 conexões</text><text x=\"535.0\" y=\"18.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">um hub: 12 conexões</text><path d=\"M360.0 40.0 L360.0 296.0\" stroke=\"var(--wire)\" stroke-width=\"1\" fill=\"none\" stroke-dasharray=\"4 4\"></path><text x=\"360.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-style=\"italic\" fill=\"var(--amber)\">o hub guarda todos os mapeamentos e regras que as 66 linhas carregariam</text></svg>", "caption": "Doze sistemas: o teto de n(n − 1)/2 = 66 conexões diretas contra doze até um hub. O número de linhas cai; o número de acordos, não.", "same": ["BW/BO", "Coleta", "Documentum", "Dynamics BC", "EDI", "ESB", "IBM BPM", "M365", "Portal B2B", "Rota", "SAP ECC", "Salesforce"]}
```

A ideia é mais velha que o nome. Nos anos 1990 os produtos se chamavam message brokers ou hubs de
EAI (enterprise application integration). Por volta de 2002, com a chegada dos web services e da
arquitetura orientada a serviços, a geração seguinte passou a ser chamada de enterprise service
bus. O termo costuma ser atribuído a analistas do Gartner, e o livro *Enterprise Service Bus*, de
David Chappell (O'Reilly, 2004), deu a ele uma forma que os fornecedores passaram a seguir. A
palavra *bus* veio do hardware: um canal compartilhado em que todo componente se conecta, em vez de
um fio entre cada par.

A promessa tinha quatro partes. Cada uma nomeia uma necessidade que não foi embora, e é por isso
que as mesmas quatro palavras voltam em todo produto de integração vendido desde então.

| o que o barramento prometia | o que isso significava para a Serra Alta |
|---|---|
| roteamento | um pedido do provedor de EDI vai para o SAP; um alerta de qualidade vai para três lugares; nenhum remetente precisa saber quem recebe |
| transformação | o pedido EDI de um supermercado vira um IDoc do SAP, o formato do próprio SAP para documentos trocados com outros sistemas |
| mediação de protocolo | o Coleta fala MQ a partir de um IBM i; uma aplicação web fala HTTP; o barramento deixa um alcançar o outro sem que nenhum aprenda o protocolo do outro |
| um lugar para observar | toda mensagem passa por um motor só, então um console mostra o que passou, o que falhou e o que está parado |

A quarta linha vendeu o produto ao antecessor de Regina. Antes do barramento, descobrir se um
pedido tinha chegado ao SAP significava perguntar a três pessoas, cada uma conhecendo uma das 17
interfaces. Depois dele, Rui podia abrir um console e procurar o número do pedido.

## Os produtos

Cinco linhas de produto são as que você vai encontrar numa empresa da idade da Serra Alta. Elas
diferem nos detalhes e compartilham a forma: um runtime que executa **fluxos** (uma cadeia de
passos por onde a mensagem passa), uma ferramenta gráfica para desenhá-los, uma biblioteca de
conectores para protocolos e aplicações de pacote, e quase sempre um message broker por baixo.

| produto | de onde veio |
|---|---|
| IBM Integration Bus, hoje App Connect Enterprise | a linha de brokers da IBM, antes chamada WebSphere Message Broker; quase sempre instalado ao lado do IBM MQ |
| Oracle Service Bus | chegou à Oracle com a BEA Systems, onde era o AquaLogic Service Bus |
| TIBCO BusinessWorks | o produto de integração da TIBCO, em geral ao lado da mensageria da própria TIBCO |
| Mule | da MuleSoft, com um núcleo de código aberto; a Salesforce comprou a MuleSoft em 2018 |
| Microsoft BizTalk Server | o servidor de integração da Microsoft, lançado pela primeira vez em 2000 |

O da Serra Alta é o primeiro. O IBM Integration Bus 10 roda os 70 message flows de Rui; cada fluxo
é uma cadeia de nós — um nó de entrada que tira uma mensagem de uma fila MQ ou recebe uma
requisição HTTP, nós de cálculo escritos em ESQL (a linguagem do produto, parecida com SQL), nós de
mapeamento desenhados num editor gráfico, e um nó de saída. **O IBM MQ, por baixo, faz a parte pela
qual um barramento raramente recebe crédito: guarda uma mensagem com segurança até o outro lado
estar pronto para recebê-la.** A aula 10 trata dessa parte, e é a parte que vale manter, aconteça o
que acontecer com o resto.

Nem tudo passou por ele. O arquivo noturno do Coleta para o SAP é mais velho que o barramento e
nunca foi transferido para ele, e a aula 9 explica por que talvez ele esteja no lugar certo.

## O que o hub não eliminou

A figura acima parece uma vitória limpa, 66 contra 12. Olhe o que mudou de lugar em vez do que
sumiu. Todo mapeamento, toda rota, toda regra sobre que sistema fica sabendo de que evento continua
existindo; agora há 12 conexões com o barramento e, dentro dele, todas as relações que as 66 linhas
teriam carregado. **Um hub reduz o número de conexões; não reduz o número de acordos.** Ele os põe
num lugar só, sob um time só.

Isso é um ganho real quando o time dono do lugar é bom no que faz, e o de Rui é. Os acordos estão
listados, versionados e observados, o que nunca estiveram em 2014. Vira custo quando o lugar se
enche de acordos que pertencem a outras pessoas, e quando toda mudança em qualquer um deles tem de
ser feita pelas mesmas quatro pessoas. A seção 05 desta aula conta essa história.

Mais dois custos vieram com o hub. Tudo passa por um motor só, então quando o motor para, toda
integração para junto; a aula 12 faz a conta do que isso significa para a disponibilidade. E um
barramento é um produto com licença, versão e calendário de suporte. O IBM Integration Bus 10 está
várias versões atrás do App Connect Enterprise, e o time de Rui gasta parte de todo ano em
atualizações que não mudam nada que um usuário consiga ver.

Nada disso torna errada a decisão de 2015. A primeira anotação de Joana no caderno, depois de uma
semana lendo fluxos, diz isso: *o barramento resolveu o problema de 2014. O que eu herdei é o
problema que a solução criou, onze anos depois.*
