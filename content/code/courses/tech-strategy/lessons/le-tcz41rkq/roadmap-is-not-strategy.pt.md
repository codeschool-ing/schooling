---
title: Um roadmap não é uma estratégia
version: 1
---

O que mais se apresenta como estratégia técnica é um roadmap: uma fileira de trimestres com
projetos dentro, talvez com uma frase de visão no slide anterior. Parece um plano, tem datas e dá
para executar. **O que ele não consegue é dizer por quê.** Um roadmap responde "o quê, e quando".
Uma estratégia responde "por que isto, e não aquilo". As duas perguntas precisam uma da outra, e
nenhum dos dois documentos responde a pergunta do outro.

## O roadmap da Coreto antes da estratégia

Antes da versão do Davi, o roadmap de engenharia da Coreto para o ano era este:

| trimestre | projeto |
|---|---|
| T1 | extrair a autenticação do monólito para um serviço |
| T2 | piloto do novo framework de front-end no Catálogo |
| T3 | redução do custo de nuvem |
| T4 | levar a busca do Catálogo para um serviço próprio |

Cada item era trabalho de verdade, com gente e estimativa. Agora faça a ele as perguntas que a aula
1 fez à primeira versão. **Por que a autenticação primeiro?** Porque o time de Plataforma queria
fazer isso fazia tempo. Por que o Catálogo para o piloto do framework? Porque o Catálogo se
ofereceu. O que o roadmap diz sobre as aberturas de vendas que falham no checkout? Nada: o único
problema que custava casas de show à Coreto não aparece no plano do ano, e ninguém conseguiria
apontar isso lendo o roadmap, porque um roadmap não declara um problema contra o qual conferir.

**Um roadmap sem estratégia por trás pode ser executado com perfeição
e ainda assim ser o ano errado.** Cada trimestre entrega o que prometeu, o slide fica verde, e o
desafio que importava continua exatamente onde estava.

## O que um roadmap faz bem

Nada disso faz do roadmap um documento ruim. Ele faz três coisas que uma estratégia não faz.

Ele **põe em sequência**. A estratégia diz que o teste de carga vem antes do trabalho nas travas de
linha; o roadmap põe cada um num trimestre e mostra a dependência.

Ele **alinha a engenharia com todo o resto**. Vendas promete a um festival que a abertura vai
aguentar; produto planeja uma funcionalidade em torno dela; finanças planeja contratações em torno
do time de Reservas. Todos planejam contra o roadmap, porque ele tem datas e a estratégia não tem.

Ele **absorve mudança a baixo custo**. Quando o teste de carga leva um mês a mais que o previsto, o
roadmap se move e a estratégia não. É o sentido certo. Uma estratégia reescrita toda vez que uma
data escorrega nunca foi estratégia; era o roadmap de novo.

A aula 11 do curso `delivery-metrics` trata de pôr datas honestas num roadmap, com intervalos de
confiança em vez de dias exatos. Este curso trata do documento acima dele.

## O mesmo trabalho, derivado da estratégia

Depois da estratégia, o roadmap da Coreto mudou no que continha e no modo como cada linha podia ser
defendida:

| trimestre | projeto | por quê, segundo a estratégia |
|---|---|---|
| T1 | time de Reservas formado; Plataforma constrói o teste de carga da abertura | ações 1 e 2 |
| T2 | tirar as travas de linha do caminho da reserva de assentos, medido pelo teste de carga | ação 3 |
| T3 | terminar as travas de linha; congelamento de deploy antes das grandes aberturas automatizado | ações 3 e 4 |
| T4 | trabalho de custo de nuvem, fora do caminho de reservas | permitido pela política, fora da temporada de aberturas |

A autenticação saiu do roadmap, e o piloto do framework também. **O time de Plataforma perdeu seu
projeto, e agora o roadmap sabe dizer por quê**: a política põe o trabalho no caminho da abertura à
frente de outros investimentos técnicos, e o tempo do time de Plataforma foi para o teste de carga.
Essa resposta só existe porque há uma estratégia acima do roadmap. Sem ela, a única razão
disponível é quem pediu primeiro ou quem pediu mais alto.

## Três jeitos de distinguir os dois

Quando alguém lhe entrega um documento chamado estratégia, três verificações rápidas dizem qual dos
dois você tem nas mãos.

| verificação | uma estratégia | um roadmap |
|---|---|---|
| Nomeia um problema que alguém poderia conferir? | sim, no diagnóstico | raramente; nomeia entregas |
| Quando uma data escorrega, ele muda? | não | sim |
| Consegue explicar por que algo está *ausente*? | sim; a política exclui | não; ausência não tem razão num roadmap |

A terceira verificação é a mais afiada. Pergunte por que o framework de front-end não está no plano
deste ano. Uma estratégia tem uma resposta, e é a mesma resposta para todos os times. Um roadmap
sozinho tem só um dar de ombros, ou uma história diferente a cada vez que alguém pergunta.

## A falha oposta

O contrário também acontece. Uma estratégia pode ser escrita, assinada e admirada, e nunca chegar a
um roadmap: nenhum trimestre carrega suas ações, nenhuma sprint de time contém seu trabalho. Essa
estratégia é decoração, e é mais difícil de ver que a primeira falha, porque o documento em si
parece bom. O único jeito de achá-la é seguir o trabalho para baixo a partir da estratégia e para
cima a partir do backlog, que é a próxima seção.
