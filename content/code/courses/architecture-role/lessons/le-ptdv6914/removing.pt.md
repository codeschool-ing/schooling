---
title: Contar os serviços e tirar alguns
version: 1
---

Os times perguntam à arquiteta o que acrescentar: um serviço, um cache, uma fila, uma ferramenta.
Ninguém pergunta o que dá para tirar, porque remover alguma coisa não produz funcionalidade, anúncio
nem linha nas metas de ninguém para o trimestre. **Remoção é um trabalho que a arquiteta precisa
pedir, e começa com um inventário, porque ninguém remove o que ninguém listou.**

## O inventário

No primeiro trimestre, Renata montou uma tabela com uma linha por serviço implantável. Para cada um
ela anotou o time dono, quem o chama, quantas vezes foi implantado nos últimos 90 dias, quantos
acionamentos de plantão gerou, quando o código mudou pela última vez por um motivo que não fosse
atualização, quem saberia explicá-lo e por que ele existe como implantável separado, e não como
código dentro de outra coisa.

A última coluna era a difícil. Nove serviços tinham uma resposta clara para ela. Cinco não tinham.

| serviço | time | por que é separado | veredito |
|---|---|---|---|
| monolith | Shipper, Payments | a aplicação Django original e o banco dela, a maior parte do negócio | manter |
| shipper-web | Shipper | o app web dos embarcadores, lançado no próprio ritmo | manter |
| driver-app | Driver | o app dos motoristas e a API dele, versionada para versões antigas do app ainda em uso | manter |
| matching | Matching | oferece cada carga aos motoristas um de cada vez, com ciclo de release próprio | manter |
| tracking | Tracking | recebe as posições GPS de todo caminhão em movimento, cerca de 270 por segundo no pico, em banco próprio | manter |
| pricing | Pricing | ciclo de release próprio, com regras de cotação mudando toda semana | manter |
| cte-issuer | Payments | conversa com a autoridade fiscal e isola uma dependência externa lenta | manter |
| pix-payouts | Payments | guarda as credenciais do banco, isolado por segurança e auditoria | manter |
| notifications | Platform | notificações push e SMS para todos os times | manter |
| pricing-floor | Pricing | guarda a tabela do piso da ANTT; só o pricing chama | fundir no pricing |
| invoice-pdf | Payments | gera faturas uma vez por dia; só o monólito chama | trazer para o monólito |
| geo-distance | Matching | embrulha uma biblioteca de rotas; só o matching chama | virar biblioteca |
| config-service | Platform | configuração feita em casa, duplicando variáveis de ambiente | apagar |
| load-search | Matching | busca de cargas abertas, feita num hackathon; usada por 4% dos embarcadores | perguntar ao produto |

**O padrão nos cinco é um implantável separado com exatamente um chamador, ou nenhum que precise
dele.** Um serviço com um chamador não tem nenhum dos benefícios para os quais um serviço existe. Não
pode ser implantado de forma independente em nenhum sentido que importe, porque o único chamador
precisa mudar junto; não isola falha, porque quando ele cai o chamador cai junto; e carrega todos os
custos da seção anterior.

## Os cinco, um de cada vez

**pricing-floor** foi separado em 2020 para que o piso "pudesse ser atualizado sem deploy do
Pricing". A ANTT revisa a tabela algumas vezes por ano, e toda revisão continuou passando por um
engenheiro e uma revisão. Em troca, toda cotação fazia uma chamada de rede a ele, e em duas ocasiões
o pricing-floor caiu e o Pricing não conseguiu cotar nada. A tabela virou um arquivo de dados
versionado dentro do Pricing, alterado por um pull request revisado, que era o que já acontecia na
prática.

**invoice-pdf** é chamado uma vez por dia, pelo job noturno de faturamento do monólito. Tinha
pipeline próprio, imagem base própria para corrigir e lugar próprio na escala de plantão. Virou um
módulo que o job noturno chama direto.

**geo-distance** embrulha uma biblioteca de rotas de código aberto numa API HTTP, e o matching o
chamava cerca de 40.000 vezes por dia. Cada chamada era um salto de rede que podia estourar o tempo,
para um cálculo que o matching podia fazer no próprio processo. A biblioteca entrou no matching como
dependência comum.

