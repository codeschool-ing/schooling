---
title: O balanceador ativo morre
version: 1
---

Para ver o que os usuários do site veem, o laptop pede a página trinta vezes seguidas, imprimindo a hora
até o milissegundo antes de cada requisição. `curl -m 1` dá a cada requisição no máximo um segundo, e uma
requisição que falha imprime `(no answer)`. Pouco mais de dois segundos depois do início, o HAProxy em
`lb1` foi morto de uma vez, do jeito que um crash ou um kill por falta de memória o terminaria:

```
ana@laptop:~$ for i in $(seq 1 30); do printf "%s " $(date +%T.%N | cut -c1-12); curl -s -m 1 http://www.example.com/ || echo "(no answer)"; sleep 0.2; done
18:11:44.583 served by web1
18:11:44.795 served by web2
18:11:45.007 served by web3
18:11:45.219 served by web1
18:11:45.430 served by web2
18:11:45.643 served by web3
18:11:45.855 served by web1
18:11:46.067 served by web2
18:11:46.279 served by web3
18:11:46.491 served by web1
18:11:46.703 served by web2
18:11:46.916 served by web3
18:11:47.128 (no answer)
18:11:47.341 (no answer)
18:11:47.552 (no answer)
18:11:47.764 (no answer)
18:11:47.975 (no answer)
18:11:48.186 (no answer)
18:11:48.397 (no answer)
18:11:49.610 served by web1
18:11:49.825 served by web2
18:11:50.037 served by web3
18:11:50.250 served by web1
18:11:50.463 served by web2
18:11:50.677 served by web3
18:11:50.889 served by web1
18:11:51.101 served by web2
18:11:51.314 served by web3
18:11:51.526 served by web1
18:11:51.739 served by web2
ana@lb1:~$ grep -E "haproxy_alive|Entering" /run/keepalived.log | tail -n 3
Mon Sep 28 18:11:47 2026: Script `haproxy_alive` now returning 7
Mon Sep 28 18:11:48 2026: VRRP_Script(haproxy_alive) failed (exited with status 7)
Mon Sep 28 18:11:48 2026: (www_a) Entering FAULT STATE
ana@lb2:~$ ip -br addr show eth0
eth0@if1316      UP             192.0.2.12/24 192.0.2.80/24 
```

A última resposta antes da falha saiu às **18:11:46.916**, e a primeira depois dela às **18:11:49.610**.
**O site ficou sem responder por 2,694 segundos**, sete requisições seguidas. Os carimbos de tempo dizem
mais do que a contagem, porque mostram dois tipos diferentes de falha.

As seis primeiras falhas estão a 0,21 segundo uma da outra, o próprio `sleep 0.2` do loop e quase mais
nada: cada requisição falhou na hora. `lb1` ainda tinha `192.0.2.80`, e com o HAProxy morto nada escutava
na porta 80, então cada conexão foi recusada na hora. A sétima começou às 18:11:48.397, e a linha seguinte
vem 1,213 segundo depois: **essa requisição esperou o limite inteiro de um segundo**, porque foi mandada
enquanto o endereço mudava de lugar e ninguém a respondeu.

O log do keepalived em `lb1` mostra a metade dele. Às 18:11:47 o check começou a falhar com status de
saída 7, que é o código do `curl` para "não consegui conectar". Às 18:11:48 tinha falhado duas vezes
seguidas, `fall 2`, e a instância foi para `FAULT`. E `lb2` agora tem `192.0.2.80`.

## Mais rápido que na aula 15, e por quê

O failover de gateway da aula 15 deixou um buraco de 3,264 segundos; este tem 2,694, com os mesmos
anúncios de um segundo. A diferença está em quem percebeu. Na aula 15 o cabo do master foi puxado, então
ele ficou em silêncio, e o backup teve de esperar o master down interval inteiro de silêncio. Aqui o
próprio master descobriu primeiro, pelo próprio script, e **um master que abre mão do endereço avisa**: o
VRRP define um anúncio com prioridade 0 como "estou saindo, assuma agora", e um backup que ouve um espera
só o seu skew curto em vez de três segundos de silêncio. Esse último pacote não está na captura, mas os
horários não deixam espaço para outra coisa: `lb1` foi para `FAULT` às 18:11:48, e `lb2` estava servindo
às 18:11:49.610, bem antes de 3,61 segundos de silêncio poderem ter terminado.

Então os 2,694 segundos são feitos de detecção, não da troca. **Dois checks falhos a um por segundo são uns
dois segundos do buraco**, e o resto é a mudança. Verificar a cada 200 milissegundos o encolheria, e a aula
14 disse quanto isso custa numa máquina ocupada: um check que estoura o tempo porque a máquina está
carregada é idêntico a um que falhou porque ela está morta.

Nada do que um usuário tinha em andamento em `lb1` sobreviveu. Um download pela metade, uma requisição
mandada um milissegundo antes do kill: essas conexões pertenciam a um processo que não existe mais, e
`lb2` nunca ouviu falar delas. **O endereço muda de lugar; as conexões por ele, não.** A última seção desta
aula volta a isso.
