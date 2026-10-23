---
title: Cliques antes de código
version: 1
---

O Salesforce pode ser alterado de dois jeitos. As mudanças **declarativas** são feitas nas telas de
configuração, apontando e preenchendo formulários: um campo, uma regra, um layout de página, um
processo automatizado. As mudanças **programáticas** são código: Apex no servidor, Lightning Web
Components no navegador. O conselho da própria plataforma, repetido na documentação e nos
treinamentos há anos, é recorrer à primeira antes da segunda. Os administradores resumem como
*cliques antes de código*.

A conclusão errada é achar que cliques são de graça e código é caro. **Os dois são customização, os
dois ficam para sempre, e os dois viram dívida no dia em que ninguém lembra por que existem.** Cliques
são mais baratos de fazer e mais baratos de mudar. Não são mais baratos de entender três anos
depois, e a org da Serra Alta é a prova.

## O que dá para fazer sem código

| declarativo | o que faz | um exemplo na Serra Alta |
|---|---|---|
| um campo customizado | acrescenta uma coluna a um objeto | `SAP_Customer_Number__c` na Account |
| uma regra de validação | recusa um salvamento quando uma fórmula é verdadeira, com uma mensagem | uma Opportunity não chega a *Closed Won* sem uma região de entrega |
| um layout de página | decide que campos um usuário vê, em que ordem, e quais são somente leitura | o limite de crédito, que os representantes veem e não editam |
| Flow | executa lógica quando um registro muda, num horário, ou como uma tela que o usuário percorre | quando um Case é marcado como *recall*, atribuí-lo à fila da qualidade e avisar o time de Cláudia Mendes |

**O Flow agora é a ferramenta de automação declarativa, e as duas mais antigas estão de saída.** O
Salesforce oferecia três: Workflow Rules, Process Builder e Flow. Ele aposentou as duas primeiras em
favor do Flow. Não dá mais para criar novas, o suporte às existentes acabou, e o Salesforce oferece
uma ferramenta, *Migrate to Flow*, que converte boa parte delas. A Serra Alta ainda roda 41 workflow
rules e 23 processos do Process Builder, quase todos escritos pela consultoria que montou a org em
2018, e levá-los para o Flow é o principal projeto de Talita no ano. Cada conversão é pequena. A parte
difícil é descobrir para que cada um servia, e esse é o tema desta seção.

O código é a outra metade:

| programático | o que é | quando é a ferramenta certa |
|---|---|---|
| Apex | uma linguagem fortemente tipada que roda na plataforma, sob os governor limits da seção 02 | lógica complexa demais para o Flow, ou volumes em que os limites do Flow apertam primeiro |
| um trigger Apex | Apex que roda antes ou depois de os registros de um objeto serem salvos | manter vários registros consistentes dentro de uma transação |
| Lightning Web Components | componentes JavaScript para a interface | uma tela que as páginas padrão não conseguem desenhar |

O Apex vem com uma regra própria. **O Salesforce não implanta Apex na produção a menos que os testes
cubram pelo menos 75% do código Apex da org** e todos passem. Numa empresa em que ninguém escreve
testes, essa regra é o único motivo de existir algum. A Serra Alta tem 14 triggers e cerca de 60
classes Apex, quase todas do parceiro de 2018, e os testes delas foram escritos para atingir o
percentual, não para verificar coisa alguma.

## Dívida de customização

No ano passado Talita rodou um relatório que hoje mostra a todo gerente novo. **O objeto padrão
Account da Serra Alta carrega 412 campos customizados, e 137 deles, um terço, não têm valor em nenhum
registro alterado no último ano.** Alguns foram criados para uma campanha de 2019 que acabou. Outros
são quase duplicatas: `Segment__c`, `Segment_New__c` e `Segmento_2020__c` convivem lado a lado,
porque toda vez que alguém precisou mudar a segmentação era mais rápido criar um campo do que migrar
o antigo.

