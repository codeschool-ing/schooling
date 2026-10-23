---
title: Uma verificação é um comando
version: 1
---

**Todo controle de todo guia se resume a uma pergunta que uma máquina responde com sim ou não.** "O
root pode entrar por SSH?" é um `sshd -T` e um `grep`. "Há mais de uma conta com id de usuário 0?" é
uma linha de `awk`. A seção de auditoria de um guia é uma lista de comandos assim, e a **linha de
base** de uma organização é a mesma coisa para as máquinas dela: os controles que decidiu adotar,
cada um com o comando que o prova.

Então escreva a do portal. Sete controles, os que a aula 1 aplicou à mão, cada um uma função que dá
certo quando a máquina está certa. No `web`, no seu home, crie `check.sh`:

```schooling-example
{"language": "sh", "file": "check.sh", "parts": [{"code": "#!/bin/bash\n# check.sh: the portal's baseline, one line per control. Exit status: how many failed.\nfail=0\ncheck() {  # check ID 'what it means' COMMAND...: PASS if the command succeeds\n  local id=$1 what=$2; shift 2\n  if \"$@\" >/dev/null 2>&1; then echo \"PASS $id $what\"; else echo \"FAIL $id $what\"; fail=$((fail + 1)); fi\n}", "note": "`check` roda um comando, joga a saída fora e guarda só o veredito. Um controle é uma pergunta com resposta sim ou não, e o código de saída de um comando é exatamente isso. A contagem de falhas vira o código de saída do próprio script, então outro programa pode perguntar \"esta máquina está dentro da linha de base?\" sem ler uma palavra."}, {"code": "only_root_uid0()   { [ \"$(awk -F: '$3 == 0' /etc/passwd | wc -l)\" -eq 1 ]; }\nno_telnet()        { ! ss -Htln | grep -q ':23 '; }\nno_ftp()           { ! dpkg -s vsftpd; }", "note": "Cada controle é uma pequena função que dá certo quando a máquina está certa. Repare no que cada uma pergunta: não \"existe uma linha num arquivo\", mas o estado que essa linha deveria produzir. O telnet é conferido perguntando o que escuta na porta 23, então um servidor telnet iniciado de outro jeito também reprova."}, {"code": "no_root_login()    { sshd -T | grep -qx 'permitrootlogin no'; }\nno_passwords_ssh() { sshd -T | grep -qx 'passwordauthentication no'; }\nintern_locked()    { passwd -S estagio | grep -q ' L '; }\nno_version()       { ! curl -s -D - -o /dev/null http://localhost/ | grep -qi '^server: nginx/'; }", "note": "Os controles de SSH perguntam ao `sshd -T`, as configurações com que o servidor rodaria de verdade, pelo motivo que a aula 1 encontrou: com vários arquivos, ler um deles responde à pergunta errada. O último pergunta ao próprio nginx o que ele diz de si."}, {"code": "check JAT-01 'only root has user id 0' only_root_uid0\ncheck JAT-02 'nothing listens for telnet' no_telnet\ncheck JAT-03 'no FTP server is installed' no_ftp\ncheck JAT-04 'root may not log in over SSH' no_root_login\ncheck JAT-05 'SSH refuses passwords' no_passwords_ssh\ncheck JAT-06 \"the intern's password is locked\" intern_locked\ncheck JAT-07 'nginx hides its version' no_version\nexit $fail", "note": "Cada controle tem um id, de `JAT-01` a `JAT-07`, escrito e não deduzido da posição, para que um relatório de março e um de junho possam ser comparados linha a linha mesmo depois de um controle ser acrescentado no meio."}]}
```

Ele precisa rodar como root, porque `sshd -T` e `passwd -S` leem arquivos que só o root lê. No portal
do jeito que foi entregue:

```
ana@web:~$ sudo bash check.sh; echo "failed: $?"
FAIL JAT-01 only root has user id 0
FAIL JAT-02 nothing listens for telnet
FAIL JAT-03 no FTP server is installed
FAIL JAT-04 root may not log in over SSH
FAIL JAT-05 SSH refuses passwords
FAIL JAT-06 the intern's password is locked
FAIL JAT-07 nginx hides its version
failed: 7
```

Sete controles, sete falhas e um código de saída 7. Esse número é o motivo da última linha do script.
Uma pessoa lê a lista; um programa lê o número, e **uma verificação que outro programa consegue ler
é uma verificação que pode rodar toda noite** sem ninguém olhar até ela dizer alguma coisa.

## O que faz uma verificação valer a pena

Uma verificação que passa numa máquina errada é pior que nenhuma, porque acreditam nela. Três
hábitos a mantêm honesta, e o `check.sh` segue os três.

**Pergunte pelo efeito, não pelo arquivo.** `no_telnet` não procura uma linha em `/etc/inetd.conf`;
pergunta o que escuta na porta 23. Um servidor telnet iniciado de qualquer outro jeito, por outro
superservidor, à mão ou por um pacote de que ninguém se lembra, reprova do mesmo jeito.

**Pergunte ao programa que decide.** As verificações de SSH leem o `sshd -T`, não o `sshd_config`,
porque a aula 1 mostrou que o valor efetivo pode vir de um arquivo que você não abriu. A seção depois
da próxima põe um arquivo assim no `web` e vê esta verificação pegá-lo.

**Dê a cada controle um id que nunca muda.** `JAT-04` quer dizer "o root não pode entrar por SSH"
enquanto a linha de base existir. Um relatório que numerasse as linhas pela posição renumeraria
todos os controles depois de um novo, e dois meses de resultados deixariam de ser comparáveis.

O que o `check.sh` não tem é a amplitude de um guia: sete controles contra os 259 testes do Lynis.
Isso é de propósito. Os sete são os que este escritório decidiu adotar, e cada um é uma promessa
sobre a qual alguém pode ser questionado. O guia é de onde vêm os próximos.
