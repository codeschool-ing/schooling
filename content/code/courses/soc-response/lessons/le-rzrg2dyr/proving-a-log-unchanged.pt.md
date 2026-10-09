---
title: Provar que um log não mudou
version: 1
---

Uma cópia em outro lugar mantém o log disponível. Ela não responde, sozinha, à pergunta que alguém vai
fazer meses depois: **como você sabe que este arquivo é o que você coletou?** A resposta é um hash, anotado
no momento da coleta e guardado longe do arquivo.

Um **hash criptográfico** como o SHA-256 transforma qualquer arquivo numa impressão digital de 64
caracteres. Mude um byte em qualquer lugar e a impressão muda por completo, e ninguém sabe construir um
arquivo diferente com a mesma impressão. A rotina no fim de cada dia, então, é: copiar o arquivo do dia,
calcular o hash e guardar o hash onde as pessoas que manuseiam o arquivo não alcançam:

```
root@soc:~# cp /var/log/remote/gw.log gw-day1.log
root@soc:~# sha256sum gw-day1.log | tee gw-day1.log.sha256
5ed00f936671242652748f410fa3a6f957fd2cce22df3ae4273707298885a3ea  gw-day1.log
root@soc:~# sha256sum -c gw-day1.log.sha256
gw-day1.log: OK
root@soc:~# sed -i 's/203.0.113.66/198.51.100.99/' gw-day1.log
root@soc:~# sha256sum -c gw-day1.log.sha256
gw-day1.log: FAILED
sha256sum: WARNING: 1 computed checksum did NOT match
```

Um endereço mudou na cópia, de `203.0.113.66` para `198.51.100.99`, e a conferência falha. Ela não diz *o
que* mudou, só que algo mudou, e é para isso que serve: um analista que vê `FAILED` deixa de se apoiar
naquela cópia e volta a uma cujo hash bate.

Um hash só cobre um arquivo fechado. Um log que ainda está crescendo precisa de algo mais fino, e a
resposta clássica é uma **corrente de hashes**: o hash de cada linha cobre essa linha *e o hash da linha
anterior*. Aqui está ela, pequena o bastante para ler:

```schooling-example
{"language": "bash", "file": "chain.sh", "parts": [{"code": "#!/bin/bash\n# chain.sh FILE: one hash per line, each one covering every line before it\nprev=$(printf 'start' | sha256sum | cut -c1-16)", "note": "A corrente começa de um valor fixo, então duas pessoas rodando o script no mesmo arquivo obtêm os mesmos hashes."}, {"code": "while IFS= read -r line; do\n  prev=$(printf '%s%s' \"$prev\" \"$line\" | sha256sum | cut -c1-16)", "note": "Cada hash novo é calculado sobre o hash anterior e a linha, juntos, então o hash de uma linha depende de todas as linhas antes dela."}, {"code": "  printf '%s  ...%s\\n' \"$prev\" \"${line: -44}\"\ndone < \"$1\"", "note": "Imprimir o hash ao lado do fim da linha, que é onde estas linhas diferem umas das outras."}]}
```

Rode-a na cópia do dia, depois apague a segunda linha e rode de novo:

```
root@soc:~# bash chain.sh gw-day1.log
f32a8cbd8f4539cc  ...: Server listening on 198.51.100.22 port 22.
7267c958d4ea37ac  ...alid user admin from 203.0.113.66 port 32906
5fc413ac19cc05fa  ...user admin 203.0.113.66 port 32906 [preauth]
root@soc:~# sed -i '2d' gw-day1.log
root@soc:~# bash chain.sh gw-day1.log
f32a8cbd8f4539cc  ...: Server listening on 198.51.100.22 port 22.
dcdfd43755d0bc4a  ...user admin 203.0.113.66 port 32906 [preauth]
```

O primeiro hash, `f32a8cbd8f4539cc`, é o mesmo nas duas vezes porque nada antes dele mudou. **Todo hash
depois da linha removida é diferente**, então quem guarda a corrente original, ou só o último valor dela,
vê não apenas que algo mudou, mas a partir de qual linha.

Sistemas de verdade embutem a mesma ideia. O `journald` tem o **Forward Secure Sealing** (`journalctl
--setup-keys` e `journalctl --verify`, não rodados aqui), que sela o journal a intervalos. Armazenamentos
de objetos oferecem travas **write once, read many**, para que um bucket de logs não possa ser alterado,
nem pelo próprio administrador, até o fim do período de retenção. E numa única máquina Linux, `chattr +a`
torna um arquivo **só de acréscimo**, de modo que linhas novas entram e as existentes não podem ser
reescritas sem antes tirar o atributo.
