---
title: Um checklist no laboratório
version: 1
---

O servidor `www` da loja tem um servidor SSH instalado, para administração remota, com a configuração que
o Ubuntu entrega. O checklist da loja tem quatro linhas para ele:

| configuração | valor desejado | por quê |
|---|---|---|
| `PermitRootLogin` | `no` | ninguém entra direto como root; administradores entram como eles mesmos e usam `sudo`, então toda ação tem um nome (aulas 1 e 6) |
| `PasswordAuthentication` | `no` | entrar com chave, e não com uma senha que pode ser adivinhada ou reaproveitada |
| `X11Forwarding` | `no` | um recurso para rodar programas gráficos remotamente de que um servidor não precisa |
| `MaxAuthTries` | `4` | menos tentativas por conexão |

### O que o arquivo diz

O jeito óbvio de conferir é ler o arquivo de configuração:

```
root@www:~# grep -n -i -E "^#?(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) " /etc/ssh/sshd_config
42:#PermitRootLogin prohibit-password
44:#MaxAuthTries 6
66:#PasswordAuthentication yes
99:X11Forwarding yes
```

Três das quatro configurações estão **comentadas**: o `#` no começo quer dizer que a linha é ignorada, e
ela só documenta o padrão. É fácil ler `#PermitRootLogin prohibit-password` como "o login do root é
restrito", ou não perceber que uma linha comentada quer dizer que vale o padrão. O arquivo também inclui,
perto do topo, todo arquivo em `/etc/ssh/sshd_config.d/`, e qualquer coisa ali muda o quadro de novo. **O
arquivo não é a configuração.** A configuração é o que o servidor de fato usaria.

### O que o servidor usaria

O `sshd -T` pede ao servidor SSH que leia toda a configuração, aplique cada padrão e cada arquivo incluído
e imprima o resultado, sem subir. O script do checklist pergunta a ele e compara quatro valores:

```schooling-example
{"language": "bash", "file": "check-ssh.sh", "parts": [{"code": "#!/bin/bash\n# Four lines of the shop's hardening checklist for the SSH server, checked\n# against the settings sshd would really use, not against what the file says.\neffective=$(sshd -T)", "note": "As configurações que o sshd de fato usaria, lidas uma vez: com cada padrão aplicado e cada arquivo incluído lido."}, {"code": "check() {\n  actual=$(awk -v key=\"$1\" '$1 == key { print $2 }' <<< \"$effective\")\n  if [ \"$actual\" = \"$2\" ]; then\n    echo \"PASS  $1 $actual\"\n  else\n    echo \"FAIL  $1 $actual, expected $2\"\n  fi\n}", "note": "Uma verificação: acha a linha da configuração nessa saída, compara o valor com o desejado e imprime PASS ou FAIL com o que achou."}, {"code": "check permitrootlogin no\ncheck passwordauthentication no\ncheck x11forwarding no\ncheck maxauthtries 4", "note": "As quatro linhas do checklist, cada uma uma configuração e o valor que a loja quer."}]}
```

```
root@www:~# ./check-ssh.sh
FAIL  permitrootlogin without-password, expected no
FAIL  passwordauthentication yes, expected no
FAIL  x11forwarding yes, expected no
FAIL  maxauthtries 6, expected 4
```

As quatro falham. O root pode entrar com chave (`without-password` é outra grafia de
`prohibit-password`), senhas são aceitas, o encaminhamento X11 está ligado e seis tentativas são
permitidas por conexão. Nada disso aparece como problema no arquivo, e o servidor está exatamente como o
pacote o entregou.

### A correção

As quatro configurações vão para um arquivo próprio da loja na pasta incluída, em vez de editar o arquivo
do pacote, para que uma atualização do pacote não as desfaça. O `sshd -t` (com `t` minúsculo) confere que
a configuração é válida antes de alguém reiniciar o servidor:

```
root@www:~# printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 4\n" > /etc/ssh/sshd_config.d/50-shop.conf
root@www:~# cat /etc/ssh/sshd_config.d/50-shop.conf
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 4
root@www:~# sshd -t; echo "exit $?"
exit 0
```

`exit 0` quer dizer que a configuração é válida. E o mesmo checklist de novo:

```
root@www:~# ./check-ssh.sh
PASS  permitrootlogin no
PASS  passwordauthentication no
PASS  x11forwarding no
PASS  maxauthtries 4
```

As quatro passam, e o arquivo principal ainda diz `X11Forwarding yes` na linha 99. O arquivo incluído é
lido primeiro, e para a maioria das configurações **o primeiro valor que o sshd lê é o que ele mantém**.
Esse é exatamente o tipo de regra que torna enganoso ler o arquivo e confiável perguntar ao programa.

Este script é o começo do processo de configuração segura da loja, a salvaguarda do IG1 de duas seções
atrás: rodá-lo toda noite, alertar quando uma linha virar `FAIL`, e o servidor não consegue se afastar do
checklist sem que alguém fique sabendo.
