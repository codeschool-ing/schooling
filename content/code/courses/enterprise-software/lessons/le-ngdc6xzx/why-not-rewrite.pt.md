---
title: Por que não simplesmente reescrever
version: 1
---

A Coleta precisa sair. Ela roda a coleta de leite da Serra Alta desde 1996, no IBM i, em RPG, e a
maior parte dela foi escrita por uma pessoa só. Sebastião Lima se aposenta em 2028, e as regras que
decidem quanto 1.900 fazendas recebem por mês estão no código dele e na cabeça dele. Ninguém discute
que é preciso um substituto. A discussão é sobre como chegar lá.

O plano que quase todo mundo pega primeiro é o que a Joana trouxe da fintech: **escrever o sistema
novo do zero, ao lado do antigo, e virar a chave num fim de semana escolhido.** Parece o plano
seguro porque parece uma cópia. O sistema antigo é a especificação, funciona há trinta anos, e tudo
o que o novo precisa fazer é a mesma coisa numa linguagem moderna.

Esse plano tem nome, a reescrita big bang, e tem um longo histórico de atrasar, estourar o orçamento
e às vezes nunca chegar. Não porque quem faz seja descuidado. Ele falha por três motivos que estão
na própria forma dele, e os três estão presentes na Serra Alta.

## O alvo se mexe enquanto você copia

**Uma reescrita copia um sistema que não fica parado enquanto é copiado.** A Coleta não está
congelada. Nos últimos doze meses o Sebastião fez 23 mudanças nela: uma tabela nova de bonificação
por proteína combinada com as associações de produtores, uma mudança no jeito de pagar uma fazenda
suspensa por qualidade quando ela volta, um campo novo que o laboratório começou a mandar, e vinte
mudanças menores. Nenhuma era opcional. O negócio pediu, e o sistema que paga as fazendas tinha de
acompanhar.

Durante uma reescrita cada uma dessas mudanças precisa ser feita duas vezes: uma na Coleta, porque é
ela que paga as fazendas hoje, e outra no sistema novo, porque senão ele estará errado no dia em que
assumir. Na prática a segunda cópia fica para trás. O time que constrói o sistema novo está ocupado
construindo, a lista de mudanças é longa, e a distância entre os dois só aparece no fim, quando
alguém os compara. Uma reescrita planejada para dois anos contra um sistema que muda duas vezes por
mês é a reescrita de um alvo que ninguém viu.

## A especificação é o código

O segundo motivo é que os documentos descrevem o que alguém pretendia em 1996, e o código descreve o
que acontece. **Num sistema tão antigo, o programa é a única descrição completa das regras.** A
Coleta tem um manual, escrito em 2003 e atualizado pela última vez em 2011. Ele cobre a fórmula
principal de pagamento e nenhuma das exceções: as fazendas de tanque comunitário, o jeito de datar
uma coleta feita depois da meia-noite, a cooperativa cujas fazendas ganham um bônus de inverno por
causa de um acordo assinado antes de qualquer pessoa que trabalha hoje na Serra Alta ter chegado.

Cada uma dessas exceções é uma linha de RPG que um dia foi um telefonema. Joel Spolsky fez o
argumento geral em 2000, num texto chamado *Things You Should Never Do, Part I*, sobre a decisão da
Netscape de reescrever o navegador do zero. Código antigo é feio em parte porque foi consertado,
escreveu ele, e cada conserto é conhecimento sobre o mundo real que a reescrita joga fora e precisa descobrir de
novo, em geral em produção. Fred Brooks já tinha descrito a outra metade em *The Mythical Man-Month*
(1975): o segundo sistema que um time constrói é aquele em que ele tenta incluir tudo o que deixou de
fora do primeiro, o que deixa a cópia maior que o original.

## Uma data carrega todo o risco

O terceiro motivo é o que torna a reescrita perigosa, e não apenas lenta. **No big bang nada está
provado até o cutover, e o cutover prova tudo de uma vez.** Dois anos de trabalho chegam às fazendas
de verdade num único dia. Para a Coleta esse dia é o dia 10 de um mês, quando 1.900 fazendas esperam
dinheiro na conta. Se o cálculo novo estiver errado para algumas delas, o primeiro sinal é um
produtor ligando para a fábrica, e o caminho de volta não é um novo deploy. Pagamentos já feitos
precisam ser estornados ou complementados à mão, e a aula 14 mostra por que esse é o ponto sem
volta de qualquer migração que movimenta dinheiro.

