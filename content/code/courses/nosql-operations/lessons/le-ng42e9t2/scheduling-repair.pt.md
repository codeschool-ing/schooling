---
title: Agendar o repair, e o que acontece quando ele para
version: 1
---

A aula 18 terminou numa regra, e esta aula mostrou a maquinaria por trás dela. **Toda réplica de toda
tabela precisa passar por repair ao menos uma vez a cada `gc_grace_seconds`**, dez dias por padrão, ou
um delete que perdeu uma réplica pode voltar. Hints e read repair estreitam as brechas; só o repair as
fecha, e só se rodar. O repair não é algo que o Cassandra 5.0.9 roda por você:

```
ana@vm:~$ docker logs c1 2>&1 | grep -i "auto-repair"
INFO  [main] 2026-10-10T20:19:57,167 StorageService.java:1466 - Auto-repair service is disabled via JVM property, skipping setup
```

Essa linha, da inicialização do `c1`, é o nó dizendo que o repair automático embutido está desligado,
e ele fica desligado a menos que alguém o ligue. Na prática o calendário é trabalho de alguém.

## Um calendário que cumpre a regra

O `nodetool repair` repara os intervalos dos quais o nó guarda uma cópia, o que com três cópias é três
vezes a parte do próprio nó; rodado em todo nó, cada intervalo é reparado três vezes. **O `nodetool
repair -pr`, primary range, repara só os intervalos dos quais o nó é a primeira réplica**, então
rodá-lo uma vez em cada nó cobre cada intervalo exatamente uma vez. Ele não foi rodado nesta aula, cujo
cluster tem três nós e foi reparado inteiro. É o formato da maioria dos calendários:

- rodar `nodetool repair -pr` num nó por vez, nunca em todos juntos, porque um repair lê muitos dados
  e transmite entre nós;
- dar a volta em todos os nós num período folgadamente menor que `gc_grace_seconds`: sete dias para
  os dez do padrão deixam espaço para uma execução que falhou ser notada e repetida;
- alertar quando o último repair bem-sucedido de um nó for mais velho que esse período, não só quando
  um repair falha, porque um repair que nunca começa nunca falha.

Com três nós isso é uma linha de cron por nó, em dias diferentes. Com trinta é trabalho para uma
ferramenta. O **Cassandra Reaper** é a ferramenta de código aberto que a maioria das equipes usa: ele
divide os intervalos de cada nó em segmentos pequenos, repara alguns por vez num ritmo que você define,
tenta de novo as falhas e mostra o último repair de cada tabela numa página web. Ele não foi instalado
para este curso; roda ao lado do cluster como serviço próprio.

## Quando o repair para

A falha é silenciosa, e é isso que a torna perigosa. Um job de repair quebra depois de uma
atualização, ou o repair de um nó vive estourando o tempo, ou a pessoa que o rodava à mão sai da
empresa. Nada dá erro na aplicação. A cada semana, porém:

1. As réplicas se afastam mais, por escritas descartadas e nós que ficaram fora além da janela de
   hints. Leituras em `QUORUM` continuam respondendo certo, graças ao read repair, então ninguém nota.
2. Passam dez dias, e lápides mais velhas que `gc_grace_seconds` são expurgadas pela compactação nos
   nós que as tinham.
3. Todo delete que uma réplica atrasada perdeu agora não tem mais volta. O próximo repair, ou a
   próxima leitura em `ALL`, traz as linhas apagadas de volta, como a aula 18 mostrou na lista de
   desejos.

Então o custo de um repair parado não é pago no dia em que ele para. **É pago no dia em que alguém o
conserta**, quando o primeiro repair bem-sucedido em semanas copia com toda a diligência cada linha
esquecida de volta. Se o repair não roda há mais que `gc_grace_seconds`, trate o cluster como
possivelmente guardando dados ressuscitados: confira as tabelas em que deletes importam, e veja o
conselho da aula 18 para nós que ficaram fora esse tempo todo.

## Os três, lado a lado

| mecanismo | quando roda | o que cobre | o que não cobre |
| --- | --- | --- | --- |
| hinted handoff | quando volta um nó que ficou fora menos que `max_hint_window` | escritas que o coordenador viu enquanto o nó estava fora | quedas mais longas, coordenadores perdidos, escritas descartadas por uma réplica de pé |
| read repair | durante uma leitura que pergunta a mais de uma réplica | as linhas lidas | linhas que ninguém lê, leituras em `ONE` |
| repair | quando alguém, ou uma ferramenta, o roda | toda linha de todo intervalo reparado | nada, se rodar dentro de `gc_grace_seconds` |

Os dois primeiros deixam o cluster quase certo quase sempre. O terceiro é o que transforma o "quase"
numa promessa. A aula 20 trata dos números que dizem que um cluster precisa de atenção antes que um
cliente perceba.
