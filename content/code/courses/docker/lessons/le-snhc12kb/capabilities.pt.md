---
title: Capabilities
version: 1
---

**O Linux não trata o root como um poder só. Ele o divide em umas quarenta capabilities**: mudar o dono
de um arquivo, usar uma porta baixa, carregar um módulo do kernel, mudar o relógio. Um processo tem um
conjunto delas, e o kernel confere a que cada operação exige. A aula 14 fez o `shelf` rodar com um
usuário que não é root; esta aula tira o que sobrou.

## O que um container recebe por padrão

```
ana@vm:~$ docker run --rm alpine:3.22 grep CapEff /proc/self/status
CapEff:	00000000a80425fb
ana@vm:~$ capsh --decode=00000000a80425fb
0x00000000a80425fb=cap_chown,cap_dac_override,cap_fowner,cap_fsetid,cap_kill,cap_setgid,cap_setuid,cap_setpcap,cap_net_bind_service,cap_net_raw,cap_sys_chroot,cap_mknod,cap_audit_write,cap_setfcap
ana@vm:~$ grep CapEff /proc/self/status
CapEff:	0000000000000000
```

**Um processo root num container tem 14 capabilities**, e não todas, e o `capsh` as nomeia. O shell da
própria Ana, como usuária comum, não tem nenhuma. As 14 são um meio-termo que o Docker escolheu para a
maioria das imagens funcionar sem mudança: o bastante para mudar donos de arquivos, trocar de usuário e
abrir sockets brutos, e aquém de carregar módulos ou mudar o relógio.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 230\" role=\"img\" aria-label=\"Capabilities do processo root de um container no laboratório da Ana, em barras. Com --cap-drop ALL: nenhuma. Por padrão: 14, entre elas chown, setuid, net_raw e mknod. Com --privileged: 40, todas as capabilities que o próprio daemon tem, junto com todos os dispositivos do host, 111 entradas em /dev contra 14 por padrão. O shelf roda sem nenhuma.\"><text x=\"150\" y=\"55\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">--cap-drop ALL</text><rect x=\"165\" y=\"40\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"175\" y=\"55\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">0: com o que o shelf roda</text><text x=\"150\" y=\"115\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">padrão</text><rect x=\"165\" y=\"100\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165\" y=\"100\" width=\"140\" height=\"30\" rx=\"2\" fill=\"var(--wire)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><text x=\"315\" y=\"115\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">14: chown, setuid, net_raw, mknod…</text><text x=\"150\" y=\"175\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">--privileged</text><rect x=\"165\" y=\"160\" width=\"400\" height=\"30\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1\"></rect><rect x=\"165\" y=\"160\" width=\"400\" height=\"30\" rx=\"2\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"1\"></rect><text x=\"175\" y=\"175\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--ink)\">40, e os 111 dispositivos do /dev</text><text x=\"565\" y=\"214\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">capabilities do processo root</text></svg>", "caption": "O padrão é um meio-termo, e não um mínimo. O shelf precisa da ponta esquerda, e nada precisa da direita.", "same": ["14: chown, setuid, net_raw, mknod…"]}
```

## Tirando-as

O `--cap-drop ALL` remove todas:

```
ana@vm:~$ docker run --rm alpine:3.22 chown nobody /tmp && echo "chown worked"
chown worked
ana@vm:~$ docker run --rm --cap-drop ALL alpine:3.22 chown nobody /tmp
chown: /tmp: Operation not permitted
ana@vm:~$ docker run --rm --cap-drop ALL alpine:3.22 grep CapEff /proc/self/status
CapEff:	0000000000000000
```

**O `chown` funcionou com o padrão e falhou sem ele**, como root, dentro do container. Esse é o
mecanismo inteiro: o usuário continua sendo o UID 0, e a operação é recusada porque a capability não
está lá.

O `shelf` roda como UID 65532 e usa a porta 8080; ele não precisa de nenhuma das 14:

```
ana@vm:~$ docker run -d --name web --cap-drop ALL --security-opt no-new-privileges -p 127.0.0.1:8080:8080 shelf:1.0.0
8524d5c6ddf20a9d987543feee5b198c2f1d8d97019b4b8f6650e8946d2695b8
ana@vm:~$ curl -s localhost:8080/version
1.0.0
ana@vm:~$ docker inspect web --format "caps dropped: {{.HostConfig.CapDrop}}  options: {{.HostConfig.SecurityOpt}}"
caps dropped: [ALL]  options: [no-new-privileges]
```

**O `--security-opt no-new-privileges` é a outra metade.** Ele impede que qualquer processo no container
ganhe privilégios com que não começou, que é para isso que serve um programa setuid como o `sudo` ou o
`passwd`. Com os dois, nada lá dentro consegue reconquistar os poderes que acabaram de ser tirados.

Quando um programa precisa mesmo de uma, devolva aquela: `--cap-drop ALL --cap-add NET_BIND_SERVICE`
para um processo root que usa a porta 80. **Comece do nada e acrescente o que um teste provar que
falta**, nunca o contrário.
