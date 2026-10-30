---
title: O que cada nível custa, em unidades, espera e regiões
version: 1
---

**Um nível mais forte não é uma versão mais lenta de um mais fraco; é uma quantidade diferente de
trabalho por requisição**, e o Cosmos DB cobra por ela em três moedas: unidades de requisição,
latência e as regiões que uma conta pode ter. Esta seção é ensinada a partir da documentação da
Microsoft e não foi executada, porque o emulador cobra uma unidade de requisição por tudo e tem uma
cópia e nenhuma região.

## Unidades de requisição: leituras nos dois níveis do topo custam cerca do dobro

**Uma unidade de requisição é a moeda em que o Cosmos DB cobra o trabalho dele**, e a lição 13 é
sobre ela. Aqui só um fato importa: a documentação da Microsoft põe as unidades de requisição de uma
leitura em forte ou em desatualização limitada em mais ou menos o dobro das da mesma leitura em
sessão, prefixo consistente ou eventual. O motivo são as cópias. Uma leitura nos dois níveis fortes é
respondida por duas réplicas que precisam concordar, um quórum minoritário, e os outros três níveis
são respondidos por uma. **Escritas custam o mesmo em todo nível**, porque toda escrita é confirmada
na maioria das cópias seja qual for o nível.

Ponha um número nisso. A página de produto da Quitanda lê um documento de produto de cerca de 1 KB,
e no pico da noite é pedida 3.000 vezes por segundo. A lição 13 mostra que uma leitura pontual de
1 KB custa uma unidade de requisição:

| nível | unidades de requisição por segundo, só para a página |
|---|---|
| sessão, prefixo consistente, eventual | 3.000 |
| forte, desatualização limitada | cerca de 6.000 |

**A vazão é reservada e cobrada por unidade de requisição por segundo**, então a segunda linha é mais
ou menos o dobro da conta para a mesma página, a cada hora em que a reserva existe. Um catálogo que
muda algumas vezes por dia não compra nada com essas 3.000 unidades a mais.

## Latência: o forte espera a região mais distante

Dentro de uma região, o acordo de nível de serviço da Microsoft promete leituras e escritas abaixo de
10 milissegundos no percentil 99, em todo nível. **Entre regiões, o forte muda as escritas.** Uma
escrita em forte só é confirmada quando todas as regiões a têm, então a latência dela inclui a ida e
volta até a região mais distante: a documentação dá o dobro dessa ida e volta mais 10 milissegundos,
no percentil 99. Entre São Paulo e uma região nos Estados Unidos, isso é uma espera em toda escrita
que nenhum índice ou chave de partição remove. Desatualização limitada, sessão, prefixo consistente e
eventual confirmam na região local e replicam depois.

## Regiões: forte e vários escritores não se misturam

Uma conta pode aceitar escritas numa região ou em todas. **Com escritas em várias regiões, o forte
não é oferecido**, porque duas regiões aceitando escritas ao mesmo tempo não conseguem ambas ver o
valor mais recente sem esperar uma pela outra, que é a latência acima, em toda escrita, nos dois
sentidos. Escritas em várias regiões trazem também conflitos: duas regiões mudam o mesmo pedido no
mesmo segundo, e o Cosmos DB guarda uma versão segundo uma política que você escolhe, por padrão a de
carimbo de tempo mais recente.

## O que uma queda regional pode perder

O nível decide também quanto um failover pode perder quando uma região inteira cai com escritas que
ainda não tinham atravessado. Para uma conta com uma região de escrita, a documentação da Microsoft
dá:

| nível | escritas que podem se perder quando a região de escrita se perde |
|---|---|
| forte | nenhuma |
| desatualização limitada | no máximo as K escritas ou os T segundos do limite |
| sessão, prefixo consistente, eventual | até uns 15 minutos |

É o mesmo formato do armazenamento com redundância geográfica da lição 1, e pelo mesmo motivo:
replicação entre regiões é assíncrona a menos que alguma coisa espere por ela, e o forte é o nível
que espera.

## A escolha da Quitanda

| dado | nível | por quê |
|---|---|---|
| pedidos | sessão | o cliente precisa ver o próprio pagamento; ninguém mais precisa dele naquele instante |
| catálogo de produtos | eventual, pedido pelo cliente da página | muda pouco, é lido o tempo todo, um segundo de idade não faz mal |
| estoque a reservar | sessão, com escrita condicional | o nível não impede dois compradores de levar o último item |

**A última linha é a que as pessoas erram.** Consistência forte não deixa seguro *ler, subtrair um,
gravar*: dois clientes podem ambos ler 1 em forte, ambos gravar 0, e dois clientes compraram o último
maço de coentro. O que deixa seguro é a escrita condicional que a lição 2 usou num blob: gravar só se
o ETag do item ainda for o que você leu, e tentar de novo se não for. Isso funciona em todo nível,
não custa nada a mais, e é a mesma ideia do token de sessão: uma promessa mantida levando uma string
de volta ao servidor.

A conta em si fica em sessão, só em `brazilsouth`, para que os dados fiquem no Brasil e nada pague a
ida e volta até outro país.
