---
title: De um modelo a algo que uma engine executa
version: 1
---

A aula 6 descreveu as suítes e engines que executam processos. Esta seção trata do arquivo que elas
executam, e da distância entre o diagrama que Denise consegue ler e o modelo que uma engine consegue
rodar. A imagem habitual é que o negócio desenha, a engine executa e ninguém escreve código. **Um
diagrama diz o que acontece e em que ordem; um modelo executável também diz, para cada forma,
exatamente como.** A segunda metade é a maior parte do trabalho, e é engenharia.

## O que uma forma precisa antes de rodar

Pegue o caminho feliz desenhado antes nesta aula e pergunte, forma por forma, o que uma engine
precisaria saber:

| no diagrama | o que a engine precisa |
|---|---|
| o processo inteiro | variáveis de processo: o número do pedido, o CPF ou CNPJ da fazenda, o resultado da visita, o id da conta, com tipos |
| "Conferir documentos", uma tarefa de usuário | um formulário para mostrar, e uma atribuição: em que lista de tarefas de qual grupo ela aparece |
| "Cadastrar conta bancária", uma tarefa de serviço | uma implementação: que serviço chamar, com que variáveis, e o que fazer com a resposta |
| "aprovada?", um gateway | uma condição em cada fluxo de saída, numa linguagem de expressões que a engine lê |
| o temporizador de 10 dias | uma definição de tempo, `P10D` |
| "contrato assinado recebido" | um nome de mensagem e uma chave de correlação, para a instância certa receber a mensagem |
| o erro na tarefa do banco | um código de erro para o qual a resposta do serviço é mapeada |
| o próprio modelo | uma versão, porque as instâncias já em execução ficam na versão em que começaram |

Nada disso aparece no desenho, e cada item é um lugar em que o modelo e os sistemas em volta dele
precisam concordar. A última linha é aquela em que a aula 6 se demorou: mude o modelo com duzentas
fazendas no meio dele e duas versões rodam lado a lado até as instâncias antigas terminarem ou
serem migradas.

## O arquivo

A BPMN 2.0 define um formato XML para tudo isso. Aqui está a primeira parte do cadastro, reduzida à
conferência de documentos e ao seu gateway, para leitura:

```xml
<bpmn:definitions xmlns:bpmn="http://www.omg.org/spec/BPMN/20100524/MODEL"
                  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                  id="Definitions_Onboarding"
                  targetNamespace="http://serraalta.example/bpmn/onboarding">
  <bpmn:process id="FarmOnboarding" name="Farm onboarding" isExecutable="true">
    <bpmn:startEvent id="Start_Application" name="Application received"/>
    <bpmn:sequenceFlow id="Flow_1" sourceRef="Start_Application" targetRef="Task_CheckDocuments"/>
    <bpmn:userTask id="Task_CheckDocuments" name="Check documents"/>
    <bpmn:sequenceFlow id="Flow_2" sourceRef="Task_CheckDocuments" targetRef="Gateway_Complete"/>
    <bpmn:exclusiveGateway id="Gateway_Complete" name="Documents complete?" default="Flow_Missing"/>
    <bpmn:sequenceFlow id="Flow_Complete" name="yes" sourceRef="Gateway_Complete" targetRef="End_Ready">
      <bpmn:conditionExpression xsi:type="bpmn:tFormalExpression">${documentsComplete}</bpmn:conditionExpression>
    </bpmn:sequenceFlow>
    <bpmn:sequenceFlow id="Flow_Missing" name="no" sourceRef="Gateway_Complete" targetRef="Task_AskForDocuments"/>
    <bpmn:sendTask id="Task_AskForDocuments" name="Ask for missing documents"/>
    <bpmn:sequenceFlow id="Flow_3" sourceRef="Task_AskForDocuments" targetRef="End_Returned"/>
    <bpmn:endEvent id="End_Ready" name="Documents accepted"/>
    <bpmn:endEvent id="End_Returned" name="Application returned"/>
  </bpmn:process>
</bpmn:definitions>
```

Quatro coisas nele merecem atenção. **Todo elemento tem um id, e os fluxos ligam elementos pelo id,
nunca pelo nome**: renomeie "Check documents" e nada se solta. O gateway indica seu fluxo padrão no
atributo `default`, que é o traço que você viu no diagrama. A condição é texto numa linguagem de
expressões: o padrão da especificação é XPath, e `${documentsComplete}` é o estilo JUEL que as
engines da Camunda e da Flowable leem, o que já torna esta linha menos portável que o resto. E **não
há desenho nenhum nele**. Posições e tamanhos ficam numa parte separada do mesmo arquivo, a seção de
diagram interchange sob `bpmndi:BPMNDiagram`, deixada de fora aqui; uma engine a ignora, e um
modelador precisa dela para desenhar o diagrama de novo.

