---
title: WS-*, os padrões que encheram o header
version: 1
---

O `Header` do SOAP foi projetado para ser estendido. Qualquer coisa que a infraestrutura precisasse
dizer sobre uma mensagem — quem a mandou, se ela pode ser lida no caminho, para onde deve ir a
resposta, a que transação pertence — podia virar um bloco de header com namespace próprio, definido
por uma especificação própria. Entre mais ou menos 2002 e 2007, fornecedores e organismos de
padronização escreveram dezenas delas, e a família ficou conhecida como WS-\*, lido "WS-star". A
visão comum hoje é que o WS-\* foi excesso de engenharia. **Cada especificação resolvia um problema
real; o que afundou a família foi que elas tinham de ser combinadas, e cada combinação era um lugar
novo para as ferramentas de dois fornecedores discordarem.**

## As quatro que você vai encontrar

| especificação | organismo, ano | o problema que ela resolvia |
|---|---|---|
| WS-Addressing | W3C Recommendation, 2006 | a mensagem diz para onde vai e para onde deve ir a resposta, dentro do envelope, então pode atravessar o MQ ou um segundo salto e ainda ser respondida |
| WS-Security | padrão OASIS, 2004 | partes de uma mensagem são assinadas e cifradas, e tokens de identidade viajam no header, então a proteção acompanha a mensagem por todo intermediário |
| WS-ReliableMessaging | padrão OASIS, 2007 | uma sequência de mensagens chega, cada uma uma vez e em ordem, por uma conexão que cai, numerando as mensagens e confirmando o que chegou |
| WS-AtomicTransaction | padrão OASIS, 2007 | vários serviços confirmam juntos ou nenhum confirma, com um coordenador rodando um commit em duas fases entre eles |