**config-service** era o terceiro jeito de configurar as coisas na Carreto. Quando ele caía, os
serviços não subiam, e ele tinha acionado o plantão 11 vezes nos 90 dias. Platform passou todos os
valores para as variáveis de ambiente que a ferramenta de deploy deles já administrava, e desligou o
serviço.

**load-search** foi o que Renata não podia decidir. Ele mantém a própria cópia de toda carga aberta,
que é a cópia que o job noturno instável sincroniza, e serve uma tela de busca usada por 4% dos
embarcadores. Tirá-lo remove uma funcionalidade, e **remover uma funcionalidade é decisão de
produto**, então foi para Helena Prado. Ela quis conversar antes com os embarcadores que o usam, e no
fim do segundo trimestre ele ainda estava no ar.

Em dois trimestres quatro dos cinco saíram, e a Carreto passou de 14 serviços implantáveis para 10.
Pela conta de Paula, de 6 horas por mês cada, são 24 horas por mês de atualização que ninguém faz
mais, perto de 300 horas por ano. Os quatro tinham gerado 23 dos 112 acionamentos nos 90 dias antes
do inventário, e hoje não geram nenhum.

## Remover com segurança

Um serviço removido pela metade é pior que um vivo ou um que já foi: ainda tem um alerta que
dispara, um painel em que alguém confia e uma página na wiki dizendo que é assim que se faz. Os
times de Renata seguiram os mesmos passos em todos os casos.

1. **Ache todos os chamadores pelo tráfego, não pela documentação.** Os logs de acesso e os
   consumidores do broker dizem quem chama um serviço; a wiki diz quem chamava quando a página foi
   escrita.
2. **Mude os chamadores**, um de cada vez, cada mudança pequena o bastante para ser desfeita.
3. **Observe o serviço antigo não receber nada** por duas semanas, o que cobre um job quinzenal de
   que ninguém se lembrava.
4. **Desligue e mantenha religável** por um mês: a imagem fica no registry e a configuração fica no
   repositório.
5. **Apague tudo o que ele deixou para trás**: o repositório ou o diretório, o pipeline, os painéis,
   os alertas, os segredos e a documentação. Depois escreva uma linha nos registros de arquitetura
   dizendo que ele se foi, e por quê.

## Por que a remoção precisa da arquiteta

Olhe quem paga e quem economiza. Fundir o pricing-floor custou cerca de duas semanas ao time de
Pricing. A economia foi para as horas de atualização de Platform e para toda pessoa na escala de
plantão. **Quando o custo cai num time e a economia se espalha por todos, nenhum roadmap de time vai
carregar esse trabalho.** A arquiteta vê o inventário inteiro e pode defender o tempo. Renata levou a
tabela a Tomás Viana com as horas e os acionamentos ao lado de cada linha e pediu três semanas
divididas entre Pricing, Payments e Platform. Conseguiu, porque a tabela tornou visível o custo de
manter, e até ali ninguém nunca o tinha somado.

## A peça mais barata de remover é a que ninguém pôs

O jeito mais seguro de ter menos para remover é acrescentar menos. **YAGNI**, "you aren't gonna need
it", você não vai precisar disso, vem da Extreme Programming do fim dos anos 1990: não construa uma
capacidade para uma necessidade que você só espera ter. O ensaio de Martin Fowler sobre o tema lista o
que custa uma funcionalidade presumida: o custo de construí-la; o custo do atraso, porque outra coisa
deixou de ser construída nesse tempo; o custo de carregá-la, porque ela torna mais difícil mudar tudo
o que está perto; e, quando a necessidade presumida se revela outra, o custo de consertá-la.

O pricing-floor era uma funcionalidade presumida. Foi feito para pessoas do negócio que atualizariam
o piso por conta própria, uma necessidade que nunca foi confirmada e nunca chegou, e a Carreto pagou
para carregá-lo todo mês de 2020 até o inventário de Renata.

Fowler também marca o limite da regra, e é fácil entendê-lo ao contrário. **YAGNI fala de
funcionalidades para um futuro que ninguém confirmou, nunca do trabalho que mantém o código fácil de
mudar.** Testes, refatoração e fronteiras claras entre módulos são o que torna barato acrescentar a
funcionalidade no dia em que ela for de fato necessária, então cortá-los em nome do YAGNI derruba o
próprio propósito da regra. A aula 17 mostra o que acontece com um sistema quando ninguém aplica
YAGNI durante vários anos, sob o nome de superengenharia.
