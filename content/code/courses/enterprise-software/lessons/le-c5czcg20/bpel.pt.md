---
title: BPEL, a linguagem que executava processos antes de a BPMN conseguir
version: 1
---

Antes de a BPMN 2.0 dar aos seus diagramas um significado que uma engine pudesse executar, a
linguagem para rodar um processo era outra: **a WS-BPEL, Web Services Business Process Execution
Language**. Se você trabalha numa empresa com um parque de integração dos anos 2000, vai encontrá-la,
quase sempre dentro de um produto de ESB, quase sempre rodando um processo que ninguém abre há anos.
Vale saber o que ela foi, porque os motivos pelos quais ela sumiu são os mesmos pelos quais um modelo
de processo e o código que o executa ainda se distanciam hoje.

Muita gente se lembra da BPEL como o formato XML da BPMN. **Era uma linguagem separada, com
um modelo de mundo separado: um processo era um web service que chama outros web services, e nada
mais.** A BPMN era uma notação para pessoas que depois aprendeu a rodar; a BPEL era uma linguagem de
programação para máquinas, da qual se esperava que as pessoas desenhassem figuras.

## De onde ela veio

A IBM e a Microsoft tinham cada uma a sua linguagem para compor web services, a WSFL da IBM e a
XLANG da Microsoft. Em 2002 as duas as fundiram na BPEL4WS, com a BEA junto, e a versão 1.1 veio em
2003, com a SAP e a Siebel entre os autores. A especificação foi para a OASIS, que publicou a
**WS-BPEL 2.0 como OASIS Standard em 2007**. O BPEL Process Manager da Oracle, parte da SOA Suite, e o
WebSphere Process Server da IBM estavam entre as engines que a executavam, e os dois eram o tipo de
produto que vinha junto com um barramento de serviços corporativo.

## Como é um processo BPEL

Um processo BPEL é um documento XML, e cada interação nele é uma operação de web service descrita em
WSDL, a linguagem de interface dos serviços SOAP que a aula 8 abre por dentro. O processo declara
seus *partner links*, os serviços com que conversa e o papel que ele faz com cada um; suas
*variáveis*, que são mensagens WSDL; e então suas atividades. Aqui está o começo do cadastro como a
BPEL o teria expressado, para leitura:

```xml
<process name="FarmOnboarding"
         targetNamespace="http://serraalta.example/bpel/onboarding"
         xmlns="http://docs.oasis-open.org/wsbpel/2.0/process/executable"
         xmlns:on="http://serraalta.example/wsdl/onboarding">
  <partnerLinks>
    <partnerLink name="field" partnerLinkType="on:FieldLT" myRole="onboarding"/>
    <partnerLink name="bank" partnerLinkType="on:BankLT" partnerRole="registry"/>
  </partnerLinks>
  <variables>
    <variable name="application" messageType="on:ApplicationMsg"/>
    <variable name="account" messageType="on:AccountMsg"/>
    <variable name="accountId" messageType="on:AccountIdMsg"/>
  </variables>
  <sequence>
    <receive name="ReceiveApplication" partnerLink="field" operation="apply"
             variable="application" createInstance="yes"/>
    <assign name="PrepareAccount">
      <copy>
        <from variable="application" part="bankDetails"/>
        <to variable="account" part="details"/>
      </copy>
    </assign>
    <invoke name="RegisterAccount" partnerLink="bank" operation="registerAccount"
            inputVariable="account" outputVariable="accountId"/>
  </sequence>
</process>
```

Leia a partir do `<sequence>`. O `<receive>` espera uma chamada à operação `apply` no partner link
`field`, em que este processo faz o papel `onboarding`; `createInstance="yes"` diz que uma chamada ali
começa uma instância nova, como um evento de início faz na BPMN. O `<assign>` copia os dados
bancários da mensagem que chegou para a mensagem que o banco espera. O `<invoke>` chama a operação
`registerAccount` do banco e guarda a resposta em `accountId`. Os nomes com `on:` apontam para um
arquivo WSDL que este fragmento não mostra; sem ele, o processo não significa nada.

