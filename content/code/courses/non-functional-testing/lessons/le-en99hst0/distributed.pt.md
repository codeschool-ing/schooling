---
title: Execução distribuída
version: 1
---

Um gerador de carga tem um teto: os seus processadores, a sua memória, a sua placa de rede. **Acima
desse teto, o que está sendo medido é o gerador**, coisa de que a aula 2 avisou com um programa bem
menor. A resposta do JMeter é rodar um plano em várias máquinas ao mesmo tempo, comandadas a partir
de uma delas.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" data-fig=\"l04-distributed\" aria-label=\"Execução distribuída. À esquerda, o controlador, que roda o jmeter com -R. Ele envia o plano de teste e as propriedades -G para dois workers, cada um rodando o jmeter-server e cada um com a sua própria cópia de shows.csv. Os dois workers rodam o plano inteiro e enviam as suas requisições para o sistema sob teste à direita. As amostras voltam de cada worker para o controlador, que grava um arquivo de resultados. Dez usuários por worker em dois workers são vinte usuários ao todo.\"><defs><marker id=\"l04-distributed-nf-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l04-distributed-nf-ah-paper\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper)\"></path></marker><marker id=\"l04-distributed-nf-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"105.0\" width=\"150.0\" height=\"90.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\"></rect><text x=\"95.0\" y=\"128.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">controlador</text><text x=\"95.0\" y=\"152.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter -n -R …</text><text x=\"95.0\" y=\"174.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">dist.jtl</text><rect x=\"285.0\" y=\"40.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"365.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker 1</text><text x=\"365.0\" y=\"78.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter-server :1099</text><text x=\"365.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shows.csv</text><path d=\"M172.0 140.0 L283.0 65.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-paper)\"></path><path d=\"M283.0 87.0 L172.0 150.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-distributed-nf-ah-phosphor)\"></path><path d=\"M447.0 75.0 L553.0 138.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-amber)\"></path><rect x=\"285.0\" y=\"200.0\" width=\"160.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.3\"></rect><text x=\"365.0\" y=\"218.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">worker 2</text><text x=\"365.0\" y=\"238.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">jmeter-server :1100</text><text x=\"365.0\" y=\"256.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">shows.csv</text><path d=\"M172.0 160.0 L283.0 225.0\" stroke=\"var(--paper)\" stroke-width=\"1.3\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-paper)\"></path><path d=\"M283.0 247.0 L172.0 170.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.3\" fill=\"none\" stroke-dasharray=\"4 3\" marker-end=\"url(#l04-distributed-nf-ah-phosphor)\"></path><path d=\"M447.0 235.0 L553.0 162.0\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#l04-distributed-nf-ah-amber)\"></path><text x=\"95.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">envia o plano, -G</text><text x=\"95.0\" y=\"212.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">amostras voltam</text><rect x=\"555.0\" y=\"115.0\" width=\"145.0\" height=\"70.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"627.0\" y=\"143.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">sistema sob teste</text><text x=\"627.0\" y=\"156.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">127.0.0.1:8000</text><text x=\"500.0\" y=\"278.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">cada worker roda o plano inteiro: 10 usuários cada, 20 ao todo</text></svg>", "caption": "Um controlador, vários workers. O plano viaja até os workers; os arquivos que ele lê, não.", "same": ["worker 1", "worker 2"]}
```

- Os **workers** rodam o `jmeter-server`, que espera receber o que fazer. Cada um roda o plano de
  teste inteiro com todas as suas threads, então dez usuários em cada um de dois workers são vinte
  usuários contra o sistema sob teste.
- O **controlador** roda `jmeter -n -t plan.jmx -R host1,host2`. Ele envia o plano a cada worker
  nomeado depois de `-R` (ou a cada worker listado em `remote_hosts` no `jmeter.properties`, com
  `-r`), inicia todos juntos, e reúne as amostras que eles mandam de volta num `.jtl` só.
- **Propriedades vão com `-G`, e não com `-J`.** `-J` define uma propriedade na máquina onde é
  digitada, o controlador, que não roda nenhuma thread; `-G` a envia também para os workers.
- **O plano viaja e os seus arquivos não.** Cada worker lê `shows.csv` do seu próprio disco, do
  diretório em que o `jmeter-server` foi iniciado. Um worker iniciado onde não havia nenhum,
  testado ao escrever esta aula, não registrou amostra nenhuma.

O controlador e os workers conversam por Java RMI. Esse tráfego é criptografado por padrão e precisa
de um keystore feito com o script `create-rmi-keystore.sh` do `bin` do JMeter. Numa rede privada sua,
`server.rmi.ssl.disable=true` desliga a criptografia, e todo comando aqui a define, nos workers e no
controlador.

## Uma máquina fazendo o papel de três

Um teste distribuído de verdade roda cada worker numa máquina própria. **O que vem a seguir roda os
dois workers e o controlador na mesma VM**, em portas diferentes, porque o objetivo é ver o mecanismo
e a VM é a única máquina que você tem. Isso não mede nada que um JMeter sozinho não mediria, e um
teste que precisasse de mais geradores não ganharia nenhum com isto.

A primeira tentativa de iniciar um worker falha, e vale conhecer a falha, porque ela acontece na
maioria das máquinas Linux:

```
ana@nft:~/loadtest$ timeout 60 jmeter-server -Dserver_port=1099 -Jserver.rmi.ssl.disable=true
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Created remote object: UnicastServerRef2 [liveRef: [endpoint:[127.0.1.1:34937](local),objID:[fef7d06:1a1276024f1:-7fff, 3849172207519650938]]]
Server failed to start: java.rmi.RemoteException: Cannot start. nft is a loopback address.
An error occurred: Cannot start. nft is a loopback address.
```

O worker consultou o próprio hostname para dizer ao controlador onde encontrá-lo, e o Ubuntu mapeia
`nft` para `127.0.1.1` no `/etc/hosts`, um endereço de loopback que nenhuma outra máquina conseguiria
usar. O JMeter se recusa a iniciar em vez de distribuir um endereço que não funcionaria.
**`-Djava.rmi.server.hostname` nomeia o endereço a anunciar**: em máquinas de verdade, o IP do worker
na rede em que o controlador está; aqui, `127.0.0.1`.

Cada worker ganha um diretório com a sua própria cópia do arquivo de dados:

```
ana@nft:~/loadtest$ mkdir -p ~/worker1 ~/worker2 && cp shows.csv ~/worker1/ && cp shows.csv ~/worker2/
```

Depois, mais dois terminais (`multipass shell nft` de novo), um por worker. No primeiro, a partir de
`~/worker1`:

```sh
jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
```

E no segundo, a partir de `~/worker2`, o mesmo com as suas duas portas:

```sh
jmeter-server -Dserver_port=1100 -Jserver.rmi.localport=50002 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
```

`server_port` é onde o worker escuta o controlador, 1099 por padrão, e `server.rmi.localport` fixa a
segunda porta que o RMI escolheria ao acaso, o que importa numa rede de verdade em que um firewall
precisa deixar as duas passarem. Com os dois esperando, o controlador roda o plano a partir de
`~/loadtest`, com dez usuários em cada worker, por vinte segundos:

```
ana@nft:~/loadtest$ jmeter -n -t plan.jmx -R 127.0.0.1:1099,127.0.0.1:1100 -Jserver.rmi.ssl.disable=true -Gusers=10 -Gseconds=20 -l dist.jtl
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Creating summariser <summary>
Created the tree successfully using plan.jmx
Configuring remote engine: 127.0.0.1:1099
Configuring remote engine: 127.0.0.1:1100
Starting distributed test with remote engines: [127.0.0.1:1100, 127.0.0.1:1099] @ 2026 Oct 10 16:53:04 BRT (1791661984280)
Remote engines have been started:[127.0.0.1:1100, 127.0.0.1:1099]
Waiting for possible Shutdown/StopTestNow/HeapDump/ThreadDump message on port 4445
summary =    229 in 00:00:20 =   11.2/s Avg:    12 Min:     1 Max:    69 Err:     0 (0.00%)
Tidying up remote @ 2026 Oct 10 16:53:25 BRT (1791662005416)
... end of run
ana@nft:~/loadtest$ cut -d, -f6 dist.jtl | cut -d- -f1 | sort | uniq -c
    112 127.0.0.1:1099
    117 127.0.0.1:1100
      1 threadName
