---
title: O cutover, e quanto custa a migração
version: 1
---

**O cutover é o minuto em que as aplicações param de escrever no banco antigo e começam a escrever no
novo**, e tudo antes dele existe para fazer esse minuto curto e sem graça. Com uma tarefa
full-load-and-cdc rodando, o destino está segundos atrás da origem, então a parada não são as horas da
cópia, e sim o tempo de parar quem escreve, deixar as últimas mudanças atravessarem, conferir, e
ligar quem escreve contra o destino.

**A ordem é a parte que as pessoas erram**, e errar para qualquer lado perde dados: troque as
aplicações antes de as últimas mudanças atravessarem e essas mudanças se perdem; deixe as aplicações
escreverem nos dois e os dois bancos discordam.

1. **Rode a tarefa até ela ficar quieta.** A carga completa terminou, a validação informa todas as
   tabelas como validadas, e a latência de CDC que o DMS informa é de alguns segundos.
2. **Pare quem escreve na origem.** Ponha a loja em manutenção, ou tire do usuário da aplicação o
   direito de escrever, para que nada novo chegue ao banco antigo.
3. **Espere as últimas mudanças atravessarem**, até a latência chegar a zero e as contagens e os
   totais das tabelas importantes baterem entre os dois lados.
4. **Aponte as aplicações para o destino** e ligue-as.
5. **Pare a tarefa, e mantenha a origem só leitura** enquanto um retorno puder ser desejado. O banco
   antigo é o backup do primeiro dia.
6. **Apague o slot de replicação na origem**, o aviso da seção anterior, quando a tarefa tiver ido
   embora de vez. Um slot esquecido depois de um cutover é o jeito clássico de encher um disco um mês
   depois.

No primeiro projeto da Quitanda o destino é o lake, e não um banco novo, então não há aplicação para
mudar de lugar: a tarefa simplesmente roda, e o cutover é o dia em que os relatórios param de ler o
PostgreSQL antigo. A mesma ordem vale para o dia em que a própria loja for para o RDS, assunto da lição
6, com um endpoint de banco como destino em vez do S3.

## Quanto custa

```
ana@laptop:~/aws$ python3 prices.py dms
AWS public price list, sa-east-1, USD, excluding tax

DMS, USD per hour
  replication instance dms.t3.medium                    0.15100  hour
  replication instance dms.c5.large                     0.31000  hour
  replication instance dms.r6i.large                    0.56000  hour
  Serverless, per DCU-hour                              0.18471  DCU-hour
```

**Uma instância de replicação é cobrada por toda hora em que existe, como um ambiente do MWAA na lição
25, e ao contrário dele foi feita para ser temporária.** Uma migração que roda duas semanas numa
`dms.c5.large` custa 0.31000 × 24 × 14 = 104.16 USD, e a mesma instância esquecida por um ano depois
do cutover custa 0.31000 × 8760 = 2715.60. Uma alimentação permanente do lake, que é o que a primeira
tarefa da Quitanda é, paga a instância todo mês: 0.31000 × 730 = 226.30 numa `dms.c5.large`, ou
0.15100 × 730 = 110.23 numa `dms.t3.medium`, se ela der conta do ritmo das mudanças.

**O Serverless põe preço na capacidade usada, e não na instância possuída.** A 0.18471 por DCU-hora,
uma alimentação que fica em 2 DCUs o mês todo custa 2 × 0.18471 × 730 = 269.68, mais que a
`dms.c5.large` no mesmo mês. Uma migração que precisa de 16 DCUs nos dois dias da carga completa e de
2 no resto da quinzena custa 16 × 0.18471 × 48 + 2 × 0.18471 × 288 = 141.86 + 106.39 = 248.25. O
Serverless vence quando a carga é desigual e ninguém sabe o tamanho dela de antemão; uma instância
vence quando a carga é constante e alguém a mediu. Nenhuma das linhas inclui o lado da origem: o
caminho de rede a partir do rack, e as leituras a mais que a validação faz.

**O custo que mais importa não está na tabela.** Uma migração cujo cutover dá errado custa os pedidos
da loja pelo tempo que levar para alguém perceber, e os passos acima, com a validação ligada, saem mais
baratos que qualquer classe de instância.
