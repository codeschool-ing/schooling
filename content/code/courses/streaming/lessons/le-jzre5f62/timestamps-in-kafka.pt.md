---
title: O timestamp dentro do Kafka, e o que o usa
version: 1
---

**O timestamp do registro não é enfeite: o Kafka o usa para achar registros por tempo e para decidir
quando apagá-los.** Os dois usos leem esse único campo e mais nada, então o que o produtor coloca ali
decide como eles se comportam.

## Quem define

Com `CreateTime`, o padrão, quem define é o produtor. Deixe de fora e o cliente escreve o presente do
próprio relógio no momento do `produce`, como fez o `tills.py`. Passe `timestamp=` em milissegundos e
ele escreve esse valor, como faz o `late_tills.py`: por padrão o momento do envio, com `--stamp sold`
o momento da venda. As duas escolhas se defendem. **Um produtor que carimba o tempo do evento faz o
timestamp do registro significar tempo do evento**, o que permite que toda ferramenta que lê
timestamps trabalhe em tempo do evento; um produtor que carimba o momento do envio mantém o timestamp
perto da ordem do log. Um tópico com `LogAppendTime` tira a escolha do produtor de vez.

## Achando um lugar pelo tempo

Cada segmento de uma partição tem um arquivo `.timeindex` ao lado do `.log`, que a lição 3 mostra no
disco: um mapa esparso de timestamps para offsets. O cliente o consulta com `offsets_for_times`, que a
lição 4 usa em Python. No shell, `kafka-get-offsets.sh --time` faz a mesma pergunta: o primeiro
offset cujo timestamp é igual ou posterior a um momento, dado em milissegundos.

Onde estava o tópico `late` à uma da tarde de 2 de março?

@@fence@@

A resposta é o primeiro registro **carimbado** às 13:00 ou depois, e em `late` o carimbo é a hora do
envio. Reler a partir desse offset lê tudo o que chegou depois das 13:00, e isso não é o mesmo que
toda venda depois das 13:00: as vendas da manhã de Natal estão todas depois dele, porque chegaram às
14:00. Agora o mesmo dia enviado de novo, com a hora da venda como carimbo:

@@fence@@

A mesma pergunta recebe o mesmo offset, e isso não é coincidência. Toda venda que chegou antes das
13:00 também aconteceu antes das 13:00, então, seja qual for o sentido do carimbo, o primeiro
registro às 13:00 ou depois é o mesmo. O que muda é o que vem depois dele. Pergunte ao `late-sold`
onde estão as vendas de Natal das onze horas:

@@fence@@

Carimbadas com as onze horas, em offsets bem depois do que a busca devolveu para a uma da tarde.
**Num tópico carimbado com o tempo do evento, os timestamps andam para trás onde quer que chegue um
evento atrasado**, e uma busca por tempo acha uma posição no log, não um conjunto de eventos: reler a
partir do offset das 13:00 lê a manhã de Natal, e começar um pouco antes só não perde nada dela por
sorte. O índice do Kafka lida com timestamps que andam para trás, e a resposta que ele dá continua
sendo "o primeiro registro carimbado neste momento ou depois", que é exatamente tão útil quanto a
ordem do log permite. A busca é a ferramenta certa para "reler o que entrou desde o incidente das
13:00", que é a pergunta que a lição 16 faz a ela.

## Apagando pelo tempo

A retenção da lição 3, `retention.ms`, sete dias por padrão, também é medida com o timestamp do
registro: um segmento é apagado quando o timestamp **mais novo** dele é mais antigo que o limite. Um
tópico de registros carimbados com 2 de março os perderia na primeira verificação de retenção,
poucos minutos depois de serem gravados, e o tópico pareceria esvaziado por alguém. É por isso que
`late` e `late-sold` foram criados com `retention.ms=-1`, que guarda tudo. O Kafka verifica a
retenção a cada cinco minutos por padrão, e essa espera não está nas transcrições. Ela foi testada
uma vez num broker separado, configurado para verificar a cada dez segundos: as 360 vendas de um
tópico com a retenção padrão sumiram na primeira verificação, o segmento ativo inclusive, e o offset
mais antigo dele virou 360.

Duas lições saem disso. **Um produtor que carimba o tempo do evento precisa contar com eventos mais
antigos que a retenção**, e esses somem rápido, do segmento mais novo tanto quanto dos antigos. E um
broker com o relógio errado apaga pela própria ideia do presente, o que é mais um motivo para os
brokers também manterem o relógio com NTP.