```

O controlador configurou os dois motores, iniciou-os e imprimiu um resumo para os dois: 229 amostras
em 20 segundos, nenhum erro. A coluna `threadName` do `dist.jtl` agora começa com o endereço do
worker, e contar por ela mostra as amostras divididas entre os dois, 112 do worker em 1099 e 117 do
que está em 1100. Enquanto isso, o terminal do primeiro worker mostrou isto:

```
ana@nft:~/worker1$ jmeter-server -Dserver_port=1099 -Jserver.rmi.localport=50001 -Jserver.rmi.ssl.disable=true -Djava.rmi.server.hostname=127.0.0.1
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
WARN StatusConsoleListener The use of package scanning to locate plugins is deprecated and will be removed in a future release
Using local port: 50001
Created remote object: UnicastServerRef2 [liveRef: [endpoint:[127.0.0.1:50001](local),objID:[-3a01a255:1a12760311f:-7fff, -3003621217474519746]]]
Starting the test on host 127.0.0.1:1099 @ 2026 Oct 10 16:53:05 BRT (1791661985157)
Finished the test on host 127.0.0.1:1099 @ 2026 Oct 10 16:53:25 BRT (1791662005416)
```

`Ctrl+C` para cada worker quando você terminar. Em máquinas de verdade os mesmos comandos valem com
endereços de verdade, mais duas regras práticas. Os workers devem ser idênticos, para uma máquina
lenta não distorcer o total. E o controlador recebe cada amostra pela rede, então a taxas muito altas
as configurações de *sample sender* do JMeter agrupam ou resumem as amostras nos próprios workers
primeiro.