Campos sem uso parecem inofensivos, e apagá-los parece faxina. Nenhuma das duas coisas é verdade:

- Todo campo está na tela de alguém. Um representante que rola por 400 campos para achar o telefone
  do comprador paga por cada um deles, a cada visita.
- A plataforma tem um teto. Cada objeto aceita um número limitado de campos customizados, fixado pela
  edição, e a Serra Alta já gastou a maior parte do da Account.
- "Onde isto é usado" só enxerga a plataforma. O Salesforce consegue dizer a Talita que um campo
  aparece num layout, num relatório ou numa classe Apex. Não consegue dizer que um fluxo de mensagens
  do IIB no time de Rui o lê toda noite e o grava no SAP, porque esse fluxo mora fora da org.

O terceiro ponto é o que cabe ao arquiteto. Um campo que o Salesforce aponta como sem uso pode ser a
única coisa de que uma integração depende, e apagá-lo quebra um fluxo em outro sistema, às 02:00, num
time que não foi avisado. **Antes de a Serra Alta apagar um campo, Talita pede ao time de Rui que
procure o nome de API dele nos mapeamentos dos fluxos**, e a resposta já impediu duas exclusões.

## Sandboxes: onde uma mudança é feita antes de ser real

Ninguém na Serra Alta altera a produção diretamente. Uma mudança é feita num **sandbox**, uma cópia da
org na mesma plataforma, testada ali e depois implantada. O Salesforce oferece quatro tipos, e eles
diferem em quanto da produção carregam:

| sandbox | o que copia | para que a Serra Alta o usa |
|---|---|---|
| Developer | só a configuração, sem registros | Talita e o parceiro constroem mudanças, um cada |
| Developer Pro | a configuração, com mais espaço para registros de teste | não usa |
| Partial Copy | a configuração e uma amostra dos registros, escolhida por um template | testes de aceitação com três gerentes de vendas |
| Full | a configuração e todos os registros | testes de integração contra o sistema de qualidade do SAP, e o preview dos releases |

