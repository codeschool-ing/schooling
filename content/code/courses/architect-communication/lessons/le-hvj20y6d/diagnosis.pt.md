---
title: Apresentar um diagnóstico que é do cliente
version: 1
---

**Um diagnóstico é entregue para que as pessoas donas do problema decidam o que fazer com ele; a
consultora recomenda, e o dono escolhe.** Lívia pode ter razão sobre os releases do time de
logística e ainda assim fracassar, se o jeito como apresenta o diagnóstico deixar Henrique
defendendo o time em vez de decidir.

## A nota escrita

A nota de Lívia em 29 de maio seguiu o formato de proposta da aula 2, em uma página:

> **O que perguntamos.** Por que os releases da logística quebram o planejamento de rotas, e o que
> impediria isso?
>
> **O que encontramos.** 7 dos 23 releases deste ano foram seguidos de um incidente no planejamento
> de rotas. Em 5 dos 7, um serviço mudou uma tabela que o planejador de rotas e o serviço de zonas
> leem, e o outro serviço quebrou. A tabela não tem dono nomeado, e os dois serviços só são testados
> juntos pela primeira vez em staging, depois do merge. Nenhum dos 7 incidentes envolveu um timeout
> entre os serviços.
>
> **O que isso significa.** Um message broker não teria evitado nenhum dos 7. Um dono claro para os
> dados compartilhados, e testar os dois serviços juntos antes do merge, teriam evitado pelo menos 5.
>
> **Opções**, para o time escolher:
> 1. Nomear um dono para a tabela compartilhada e exigir a revisão dele em qualquer mudança nela.
>    Dias, não semanas. Evita a maioria das quebras de esquema; não elimina o acoplamento.
> 2. A opção 1, mais um teste de contrato rodando em todo pull request, que confere os dois
>    serviços contra o formato atual da tabela. Cerca de duas semanas. Encontra a quebra antes do
>    merge.
> 3. Dar a cada serviço os seus próprios dados, mantidos em sincronia por eventos, que é a ideia do
>    broker feita pelo motivo certo. Cerca de um trimestre. Elimina o acoplamento; é a que custa mais
>    e precisa do tempo do time do serviço de zonas.
>
> **Minha recomendação** é a opção 2 agora, e a opção 3 avaliada no próximo trimestre se o
> acoplamento continuar custando tempo. A decisão é do time.

## Por que ela é escrita assim

- **Fatos primeiro, interpretação depois, recomendação por último**, e com rótulos. Quem discorda
  da recomendação ainda pode aceitar as constatações, e isso mantém a conversa andando.
- **Nenhum nome ligado a incidentes.** A nota não diz de quem foi a mudança que quebrou o quê. O
  contrato dizia que aquilo não era uma avaliação, e o padrão estava no sistema, não numa pessoa: a
  lei de Weinberg, mas sobre como as pessoas trabalham juntas e não sobre quem falhou.
- **A solução pedida é tratada com justiça.** A opção 3 é o broker, pelo motivo pelo qual ele de fato
  ajudaria. O instinto de Henrique não estava errado; estava apontado para um sintoma. **Dizer onde
  a ideia do cliente se encaixa é o que permite a ele aceitar um diagnóstico que começou em outro
  lugar.**
- **"A decisão é do time"** não é modéstia. É a segunda linha do contrato, e o time que escolhe a
  opção 2 é o time que vai fazê-la funcionar.

## Quando o cliente discorda

A primeira reação de Henrique, na conversa do meio do caminho, foi "mas o time do serviço de zonas
nunca vai aceitar um dono". Aquilo não era uma rejeição do diagnóstico; era o problema de pessoas
se apresentando. Lívia não discutiu. Perguntou o que faria o time do serviço de zonas concordar, e
Henrique disse "se a pergunta não viesse da gente". Então Lívia mandou o pedido de um dono para os
líderes dos dois times ao mesmo tempo, com a contagem de incidentes anexada. A aula 9 trata
do tipo de conversa que vem depois, quando dois times discordam sobre quem é dono de alguma coisa.

**Uma consultora que ganha a discussão com o cliente quase sempre perdeu o trabalho.** Se o dono,
depois de ouvir o diagnóstico, escolher outra coisa, a consultora registra o que foi recomendado e
por quê, e ajuda com o que foi escolhido. A nota escrita é o registro; a relação é o que traz o
próximo chamado.