O que não está nele é a metade da tabela acima que o padrão deixa em aberto. Que formulário uma
tarefa de usuário mostra, a que grupo ela é atribuída, que classe ou URL uma tarefa de serviço chama:
as engines põem isso em **atributos de extensão no próprio namespace**, com prefixo `camunda:` ou
`flowable:` ou outro. O núcleo do arquivo passa de uma ferramenta para outra; as ligações não. Um
modelo "em BPMN" é portável do jeito que um schema SQL com tipos específicos de um fornecedor é
portável: a estrutura sobrevive, e as partes que o fazem rodar precisam ser refeitas.

## A ida e volta

Aqui o problema que machucou a BPEL volta em tamanho menor. Denise desenha numa ferramenta, um
engenheiro abre o arquivo e acrescenta as ligações, Denise depois muda duas tarefas de lugar na
ferramenta dela, e as ligações ou desaparecem ou continuam apontando para a estrutura antiga. O mesmo
processo agora existe duas vezes, e as duas cópias se afastam a cada mudança.

Há dois jeitos honestos de conviver com isso:

- **Um modelo, dos engenheiros e revisado pelo negócio.** O arquivo executável é o único; fica no
  controle de versão ao lado do código que ele chama, e toda mudança nele passa por um pull request
  que Denise revisa como diagrama renderizado. O negócio nunca edita o arquivo diretamente, e o
  modelo nunca fica desatualizado, porque é ele que roda.
- **Dois modelos, e um acordo de que eles diferem.** Um modelo descritivo para pessoas, mantido
  simples e de responsabilidade do escritório de processos, e uma implementação, numa engine ou em
  código, de responsabilidade da TI. O modelo descritivo é revisado contra a implementação numa
  agenda combinada, e ninguém finge que um é gerado a partir do outro.

O que falha é o meio-termo: um arquivo que os dois grupos editam em ferramentas diferentes. A
própria especificação da BPMN 2.0 reconhece a separação nas suas classes de conformidade: uma
subclasse **descritiva**, com o punhado de formas de que as pessoas precisam para documentar um
processo, uma **analítica**, com mais, e uma **executável comum**, para modelos que uma engine roda.
Um modelo pode estar correto na primeira e ser inútil na terceira.

## Quando executar e quando documentar

Nem todo processo deve rodar numa engine. Uma engine se paga quando **o processo é longo, espera
pessoas e partes de fora, tem prazos, e você precisa ver onde está cada instância**; o cadastro
reúne as quatro coisas. Ela também se paga quando a ordem dos passos muda com mais frequência que os
próprios passos, porque então o modelo é a parte que se mexe.

Ela não se paga quando o processo é, na verdade, a lógica interna de um sistema: um laço sobre os
itens de um pedido pertence ao código, onde um teste o alcança. Nem quando o estado já mora num
sistema que o acompanha: a cadeia do pedido ao recebimento da aula 1 é um processo, e o fluxo de
documentos do SAP já registra onde está cada pedido, então uma segunda engine o acompanhando seria
um segundo registro capaz de discordar. E não se paga enquanto o processo ainda está sendo
descoberto, porque um modelo que vai mudar de forma toda semana sai mais barato no papel.

O primeiro instinto de Joana, depois de oito anos construindo tudo como serviços, foi tornar o
modelo inteiro executável, até os passos dentro da visita técnica. Denise a convenceu a deixar a
visita de fora: é um técnico numa fazenda com uma lista de verificação, e o processo só precisa
saber que um relatório voltou, o que ele dizia e quando. **Execute a coordenação, não o ofício.** A
visita continua sendo uma única tarefa de usuário com um formulário; o que o técnico faz no curral é
procedimento da equipe de qualidade, guardado no Documentum, onde a aula 5 o deixou.

Elas terminaram com uma decisão que Joana registrou num ADR. O modelo BPMN, com os temporizadores, o
erro e a compensação, passa a ser a especificação do cadastro. Ele fica no repositório de arquitetura,
Denise é dona do conteúdo, e o que quer que rode o cadastro daqui para a frente, IBM BPM, uma engine
aberta ou código, tem de responder "onde está a fazenda 4471?" nos termos desse modelo. Qual dos três
vai ser espera o mapa de integrações que Joana desenha nas aulas 9 a 11, porque o custo de cada
chamada ao banco, ao Coleta e ao SAP depende de como esses sistemas podem ser alcançados.
