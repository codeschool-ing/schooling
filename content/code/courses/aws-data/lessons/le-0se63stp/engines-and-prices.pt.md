---
title: Três engines e duas formas de pagar
version: 1
---

**O ElastiCache é a máquina de outra pessoa rodando um servidor chave-valor em memória, e a parte
que a AWS administra é a máquina, não as suas chaves.** Ela instala o servidor, aplica os patches,
substitui um nó que morre e promove uma réplica quando uma primária falha. O que entra no cache, por
quanto tempo, e o que acontece quando ele enche continuam sendo decisões do seu programa, e são a
maior parte desta lição. A imagem errada é a de um banco de dados mais rápido: um cache guarda
cópias, tem o direito de esquecê-las, e um programa que não sobrevive a um cache esvaziado de uma
noite para outra transformou o cache num banco de dados sem as garantias de um.

## Valkey, Redis OSS e Memcached

O ElastiCache oferece três engines, e duas delas são quase o mesmo programa.

| engine | o que é | o que acrescenta a um armazenamento chave-valor simples |
|---|---|---|
| Valkey | o fork do Redis 7.2.4 feito pela Linux Foundation em 2024, quando o Redis abandonou a licença de código aberto | tipos de dados, replicação, failover, shards |
| Redis OSS | o Redis até a última versão de código aberto que o ElastiCache oferece | o mesmo que o Valkey |
| Memcached | um cache mais antigo e mais simples: só strings, sem replicação, sem persistência | muitas threads por nó |

**O Valkey fala o mesmo protocolo que o Redis**, responde aos mesmos comandos e é acessado pelas
mesmas bibliotecas de cliente, então um programa escrito para um roda no outro. É por isso que a
prática mais adiante nesta lição usa o servidor Redis que o Ubuntu empacota: o que você aprende
sobre `SET`, `EXPIRE` e despejo vale sem mudança. O Memcached é a engine a escolher só quando tudo
de que você precisa são strings com validade e um nó que use todos os núcleos; qualquer coisa que
precise de uma réplica, de um sorted set ou de um contador que sobreviva a um nó é do Valkey.

Os preços decidem entre as duas primeiras por você. Com o moto rodando no terminal dele e as quatro
linhas de "Seu laboratório, em resumo" da lição 1 digitadas neste, o bloco do ElastiCache da tabela
é:

```
ana@laptop:~/aws$ python3 prices.py elasticache
AWS public price list, sa-east-1, USD, excluding tax

ElastiCache, USD
  Valkey, cache.t4g.micro, per node-hour                0.02400  hour
  Valkey, cache.r7g.large, per node-hour                0.34880  hour
  Redis, cache.t4g.micro, per node-hour                 0.03000  hour
  Redis, cache.r7g.large, per node-hour                 0.43600  hour
  Memcached, cache.t4g.micro, per node-hour             0.03000  hour
  Memcached, cache.r7g.large, per node-hour             0.43600  hour
  Serverless Valkey, data stored                        0.13300  GB-hour
  Serverless Valkey, per million ECPUs                  0.00370  million
```

**O Valkey custa 20% menos que o Redis OSS no mesmo nó**: 0,34880 contra 0,43600 por hora num
`cache.r7g.large`, e 0,02400 contra 0,03000 num `cache.t4g.micro`, o que dá 0,8 do preço nos dois
casos. O Memcached tem o preço do Redis OSS. Um mês tem 730 horas, então um `cache.r7g.large` com
Valkey sai 0,34880 × 730 = 254,62 USD e o mesmo nó com Redis OSS sai 318,28. Sem nenhum recurso a
comprar, um cache novo na Quitanda começa no Valkey.

## Nós, ou Serverless

**Um cache baseado em nós são máquinas que você escolhe e paga por hora, estejam ocupadas ou não.**
Você escolhe o tipo de nó, que fixa a memória: um `cache.r7g.large` tem 13,07 GiB e um
`cache.t4g.micro` 0,5 GiB. Você escolhe quantos, e a próxima seção os organiza em shards e
réplicas. Se os dados crescerem além deles, você acrescenta nós ou troca o tipo.

**O Serverless não tem nós para escolher e cobra duas quantidades no lugar**: os dados que guarda,
em GB-hora, e o trabalho que faz, em ElastiCache Processing Units (ECPUs). A AWS documenta uma
leitura ou escrita simples de até 1 KB como uma ECPU, e valores maiores ou comandos mais pesados
como mais. Ele cresce e encolhe sozinho e já nasce espalhado por várias zonas.

As duas linhas da tabela deixam a comparação concreta para o cache do catálogo de produtos da
Quitanda. Digamos que ele guarde 2 GB em média e responda a 500 milhões de requisições por mês,
todas pequenas:

| | conta | USD por mês |
|---|---|---|
| Serverless, dados | 2 GB × 0,133 × 730 h | 194,18 |
| Serverless, requisições | 500 milhões × 0,0037 por milhão | 1,85 |
| dois nós `cache.r7g.large` com Valkey, primária e réplica | 2 × 0,3488 × 730 | 509,25 |

**Com 2 GB o Serverless ganha, e com 13 GB perde**: 13 × 0,133 × 730 dá 1.262,17 USD só pelos
dados, contra os mesmos 509,25 de dois nós que guardam 13,07 GiB cada. O Serverless é cobrado pelo
que você guarda nele, então serve a um cache pequeno com tráfego que vai e volta. Um cache grande e
constante sai mais barato em nós, e as requisições, que são a primeira preocupação das pessoas, são
a menor das três linhas. A lição 11 fez a mesma troca no DynamoDB, entre capacidade sob demanda e
provisionada.

**Nenhum dos dois pode ser praticado no moto.** Pedir a ele um cache Serverless falha com um erro do
próprio moto, como mostra a próxima seção, e os clusters baseados em nós que ele cria não rodam
servidor nenhum.
