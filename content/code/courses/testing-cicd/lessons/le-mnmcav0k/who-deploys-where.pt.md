---
title: Quem pode implantar onde
version: 1
---

Ambientes diferem no que está em jogo, então diferem em quem pode mudá-los. Uma regra prática que vale
na maioria das equipes: **quanto mais perto dos clientes, menos mãos, e mais delas são máquinas.**

| ambiente | quem implanta | como |
|---|---|---|
| desenvolvimento | qualquer pessoa que desenvolve | à mão ou pelo pipeline |
| prévia | o pipeline, para cada pull request | automaticamente |
| homologação | o pipeline, depois das verificações | automaticamente, a partir da `main` |
| produção | o pipeline, depois da barreira | com aprovação, ou por regra |

Duas propriedades fazem essa tabela valer em vez de só descrever intenções.

**As credenciais do pipeline são por ambiente.** O job que implanta na homologação não alcança a
produção, porque nunca recebe as credenciais da produção. No GitHub Actions é para isso que servem os
*environments* com segredos e regras de proteção próprios, como a aula 7 seção 08 mostrou; no GitLab,
ambientes protegidos fazem o mesmo. Quem quiser implantar na produção à mão descobre que não há chave
para isso.

**Todo deploy deixa um registro.** Qual artefato, qual hash, qual ambiente, quem ou o que disparou, e
quando. O histórico do próprio pipeline é um registro; um script de deploy pode acrescentar uma linha
a um log também. Quando a produção se comporta mal às 15:10, o primeiro fato útil é o deploy das
15:02, e um ambiente cujas mudanças não têm registro obriga todo mundo a adivinhar.

## A exceção de emergência

Toda equipe acaba precisando mudar a produção mais rápido do que o pipeline permite. A resposta que
mantém as regras intactas é um **procedimento de quebra de vidro** (*break-glass*): uma entrada
separada e auditada, usada raramente, que avisa pessoas quando é usada, seguida da mesma mudança pelo
pipeline para o ambiente voltar a bater com a definição. A resposta que as quebra é uma pessoa com
acesso permanente que edita um arquivo no servidor, que é o desvio da seção 07 com um bom motivo por
trás.

A aula 9 leva a sério as credenciais dessa tabela: onde ficam guardadas, como um job as recebe, e quão
pouco cada uma deveria poder fazer.
