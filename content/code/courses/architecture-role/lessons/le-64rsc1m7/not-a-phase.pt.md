---
title: Arquitetura não é uma fase
version: 1
---

Há dois erros opostos sobre quando a arquitetura acontece, e cada um é uma reação ao outro. **Um
trata a arquitetura como uma fase no começo do projeto**: um desenho é escrito, aprovado e entregue,
e a programação começa. **O outro a trata como algo de que times ágeis não precisam**: escreva
código, refatore e deixe o desenho emergir. Os dois falham, de jeitos diferentes, e a resposta que
funciona fica entre eles e dura tanto quanto o sistema.

## O grande desenho antecipado

O primeiro erro tem nome, *big design up front*, o grande desenho antecipado. Um time passa meses
num desenho completo antes de alguém escrever código, para que o código só precise segui-lo. O apelo
é real: decisões tomadas cedo, no papel, são baratas de mudar, e um time que sabe para onde vai
desperdiça menos trabalho.

O problema é que **a maior parte daquilo de que o desenho depende ainda não se sabe.** Quantos
embarcadores vão usar o produto, que funcionalidades vão de fato querer, onde a carga vai se
concentrar, o que o regulador vai mudar no ano que vem. Um desenho que fixa tudo isso de antemão é
um conjunto de palpites, e os palpites são mais difíceis de corrigir justamente quando se mostram
errados, porque a essa altura já há código construído sobre eles. Um documento de desenho aprovado e
nunca revisto vira o slide da seção 02 desta aula: um plano apresentado como descrição.

## Nenhum desenho

O erro oposto nasceu da reação ao primeiro. O Extreme Programming e o movimento ágil argumentaram,
com razão, que boa parte do desenho pode ser feita em passos pequenos enquanto o código cresce,
guiada por testes e refatoração. O ensaio de Martin Fowler "Is Design Dead?" examinou essa tese e
concluiu que o desenho não morreu, só mudou de forma. Alguns times ouviram só a primeira metade e
pararam de decidir qualquer coisa com antecedência.

**Algumas decisões não podem ser refatoradas depois por um preço razoável.** O formato dos dados que
três times compartilham, o jeito como o dinheiro se move, se um passo pode ser repetido com
segurança: quando código e dados dependem disso, mudar vira um projeto, não uma refatoração. A
tabela `loads` compartilhada da Carreto é o resultado de anos sem decidir. Cada passo foi pequeno e
sensato; a soma é a decisão mais cara do sistema, e ninguém a tomou.

## O suficiente, no momento certo

A resposta que funciona é decidir **o suficiente de antemão**: as decisões que seriam caras de
mudar, e nenhuma outra. O teste da aula 1 faz a triagem. O que tem custo de mudança alto, ou
atravessa fronteiras de times, é decidido de propósito e cedo o bastante para importar. O resto fica
com o time que constrói, para ser decidido quando ele souber mais.

