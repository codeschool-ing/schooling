---
title: Três servidores lado a lado
version: 1
---

Os três servidores agora rodam juntos numa máquina, cada um na sua porta:

```
ana@web:~$ sudo ss -ltnp | grep -E ':(80|8080|8081) '
LISTEN 0      511          0.0.0.0:80        0.0.0.0:*    users:(("nginx",pid=287,fd=5),("nginx",pid=285,fd=5),("nginx",pid=284,fd=5),("nginx",pid=283,fd=5),("nginx",pid=227,fd=5))
LISTEN 0      511          0.0.0.0:8080      0.0.0.0:*    users:(("apache2",pid=399,fd=3),("apache2",pid=398,fd=3),("apache2",pid=396,fd=3))                                        
LISTEN 0      4096         0.0.0.0:8081      0.0.0.0:*    users:(("caddy",pid=498,fd=7))                                                                                            
```

O jeito mais rápido de ver como eles diferem é olhar os processos. `NLWP` é o número de threads de
cada processo, e `RSS` a memória residente em kilobytes:

```
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C nginx
    PID    PPID USER     NLWP   RSS CMD
    227       1 root        1  3572 nginx: master process /usr/sbin/nginx -g daemon on; master_proce
    283     227 www-data    1  5120 nginx: worker process
    284     227 www-data    1  5032 nginx: worker process
    285     227 www-data    1  5120 nginx: worker process
    287     227 www-data    1  5032 nginx: worker process
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C apache2
    PID    PPID USER     NLWP   RSS CMD
    396       1 root        1  5380 /usr/sbin/apache2 -k start
    398     396 www-data   27  5880 /usr/sbin/apache2 -k start
    399     396 www-data   27  6824 /usr/sbin/apache2 -k start
ana@web:~$ ps -o pid,ppid,user,nlwp,rss,cmd -C caddy
    PID    PPID USER     NLWP   RSS CMD
    498       1 caddy       9 35964 /usr/bin/caddy run --environ --config /etc/caddy/Caddyfile
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" aria-label=\"Três colunas. Nginx: um processo mestre como root e quatro processos de trabalho com uma thread cada, cada um com muitas conexões. Apache com o MPM event: um processo pai e dois filhos com 27 threads cada. Caddy: um só processo com nove threads rodando muitas goroutines.\"><defs><marker id=\"fpm-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"115\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">nginx</text><rect x=\"40\" y=\"32\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"115.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">mestre (root)</text><rect x=\"20\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"41.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"41\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"26\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"37\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"48\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"68\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"89.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"89\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"74\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"85\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"96\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"116\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"137.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"137\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"122\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"133\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"144\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"164\" y=\"110\" width=\"42\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"185.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">w</text><line x1=\"115\" y1=\"68\" x2=\"185\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"170\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"181\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"192\" y=\"156\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"115\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">1 thread por worker</text><text x=\"115\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">muitas conexões cada</text><text x=\"350\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">apache2 (event)</text><rect x=\"275\" y=\"32\" width=\"150\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"50.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pai (root)</text><rect x=\"270\" y=\"110\" width=\"75\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"307.5\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">filho</text><line x1=\"350\" y1=\"68\" x2=\"307\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"274\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"286\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"298\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"310\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"322\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"334\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"355\" y=\"110\" width=\"75\" height=\"36\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"392.5\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">filho</text><line x1=\"350\" y1=\"68\" x2=\"392\" y2=\"108\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\"></line><rect x=\"359\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"371\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"383\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"395\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"407\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"419\" y=\"156\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"350\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">27 threads por filho</text><text x=\"350\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma requisição por thread</text><text x=\"585\" y=\"18\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">caddy</text><rect x=\"505\" y=\"32\" width=\"160\" height=\"114\" rx=\"5\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"585.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">um processo</text><rect x=\"517\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"532\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"547\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"562\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"577\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"592\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"607\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"622\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"637\" y=\"100\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"517\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"532\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"547\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"562\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"577\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"592\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"607\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"622\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><rect x=\"637\" y=\"114\" width=\"9\" height=\"9\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"585\" y=\"186\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">9 threads, runtime do Go</text><text x=\"585\" y=\"202\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma goroutine por conexão</text><rect x=\"220\" y=\"228\" width=\"8\" height=\"8\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"234\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma conexão sendo atendida</text><rect x=\"420\" y=\"223\" width=\"3\" height=\"18\" fill=\"var(--phosphor-dim)\" stroke=\"none\"></rect><text x=\"430\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">uma thread</text></svg>", "caption": "Os processos que o ps listou no servidor do laboratório. Os três desenhos respondem à mesma pergunta de jeitos diferentes: quanto custa um cliente lento?", "same": ["w"]}
```

