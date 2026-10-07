---
title: Escolhendo qual cópia responde
version: 1
---

O round robin supõe que todo membro é igual e que toda requisição custa o mesmo. Quando uma das duas
coisas é falsa, o bloco upstream tem outras três respostas.

## Pesos, quando os membros diferem

Se o `shop1` rodasse numa máquina três vezes maior que a do `shop2`, deveria receber três vezes mais
requisições:

```
ana@web:~$ sudo sed -i 's/server 127.0.0.1:8001;/server 127.0.0.1:8001 weight=3;/' /etc/nginx/sites-available/ipelivros && sed -n '1,6p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    server 127.0.0.1:8001 weight=3;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in $(seq 100); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     75 shop1
     25 shop2
```

Setenta e cinco e vinte e cinco, exatos. Um peso é uma proporção, e é também a ferramenta para mover
tráfego de propósito: uma versão nova num membro com `weight=1` contra outros nove com `weight=9`
recebe um décimo das requisições, que é a forma mais simples de um lançamento canário.

## `least_conn`, quando as requisições diferem

O round robin conta requisições e ignora quanto tempo cada uma leva. Comece uma requisição lenta,
quatro segundos de trabalho, e mande quatro rápidas enquanto ela roda:

```
ana@web:~$ (curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done
shop2
shop1
shop2
shop1
```

A requisição lenta foi para o `shop1`, e o round robin continuou alternando, mandando metade das
rápidas para o membro que ainda estava ocupado. Aqui isso não custou nada, porque a loja tem threads
de sobra. Um membro com número fixo de workers, todos ocupados com requisições lentas, teria posto as
rápidas na fila. O `least_conn` manda cada requisição para o membro com menos requisições em
andamento:

```
ana@web:~$ sudo sed -i 's/^    zone shop 64k;/    zone shop 64k;\n    least_conn;/' /etc/nginx/sites-available/ipelivros && sed -n '1,7p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    least_conn;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ (curl -s "http://ipelivros.example/api/slow?s=4" > /dev/null &); sleep 0.5; for i in 1 2 3 4; do curl -s http://ipelivros.example/api/echo | jq -r .server; done
shop2
shop2
shop2
shop2
```

As quatro foram para o `shop2`, o membro sem nada em andamento. **O `least_conn` é o padrão melhor
quando os tempos das requisições variam muito**, o que vale para a maioria das APIs: uma página de
listagem e uma busca não são a mesma quantidade de trabalho. Ele precisa do `zone` ainda mais que o
round robin, já que "em andamento" contado por cada worker sozinho é um quarto da verdade.

## `hash`, quando o mesmo cliente deve chegar à mesma cópia

```
ana@web:~$ sudo sed -i 's/    least_conn;/    hash $remote_addr;/' /etc/nginx/sites-available/ipelivros && sed -n '1,7p' /etc/nginx/sites-available/ipelivros
upstream shop {
    zone shop 64k;
    hash $remote_addr;
    server 127.0.0.1:8001;
    server 127.0.0.1:8002;
    keepalive 16;
}
ana@web:~$ for i in $(seq 20); do curl -s http://ipelivros.example/api/echo | jq -r .server; done | sort | uniq -c
     20 shop2
```

`hash $remote_addr` escolhe o membro pelo endereço do cliente, então o mesmo cliente sempre cai na
mesma cópia: aqui, cada uma das vinte requisições de `127.0.0.1` foi para o `shop2`. Isso se chama
**afinidade de sessão**, e serve para uma aplicação que guarda algo por usuário na própria memória,
uma sessão de login ou um carrinho pela metade, que a outra cópia não enxerga.

É também um remendo, não um projeto. Muitos clientes atrás da rede de um escritório dividem um
endereço e caem juntos num membro; quando um membro sai, os clientes dele mudam de membro e perdem o
que ele guardava. **A aplicação que guarda as sessões num armazenamento compartilhado, como o Redis da
aula 8, não precisa de afinidade nenhuma**, e todo membro responde a toda requisição.

| método | escolhe | serve para |
|---|---|---|
| round robin (padrão) | cada um na sua vez | membros iguais, requisições parecidas |
| `weight=` | em proporção | membros de tamanhos diferentes, um canário |
| `least_conn` | o com menos em andamento | requisições de custo muito diferente |
| `hash` / `ip_hash` | o mesmo membro para a mesma chave | estado guardado na memória de um membro |
