---
title: Trello, YouTrack e Assembla
version: 1
---

Os outros três produtos desta aula são três respostas diferentes às mesmas cinco necessidades da
seção 01, e cada um se entende melhor pelo que deixa de fora em comparação com o Jira. Nenhum deles
foi rodado para este curso; o que segue é o tipo de ferramenta que cada um é.

## Trello: um quadro e nada mais

**O Trello é primeiro um quadro, e só vira ferramenta de acompanhamento se você o fizer virar.** É
feito pela Atlassian, como o Jira, e o modelo inteiro dele são três coisas: um **quadro**, as
**listas** nele e os **cartões** em cada lista. Um cartão tem título, descrição, comentários,
anexos, **etiquetas** coloridas, membros e uma lista de verificação, e passa de lista em lista sendo
arrastado.

Para acompanhar os defeitos do boxoffice no Trello, você faria uma lista por estado da aula 16,
*novo*, *triado*, *em andamento*, *corrigido*, *pronto para reteste*, *fechado*, um cartão por
relato e uma etiqueta por severidade. Funciona, e para um time de duas pessoas pode ser tudo o que
elas precisam.

O que ele abre mão é da cobrança. **Qualquer cartão pode ser arrastado para qualquer lista por
qualquer pessoa**, então nada impede um cartão de ir de *novo* direto para *fechado*, e a regra de
que só quem testa fecha um defeito mora nos hábitos do time. Campos além dos básicos são possíveis,
mas soltos, e as contagens da aula 16, idade por severidade ou taxa de reabertura, são mais difíceis
de tirar de um quadro do que de uma ferramenta construída em torno de buscas. O Trello serve a um time
pequeno, um produto e um ciclo de vida com que todos já concordam.

## YouTrack: uma ferramenta com as mesmas ambições do Jira

**O YouTrack é uma ferramenta de acompanhamento completa, feita pela JetBrains**, a empresa por trás
de várias ferramentas de programação muito usadas. Tem as mesmas partes do Jira: projetos, itens com
identificador, campos tipados que o time pode ampliar, fluxos de trabalho configuráveis, quadros e
buscas salvas digitadas como consultas. Um time que já escreve código nas ferramentas da JetBrains
ganha uma ferramenta de acompanhamento da mesma empresa, e esse é um motivo comum para escolhê-lo.

Para quem testa, passar do Jira para o YouTrack é quase só uma questão de nomes novos para as mesmas
coisas. O relato da aula 15 cabe em qualquer um dos dois campo por campo, e um time que use
qualquer um deles consegue cobrar o ciclo de vida da aula 16 na ferramenta, e não no hábito.

## Assembla: itens ao lado do código

**O Assembla é um serviço hospedado de código-fonte com itens (*tickets*) ao lado.** A ênfase dele
são os repositórios, e ele é conhecido por hospedar Subversion e Perforce além de Git, o que importa
para times como estúdios de jogos, cujos projetos guardam arquivos grandes que o Git lida mal. Os
itens, com seus campos e uma visão de quadro, ficam ao lado desse código e se ligam às mudanças que
os corrigem.

Quem testa encontra o Assembla onde uma empresa o escolheu pelos repositórios e levou junto os itens
que vieram com eles. O lado dos itens é uma ferramenta de acompanhamento no sentido da seção 01, e o
mesmo relato entra nele do mesmo jeito.

## O padrão

Lado a lado, os quatro mostram uma coisa:

| | o que é primeiro | o fluxo de trabalho | onde quem testa o encontra |
|---|---|---|---|
| **Jira** | ferramenta de acompanhamento, e plataforma de complementos | configurado por projeto, e pode recusar um movimento | empresas de software de todo tamanho |
| **Trello** | um quadro de cartões | nenhum próprio: qualquer cartão para qualquer lista | um time pequeno com um produto |
| **YouTrack** | ferramenta de acompanhamento | configurado por projeto, e pode recusar um movimento | um time que escolheu uma alternativa ao Jira |
| **Assembla** | hospedagem de código, com itens ao lado | estados dos itens definidos por projeto | um time que o escolheu pelos repositórios |

As listas de funcionalidades fazem os quatro parecerem iguais. **O que os separa é o que cada um
recusa.** Uma ferramenta que recusa um movimento proibido pelo ciclo de vida do time transforma uma
regra numa garantia; um quadro que aceita tudo deixa a regra como hábito, que dura até a semana em
que o time está ocupado.
