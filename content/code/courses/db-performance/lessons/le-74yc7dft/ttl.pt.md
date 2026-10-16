---
title: O TTL, que é uma promessa sobre o quanto a resposta pode estar velha
version: 1
---

Todo valor no cache era verdadeiro quando foi guardado. O **TTL**, time to live, é por quanto tempo
ele pode continuar sendo servido depois disso, siga verdadeiro ou não. Costuma ser escolhido como um
ajuste de desempenho, "longo o bastante para uma boa taxa de acerto", e esse é o jeito invertido.
**Um TTL é o tempo máximo em que um usuário pode ver algo que já não é assim**, e deve ser escolhido
perguntando quão velha uma resposta a tela pode se dar ao luxo de mostrar.

## Olhando a janela

Jogue fora o painel guardado do vendedor 7, leia-o, faça um pedido para o vendedor 7 e leia de novo:

```
ana@vm:~$ redis-cli DEL dashboard:7
1
ana@vm:~$ python3 dashboard.py 7
seller 7: 91 orders since 2025-12-01, from the database; expires in 60 s
ana@vm:~$ psql market -c "INSERT INTO orders (customer_id, seller_id, placed_at, status, total_cents) VALUES (42, 7, now(), 'pending', 1990)"
INSERT 0 1
Time: 6.971 ms
ana@vm:~$ python3 dashboard.py 7
seller 7: 91 orders since 2025-12-01, from the cache; expires in 60 s
```

A primeira leitura foi ao banco e guardou **91** pedidos por sessenta segundos. O pedido novo foi
confirmado. A segunda leitura veio do cache e disse 91 de novo: certo um instante atrás, errado
agora, e nada na saída avisa. Pergunte ao Redis quanto tempo o valor ainda tem, e ao banco o que ele
guarda:

```
ana@vm:~$ redis-cli TTL dashboard:7
60
ana@vm:~$ psql market -c "SELECT count(*) FROM orders WHERE seller_id = 7 AND placed_at >= '2025-12-01'"
 count 
-------
    92
(1 row)

Time: 6.418 ms
```

O `TTL` responde em segundos, **60**, porque o valor tinha sido guardado havia menos de um segundo. O
banco diz **92**. No minuto seguinte todo pedido de painel do vendedor 7 recebe o 91, rápido. Um
minuto depois a chave expirou, a leitura seguinte falha no cache, e o painel se atualiza:

```
ana@vm:~$ python3 dashboard.py 7
seller 7: 92 orders since 2025-12-01, from the database; expires in 60 s
```

Nada deu errado nessa sequência. O cache fez exatamente o que o cache-aside promete, e a promessa
inclui esse minuto. O pedido foi feito no começo do TTL, que é o pior caso. Um valor guardado logo
antes de uma mudança fica errado durante o TTL inteiro, um guardado logo depois nunca fica, e em
média uma mudança fica invisível por metade dele.

## Escolhendo

Pergunte de cada chave quão velha a tela pode estar, e diante de quem:

| o que está em cache | quão velho pode estar | um TTL que serve |
|---|---|---|
| a descrição e as fotos de um produto | horas: mudam quando um vendedor as edita | uma hora, com invalidação na edição |
| o painel de um vendedor | um minuto: o vendedor recarrega para ver pedidos novos | 30 a 60 segundos |
| a contagem da tela de operações | segundos: as pessoas agem com base nela | alguns segundos, ou nenhum cache |
| a lista de pedidos do próprio cliente, logo depois de comprar | nada: ele acabou de fazer o pedido | não sirva de um cache tão velho |

A última linha é de novo o ler a própria escrita da aula 20, e tem as mesmas respostas: ler da fonte
para aquele usuário por um tempo, ou invalidar a chave quando o usuário escreve, que é a próxima
seção.

## O TTL é a rede de segurança, não o mecanismo

Um TTL longo sozinho é um cache que erra muito. Um curto é um cache que falta muito, e com dois
segundos a taxa de acerto do painel desabaria. Sistemas em produção combinam os dois: a
**invalidação** remove uma chave no momento em que o dado dela muda, e um TTL limita quanto tempo um
valor pode sobreviver se uma invalidação se perder. Perder-se não é hipotético. O programa que muda o
dado pode cair entre o commit e o delete, uma implantação pode esquecer de apagar uma chave nova, ou o
Redis pode estar fora do ar no segundo que importava. Sem TTL, qualquer um desses é um valor errado
servido até alguém notar. Com um, fica errado por um minuto.

Dois refinamentos baratos valem conhecer. **Jitter**: acrescente alguns segundos aleatórios a cada
TTL, para que chaves guardadas juntas não expirem todas juntas; a seção 05 mostra por quê. E o Redis
pode receber um **limite de memória com uma política de despejo**, `maxmemory` com `allkeys-lru`,
para que um cache que cresce além da máquina jogue fora as chaves usadas há mais tempo em vez de
recusar escritas. Nenhum dos dois muda a promessa acima: o TTL continua sendo quão velha uma resposta
você aceitou servir.
