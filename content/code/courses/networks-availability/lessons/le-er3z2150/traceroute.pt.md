---
title: traceroute, e o salto que não diz nada
version: 1
---

O traceroute manda sondas com TTL 1, depois 2, depois 3. Cada roteador que zera o TTL de uma sonda a
descarta e responde com um ICMP "time exceeded", e essas respostas, salto a salto, são o caminho. **Do que
a sonda é feita é uma escolha**, e as três escolhas no Linux se comportam de forma diferente:

```
ana@laptop:~$ traceroute -n 192.0.2.22
traceroute to 192.0.2.22 (192.0.2.22), 30 hops max, 60 byte packets
 1  192.168.10.1  0.076 ms  0.026 ms  0.025 ms
 2  203.0.113.1  0.380 ms  0.226 ms  0.193 ms
 3  192.0.2.22  0.370 ms  0.238 ms  0.212 ms
ana@laptop:~$ traceroute -n -I 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  0.077 ms *  0.004 ms
 2  * 203.0.113.1  0.168 ms *
 3  192.0.2.21  0.016 ms  0.007 ms  0.007 ms
ana@laptop:~$ sudo traceroute -n -T -p 80 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  5.105 ms * *
 2  203.0.113.1  5.031 ms  5.043 ms *
 3  192.0.2.21  0.338 ms  0.245 ms  0.299 ms
```

O padrão manda UDP para portas altas. O destino não tem nada escutando nelas, responde "port
unreachable", e é assim que o traceroute sabe que chegou. `-I` manda ecos ICMP, como o ping. `-T -p 80`
manda SYN de TCP para a porta 80, que passa por firewalls que deixam o tráfego web passar e descartam o
resto; ele monta os pacotes num socket raw, e por isso rodou com `sudo`. **Escolha a sonda que se parece
com o tráfego que interessa**, porque um firewall que descarta UDP para portas altas pode fazer um
caminho saudável parecer quebrado.

As três rodadas acharam os mesmos três saltos: `hq` em `192.168.10.1`, o provedor em `203.0.113.1` e o
servidor. **As estrelas da segunda e da terceira rodada não são falha**, e nada foi encenado para elas.
Roteadores limitam a velocidade com que mandam erros ICMP, o traceroute dispara as sondas em rajadas
rápidas, e algumas respostas simplesmente não são enviadas; a próxima seção mede esse limite. Os tempos
pedem o mesmo cuidado. Os dois primeiros saltos das sondas TCP levaram uns 5 ms enquanto o servidor
respondeu em 0.338. **O tempo de um salto é quanto aquele roteador levou para responder**, e um roteador
escreve mensagens de erro com baixa prioridade, então um salto do meio lento seguido de um destino rápido
mede a atenção do roteador, não o caminho.

## Um salto calado

Para a rodada seguinte o roteador do provedor recebeu ordem de descartar todo "time exceeded" que envia,
e o traceroute pediu uma sonda por salto com `-q 1`:

```
ana@laptop:~$ traceroute -n -q 1 192.0.2.21
traceroute to 192.0.2.21 (192.0.2.21), 30 hops max, 60 byte packets
 1  192.168.10.1  0.068 ms
 2  *
 3  192.0.2.21  0.209 ms
```

O salto 2 é uma estrela, e o salto 3, o servidor, responde em 0.209 ms. **Um salto calado não é um salto
quebrado.** Toda sonda que chegou ao servidor passou pelo roteador do provedor, então o encaminhamento
funciona; o que falta é só a resposta do próprio roteador. Operadoras configuram roteadores assim de
propósito, para esconder endereços internos ou poupar o processador. **O que indica problema é um trace
que se cala e continua calado até o fim**: aí as sondas não estão indo adiante, e o último salto que
respondeu é onde começar a perguntar.
