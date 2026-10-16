---
title: Um time de plataforma é um time de produto cujos clientes são engenheiros
version: 1
---

A maioria dos times de plataforma nasce como o time dono das coisas compartilhadas que ninguém mais
quer: as máquinas de build, os scripts de deploy, os pedidos de banco de dados. O trabalho chega como
chamado e o time é julgado pela velocidade com que a fila esvazia. **Um time tocado assim não
consegue saber se o que constrói presta**, porque ninguém que usa teve escolha, e um uso que nunca
foi opcional não mede nada.

O outro arranjo trata a plataforma como produto. Ela tem clientes — os engenheiros dos outros times
— e dá certo quando eles a adotam porque ela facilita a semana deles. Ela também pode fracassar como
um produto fracassa, sendo ignorada, e esse fracasso é uma informação que uma fila de chamados nunca
produz.

## De onde vem a ideia

Matthew Skelton e Manuel Pais dão um vocabulário a isso em *Team Topologies* (2019). Eles descrevem
quatro tipos de time, e um time de plataforma só faz sentido ao lado dos outros três:

| tipo de time | o que faz | na Coreto |
|---|---|---|
| alinhado ao fluxo (*stream-aligned*) | entrega um fluxo de mudanças direto aos usuários | Checkout, Catálogo, Bilheteria, Mobile, Pagamentos |
| habilitador (*enabling*) | ajuda outro time a ganhar uma habilidade e depois sai de cena | nenhum ainda |
| subsistema complicado (*complicated-subsystem*) | é dono de uma parte que exige especialização rara | o time de Reservas criado na aula 1 chega perto |
| plataforma (*platform*) | oferece serviços internos que deixam os times alinhados ao fluxo entregarem sozinhos | Plataforma |

O propósito do time de plataforma, nas palavras deles, é **reduzir a carga cognitiva dos times
alinhados ao fluxo**: o quanto um time precisa manter na cabeça para entregar uma mudança. O time de
Checkout do Mateus Araújo deveria estar pensando em como um comprador paga por um assento. Cada hora
gasta aprendendo como o agente de logs é configurado, ou por que um deploy ainda tem passos manuais,
é uma hora tirada da coisa que só eles sabem fazer.

O livro também nomeia a forma como um time de plataforma deveria ser consumido na maior parte do
tempo: **como serviço**, por meio de algo que o outro time usa sem precisar de reunião. Um pedido
que exige uma conversa toda vez é colaboração, o que é certo por algumas semanas enquanto algo novo
toma forma e caro como arranjo permanente.

## A plataforma mínima viável

O mesmo livro alerta para o fracasso oposto: um time de plataforma que constrói um grande sistema
interno antes que alguém tenha usado qualquer parte dele. A resposta é a **plataforma mínima viável**
(*thinnest viable platform*) — o menor conjunto de serviços, documentação e ferramentas que acelera
os outros times. Skelton e Pais lembram que ela pode ser tão fina quanto uma página de documentação
listando o jeito combinado de fazer algo.

A palavra que importa é *viável*. Uma página que diz "é assim que um serviço novo ganha logs,
alertas e um pipeline na Coreto" é uma plataforma se os times a seguem e ela lhes poupa tempo. Ela
pode crescer para um template, depois para uma ferramenta, cada passo dado porque o anterior foi
usado e mostrou onde está a próxima dor.

## O que mudou na Coreto

Rafaela Nunes assumiu o time de Plataforma quando ele ainda era uma fila. Os times pediam um banco de
dados, uma entrada de DNS ou um deploy em produção num canal de chat e esperavam. O time vivia
ocupado, e ninguém de fora saberia dizer para que ele servia além de atender pedidos.

Ela mudou três coisas, e cada uma é o que transforma um time de plataforma em time de produto:

1. **Ela descobriu o que doía antes de decidir o que construir.** Rafaela passou a primeira sprint
   com os outros seis times perguntando para onde ia o tempo deles, o mesmo movimento do Davi na
   aula 1 quando leu o registro de incidentes em vez de colecionar desejos.
2. **Ela tornou o resultado opcional.** O que a Plataforma construísse teria de conquistar os
   usuários, e assim o uso diria se funcionou.
3. **Ela mediu a adoção e perguntou aos times que não adotaram.** Um time que ficou de fora era um
   cliente com um motivo, e o motivo era o próximo item da lista dela.

A resposta à primeira pergunta surpreendeu o time. Os times não queriam mais infraestrutura.
Queriam parar de gastar os primeiros dias de cada serviço novo montando pipeline, logs e alertas,
copiando a configuração de outro time e consertando o que não servia. Esse é o assunto da próxima
seção.

## O trabalho de plataforma dentro da estratégia

O time de plataforma também tem lugar na estratégia, e a aula 1 já lhe deu um. A segunda ação da
estratégia da Coreto pede à Plataforma um teste de carga que reproduza o tráfego de uma abertura de
vendas. **Isso é um produto de plataforma com um cliente nomeado**: o time de Reservas, que precisa
dele para medir cada mudança no código de reserva de assentos. Ele é julgado como tudo o que a
Plataforma constrói — por o time de Reservas rodá-lo antes de cada mudança porque é o jeito mais
fácil de saber, e não porque uma regra manda.

| | plataforma como fila | plataforma como produto |
|---|---|---|
| o que é construído | o que o chamado mais barulhento pede | o que tira mais tempo dos outros times |
| como chega aos times | um pedido e uma espera | um serviço que eles usam sem pedir |
| como o sucesso é medido | chamados fechados | times que a escolheram, e o que deixaram de fazer |
| um time que vai para outro lado | alguém quebrando a regra | um cliente dizendo alguma coisa |