**Nginx: poucos workers de uma thread, cada um rodando um laço de eventos.** Um worker nunca espera
por um cliente. Ele pergunta ao kernel quais das suas milhares de conexões têm algo para ler ou
espaço para escrever, faz esse pedaço de trabalho e pergunta de novo. Um cliente lento custa alguns
kilobytes de memória e nenhuma thread. Esse desenho é o motivo de o Nginx ter virado a coisa padrão
na frente de outros programas, onde a maioria das conexões fica ociosa a maior parte do tempo.

**Apache com `event`: poucos processos, cada um com um conjunto de threads.** Aqui, dois filhos com
27 threads cada. Uma thread cuida de uma requisição do começo ao fim e pode ficar bloqueada enquanto
isso, o que é mais simples de programar (é por isso que existem tantos módulos), e a thread de escuta
separada impede que conexões keep-alive ociosas prendam threads. No `prefork`, cada conexão é um
processo inteiro.

**Caddy: um processo, e o runtime do Go por baixo.** Cada conexão é uma goroutine, uma thread leve que
o Go distribui sobre um punhado de threads reais, as nove do `NLWP`. É o laço de eventos de novo,
escrito para você pelo runtime da linguagem em vez de à mão. Os 35 MB de memória dele são quase todos
o runtime do Go e o código de recursos que este site não usa, como o gerenciamento de certificados.

## E a velocidade

As pessoas escolhem servidor web por benchmark, então aqui vai um, com o `ab`, o ApacheBench, do
pacote `apache2-utils`: duas mil requisições pela folha de estilo, cinquenta de cada vez, contra cada
servidor.

```
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    19176.37 [#/sec] (mean)
Time per request:       2.607 [ms] (mean)
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example:8080/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    15546.42 [#/sec] (mean)
Time per request:       3.216 [ms] (mean)
ana@web:~$ ab -q -n 2000 -c 50 http://ipelivros.example:8081/css/site.css | grep -E 'Requests per second|Failed|Time per request.*mean\)$'
Failed requests:        0
Requests per second:    11853.19 [#/sec] (mean)
Time per request:       4.218 [ms] (mean)
```

Leia isso pelo que é. **Os três serviram um arquivo pequeno a entre 11.853 e 19.176 requisições por
segundo, na mesma máquina que enviava as requisições**, e a ordem entre eles mudou de uma execução
desta captura para a seguinte. Para um arquivo estático, nenhum deles é o seu gargalo, e os números
acima dizem mais sobre o `ab` e a máquina do que sobre os servidores. O que os separa em produção é
como se comportam com dez mil clientes lentos ao mesmo tempo, como são configurados e por quem, e o
que fazem além de servir arquivos. É essa a comparação que a tabela faz.

| | Nginx | Apache | Caddy |
|---|---|---|---|
| conexões | laço de eventos por worker | threads por processo (MPM `event`) | goroutines num processo |
| configuração | blocos aninhados, `nginx -t` | diretivas e `<VirtualHost>`, `apachectl configtest` | Caddyfile ou JSON, `caddy validate` |
| configuração por diretório | não | `.htaccess` | não |
| HTTPS | você configura (aula 3) | você configura | automático por padrão |
| onde você o encontra | na frente de quase tudo | hospedagem compartilhada, sistemas antigos, PHP | sites pequenos, ferramentas internas |

Este curso usa o Nginx daqui em diante, pelo motivo da última linha da tabela. A aula 3 volta ao
Caddy, porque certificados automáticos são o argumento mais forte dele.
