---
title: Quatro tipos de lock-in, e onde cada escolha de computação fica
version: 1
---

Costuma-se falar de lock-in como uma coisa só, uma armadilha que um provedor arma e uma equipe
cuidadosa evita. **São quatro coisas diferentes, cada uma comprada com algo que você queria**, e uma
escolha de computação carrega algumas delas e não outras. Falar delas separadamente é o que
transforma "estamos presos" de um estado de espírito numa lista.

## Lock-in de API: o que o seu código diz

Código que chama a interface de um provedor precisa ser reescrito para sair dela. Um handler do
Lambda recebe um dicionário `event` cujo formato é da AWS: uma notificação do S3, um lote do SQS e
uma requisição do API Gateway têm formatos diferentes, e nenhum deles se parece com uma requisição
HTTP em outro provedor. Uma máquina de estados em Amazon States Language (aula 20) roda no Step
Functions e em nenhum outro lugar. Uma task definition (aula 8) é o formato do ECS; o Kubernetes lê
manifests, e o serviço de contêineres de outro provedor lê o seu próprio.

O que você ganha com isso é real: o gatilho, as novas tentativas, a escala e a fila de mensagens
mortas que outra pessoa escreveu e opera. **O lock-in de API é o preço de um recurso gerenciado**, e
quanto mais trabalho a plataforma faz, mais o seu código tem a forma dela.

## Gravidade dos dados e saída: onde os seus dados estão

Dados pesam em dois sentidos. Movê-los custa dinheiro por gigabyte (a seção 04 lê a tabela de
preços), e movê-los leva tempo, durante o qual duas cópias precisam ficar em sincronia. Quanto mais
tempo um serviço roda, mais dados ele acumula e mais pesado fica.

Esse tipo pertence ao armazenamento, e não à computação: um bucket S3 ou um banco de dados pesa o
mesmo, seja o Lambda ou o Fargate a lê-lo. O que a computação decide é o quanto o código precisa
ficar perto dos dados. Uma função em São Paulo lendo um banco em São Paulo paga pouco ou nada para
atravessar entre os dois; mova a função e deixe o banco, e toda consulta vira uma requisição entre
provedores, lenta e cobrada por gigabyte.

## Habilidades: o que a sua equipe sabe

Uma equipe que passou dois anos aprendendo ECS, papéis do IAM para tasks e CloudWatch tem um
conhecimento que não viaja inteiro. Os conceitos viajam, e é por isso que este curso os ensina pelo
nome; os detalhes, os modos de falha e os reflexos às três da manhã, não. **O lock-in de habilidades
é o que ninguém põe num diagrama**, e para uma equipe pequena muitas vezes é o maior, porque uma
mudança custa semanas de três pessoas aprendendo em vez de construir.

Ele também é o que corre nos dois sentidos. Uma equipe de especialistas em Kubernetes a quem se pede
rodar tudo no Lambda fica tão trancada fora da própria experiência quanto uma equipe de Lambda fica
trancada dentro.

## Contratos: o que você assinou

Um Savings Plan ou uma Reserved Instance é um compromisso de um ou três anos em troca de uma tarifa
menor (aula 14 de `aws-foundations`). **É o único tipo de lock-in com data de fim escrita**, e o único
puramente financeiro: nada no código muda. Um compromisso de três anos assinado no primeiro mês de
um serviço é uma aposta de que o serviço, o tamanho dele e a plataforma ainda vão estar certos no
trigésimo sexto.

## Onde cada escolha fica

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Uma tabela de julgamentos com seis escolhas de computação nas linhas e três tipos de lock-in nas colunas. Lock-in de API: EC2 pouco, ECS no Fargate algum, EKS pouco, Lambda muito, Step Functions muito, Elastic Beanstalk algum. Lock-in de habilidades: EC2 pouco, ECS no Fargate algum, EKS muito, Lambda algum, Step Functions algum, Elastic Beanstalk pouco. Lock-in de contrato: se você se comprometer em todas as linhas menos Step Functions, que não tem nenhum. Uma nota diz que a gravidade dos dados fica de fora porque ela é do armazenamento.\"><text x=\"300\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">API: o que o seu código diz</text><text x=\"460\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">habilidades: o que a equipe sabe</text><text x=\"620\" y=\"30\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--paper)\">contrato: o que você assinou</text><text x=\"30\" y=\"68\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EC2</text><rect x=\"230\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pouco</text><rect x=\"390\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pouco</text><rect x=\"550\" y=\"50\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"67\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se você se comprometer</text><text x=\"30\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ECS on Fargate</text><rect x=\"230\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">algum</text><rect x=\"390\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">algum</text><rect x=\"550\" y=\"94\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"111\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se você se comprometer</text><text x=\"30\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EKS</text><rect x=\"230\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pouco</text><rect x=\"390\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">muito</text><rect x=\"550\" y=\"138\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"155\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se você se comprometer</text><text x=\"30\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Lambda</text><rect x=\"230\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">muito</text><rect x=\"390\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">algum</text><rect x=\"550\" y=\"182\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"199\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se você se comprometer</text><text x=\"30\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Step Functions</text><rect x=\"230\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">muito</text><rect x=\"390\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">algum</text><rect x=\"550\" y=\"226\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"243\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">nenhum</text><text x=\"30\" y=\"288\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Elastic Beanstalk</text><rect x=\"230\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"300\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">algum</text><rect x=\"390\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"460\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">pouco</text><rect x=\"550\" y=\"270\" width=\"140\" height=\"34\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"620\" y=\"287\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">se você se comprometer</text><text x=\"30\" y=\"318\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a gravidade dos dados fica de fora: ela é do armazenamento, e pesa o mesmo seja qual for a computação que o lê</text></svg>", "caption": "Um julgamento, linha a linha: quanto mais um serviço faz por você, mais o seu código toma a forma dele. Contratos se prendem à conta, não à plataforma."}
```

A figura é um julgamento, não uma medição, e cada linha pode ser contestada: um cluster EKS que usa
dez controladores específicos da AWS tem mais lock-in de API do que a linha dele diz, e uma frota de
EC2 construída com as imagens próprias de um provedor também. O que ela mostra é o padrão. **Quanto
mais um serviço faz por você, mais o seu código toma a forma dele**, e as habilidades seguem o
serviço, e não o código. Os contratos aparecem iguais em toda linha que um Savings Plan ou uma
reserva pode cobrir, porque se prendem à conta e não à plataforma; o Step Functions não oferece
compromisso para assinar.

Duas consequências seguem para o resto da aula. O lock-in é um custo a pesar contra o que ele
compra, como qualquer outro custo da aula 23. E ele só pode ser reduzido num lugar, o código entre
as suas regras e o provedor, que é a seção 03.
