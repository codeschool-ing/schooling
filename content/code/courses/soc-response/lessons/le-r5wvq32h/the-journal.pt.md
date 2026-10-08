---
title: Linux: o journal
version: 1
---

Uma crença comum é que o `/var/log/syslog` é onde o Linux guarda o log, e que o journal é uma cópia mais
nova dele. **No Ubuntu 24.04 é o contrário.** Toda mensagem é recebida primeiro pelo `journald`, parte do
systemd, que a guarda num journal binário com todos os campos; o rsyslog recebe uma cópia do journald e
escreve os arquivos de texto da seção anterior. Duas estradas a partir da mesma mensagem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Como uma linha de log viaja no Ubuntu 24.04. Programas como sshd, su e o kernel entregam as mensagens ao journald, que as guarda no journal binário em /var/log/journal e passa uma cópia ao rsyslog. O rsyslog separa a cópia por facility em arquivos de texto: auth e authpriv vão para o auth.log, kern para o kern.log, todo o resto para o syslog.\"><text x=\"20\" y=\"20\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">programas</text><rect x=\"20\" y=\"40\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"60.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">sshd</text><path d=\"M130 60 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L206.0 112.0 L201.2 118.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"20\" y=\"92\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"112.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">su</text><path d=\"M130 112 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L202.4 115.2 L201.6 123.2 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"20\" y=\"144\" width=\"110\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"164.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kernel</text><path d=\"M130 164 L210 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M210 120 L201.1 120.4 L204.9 127.4 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"210\" y=\"95\" width=\"130\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">journald</text><path d=\"M275 145 L275 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M275 190 L279.0 182.0 L271.0 182.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"195\" y=\"190\" width=\"160\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"275.0\" y=\"205.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">/var/log/journal</text><text x=\"275.0\" y=\"221.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">binário, todos os campos</text><path d=\"M340 120 L410 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M410 120 L402.0 116.0 L402.0 124.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"410\" y=\"95\" width=\"120\" height=\"50\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"470.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">rsyslog</text><path d=\"M530 110 L565 110 L565 50 L580 50\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 50 L572.0 46.0 L572.0 54.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 120 L580 120\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 120 L572.0 116.0 L572.0 124.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><path d=\"M530 130 L565 130 L565 190 L580 190\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\"></path><path d=\"M580 190 L572.0 186.0 L572.0 194.0 Z\" fill=\"var(--paper-dim)\" stroke=\"none\"></path><rect x=\"580\" y=\"30\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"50.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">auth.log</text><rect x=\"580\" y=\"100\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"120.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">syslog</text><rect x=\"580\" y=\"170\" width=\"130\" height=\"40\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"590\" y=\"190.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">kern.log</text><text x=\"645\" y=\"82\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">auth, authpriv</text><text x=\"645\" y=\"152\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o resto</text><text x=\"645\" y=\"222\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">kern</text></svg>", "caption": "Duas estradas a partir de uma mensagem: um journal binário com todos os campos, e arquivos de texto separados por facility."}
```

O journal guarda mais do que o arquivo de texto. Cada entrada carrega **campos**: a mensagem, mas também
o número do processo, o id do usuário, a unidade do systemd a que o processo pertence, o boot em que
aconteceu, o executável exato. Isso transforma perguntas como "tudo o que o `ssh.service` disse desde o
último boot" num filtro, e não num `grep`.

Os comandos abaixo são os que um analista mais usa. **Eles não foram rodados na máquina em que este curso
foi gravado**, que não tinha systemd rodando; rode-os na sua máquina virtual, onde funcionam, e compare o
que aparece com os arquivos de texto:

```
journalctl -u ssh.service --since "2026-09-17 00:00" --until "2026-09-17 06:00"
journalctl _COMM=sudo -o short-iso
journalctl -p warning -b
journalctl --list-boots
journalctl -u ssh.service -o json-pretty -n 1
```

`-u` filtra por unidade, `_COMM=` pelo nome do programa, `-p` pela severidade (e tudo o que for pior),
`-b` pelo boot atual, e `-o json-pretty` mostra todos os campos de uma entrada, que é o que um coletor
despacharia. **Onde o journal mora decide se ele sobrevive a um reinício**: `/var/log/journal` é
persistente, e se esse diretório não existir o journald guarda o journal em `/run/log/journal`, na
memória, e o perde a cada reinício. O Ubuntu cria o persistente; uma imagem mínima de contêiner, não.

Duas consequências para uma investigação. O journal é binário, então **não dá para lê-lo com `grep` nem
colá-lo num chamado como texto** sem o `journalctl` exportá-lo. E ele rotaciona por tamanho
(`SystemMaxUse=` em `/etc/systemd/journald.conf`), não por data, então um serviço barulhento pode empurrar
a semana passada para fora antes do que alguém espera. A aula 3 é sobre decidir isso de propósito.
