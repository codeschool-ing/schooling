---
title: O que merece um alarme
version: 1
---

**Um alerta é a promessa de acordar alguém, então ele só deve disparar quando alguém tiver de
agir.** Um stream produz centenas de números, e a maioria serve para olhar depois que algo deu
errado. Os poucos que merecem alarme são os que dizem que uma promessa está para ser quebrada: a
saída está ficando velha, dados estão para se perder, ou o cluster tem menos margem do que aquela
com que foi construído.

## Lag: alarme pela tendência e pela idade, não pelo tamanho

A regra tentadora é *lag acima de 1000*. Ela dispara em todo pico, quando os caixas registram uma
manhã de sábado e o consumidor alcança o fim dez minutos depois sozinho, e as pessoas aprendem a
ignorá-la. A seção de lag mostrou a forma que importa: lag que cresce enquanto o produtor está
ocupado e encolhe quando ele está calmo é um consumidor fazendo o trabalho dele.

Duas regras funcionam melhor:

- **Lag em tempo acima do que a saída promete.** Se o estoque do site pode ter um minuto de atraso,
  alerte com alguns minutos de lag em tempo, o número que o `lag_seconds.py` imprimiu. Ele quer dizer
  que a promessa já foi quebrada, seja qual for a contagem.
- **Lag que não para de crescer.** Se o lag cresceu em toda amostra dos últimos quinze minutos, o
  consumidor é mais lento que o produtor, e esperar não vai resolver. Isso pega o declínio lento
  antes da regra da idade.

E uma que é fácil esquecer: **um grupo de consumidores sem membros**. Um consumidor que caiu não tem
lag para crescer até chegarem vendas, e de madrugada não chega nenhuma; a ausência dele é o sinal.

## Replicação: partições sub-replicadas e offline

Num cluster de três nós, com um tópico cujas partições têm três cópias:

```
ubuntu@stream:~/work$ kafka-topics.sh --bootstrap-server localhost:9092 --create --topic sales --partitions 3 --replication-factor 3
```

`--under-replicated-partitions` lista as partições com menos cópias em sincronia do que deveriam ter,
e **não imprimir nada é a resposta saudável**. Agora um nó morre, como morreu de propósito na lição
5, e alguns segundos depois:

```
ubuntu@stream:~/work$ ./cluster.sh kill 3
```

Toda partição perdeu uma cópia, e todas continuam sendo servidas: `--unavailable-partitions` lista
as que não têm líder nenhum, e não imprimiu nada. **Sub-replicada é um aviso: o cluster está
trabalhando com menos margem do que aquela com que foi construído**, e mais uma falha nas mesmas
partições perde dados ou disponibilidade. Uma partição **offline**, sem líder, é a emergência:
ninguém consegue escrever nela nem ler dela. Essa não foi provocada aqui, porque neste cluster
perder os dois nós necessários também perde a maioria dos controllers, e as ferramentas param de
responder de vez. Quando o nó volta, a lista se esvazia de novo:

```
ubuntu@stream:~/work$ ./cluster.sh start 3
```

## Disco: o que não se recupera sozinho

Um broker com o disco cheio para de aceitar escritas nas partições que estão nele. Diferente do lag,
nada o esvazia sozinho; a retenção apaga segmentos antigos no ritmo dela, não no do disco. Vigie o
espaço livre do volume que guarda os dados, e alerte bem antes de acabar:

```
ubuntu@stream:~/work$ df -h ~/kafka-data
```

Neste laboratório os dados são minúsculos e o disco é dividido com tudo o mais da máquina. Num
broker de verdade o diretório de log tem um volume próprio, e o tamanho dele é aritmética de
retenção, que é o assunto da lição 17.

## Uma lista curta

| alerte por | porque |
|---|---|
| lag em tempo acima da promessa da saída | a promessa está quebrada agora |
| lag crescendo por um período sustentado | o consumidor não acompanha, e não vai acompanhar sozinho |
| um grupo sem membros | um consumidor parado não tem lag até chegarem dados |
| partições sub-replicadas, por mais de alguns minutos | o cluster está a uma falha de perder dados |
| qualquer partição offline | escritas e leituras nela estão falhando agora |
| disco livre num volume de log | um disco cheio para as escritas e não se recupera sozinho |
| mensagens chegando num tópico de cartas mortas | alguém precisa lê-las |

Todo o resto, as taxas de requisição, as contagens de rebalanceamento, os bytes de entrada e de
saída, vai para um painel, para o dia em que algo desta lista disparar. Num cluster de verdade esses
números vêm das métricas dos brokers e dos clientes, coletadas pelo sistema de monitoramento que a
empresa usa; os comandos daqui são as mesmas perguntas feitas à mão.
