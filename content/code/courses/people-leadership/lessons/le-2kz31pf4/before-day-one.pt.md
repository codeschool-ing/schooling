---
title: Antes do primeiro dia
version: 1
---

A integração começa no dia em que a proposta é aceita, não no dia em que a pessoa chega. **O que
acontece nas semanas entre um e outro decide se o primeiro dia é gasto trabalhando ou esperando**, e
se a pessoa nova chega já se sentindo esperada ou se perguntando se alguém lembrou dela.

## O intervalo

O Lucas aceitou na segunda semana de outubro e começou em meados de novembro, depois dos trinta dias de
aviso prévio. Um mês é tempo suficiente para preparar tudo, e tempo suficiente para esquecer dele por
completo. Na Caju, antes da Renata, pessoas engenheiras novas costumavam passar os dois primeiros dias
esperando um notebook, uma conta de e-mail e acesso ao código. São dois dias da primeira impressão de
alguém sobre a empresa gastos vendo outras pessoas trabalharem.

## A lista da Renata

A Renata mantém uma lista para cada contratação, e a percorre nas semanas antes de a pessoa chegar:

| quando | o quê |
|---|---|
| a semana do aceite | uma mensagem da Renata dando as boas-vindas e dizendo como vai ser a primeira semana |
| duas semanas antes | notebook pedido, contas solicitadas: e-mail, chat, repositório de código, o quadro de tarefas |
| uma semana antes | uma pessoa de referência escolhida e avisada; primeira tarefa pequena escolhida e descrita |
| a sexta-feira antes | uma mensagem curta da pessoa de referência se apresentando |
| o primeiro dia | tudo acima funcionando antes de ele chegar às 9:00 |

Nada disso é difícil. **Tudo depende de alguém lembrar**, e é por isso que é uma lista, e não um
hábito.

## A pessoa de referência

A pessoa de referência é alguém do time, não a gestora, que é o primeiro contato da pessoa nova para
qualquer coisa: onde ficam as coisas, como funciona o deploy, a quem perguntar sobre o código de
cobrança, se é normal os testes levarem nove minutos. A aula 13 descreveu a integração como trabalho de
cola, e o papel de referência é onde a maior parte dele cai.

A Renata escolheu a Paula para o Lucas, por três motivos. Ela era dona do serviço de lembretes que o
Lucas ia assumir, então era a pessoa de quem ele mais ia precisar de qualquer jeito. O registro da
contratação do Lucas dizia que a área mais fraca dele era explicar coisas para quem não é da
engenharia, e a Paula era a melhor do time nisso. E o papel de referência não era mais
automaticamente da Paula, desde o rodízio da aula 13: desta vez era a vez dela pela escala, o que
importava, porque queria dizer que ninguém estava supondo que ela faria.

**A pessoa de referência precisa de tempo para fazer isso.** A Renata tirou um terço do trabalho
planejado da Paula da sprint nas duas primeiras semanas do Lucas, e disse isso no planejamento. Uma
pessoa de referência de quem se espera integrar alguém além de uma carga cheia faz isso nos buracos, e
a pessoa nova aprende a parar de perguntar.

## A primeira tarefa, escolhida antes

A preparação isolada mais importante é o primeiro trabalho. A Renata o escolheu uma semana antes de o
Lucas chegar: um bug pequeno e real no serviço de lembretes, relatado por uma clínica, em que um
lembrete mostrava o horário da consulta no fuso errado para clínicas de Manaus. Ele era:

- **real**, então terminá-lo importaria para alguém;
- **pequeno**, algumas linhas depois de encontrado, então podia chegar à produção na primeira semana;
- **na área que ele ia assumir**, então ensinava o código em que ele ia passar meses;
- **descrito**, com como reproduzir e quem relatou, então ele podia começar sem uma explicação.

A próxima seção trata de por que importa tanto a primeira mudança chegar à produção, e de quão rápido
isso pode acontecer.