Um `<receive>` posterior para o contrato assinado precisaria de mais uma ideia, a **correlação**: um
valor na mensagem, como o número do pedido da fazenda, que diz à engine a qual das instâncias em
execução a mensagem pertence. As engines BPMN precisam da mesma coisa para um evento de mensagem no
meio de um processo, e a BPEL foi o primeiro lugar em que a maioria dos engenheiros a encontrou.

O resto da linguagem vai parecer familiar depois das seções anteriores. `<flow>` roda atividades em
paralelo, como uma divisão e uma junção paralelas. `<if>` e `<while>` ramificam e repetem. `<pick>`
espera a primeira de várias mensagens ou alarmes, que é o gateway baseado em eventos da BPMN.
`<scope>` agrupa atividades com seus próprios *tratadores de falha* e *tratadores de compensação*,
as mesmas ideias de um evento de borda de erro e de uma atividade de compensação. Os conceitos
passaram de uma para a outra; a notação não.

## Por que ela sumiu

**Ela só falava SOAP.** Um processo BPEL só conseguia chamar um parceiro por uma operação WSDL. Quando
os serviços passaram para REST e JSON ao longo dos anos 2010, cada chamada a algo novo precisava
primeiro de um invólucro SOAP, e a linguagem envelheceu junto com o protocolo sobre o qual foi
construída.

**Ela não tinha pessoas.** Toda atividade BPEL é uma troca de mensagens com um serviço. O cadastro é
quase todo feito de pessoas: uma conferência de documentos, uma visita, uma gerente decidindo. A IBM
e a SAP propuseram a BPEL4People e a WS-HumanTask em 2005 para acrescentar tarefas humanas, e a OASIS
depois as assumiu, mas àquela altura cada fornecedor tinha sua própria extensão, e um processo com
pessoas dentro deixou de ser portável entre engines.

**Ninguém fora de TI conseguia lê-la.** O negócio desenhava seu processo numa ferramenta de
diagramas, e a TI traduzia o desenho para BPEL. A tradução perdia coisas: um diagrama BPMN é um
grafo, em que quase qualquer elemento pode se ligar a quase qualquer outro, e a BPEL é feita
principalmente de blocos aninhados, então um diagrama com setas que pulavam entre ramos não tinha
tradução direta. Depois que a TI mudava a BPEL, o desenho ficava desatualizado, e nada levava a
mudança de volta. **Dois artefatos descrevendo um processo, editados por dois grupos em duas
linguagens, vão discordar**, e na maioria das empresas discordaram em uma ou duas versões.

**A BPMN 2.0 tomou o lugar dela.** Quando a BPMN ganhou semântica de execução e um formato XML
próprios, o modelo que o negócio conseguia ler passou a ser também o arquivo que uma engine
conseguia rodar, e a etapa de tradução perdeu a razão de existir. As engines que a maioria dos times
escolhe hoje, entre elas as abertas da Camunda e da Flowable, executam BPMN diretamente e chamam
serviços de qualquer tipo.

## Orquestração e coreografia

A BPEL deixou uma distinção clara para sempre. **Na orquestração, um processo é o maestro: ele
conhece a sequência inteira, chama cada participante na sua vez e guarda o estado.** Um processo
BPEL é uma orquestração, e um processo BPMN único num pool também é. Você pode perguntar ao maestro
onde está qualquer instância.

**Na coreografia, não há maestro.** Cada participante conhece a sua parte e reage às mensagens que
recebe, e o processo só existe como a soma do que todos fazem. O W3C começou uma linguagem para
descrever coreografias, a WS-CDL, nos mesmos anos da BPEL; ela nunca chegou a ser muito usada. A
BPMN 2.0 tem diagramas de coreografia, e poucas ferramentas os executam.

A troca é real nos dois sentidos. Uma orquestração dá um lugar só para ver o estado do pedido de
cada fazenda e um lugar só para mudar a ordem dos passos; também dá a cada participante uma
dependência do maestro. Uma coreografia espalha o conhecimento para que nenhum componente precise
saber tudo, e não deixa ninguém capaz de responder "onde está a fazenda 4471?" sem perguntar a
todos. As aulas 10 e 11 voltam à coreografia feita de eventos e mensagens. No cadastro, Joana e
Denise querem a resposta a essa pergunta mais do que qualquer outra coisa, o que aponta para um
orquestrador; a fazenda e o banco ficam fora dele, como pools trocando mensagens.
