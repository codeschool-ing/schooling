---
title: Uma tarefa diz o que fazer; um resultado diz o que precisa ser verdade
version: 1
---

Delegar é a primeira habilidade de gestão que uma gestora nova tenta usar, e a primeira tentativa
costuma ser entregar tarefas. **Uma tarefa diz a alguém o que fazer. Um resultado diz o que precisa
ser verdade quando a pessoa terminar, e deixa o fazer com ela.** A diferença parece de redação e
acaba decidindo se delegar economiza algum tempo da gestora.

## O mesmo trabalho, delegado duas vezes

No segundo mês a Renata precisava de alguém para cuidar de uma reclamação das clínicas: pacientes
estavam recebendo duas mensagens de lembrete para a mesma consulta. Ela passou para a Paula, e a
mensagem que rascunhou primeiro foi esta:

> Você pode pôr uma verificação no job de lembretes para ele pular consultas que já tiveram um
> lembrete enviado nas últimas 24 horas? Use a coluna `sent_at`. Deve ser uma mudança pequena.

Isso é uma tarefa. É precisa, e carrega o diagnóstico da Renata, o design da Renata e a estimativa
da Renata. Se qualquer um dos três estiver errado, a Paula vai construir a coisa errada do jeito
certo, ou voltar com perguntas que só a Renata sabe responder. **A Renata ficou com o raciocínio e
entregou a digitação.**

Ela apagou a mensagem e escreveu esta:

> As clínicas estão relatando que alguns pacientes recebem dois lembretes para uma consulta, e duas
> delas disseram que agora os pacientes ignoram as mensagens. Até o fim da semana que vem eu queria
> que toda consulta gerasse exatamente um lembrete, e uma forma de a gente saber se isso deixar de
> ser verdade. Não olhei a causa. A Helena sabe quais clínicas reclamaram.

Isso é um resultado. Diz o que precisa ser verdade (um lembrete por consulta), como alguém vai saber
(uma forma de detectar), por que importa (pacientes ignorando mensagens) e até quando. Não diz nada
sobre o job de lembretes, a coluna ou o tamanho da mudança.

## O que a Paula encontrou

A causa não era a que a Renata tinha imaginado. As duplicatas vinham de clínicas que remarcavam uma
consulta: a antiga era cancelada e uma nova era criada, e as duas tinham lembretes na fila. Uma
verificação de `sent_at` em vinte e quatro horas pegaria parte delas e perderia todos os casos em que
a remarcação acontecia mais de um dia antes da consulta. A Paula corrigiu onde as remarcações eram
tratadas e acrescentou um alerta para envios duplicados por dia.

**A versão como tarefa teria ido para produção, passado na revisão e deixado mais ou menos metade das
duplicatas no lugar**, e as clínicas teriam reclamado de novo em um mês. Ninguém teria culpa, porque
a Paula teria feito exatamente o que foi pedido.

## Por que resultados são mais difíceis de escrever

Escrever o resultado levou mais tempo para a Renata do que escrever a tarefa, e esse é o padrão
geral. Para declarar um resultado você precisa saber o que de fato quer, o que muitas vezes é menos
claro do que a primeira correção que vem à cabeça. "Pular lembretes recentes" é uma solução. "Um
lembrete por consulta, e a gente saberia se não" é aquilo para o que a solução servia.

Três testes pegam uma tarefa disfarçada de resultado:

- **Ela nomeia um mecanismo?** Uma tabela, uma coluna, uma biblioteca, uma tela. Se sim, o design já
  foi decidido pela pessoa.
- **Dá para fazer exatamente como está escrito e ainda falhar?** A verificação de `sent_at` dava.
  "Exatamente um lembrete por consulta" não dá.
- **A pessoa precisaria voltar até você se a primeira ideia não funcionasse?** Com uma tarefa, sim,
  porque o plano era seu. Com um resultado, ela tenta a próxima ideia.

## Quando uma tarefa é a coisa certa

Nada disso torna tarefas erradas. Uma tarefa é o jeito certo de passar um trabalho quando a pessoa
está aprendendo e precisa dos passos, quando os passos são de fato fixos (uma mudança regulatória com
uma única implementação correta) ou quando é pequeno o bastante para que explicar o resultado custe
mais do que fazer. "Ponha o novo número de escalonamento no documento de plantão" é uma tarefa
perfeitamente boa, e transformá-la em resultado desperdiçaria o tempo de todo mundo.

O que dá errado é tratar todo trabalho como tarefa por padrão, porque é assim que a gestora pensa
nele. **A gestora vira então o gargalo de toda decisão de design do time**, que é o oposto daquilo
para o que delegar servia. A próxima seção trata do que precisa ir junto com um resultado para que a
pessoa possa de fato ser dona dele.
