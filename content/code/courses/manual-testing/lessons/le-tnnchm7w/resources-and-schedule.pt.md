---
title: Pessoas, ambiente, cronograma e os critérios
version: 1
---

O escopo e os riscos dizem o que testar. O resto de um plano diz do que o teste precisa e quando ele
termina, e **a parte que mais fica vaga é o fim**. Esta seção cobre as perguntas que faltam e
termina com o plano inteiro do boxoffice 1.0 numa página.

## Pessoas e habilidades

Um plano diz quem testa, pelo papel se não pelo nome, e o que cada pessoa precisa saber. Para um
time pequeno a resposta é curta e ainda vale escrever: uma testadora por duas semanas, e o
desenvolvedor uma hora por dia para responder perguntas e corrigir o que for achado. A gerente do
teatro dá uma tarde ao teste de aceitação no fim, o assunto da aula 12. Escrever a tarde da gerente no
plano é o que a faz acontecer; um teste de aceitação que depende de alguém lembrar de pedir quase
sempre é pulado.

Habilidades também entram aqui. Se o plano diz que as páginas serão conferidas com um leitor de
tela, alguém precisa saber usar um, e se ninguém sabe, o plano diz quem vai aprender e quando.

## O ambiente

O **ambiente de teste** é tudo em que a aplicação roda e tudo que conversa com ela enquanto é
testada. Isso inclui a máquina, o sistema operacional, a versão da aplicação, os navegadores e dispositivos, as
contas, os dados, e qualquer coisa fora dela, como um servidor de e-mail. Cada um desses pode fazer
um teste passar ou falhar sozinho, e por isso a aula 21 trata de ambientes que discordam.

Para o boxoffice o ambiente é o que a seção 03 desta aula montou, com três decisões a mais. A versão
testada é o arquivo como a seção 04 mostra, a 1.0. Os navegadores são os quatro citados no R8. E o
e-mail é a caixa de saída, então o plano diz que o servidor de e-mail real não é testado, o que o
escopo já tinha dito.

## O cronograma

Um cronograma de teste é amarrado ao cronograma do projeto, porque o teste espera coisas: uma versão
existir, uma funcionalidade ficar pronta, um ambiente estar disponível. Por isso **um cronograma de
teste se escreve primeiro em dependências e depois em datas**. "Os testes de reserva começam quando
a reserva for implantada no ambiente de teste" sobrevive a dois dias de atraso no desenvolvimento;
"os testes de reserva começam dia 12" não, e deixa o testador esperando com uma data que deixou de
significar alguma coisa.

## Critérios de entrada, de saída e de suspensão

**Critérios de entrada** dizem quando o teste pode começar: a versão inicia, o ambiente responde, os
requisitos da funcionalidade estão escritos. Começar antes de eles valerem produz falhas que são do
ambiente e não do produto, e um dia de relatórios sobre os quais ninguém consegue agir.

**Critérios de saída** dizem quando o teste terminou, e são escritos agora, enquanto ninguém está
cansado. Um critério útil pode ser conferido por alguém que não fez o teste. *"O teste está completo
quando a qualidade for aceitável"* não pode ser conferido. *"Todo caso dos riscos A a C rodou e
passou, nenhum defeito aberto tem severidade crítica ou grave, e a gerente assinou a sessão de
aceitação"* pode, e as palavras dele, severidade e assinatura, são as aulas 15 e 12.

**Critérios de suspensão** dizem quando parar e esperar em vez de continuar: se a aplicação não
inicia, ou se mais de um quarto dos casos de uma área falham, o teste nessa área pausa até chegar
uma versão nova. Eles existem porque um testador que segue numa versão quebrada passa o dia
escrevendo relatórios sobre um defeito disfarçado de vinte. O teste de fumaça da aula 8 é o jeito
usual de conferi-los a cada versão nova.

## O plano inteiro, numa página

| | boxoffice 1.0, plano de teste |
|---|---|
| escopo | R2 a R9, como a seção 06 lista. Fora: pagamento, carga, o servidor de e-mail real |
| riscos | A preço, B venda além da lotação, C reembolsos, D e-mail de confirmação, E layout no celular; testados nessa ordem |
| abordagem | manual, contra os requisitos; técnicas de projeto de caso das aulas 4 e 5 para A a C; sessões exploratórias da aula 11 para cada área; fumaça a cada versão |
| pessoas | Ana, testadora, duas semanas; Rui, desenvolvedor, uma hora por dia; a gerente do teatro, uma tarde |
| ambiente | boxoffice 1.0 no laptop da testadora; Chrome, Firefox, Safari e Edge, versões atuais; um celular de 360 pixels de largura; e-mail lido na caixa de saída |
| cronograma | casos escritos na semana 1 conforme cada funcionalidade chega; riscos A a C rodados primeiro; sessão de aceitação na última tarde |
| entrada | a versão inicia e o `/health` responde; R1 a R9 escritos |
| saída | todos os casos de A a C rodados e aprovados; nenhum defeito crítico ou grave aberto; aceitação assinada |
| suspensão | a versão não inicia, ou um quarto dos casos de uma área falha |
| entregas | os casos, os relatórios de defeito, um resumo de uma página no fim (aula 19) |

Dez linhas, e cada uma delas pode ser contestada. É o que a primeira seção desta aula pediu de um
plano, e um plano deste tamanho leva uma hora para escrever e poupa as discussões que de outro modo
acontecem no dia da entrega.
