---
title: Integridade de arquivos, a metade da detecção
version: 1
---

**O monitoramento de integridade de arquivos responde a uma pergunta: o que mudou nesta máquina desde
a última vez que alguém disse que ela estava certa?** Ele registra uma impressão digital de arquivos
escolhidos, as permissões, os donos e um hash do conteúdo, e compara depois. Qualquer diferença é
informada. Ele não sabe se a diferença foi uma edição legítima ou de um invasor, e é exatamente por
isso que informa e não bloqueia.

No `web`, o AIDE está instalado. A configuração dele vigia o sistema inteiro e demora para montar o
banco de dados; uma menor, escrita para o portal, é mais rápida e mais fácil de ler. Salve isto como
`aide.conf` no seu home no `web`:

```schooling-example
{"language": "conf", "file": "aide.conf", "parts": [{"code": "database_in=file:/var/lib/aide/portal.db\ndatabase_out=file:/var/lib/aide/portal.db.new\nreport_url=stdout", "note": "O AIDE compara os arquivos com um banco de dados de como eles eram. Lê o banco antigo de um arquivo e grava um novo em outro, e a diferença entre os dois nomes é de propósito: um banco novo só é confiável depois que uma pessoa o põe no lugar."}, {"code": "Watched = p+u+g+s+sha256\n/etc/ssh Watched\n/etc/sudoers.d Watched\n/opt/portal Watched\n/usr/local/sbin Watched", "note": "`Watched` é uma regra que diz o que registrar de cada arquivo: permissões, dono, grupo, tamanho e um SHA-256 do conteúdo. Os quatro diretórios são os que, mudando no `web`, mais importariam: quem pode entrar, quem pode virar root, o próprio portal e os programas que o root roda."}]}
```

Monte o primeiro banco e aprove-o pondo-o no lugar:

```
ana@web:~$ sudo mkdir -p /var/lib/aide && sudo aide --config=aide.conf --init | tail -3


End timestamp: 2026-10-23 09:18:50 -0300 (run time: 0m 0s)
ana@web:~$ sudo mv /var/lib/aide/portal.db.new /var/lib/aide/portal.db
```

Esse banco agora é o estado aprovado dos quatro diretórios. **A aprovação é o passo importante**: o
AIDE informa diferenças em relação ao banco que receber, então um banco montado numa máquina já
alterada aprova a alteração. Montado num servidor novo e guardado num lugar que o servidor não consegue
reescrever, ele é uma referência.

Agora mude duas coisas como um administrador mudaria, ou um invasor: uma linha acrescentada ao script
de backup que o root roda toda noite, e um arquivo novo em `sudoers.d`:

```
ana@web:~$ echo "# reviewed by the new administrator" | sudo tee -a /opt/portal/backup.sh
# reviewed by the new administrator
ana@web:~$ echo "estagio ALL=(ALL) ALL" | sudo tee /etc/sudoers.d/90-helpdesk
estagio ALL=(ALL) ALL
```

E pergunte ao AIDE:

```
ana@web:~$ sudo aide --config=aide.conf --check | head -34
Start timestamp: 2026-10-23 09:27:45 -0300 (AIDE 0.18.6)
AIDE found differences between database and filesystem!!

Summary:
  Total number of entries:	22
  Added entries:		1
  Removed entries:		0
  Changed entries:		1

---------------------------------------------------
Added entries:
---------------------------------------------------

f+++++++++++++++++: /etc/sudoers.d/90-helpdesk

---------------------------------------------------
Changed entries:
---------------------------------------------------

f > ...     H     : /opt/portal/backup.sh

---------------------------------------------------
Detailed information about changes:
---------------------------------------------------

File: /opt/portal/backup.sh
 Size      : 54                               | 90
 SHA256    : zVu/+ldDCNjTUYMdyX1M3ffStckqX7Qi | 4+PkGXp2qaiXUEEfX+P9bqqC1vxH5Igd
             j81yOEiv7U0=                     | tBIDR40hHmw=


---------------------------------------------------
The attributes of the (uncompressed) database(s):
---------------------------------------------------
```

As duas mudanças estão no relatório, com o que mudou em cada uma: o tamanho e o hash do script de
backup, e um arquivo acrescentado onde ninguém aprovou um. O AIDE não diz nada sobre se alguma delas
estava certa. Uma pessoa lê o relatório e ou aprova o novo estado, montando e movendo um banco novo
como antes, ou começa a perguntar quem editou o arquivo que o root roda toda noite.

Uma conferência assim pertence a um agendamento, toda noite, com o relatório mandado para fora da
máquina, que é o mesmo argumento que a aula 8 fez sobre telemetria: **um relatório guardado na máquina
sobre a qual ele informa pode ser editado por quem mudou a máquina.**
