---
title: O que o sistema permite, e quem decide quando
version: 1
---

**Um app não roda em segundo plano quando quer; ele pede, e o sistema decide quando, por quanto
tempo e se vai rodar.** A crença que isto substitui é a de que uma sincronização se agenda como um
cronômetro: a cada quinze minutos, em ponto. Nem o Android nem o iOS oferecem isso. Os dois tratam
a bateria como da pessoa, não do app, e os dois adiam, encurtam ou pulam uma execução em segundo
plano para protegê-la.

*Tudo nesta aula sobre Android e iOS vem da documentação de cada plataforma e não foi rodado para
este curso; a última seção é um programa que você roda no Node.*

## Android

- **Doze.** Quando o celular está fora da tomada, parado e com a tela apagada por um tempo, o
  sistema suspende o acesso à rede dos apps e adia os trabalhos e alarmes deles. Ele acorda por
  pouco tempo em **janelas de manutenção** para deixar o trabalho adiado rodar, e as janelas ficam
  mais espaçadas quanto mais tempo o celular fica ocioso.
- **Buckets do App Standby.** A partir do Android 9, todo app fica num balde escolhido por quão
  recente e quão frequente é o uso: *active*, *working set*, *frequent*, *rare* e, a partir do
  Android 12, *restricted*. Quanto mais raro o balde, menos vezes os trabalhos do app podem rodar. Um
  planner aberto toda noite roda bastante; um aberto uma vez por mês quase não roda.
- **Um forçar parada** na página de configurações do app cancela o trabalho agendado até a pessoa
  abrir o app de novo. Alguns fabricantes acrescentam gerenciadores de bateria próprios que param
  apps com mais facilidade que o próprio Android, então o mesmo app pode se comportar diferente em
  duas marcas de celular.

## iOS

- **Sem agenda.** Um app pede uma atualização *não antes de* um horário, e o sistema escolhe o
  momento pelo que aprendeu: quando a pessoa costuma abrir o app, a bateria, a rede. Pode ser vinte
  minutos depois ou na manhã seguinte.
- **Dois tipos de tarefa.** Uma tarefa de **atualização do app** (*app refresh*) ganha uns trinta
  segundos. Uma tarefa de **processamento** pode rodar por minutos, e em geral roda quando o celular
  está ocioso e carregando, muitas vezes de madrugada.
- **Arrastar o app para fora** do seletor de apps diz ao iOS que a pessoa quer o app parado: nenhuma
  abertura em segundo plano até ela abri-lo de novo. Desligar a Atualização em Segundo Plano nos
  Ajustes, ou o Modo de Pouca Energia, tem o mesmo efeito para as tarefas de atualização.

## O que isso significa para o planner

Três consequências, e o resto da aula se apoia nelas.

| o que o sistema faz | o que a sincronização precisa conseguir fazer |
|---|---|
| roda tarde, ou não roda | nunca ser o único caminho: sincronizar também quando o app abre e quando a pessoa salva |
| dá segundos a ela, depois a para | parar a qualquer momento sem perder o que já fez |
| mata o processo sem aviso | retomar na próxima vez de onde parou, a partir do que está no disco |

**A sincronização em segundo plano é um extra, nunca o mecanismo.** A caixa de saída da aula 8
esvazia sempre que o app está aberto e online; uma execução em segundo plano só quer dizer que a
fila estava mais curta quando a pessoa olhou. Um planner que mostrasse dado velho até o sistema
resolver agendá-lo estaria quebrado em todo celular em Doze.