A pergunta de *quando* exatamente tem uma resposta útil, de *Lean Software Development* (2003), de
Mary e Tom Poppendieck: o **último momento responsável**, o ponto em que deixar de decidir
eliminaria uma alternativa importante. Antes dele, decidir é adivinhar com menos informação do que
você poderia ter. Depois dele, a decisão é tomada por você, por omissão, pelo que o código já faz.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Um gráfico conceitual com o tempo no eixo horizontal e o custo no vertical. Uma curva, o custo de adivinhar, cai à medida que a informação chega. A outra, o custo de esperar, sobe à medida que se constrói trabalho em volta da decisão em aberto. Uma linha vertical tracejada onde elas se cruzam marca o último momento responsável; à esquerda dela a decisão é um palpite, à direita é tomada por omissão.\"><defs><marker id=\"lrm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M70 270 L680 270\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lrm-ah)\"></path><path d=\"M70 270 L70 40\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#lrm-ah)\"></path><text x=\"370.0\" y=\"294\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">tempo, à medida que o projeto aprende</text><text x=\"60\" y=\"28\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">custo</text><polyline points=\"70.0,80.0 80.0,85.6 90.0,91.1 100.0,96.6 110.0,101.9 120.0,107.2 130.0,112.3 140.0,117.4 150.0,122.3 160.0,127.2 170.0,131.9 180.0,136.6 190.0,141.2 200.0,145.7 210.0,150.1 220.0,154.4 230.0,158.6 240.0,162.7 250.0,166.7 260.0,170.6 270.0,174.4 280.0,178.2 290.0,181.8 300.0,185.4 310.0,188.8 320.0,192.2 330.0,195.4 340.0,198.6 350.0,201.6 360.0,204.6 370.0,207.5 380.0,210.3 390.0,213.0 400.0,215.6 410.0,218.1 420.0,220.5 430.0,222.8 440.0,225.0 450.0,227.1 460.0,229.2 470.0,231.1 480.0,233.0 490.0,234.7 500.0,236.4 510.0,237.9 520.0,239.4 530.0,240.7 540.0,242.0 550.0,243.2 560.0,244.3 570.0,245.3 580.0,246.2 590.0,247.0 600.0,247.7 610.0,248.3 620.0,248.8 630.0,249.2 640.0,249.6 650.0,249.8 660.0,250.0 670.0,250.0\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"2.5\"></polyline><polyline points=\"70.0,258.0 80.0,258.0 90.0,257.9 100.0,257.7 110.0,257.5 120.0,257.2 130.0,256.8 140.0,256.3 150.0,255.7 160.0,255.1 170.0,254.3 180.0,253.5 190.0,252.5 200.0,251.4 210.0,250.3 220.0,249.0 230.0,247.6 240.0,246.1 250.0,244.6 260.0,242.9 270.0,241.1 280.0,239.1 290.0,237.1 300.0,235.0 310.0,232.7 320.0,230.3 330.0,227.8 340.0,225.2 350.0,222.5 360.0,219.6 370.0,216.6 380.0,213.6 390.0,210.3 400.0,207.0 410.0,203.5 420.0,200.0 430.0,196.2 440.0,192.4 450.0,188.4 460.0,184.4 470.0,180.1 480.0,175.8 490.0,171.3 500.0,166.7 510.0,162.0 520.0,157.1 530.0,152.1 540.0,147.0 550.0,141.7 560.0,136.3 570.0,130.8 580.0,125.1 590.0,119.3 600.0,113.4 610.0,107.3 620.0,101.1 630.0,94.8 640.0,88.3 650.0,81.7 660.0,74.9 670.0,68.0\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"2.5\"></polyline><path d=\"M390.0 270 L390.0 60\" fill=\"none\" stroke=\"var(--paper)\" stroke-width=\"1.5\" stroke-dasharray=\"5 4\"></path><text x=\"390.0\" y=\"43.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">o último</text><text x=\"390.0\" y=\"57.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">momento responsável</text><text x=\"90\" y=\"63.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">custo de decidir agora:</text><text x=\"90\" y=\"77.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">adivinhar sem os fatos</text><text x=\"590\" y=\"63.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">custo de esperar: trabalho</text><text x=\"590\" y=\"77.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">construído em volta da lacuna</text><text x=\"180\" y=\"223.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">cedo demais:</text><text x=\"180\" y=\"237.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um palpite</text><text x=\"570\" y=\"183.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tarde demais:</text><text x=\"570\" y=\"197.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">decidido por omissão</text></svg>", "caption": "Sem números, só a forma: decidir cedo custa palpites, decidir tarde custa o trabalho construído em volta da lacuna. O último momento responsável é onde o segundo custo começa a passar o primeiro."}
```

O momento é o último *responsável*, não o último possível. **Esperar não é de graça**: enquanto uma
decisão está aberta, os times constroem em volta da lacuna, e cada semana acrescenta trabalho que a
decisão final talvez precise desfazer. Uma decisão adiada além do seu momento não foi evitada. Foi
tomada por acidente.

## Duas decisões em Payments

Na terceira semana de Renata, Bruno Farias traz para ela o plano de pagar os motoristas por Pix
através de um banco parceiro. Há várias decisões no plano, e elas não têm todas o mesmo momento.

**Como tornar um pagamento seguro para ser repetido é para agora.** Se a Carreto envia um pedido de
pagamento, o banco demora para responder e a Carreto envia de novo, o motorista pode receber duas
vezes. Se cada pedido leva uma chave que o banco usa para recusar duplicatas precisa estar resolvido
antes do primeiro pagamento real. O custo de errar chega em dinheiro, no dia em que entra no ar, e
recuperar um pagamento de um motorista é lento e abala a confiança. Essa decisão é arquitetural em
todos os critérios: atravessa o Payments e o banco, e é caríssima de mudar depois que o dinheiro se
moveu.

**Qual biblioteca de cliente conversa com o banco pode esperar.** Ela fica dentro de Payments, pode
ser trocada por trás de uma interface em poucos dias, e o time vai saber muito mais sobre a API do
banco depois de um mês usando o ambiente de testes dele. Decidir agora seria decidir com menos
informação sem ganhar nada.

A aula 3 volta à primeira dessas decisões, porque o jeito como ela foi tomada acaba importando tanto
quanto o que foi decidido.

## Decisões são revistas

A última parte do erro é a ideia de que uma decisão, uma vez tomada, está encerrada. **Uma decisão
arquitetural é tomada num contexto, e quando o contexto muda a decisão precisa ser olhada de novo.**
Em 2017, os fundadores da Carreto construíram uma aplicação Django com um banco. Com seis
engenheiros e nenhum cliente, era uma boa decisão: uma coisa para implantar, um lugar para os dados,
nada para coordenar. Com cinquenta engenheiros em sete times, a mesma decisão produz as implantações
de 40 minutos e os choques sobre a tabela `loads` que a seção anterior listou.

Os fundadores não erraram. **O contexto mudou, e ninguém voltou à decisão.** É esse o trabalho que
"arquitetura não é uma fase" descreve: manter o registro do que foi decidido e por quê, para que uma
mudança de contexto possa ser notada e a decisão reaberta de propósito, em vez de corroída por
acidente. A aula 5 dá a ferramenta para isso, o registro de decisão de arquitetura, inclusive o que
acontece com ele quando é substituído.

Então a arquitetura acontece antes do código, durante ele e enquanto o sistema rodar. Não é um
documento entregue no começo; é um conjunto de decisões que alguém continua decidindo.