Em volta dessas quatro ficavam o WS-Policy (um serviço declara o que exige, como "toda requisição
assinada"), o WS-Trust e o WS-SecureConversation (emitir e reaproveitar tokens de segurança), o
WS-Federation, o WS-Coordination e o WS-BPEL, a linguagem de orquestração que a aula 7 descreveu.
Uma pilha WS-\* completa somava milhares de páginas de especificação.

## WS-Addressing: o envelope que sabe o caminho

Em HTTP puro, a resposta volta pela conexão por onde a requisição chegou. Ponha a mesma mensagem
numa fila MQ, ou faça-a passar por um barramento que a segura por uma hora, e não há conexão por
onde responder. O WS-Addressing pôs os fatos de roteamento no header: `To`, `Action`, `MessageID`,
`ReplyTo` e, na resposta, `RelatesTo`, com o id da mensagem que ela responde. Esse último par é o
identificador de correlação, e a aula 11 mostra que ele é um padrão e não uma invenção do SOAP.
**A ideia sobreviveu em toda parte; o header, não.** Os brokers hoje levam os mesmos fatos como
propriedades da mensagem, e uma API HTTP os leva em headers próprios.

## WS-Security: proteção que viaja com a mensagem

O TLS protege uma conexão, de uma ponta à outra. Quando uma mensagem atravessa um barramento, há
duas conexões, e no meio o barramento lê a mensagem aberta, porque precisa roteá-la e
transformá-la. **O WS-Security tirou a proteção da conexão e a pôs na mensagem.** Uma XML Signature
sobre o body prova quem a escreveu e que ninguém a alterou, a XML Encryption esconde elementos
escolhidos de todos menos do receptor final, e o barramento no meio ainda consegue ler as partes de
que precisa.

Essa é uma capacidade de verdade, e é exatamente o que o TLS não consegue dar. Também foi a parte
do WS-\* mais difícil de acertar. Uma assinatura sobre XML é calculada sobre uma forma canônica do
documento, e duas ferramentas que discordavam num detalhe da canonicalização, uma declaração de
namespace movida ou uma quebra de linha normalizada, produziam assinaturas que a outra não
conseguia verificar.

O que a maioria dos serviços usava de fato era bem mais simples: um `UsernameToken` no header. O
FarmRegistry exige um, e é por isso que a requisição da seção anterior estava incompleta:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<soap:Envelope xmlns:soap="http://schemas.xmlsoap.org/soap/envelope/"
    xmlns:wsse="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd"
    xmlns:fr="http://schemas.serraalta.example/farm-registry/2016">
  <soap:Header>
    <wsse:Security soap:mustUnderstand="1">
      <wsse:UsernameToken>
        <wsse:Username>rota-planner</wsse:Username>
        <wsse:Password Type="http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-username-token-profile-1.0#PasswordText">********</wsse:Password>
      </wsse:UsernameToken>
    </wsse:Security>
  </soap:Header>
  <soap:Body>
    <fr:GetFarmTank>
      <fr:farmCode>0412736</fr:farmCode>
    </fr:GetFarmTank>
  </soap:Body>
</soap:Envelope>
```

Dois detalhes carregam a lição. `mustUnderstand="1"` diz ao receptor que, se ele não souber o que é
um bloco `wsse:Security`, deve recusar a mensagem com um fault em vez de ignorá-lo; sem isso, um
serviço que pulasse a segurança processaria a chamada como se nada faltasse. E `PasswordText`
significa que a senha está na mensagem como foi escrita. **Um `UsernameToken` com senha em texto
puro é exatamente tão seguro quanto o TLS em volta dele, e nem um pouco mais**: é de nível de
mensagem na forma e de nível de conexão na proteção. O FarmRegistry e os 14 serviços que o
Salesforce chama funcionam todos assim, com uma conta compartilhada por sistema chamador, e nenhum
dos 70 fluxos assina ou cifra coisa alguma.

A capacidade não sumiu onde ela é necessária. Uma NF-e é um documento XML assinado com XML
Signature, usando o certificado digital do emissor, para que a autoridade tributária, o cliente e
um auditor anos depois possam conferir cada um quem a emitiu e que nada nela mudou. A assinatura
fica dentro da nota e não num header SOAP, porque é o documento que precisa ser provado, não uma
viagem que ele fez.

## WS-ReliableMessaging e WS-AtomicTransaction

O WS-ReliableMessaging deu ao SOAP sobre HTTP o que um message broker dá a qualquer coisa: cada
mensagem de uma sequência é numerada, o receptor confirma faixas, e o remetente retransmite o que
não foi confirmado. Funcionava, e exigia que as duas pontas guardassem estado de sequência. **As
empresas que já tinham um broker, como a Serra Alta tem o IBM MQ, ganhavam a mesma garantia sem exigir nada das pontas.** A aula 10 mostra o dever que o broker não consegue tirar delas: um
consumidor que recebe a mesma mensagem duas vezes sem fazer o trabalho duas vezes.

O WS-AtomicTransaction levou aos serviços o commit em duas fases dos bancos de dados. Um coordenador
pede a cada participante que se prepare, e cada um segura os seus locks até o coordenador dizer
confirma ou aborta. Dentro de um data center com um dono só, isso é viável. Entre serviços de times
diferentes, significa o banco de um time esperando, com locks presos, pelo coordenador de outro
time. Entre empresas, a pane de um fornecedor prende as suas linhas. Pouquíssimas organizações o
ligaram. A ideia que o substituiu é a compensação da aula 7: faça cada passo de verdade e, quando um
passo posterior falhar, desfaça os anteriores com uma ação própria.

## Por que o peso empurrou todo mundo para longe

Nenhuma especificação sozinha era o problema. O problema estava nas junções:

- A interoperabilidade tinha de ser negociada. A organização WS-I existia para publicar perfis
  dizendo que opções de que especificação duas ferramentas deviam usar, para que um serviço Java e
  um cliente .NET conseguissem conversar.
- A ferramenta era o único jeito de escrever uma mensagem. Um desenvolvedor não conseguia montar à
  mão uma requisição SOAP assinada, endereçada e confiável e conferi-la a olho, então os bugs da
  ferramenta viravam os do sistema.
- Tamanho e velocidade sofriam: uma requisição com três blocos de header e uma assinatura tinha
  muitas vezes o tamanho da sua carga, e interpretá-la custava tempo de verdade no hardware de 2005.
- O navegador e o celular não conseguiam participar. O JavaScript numa página conseguia fazer uma
  chamada HTTP e ler JSON; não conseguia rodar uma pilha WS-Security.

Roy Fielding tinha descrito o REST na sua tese de doutorado em 2000, e o JSON tinha sido
especificado como RFC 4627 em 2006. Na década seguinte a 2005, as APIs públicas migraram para JSON
sobre HTTP, com TLS para a conexão e tokens como os do OAuth para a identidade, e os times das
empresas foram atrás quando construíam serviços novos. **O que ficou para trás foi a segurança no
nível da mensagem e um contrato legível por máquina; a primeira raramente faz falta, e o segundo
voltou como OpenAPI.**

Dentro de empresas como a Serra Alta, o WS-\* não morreu. Parou de crescer. Os 14 serviços que o
Salesforce chama ainda esperam um `UsernameToken`, os serviços da NF-e ainda carregam XML assinado,
e o time de Rui ainda mantém uma ferramenta de teste SOAP aberta em toda tela. O trabalho de Joana
não é tirar nada disso às pressas. É garantir que nada novo seja construído desse jeito, e que os
serviços que ficam estejam bem embrulhados, que é a seção 06 desta aula.
