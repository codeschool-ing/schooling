---
title: O que não vamos fazer
version: 1
---

Uma política orientadora exclui coisas em princípio. **A lista do que não vamos fazer dá nome a
elas**, para que ninguém precise deduzir da política o que ela exclui. É a seção mais curta da página
e a que mais custa escrever, porque é onde a escolha deixa de ser abstrata e cai sobre o projeto de
alguém.

## O argumento para deixá-la implícita

O instinto comum é deixar a lista de fora. A política diz "proteger a abertura de vendas primeiro";
certamente todo mundo vê que uma migração para microsserviços não se encaixa, e escrever isso só
esfrega na cara de quem era dono do projeto. Uma página que diz o que a empresa vai fazer, e se cala
sobre o resto, soa positiva e não começa discussão nenhuma.

**Ela as começa depois, um time de cada vez, sem ninguém ver.** A aula 2 mostrou o que aconteceu na
Coreto no trimestre seguinte à publicação da estratégia: um gateway GraphQL para o app mobile, e a
busca do Catálogo indo para um serviço próprio. Cada um era um projeto sensato. Cada um era a
migração para microsserviços entrando pela porta lateral, e cada um sobreviveu no roadmap porque
ninguém tinha escrito que a migração estava fora do ano, nem mesmo um serviço de cada vez. Quando
essa linha entrou na página, os dois projetos ficaram reconhecíveis à primeira vista. Antes dela,
uma pessoa razoável podia ler a política e concluir que um servicinho não fazia mal.

Uma exclusão implícita é decidida por cada time separadamente, e eles decidem de jeitos diferentes.

## O que faz uma boa linha na lista

Uma linha pertence à lista do que não vamos fazer quando passa em três testes.

**Alguém razoável a quer.** "Não vamos negligenciar a segurança" não exclui nada que alguém tenha
proposto; é enchimento com uma negação na frente. Uma linha se justifica por decepcionar uma pessoa
real com uma proposta real. Cada linha da lista do Davi custou algo a alguém. A migração para
microsserviços era o projeto do ano do time de Plataforma da Rafaela. O piloto do framework de
front-end era aquele para o qual o Catálogo tinha se oferecido. Reescrever o módulo de reservas era
o que Mateus, líder técnico do Checkout, defendia desde a última abertura que falhou.

**Ela dá nome à coisa.** "Vamos despriorizar parte do trabalho de modernização" deixa cada time livre
para decidir que a sua modernização não é a do tipo mencionado. "Mudar para um novo framework de
front-end" não deixa.

**Ela diz por quanto tempo, ou até quando.** "Não este ano" e "a menos que a mudança tenha passado no
teste de carga" dizem a um time quando trazer a proposta de volta e o que mudaria a resposta. Um
"não" seco soa permanente, e é contestado como se fosse.

| linha fraca | o que está errado | uma linha da página do Davi |
|---|---|---|
| Não vamos negligenciar a confiabilidade. | ninguém propôs negligenciá-la | Reescrever o módulo de reservas do zero. |
| Vamos limitar mudanças de arquitetura. | não nomeia nada; cada time se considera exceção | Começar a migração para microsserviços, nem mesmo um serviço de cada vez. |
| Nenhuma mudança em reservas. | sem escopo e sem fim; bloqueia o trabalho de que a estratégia precisa | Mudar o caminho de reservas na temporada de aberturas por custo ou por funcionalidade, a menos que a mudança tenha passado no teste de carga. |

A última linha é a sutil. Uma linha que proíbe demais proíbe as ações da própria estratégia: o time
de Reservas precisa mudar o caminho de reservas, esse é todo o seu trabalho. A linha da página exclui
mudanças feitas por outros motivos, na temporada em que são perigosas, sem a evidência que a
política pede.

## Contar às pessoas antes da página

**Ninguém cujo projeto está na lista deveria ficar sabendo pela página.** Davi conversou com a
Rafaela e com o Mateus antes de a estratégia sair, cada um separadamente, e contou o que a página ia
dizer e por quê. Rafaela defendeu manter uma extração de serviço; Mateus defendeu que uma reescrita
seria mais rápida que tirar as travas uma a uma. Nenhum dos argumentos mudou a página. As duas
conversas mudaram como a página foi recebida, porque nenhum dos dois foi surpreendido na frente do
próprio time.

As habilidades para essas conversas pertencem a outros cursos desta trilha: a aula 8 de
`architect-communication` é dizer não com uma alternativa, e a aula 24 de `people-leadership` é
gerenciar para cima e para os lados. A aula 19 deste curso volta a dizer não quando o pedido chega
de fora da engenharia. O que é particular da página de estratégia é a ordem: a conversa primeiro, a
publicação depois.

## O que a lista faz ao longo do ano

A lista continua trabalhando depois que a página é publicada, de três jeitos.

Ela **encerra discussões antes que comecem**. Quando chega em maio uma proposta de serviço novo, a
resposta está na página, é a mesma resposta para todos os times, e ninguém precisa marcar reunião
para dá-la.

Ela **torna o roadmap conferível**. O rastreamento da aula 2 achou seus órfãos porque havia uma
linha com a qual compará-los. Sem a lista, o gateway teria exigido uma discussão; com ela, exigiu um
olhar.

Ela **marca o que vai voltar**. "Não este ano" é uma promessa de que a pergunta será feita de novo,
e a revisão de fim de ano deveria fazê-la. Se as reservas de assento estiverem resolvidas até lá, a
questão dos microsserviços reabre com um novo diagnóstico por trás, e a proposta da Rafaela é a
primeira da mesa.

Uma lista do que não fazer da qual ninguém nunca reclama provavelmente foi escrita para evitar
reclamação, que é a mesma falha da primeira versão da aula 1. A versão útil desagrada algumas
pessoas no dia em que é publicada, e poupa a empresa dessa discussão muitas vezes ao longo do ano.
