---
title: TestLink, o de código aberto, e Zephyr, o que mora dentro do Jira
version: 1
---

As duas ferramentas desta seção atendem a mesma necessidade das duas anteriores, vindo de lados
opostos. **O TestLink é de código aberto e mora num servidor que você mesmo roda. O Zephyr é vendido
como extensão do Jira e mora dentro do rastreador que o seu time já usa.** Nenhum dos dois foi
rodado para este curso; o que vem a seguir é que tipo de ferramenta cada um é e o que isso
significa para quem usa.

## TestLink

O TestLink é uma aplicação web publicada como código aberto, escrita em PHP e guardada num banco de
dados, e qualquer pessoa pode baixá-la e instalá-la no próprio servidor. Seu modelo é o que esta
aula vem descrevendo, com nomes próprios. Um **test project** contém a **test specification**, que é
o repositório de suítes e casos, e pode conter os **requisitos** que os casos citam. Um **test
plan** escolhe casos para uma versão e é executado contra um **build**, então o resultado de um caso
sempre diz de que build ele veio.

O que ele custa não é licença. **Alguém precisa instalá-lo, mantê-lo atualizado, fazer backup do
banco e atender quando ele cai**, e numa empresa pequena esse alguém muitas vezes é o testador. A
interface tem um estilo mais antigo que a das ferramentas comerciais, e integrações que os times dão
como certas em outros lugares podem precisar de configuração manual. Em troca, os dados nunca saem
das máquinas da própria empresa, o que algumas organizações exigem, e nada impede um time de
experimentá-lo por um mês para descobrir o que de fato quer de uma ferramenta de casos.

## Zephyr

O Zephyr é uma família de produtos de gestão de testes vendida pela SmartBear, e os que a maioria
dos testadores encontra são apps instalados no Jira. Em vez de uma segunda aplicação web ao lado do
rastreador, os casos, os **ciclos de teste** que os agrupam para uma versão e as **execuções** que
registram cada resultado ficam todos no mesmo projeto do Jira que as histórias e os defeitos. Em
algumas edições um teste é ele próprio uma issue do Jira, de um tipo só dele, e pode ser buscado,
vinculado e posto num quadro como qualquer outra issue.

A atração é haver um lugar só. **Uma execução que falhou e o bug que ela gerou ficam vinculados
dentro de uma ferramenta**, e a história cujos critérios de aceitação o caso confere está a um
clique, então a rastreabilidade da seção 01 sai de vínculos que o time já faz. Um time que vive no
Jira não precisa convencer ninguém a abrir uma segunda ferramenta.

O custo é o outro lado do mesmo fato. O modelo de casos assume a forma do rastreador, e um
repositório de dois mil casos dentro de um projeto que também guarda o trabalho do time é muita
issue para todo mundo filtrar. O Zephyr também vai para onde o Jira da empresa for; se o Jira for
substituído, os casos mudam de lugar com uma migração em vez de ficarem onde estão.

## O mesmo modelo, quatro nomes

Tudo nesta aula até aqui cabe numa tabela. As palavras mudam; a forma não.

| ferramenta | tipo | onde mora | o repositório | uma execução se chama |
|---|---|---|---|---|
| TestRail | comercial | aplicação web própria, hospedada ou nos seus servidores | suítes e seções | test run, agrupado num test plan |
| qTest | comercial | aplicação web própria | desenho de teste, em módulos | test run, dentro de um ciclo de teste |
| TestLink | código aberto | um servidor que você roda | a test specification | um test plan, executado contra um build |
| Zephyr | comercial, um app do Jira | dentro do Jira | testes num projeto do Jira | um ciclo de teste e suas execuções |

**A escolha entre eles começa por onde o time já trabalha**, e não por uma lista de
funcionalidades. Um time cujo dia se passa no Jira é puxado para o Zephyr. Um grupo de teste que
atende vários produtos e vários rastreadores é puxado para uma ferramenta independente como o
TestRail ou o qTest. Um time sem orçamento e com alguém disposto a cuidar de um servidor pode rodar
o TestLink. E um time de uma testadora e dezessete casos pode não precisar de nenhum ainda, que é
onde a seção 04 desta aula começa.
