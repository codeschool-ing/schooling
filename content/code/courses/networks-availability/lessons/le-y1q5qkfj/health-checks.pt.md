---
title: Health checks, um nível abaixo
version: 1
---

O par de balanceadores protege o site de um balanceador morto. O balanceador o protege de um servidor web
morto, e faz isso do mesmo jeito, com um check que roda haja ou não algo errado. Cada linha `server` da
configuração termina em `check inter 1s fall 2 rise 2`, e `option httpchk GET /` faz do check uma
requisição HTTP de verdade pela página inicial, e não um teste de que a porta está aberta.

Com o HAProxy de `lb1` iniciado de novo, o que não aparece aqui, o nginx de `web2` foi parado. Cada
balanceador verifica os servidores por conta própria; esta é a visão de `lb2`:

```
ana@lb2:~$ grep -E "web2" /run/haproxy.log | tail -n 2
[WARNING]  (1711) : Server web/web2 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 2 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
Server web/web2 is DOWN, reason: Layer4 connection problem, info: "Connection refused", check duration: 0ms. 2 active and 0 backup servers left. 0 sessions active, 0 requeued, 0 remaining in queue.
ana@lb2:~$ echo "show stat" | sudo socat stdio /run/haproxy.sock | cut -d, -f1,2,18 | grep -E "^web,"
web,web1,UP
web,web2,DOWN
web,web3,UP
web,BACKEND,UP
ana@laptop:~$ for i in 1 2 3 4 5 6; do curl -s http://www.example.com/; done
served by web1
served by web3
served by web1
served by web3
served by web1
served by web3
ana@lb2:~$ grep -E "web2" /run/haproxy.log | tail -n 1
Server web/web2 is UP, reason: Layer7 check passed, code: 200, check duration: 0ms. 3 active and 0 backup servers online. 0 sessions requeued, 0 total in queue.
```

O log do HAProxy diz o que ele viu e como julgou: **`Layer4 connection problem`, `Connection refused`**, ou
seja, o check nem chegou ao HTTP, porque nada escutava mais na porta 80 de `web2`. A linha aparece duas
vezes, uma como aviso do próprio HAProxy e outra como mensagem do log, e termina contando o que sobrou:
`2 active and 0 backup servers left`.

O `show stat` no socket de administração imprime uma linha de campos separados por vírgula por servidor, e
o `cut` guarda três deles: o backend, o servidor e o status. **`web2` está `DOWN` e o backend como um todo
continua `UP`**, porque dois dos três servidores estão. As seis requisições seguintes foram para `web1` e
`web3` em rodízio, e nenhuma falhou nem percebeu nada. Quando o nginx foi iniciado de novo, dois checks
bem-sucedidos trouxeram `web2` de volta, e desta vez o motivo é `Layer7 check passed, code: 200`: a
própria página inicial respondeu.

## Dois checks, duas camadas

Agora há dois health checks no projeto, e eles respondem a perguntas diferentes:

| check | quem roda | o que pergunta | o que acontece quando falha |
|---|---|---|---|
| `haproxy_alive` | o keepalived, em cada balanceador | o meu HAProxy está respondendo? | este balanceador abre mão do endereço público |
| `httpchk GET /` | o HAProxy, em cada balanceador | este servidor web está servindo páginas? | o servidor sai do rodízio |

O primeiro check pergunta pouco de propósito. `/health` é respondida pelo próprio HAProxy, então passa
enquanto o HAProxy roda, **mesmo que os três servidores web estejam fora**. Essa é a escolha certa aqui: se
todos os servidores web estivessem mortos, mover o endereço para o outro balanceador chegaria aos mesmos
servidores mortos por outra porta e não ganharia nada. Um check deve fazer a pergunta cuja resposta o
failover consegue de fato resolver.

O segundo check só é tão bom quanto a página que pede. `GET /` provou que o nginx em `web2` respondeu com
`200`. Passaria do mesmo jeito para um servidor cuja conexão com o banco de dados tivesse morrido, se a
página inicial não usar o banco. O remédio é **um check que pede uma página que exercita as dependências reais**, muitas vezes um caminho `/health` próprio da aplicação que consulta o banco e informa o que encontrou. É essa a diferença entre saber que o processo está rodando e saber que o serviço funciona.