**O sandbox Full é o único lugar em que uma integração pode ser testada com o volume da produção**, e
volume é o que quebra integrações, como mostra a seção 04. Ele também é uma cópia completa dos dados
de clientes, então quem pode entrar nele é quem pode entrar na produção. Um sandbox Full pode ser
atualizado a partir da produção muito menos vezes do que um Developer, então ele se distancia dela, e
a Serra Alta agenda as atualizações em torno dos previews de release.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-sandboxes\" aria-label=\"Uma mudança indo da esquerda para a direita por quatro orgs. Um sandbox Developer tem a configuração e nenhum registro; Talita constrói a mudança ali. Um Partial Copy tem a configuração e uma amostra dos registros; três gerentes de vendas a testam. Um Full tem a configuração e todos os registros; a integração com o SAP é testada ali com o volume da produção. A produção é onde trabalham os 140 representantes. Acima deles, um repositório git guarda os metadados como arquivos: a mudança é recuperada do sandbox Developer para ele e implantada a partir dele em cada um dos outros três. Uma nota embaixo diz que cada passo para a direita carrega mais dados da produção, e é protegido mais como ela.\"><defs><marker id=\"l04-sandboxes-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-sandboxes-es-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"150.0\" y=\"20.0\" width=\"420.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"360.0\" y=\"40.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">repositório git: os metadados da org como arquivos</text><rect x=\"15.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"95.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Developer</text><text x=\"95.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">só a configuração</text><text x=\"95.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">Talita constrói</text><path d=\"M177.0 190.0 L186.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"190.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"270.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Partial Copy</text><text x=\"270.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">configuração + amostra</text><text x=\"270.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">gerentes de vendas testam</text><path d=\"M352.0 190.0 L361.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"365.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">Full</text><text x=\"445.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">configuração + tudo</text><text x=\"445.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">integração SAP com volume</text><path d=\"M527.0 190.0 L536.0 190.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><rect x=\"540.0\" y=\"144.0\" width=\"160.0\" height=\"92.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"620.0\" y=\"162.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">produção</text><text x=\"620.0\" y=\"190.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">os registros reais</text><text x=\"620.0\" y=\"214.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--paper-dim)\">140 representantes</text><path d=\"M95.0 142.0 L180.0 62.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-sandboxes-es-ah-phosphor)\"></path><text x=\"126.0\" y=\"96.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">recuperar</text><path d=\"M270.0 62.0 L270.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><path d=\"M445.0 62.0 L445.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><path d=\"M620.0 62.0 L620.0 142.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"5 3\" marker-end=\"url(#l04-sandboxes-es-ah-paper-dim)\"></path><text x=\"452.0\" y=\"102.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">implantar</text><text x=\"360.0\" y=\"268.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-style=\"italic\" fill=\"var(--amber)\">cada passo para a direita carrega mais dados da produção, e é protegido mais como ela</text></svg>", "caption": "O caminho de uma mudança na Serra Alta. Só o sandbox Full tem o volume da produção, e é por isso que a integração é testada ali e em nenhum outro lugar.", "same": ["Developer", "Full", "Partial Copy"]}
```

## Uma mudança é um arquivo

Como tudo o que Talita configura é metadado, toda mudança pode ser lida de uma org como arquivo e
gravada em outra. É isso que torna os sandboxes úteis e não decorativos. O campo que a Serra Alta usa
para guardar o número de cliente do SAP, recuperado com o Salesforce CLI, é este arquivo,
`force-app/main/default/objects/Account/fields/SAP_Customer_Number__c.field-meta.xml`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<CustomField xmlns="http://soap.sforce.com/2006/04/metadata">
    <fullName>SAP_Customer_Number__c</fullName>
    <caseSensitive>false</caseSensitive>
    <externalId>true</externalId>
    <label>SAP customer number</label>
    <length>10</length>
    <required>false</required>
    <type>Text</type>
    <unique>true</unique>
</CustomField>
```

Três dessas linhas importam mais adiante nesta aula. `length` é 10 porque um número de cliente do SAP
tem dez caracteres. `externalId` marca o campo como uma chave que sistemas de fora usam para achar um
registro. `unique` faz a plataforma recusar uma segunda Account com o mesmo número. A seção 05 trata
de por que cada uma dessas três é uma decisão sobre quem é dono do cliente.

Há dois jeitos de levar mudanças de uma org para outra. Os **change sets** são montados nas telas de
configuração de uma org e implantados em outra: sem arquivos, sem histórico, e uma lista que alguém
marca à mão. A **Metadata API**, normalmente acionada pelo Salesforce CLI, recupera e implanta os
próprios arquivos, o que quer dizer que eles podem morar num repositório git, ser revisados num pull
request e ser implantados por um pipeline. A Serra Alta usou change sets até 2025. Talita passou para
o CLI e um repositório depois que um change set levou uma regra de validação nova para a produção e
deixou de fora o layout de página que mostrava o campo dela. Durante quarenta minutos, todo
representante foi mandado preencher um campo que não enxergava, e nenhuma oportunidade pôde ser salva.

## Como Joana lê isso

A pergunta de arquitetura numa org de Salesforce raramente é "isto deve ser clique ou código". É
**quais customizações alguém escolheria de novo**, e quem perceberia se uma delas sumisse. Uma org de
sete anos é um sistema com sete anos de decisões dentro, e a maioria foi tomada sem registro. Joana
pede a Talita o que agora pede a todo sistema do parque: a lista de customizações, cada uma com um
dono e um motivo, e as que não têm nenhum dos dois marcadas para remoção. Nos termos da aula 1, cada
um dos 137 campos é configuração, o anel mais barato que existe, e ainda assim um custo que ninguém
escolheu continuar pagando.
