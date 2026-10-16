---
title: Reconhecê-las antes de irem para produção
version: 1
---

Ninguém escala uma decisão que não reconhece como decisão. A reserva de assento chegou ao backlog do
Mateus como uma correção de desempenho, e teria ido para produção assim se o Davi não tivesse lido o
chamado e perguntado quem perde um assento. **A habilidade é reconhecer**, e ela se treina, porque
essas decisões trazem as mesmas marcas toda vez.

## As marcas

Cinco sinais, e qualquer um deles basta para parar e perguntar:

1. **Há um número que um usuário sentiria.** Um timeout, uma duração de cache, um prazo de retenção,
   um limite de quantos ingressos um comprador pode segurar. Números dentro do sistema que ninguém de
   fora encontra são da engenharia; números que definem quanto tempo alguém espera ou o que lhe é
   mostrado não são.
2. **A falha seria visível para um cliente ou uma casa de shows.** Pergunte o que acontece quando a
   escolha dá errado. Se a resposta é "uma consulta lenta", é técnica. Se a resposta é "um comprador
   vê um assento que já se foi", não é.
3. **As duas opções são tecnicamente corretas.** Quando os engenheiros da sala concordam que qualquer
   uma funcionaria e ainda assim discordam sobre qual escolher, a discordância é sobre quem arca com
   um custo, e essa é uma pergunta que a engenharia não resolve sendo melhor em engenharia.
4. **Alguém diz "depende do que a gente quer".** Toda revisão de design já ouviu isso. A frase admite
   que a decisão gira em torno de um objetivo, e os donos do objetivo não estão na sala.
5. **Um padrão está para ser aceito.** O timeout de um framework, a duração de cache de uma
   biblioteca, a configuração de retenção de um serviço de nuvem. Ninguém o escolheu, e ainda assim é
   uma escolha.

A quinta é a que pegou a Coreto. O cache de disponibilidade do Catálogo tinha uma duração que vinha
do padrão da biblioteca de cache, e ninguém a tinha definido de propósito. Isso veio à tona quando um
comprador reclamou de ter visto um assento que estava vendido, e o engenheiro que rastreou a
reclamação encontrou uma decisão que ninguém lembrava de ter tomado, porque ninguém tinha.

## A lista da Coreto

O Davi percorreu os backlogs dos sete times com as cinco marcas e voltou com uma lista curta. A
maioria dos itens era claramente da engenharia. Alguns não eram:

| decisão | como foi levantada | a marca que carrega | quem deveria decidir junto com a engenharia |
|---|---|---|---|
| duração da reserva de assento | uma correção para a disputa por travas | um número que o comprador sente | produto, com a visão das casas |
| duração do cache de disponibilidade | um padrão de biblioteca | um padrão aceito | produto |
| retenção dos dados do comprador | um job de limpeza de armazenamento | uma falha que comprador e regulador veem | produto e jurídico |
| meta de disponibilidade do checkout | um limiar de alerta | as duas opções corretas; "depende do que a gente quer" | produto e a CTO |
| leitura offline na porta | uma estratégia de sincronização da Bilheteria | uma falha que a casa vê | produto, Bilheteria e as casas |

A última coluna importa tanto quanto a primeira. **O sentido de reconhecer uma decisão disfarçada é
pôr as pessoas certas ao lado dela**, e a engenharia continua na sala: é a única parte que sabe
quanto cada opção custa para construir e o que ela faz sob carga.

## O erro oposto

Um time que aprende esta lição do jeito errado começa a mandar tudo para produto. Que índice de banco,
que biblioteca de filas, como dividir um módulo, que framework de testes: nada disso carrega qualquer uma das cinco marcas. Pedir a opinião de produto sobre isso desperdiça o tempo de todos, e ensina a produto que a engenharia não consegue decidir o próprio trabalho.

As marcas também defendem a autonomia da engenharia. Uma decisão sem elas é da engenharia, e dizer
isso fica mais fácil quando existe uma regra clara para as que não são. **O teste corta para os dois
lados**: manda a reserva de assento para a Júlia e mantém a escolha do índice longe dela.

| carrega uma marca | não carrega nenhuma |
|---|---|
| por quanto tempo um assento fica reservado | que índice a tabela de reservas ganha |
| quão desatualizado o mapa de assentos pode estar | que biblioteca de cache o guarda |
| por quanto tempo os dados do comprador são guardados | que mecanismo de armazenamento os guarda |
| o que a Bilheteria faz quando a rede cai | como a cópia local da Bilheteria é serializada |

Cada linha da direita é a implementação da linha da esquerda, e esse é o formato de sempre: uma
decisão de produto fica em cima, e as decisões de engenharia embaixo dela são da engenharia depois
que a de cima é tomada.

## Onde procurar

Decisões disfarçadas se juntam em poucos lugares, e um líder pode conferi-los de propósito. Arquivos
de configuração, onde moram os padrões. Pull requests cuja descrição diz "ajustar" ou "calibrar".
Revisões de incidente, onde a correção proposta para a próxima vez muitas vezes é um novo limite ou
timeout. E qualquer documento de design com uma seção chamada "trade-offs", porque um trade-off com
um usuário de um dos lados é a definição do assunto desta aula. A aula 17 dá a essas decisões um
lugar onde ser registradas depois de tomadas.
