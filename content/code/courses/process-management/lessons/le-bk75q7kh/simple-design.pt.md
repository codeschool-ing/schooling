---
title: Design simples, refatoração e o arquiteto
version: 1
---

O conselho de design do XP é curto e causou mais discussão com arquitetos do que qualquer outra coisa do ágil. Ele diz: **construa o design mais simples que funcione para as histórias que você tem hoje**, e mude-o quando a próxima história precisar de algo diferente. Não construa para requisitos que você está adivinhando.

## As quatro regras

Beck enunciou o design simples como quatro regras, em ordem de prioridade. O código:

1. passa em todos os testes;
2. revela sua intenção, para quem lê saber para que serve;
3. não tem duplicação;
4. tem o menor número de elementos — classes, funções, camadas — compatível com as três primeiras.

O lema que acompanha as regras é **YAGNI**, *you aren't gonna need it* (você não vai precisar disso): a arquitetura de plug-ins configurável para os três provedores de pagamento que a empresa talvez um dia aceite não é construída enquanto houver um provedor. Se o segundo chegar, o design muda nessa hora.

## A refatoração torna isso seguro

O design simples só funciona se mudar o design depois for barato. A **refatoração** — melhorar a estrutura do código sem mudar o que ele faz, em passos pequenos, com os testes passando depois de cada um — é a prática que o torna barato. O livro de Martin Fowler com esse nome, de 1999, catalogou os passos. Sem testes, refatorar é só editar, e ninguém se atreve; com eles, é o terceiro passo de toda volta do ciclo do teste primeiro.

## Onde um arquiteto discorda, e tem razão

O YAGNI é um argumento sobre decisões baratas de reverter. Para essas ele está certo: generalidade especulativa custa tempo agora, e em geral o palpite estava errado. Algumas decisões não são baratas de reverter, e a última seção da aula 2 as nomeou — o armazenamento de dados, as fronteiras entre serviços, como a identidade funciona. Um time que aplica o YAGNI a essas constrói a coisa mais simples para uma clínica e descobre, na quadragésima clínica, que os dados de todas estão numa tabela sem jeito de separá-los.

A conciliação a que a maioria dos praticantes chegou é **separar o reversível do irreversível**. Decisões reversíveis são tomadas tarde e de forma simples, como o XP diz. As irreversíveis recebem reflexão deliberada cedo, muitas vezes um spike, e um registro escrito do porquê. Isso não contradiz o XP; é a mesma economia — gastar esforço onde uma mudança tardia seria cara — aplicada às decisões em que ela é.

## O que as práticas precisam da gestão

Cada prática desta aula custa algo visível e devolve algo menos visível. O par mostra duas pessoas numa tarefa; os testes mostram tempo gasto em código que o usuário nunca vê; a refatoração mostra uma semana em que as funcionalidades não mudaram. Um gestor que mede só a produção visível vai cortar as três, e a curva do custo da mudança vai subir de novo, devagar, até uma mudança tardia custar o que a aula 1 disse que custava antes. Reconhecer essa troca, e defendê-la, é parte do que um líder técnico faz. A aula 14 dá nome ao custo: dívida técnica.
