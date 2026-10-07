---
title: Chaves que vencem
version: 1
---

Toda chave pode ter um tempo de vida, e para um cache é a propriedade mais importante que uma chave tem: a
aula 6 defendeu que **o tempo de vida é a rede de segurança quando toda invalidação falha**, e o Redis é
onde essa rede fica para os dados da aplicação.

```
ana@web:~$ redis-cli SET session:7f3a ana EX 30
OK
ana@web:~$ redis-cli TTL session:7f3a; redis-cli PTTL session:7f3a
30
29945
ana@web:~$ redis-cli TTL greeting; redis-cli TTL nothing-here
-1
-2
```

`EX 30` define trinta segundos quando a chave é gravada; o `TTL` conta para trás em segundos e o `PTTL`
em milissegundos. Vale decorar as duas respostas especiais: **`-1` quer dizer que a chave existe e nunca
vence**, que é o que o `greeting` ganhou com um `SET` simples, e **`-2` quer dizer que a chave não
existe**.

```
ana@web:~$ redis-cli EXPIRE greeting 2 && sleep 3 && redis-cli GET greeting
1

ana@web:~$ redis-cli PERSIST session:7f3a && redis-cli TTL session:7f3a
1
-1
```

O `EXPIRE` acrescenta um tempo de vida a uma chave que já existe, e três segundos depois a chave tinha
sumido. O `PERSIST` tira o tempo de vida, e a sessão volta a `-1`, que num servidor de cache é como as
chaves se acumulam até a memória acabar.

O Redis remove chaves vencidas de dois jeitos ao mesmo tempo. **Com preguiça**: uma chave cujo tempo
passou é apagada no momento em que alguém a pede, então ninguém nunca lê um valor vencido. E
**ativamente**: várias vezes por segundo ele sorteia algumas chaves com tempo de vida e apaga as vencidas
que encontrar, para chaves que ninguém pede de novo não ficarem na memória para sempre. Entre os dois,
uma chave vencida pode ocupar memória por um tempinho, e nunca é devolvida.