Um big bang também não entrega valor nenhum até terminar. Durante dois anos a empresa paga dois
times, um mantendo a Coleta viva e outro construindo o substituto, e a única coisa que a diretoria
enxerga é uma data que já mudou duas vezes. Projetos nesse estado perdem os patrocinadores antes de
perder os problemas técnicos.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 310\" role=\"img\" data-fig=\"l13-risk\" aria-label=\"Um gráfico com o tempo em meses no eixo horizontal, de 0 a 30, e, no eixo vertical, a mudança já construída mas ainda não provada em produção. A linha do big bang sobe sem parar durante todo o projeto, de nada no mês 0 até o ponto mais alto no mês 28, e só cai a zero no cutover, onde tudo é provado de uma vez. A linha incremental é um dente de serra que fica baixo: sobe durante uns quatro meses, cai a zero quando uma fatia entra em produção, e se repete seis vezes.\"><defs><marker id=\"l13-risk-es-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M90.0 250.0 L660.0 250.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-es-ah-paper-dim)\"></path><path d=\"M90.0 250.0 L90.0 50.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l13-risk-es-ah-paper-dim)\"></path><path d=\"M90.0 250.0 L90.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"90.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">0</text><path d=\"M202.0 250.0 L202.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"202.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">6</text><path d=\"M314.0 250.0 L314.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"314.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">12</text><path d=\"M426.0 250.0 L426.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"426.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">18</text><path d=\"M538.0 250.0 L538.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"538.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">24</text><path d=\"M650.0 250.0 L650.0 254.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1\" fill=\"none\"></path><text x=\"650.0\" y=\"264.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">30</text><text x=\"370.0\" y=\"284.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">meses desde o início do projeto</text><text x=\"42.0\" y=\"141.3\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">construído,</text><text x=\"42.0\" y=\"155.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">ainda não</text><text x=\"42.0\" y=\"168.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper-dim)\">provado</text><path d=\"M90.0 250.0 L612.7 70.0 L612.7 250.0\" stroke=\"var(--amber)\" stroke-width=\"2.2\" fill=\"none\"></path><circle cx=\"612.7\" cy=\"70.0\" r=\"4\" fill=\"var(--amber)\"></circle><text x=\"604.7\" y=\"68.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">cutover: tudo provado numa noite só</text><path d=\"M90.0 250.0 L187.1 226.0 L187.1 250.0 L272.9 226.0 L272.9 250.0 L358.8 226.0 L358.8 250.0 L444.7 226.0 L444.7 250.0 L530.5 226.0 L530.5 250.0 L616.4 226.0 L616.4 250.0\" stroke=\"var(--phosphor)\" stroke-width=\"2\" fill=\"none\"></path><text x=\"416.7\" y=\"204.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">incremental: cada fatia provada quando entra em produção</text><text x=\"258.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">big bang</text></svg>", "caption": "O risco está no trabalho que ninguém viu ainda rodando contra fazendas de verdade. O big bang deixa ele se acumular durante o projeto inteiro; o strangler libera uma fatia de cada vez.", "same": ["big bang"]}
```

A figura é o argumento desta seção numa forma só. A grandeza no eixo vertical é **a mudança que já
foi construída mas ainda não foi provada em produção**, que é onde o risco está: trabalho que ninguém
viu rodando contra fazendas de verdade. O big bang deixa esse monte crescer durante o projeto inteiro
e solta tudo numa noite. Uma substituição incremental mantém o monte pequeno, porque de poucos em
poucos meses alguma coisa entra em produção, é conferida contra a realidade e deixa de ser risco.

## A figueira estranguladora

Em 2004 Martin Fowler deu à abordagem incremental o nome que pegou. Num artigo curto chamado
*StranglerFigApplication* ele descreveu as figueiras estranguladoras que tinha visto nas florestas
tropicais de Queensland. A figueira germina nos galhos altos de uma árvore hospedeira, desce as
raízes até o solo e, ao longo dos anos, cresce em volta da hospedeira até ficar de pé sozinha, com a
hospedeira morta lá dentro. **A versão em software constrói o sistema novo em volta das bordas do
antigo, leva o trabalho dele uma capacidade de cada vez e desliga o antigo quando não sobra nada lá
dentro.**

Três coisas mudam em relação à reescrita. Algo entra em produção cedo, então o sistema novo encontra
fazendas de verdade no sexto mês, e não no trigésimo. Cada mudança é pequena, então quando uma dá
errado o estrago é uma capacidade, e o caminho de volta é rotear aquela capacidade de novo para o
sistema antigo. E o sistema antigo continua fazendo tudo o que ainda não mudou de lado, então as
mudanças que o negócio pede nesse meio-tempo caem num lugar só: onde quer que aquela capacidade more
naquele momento.

## Quanto custa o strangler

Ele não é de graça, e quem paga precisa ouvir isso antes de concordar. **Enquanto a migração durar,
os dois sistemas rodam, e o código que permite que rodem juntos é escrito para ser jogado fora.** O
roteamento na frente do sistema antigo, a tradução entre os dois modelos, a sincronização dos dados
de que os dois precisam: tudo isso só existe para o meio da migração, e o meio é longo. A duração
total costuma passar do que o plano da reescrita dizia, embora o plano da reescrita raramente tenha
sido a duração que ela conseguiu.

Por isso o strangler não é sempre a resposta. Um big bang é razoável quando o sistema é pequeno,
quando as regras estão congeladas e escritas, quando ninguém o chama, ou quando a coexistência
custaria mais do que o risco que ela elimina. Trocar uma ferramenta isolada que dez pessoas usam,
cujos dados podem ser levados numa tarde e conferidos à mão, não pede um programa de migração. A
Coleta é o oposto em todos os pontos: é grande, muda todo mês, as regras estão no código, metade da
empresa depende do que ela produz e ela movimenta dinheiro.

## A decisão da Joana

O primeiro rascunho do plano da Joana, escrito no segundo mês dela, era uma reescrita. Ela tinha
passado oito anos construindo sistemas do nada, e era o plano que ela sabia estimar. O Edson leu e
fez uma pergunta só: o que a Serra Alta faria no dia 10 do mês seguinte ao cutover se 200 fazendas
tivessem recebido o valor errado. O rascunho não tinha resposta, e o segundo rascunho foi um
strangler.

A forma dele é o resto desta aula. Uma camada de roteamento onde a Coleta tem uma borda, e
interceptação onde não tem. Uma camada de tradução para que o modelo novo não nasça à imagem da
Coleta. Um meio longo em que os dois sistemas rodam, com um dono para cada dado em cada momento. E
um fim, escrito com data, em que o IBM i é desligado. Se o sistema que vai substituir o cálculo de
pagamento da Coleta será comprado, construído ou acrescentado ao SAP é outra pergunta, e a aula 15
responde. O strangler funciona do mesmo jeito para as três.
