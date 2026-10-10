---
title: O Jira, e os produtos da Atlassian em volta dele
version: 1
---

**O Jira é a ferramenta de acompanhamento que quem testa tem mais chance de encontrar numa empresa
de software**, e uma que os anúncios de vaga para testador citam com frequência. É feito pela
Atlassian, uma empresa australiana, e vendido tanto como serviço hospedado quanto como software que
a empresa roda nos próprios servidores. Ele não foi rodado para este curso, e esta seção descreve
que tipo de ferramenta ele é, e não onde ficam os botões.

## Como o Jira guarda um defeito

O trabalho no Jira vive em **projetos**, e todo item ganha uma chave feita do nome curto do projeto
e de um número: se o projeto do teatro se chamasse BOX, o relato do traceback da aula 15 poderia ser
`BOX-42`. Essa chave é o que todo mundo digita, numa mensagem de commit, num chat, num caso de
teste, e o Jira a transforma em link.

Cada item tem um **tipo**, e um projeto de software costuma ter pelo menos *bug*, *story*, *task* e
*epic*. Um defeito é um bug. Os campos dele incluem um **resumo** (*summary*), uma **descrição**,
**prioridade**, **ambiente** (*environment*), **anexos**, **rótulos** (*labels*), os
**componentes** do produto que ele toca, e as versões que ele **afeta** e em que é **corrigido**. Um
administrador pode criar **campos personalizados**, e **a severidade é o mais comum deles**: o campo
de prioridade do próprio Jira vem desde o início, e um campo de severidade é algo que cada time cria
e define. Um time que não o cria acaba escrevendo a severidade na prioridade, que é justamente a
confusão que a aula 15 gastou uma seção desfazendo.

Os **fluxos de trabalho** (*workflows*) são configurados por projeto, por um administrador: os
estados, as transições entre eles, quem pode fazer cada uma e o que precisa ser preenchido no
caminho. É ali que um time escreve as regras da aula 16 na ferramenta. Por exemplo, *só quem relatou
ou quem testa pode mover um item de pronto para reteste para fechado*, ou *um item rejeitado precisa
levar uma resolução dizendo por quê*. Um time que nunca mexe no fluxo está usando o ciclo de vida de
outra pessoa.

A busca do Jira tem uma linguagem de consulta própria, a JQL, que se lê como uma frase de condições.
Uma busca pelos defeitos abertos do boxoffice, os mais urgentes primeiro, fica assim:
`project = BOX AND issuetype = Bug AND status != Closed ORDER BY priority DESC`. A consulta não foi
rodada aqui, e os nomes de campos e estados num projeto real são os que o administrador escolheu. Uma
consulta salva vira um **filtro**, e os filtros alimentam os **quadros** e os **painéis**
(*dashboards*) onde os números da aula 16 são desenhados.

## O resto da Atlassian, onde quem testa o encontra

A Atlassian vende vários produtos que muitas vezes são comprados juntos, e três deles chegam ao dia a
dia de quem testa.

**Confluence** é a wiki da empresa: páginas editadas no navegador, ligadas entre si e aos itens do
Jira. Planos de teste como o da aula 1, requisitos como o R1 a R9 do boxoffice e as anotações de uma
sessão exploratória muitas vezes moram ali, com um link de cada defeito de volta para o requisito
que ele quebra.

**Bitbucket** hospeda código. Quando a mensagem de commit de um desenvolvedor traz a chave de um
item, o item mostra o commit, o que deixa quem retesta o `BOX-42` ver exatamente o que mudou.

**Jira Service Management** cuida de pedidos de pessoas de fora do time, como clientes ou
funcionários escrevendo para uma central de atendimento. Um pedido que se revela um defeito é ligado
a um bug no projeto de software, ou transformado nele. Para quem testa, essa é a porta de entrada dos
*defeitos que escaparam* que a aula 16 contou.

**Trello**, uma ferramenta de quadros bem mais simples, também pertence à Atlassian, e a seção 03
desta aula trata dele nos termos dele.

O Jira também é uma plataforma: outras empresas vendem complementos que rodam dentro dele, e várias
ferramentas de casos de teste funcionam assim. A aula 18 cita uma delas, o Zephyr.
