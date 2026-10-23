---
title: Chaves que expiram em uma hora
version: 1
---

**Uma chave em `authorized_keys` vale até alguém se lembrar de removê-la.** Essa é a fraqueza que a
aula 1 apontou ao listar os arquivos de chaves do `web`: cada linha é uma permissão permanente, não
traz data de expiração, e uma pessoa que sai do escritório a mantém até a linha ser encontrada. A
maioria das invasões que começam com uma chave SSH roubada começa com uma que deveria ter parado de
funcionar anos antes.

**Um certificado SSH é uma chave assinada por uma autoridade, com data de expiração e uma lista dos
nomes com que pode entrar.** O servidor confia na autoridade, não em cada chave. Então um
administrador recebe um certificado de manhã, válido pelas horas de que precisa; ele para de funcionar
sozinho; e a configuração do servidor nunca lista pessoa nenhuma.

## A autoridade

A autoridade certificadora é mais um par de chaves. No laboratório ela fica no `admin`:

```
ana@admin:~$ ssh-keygen -q -t ed25519 -N "" -C "jatoba user CA" -f ~/user-ca; cat ~/user-ca.pub
ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1M6z71F2vUOh+XHozQw0N0uet3KVSOd0dmFu/h2Br6 jatoba user CA
```

**Num escritório de verdade essa chave nunca fica numa estação de trabalho.** É a chave capaz de
fazer de qualquer um administrador de todos os servidores, então fica offline, num token de hardware
ou num serviço de assinatura dedicado, e o próprio ato de assinar fica registrado. O laboratório a
guarda no seu diretório home porque não tem lugar melhor, e o texto diz isso para que ninguém copie o
atalho.

## Um certificado para uma hora

Assinar pega a sua chave pública existente e acrescenta três coisas: uma identidade para os logs
(`-I`), os nomes de conta com que ela pode entrar (`-n`) e um período de validade (`-V +1h`):

```
ana@admin:~$ ssh-keygen -s ~/user-ca -I ana@jatoba -n ana -V +1h ~/.ssh/id_ed25519.pub
Signed user key /home/ana/.ssh/id_ed25519-cert.pub: id "ana@jatoba" serial 0 for ana valid from 2026-10-23T08:40:00 to 2026-10-23T09:41:48
ana@admin:~$ ssh-keygen -L -f ~/.ssh/id_ed25519-cert.pub | sed -n "4,9p"
        Signing CA: ED25519 SHA256:cGACsyfksD/bNohootB5cxsSQnXiWRHRd0ZyB8Jxg/k (using ssh-ed25519)
        Key ID: "ana@jatoba"
        Serial: 0
        Valid: from 2026-10-23T08:40:00 to 2026-10-23T09:41:48
        Principals: 
                ana
```

`ssh-keygen -L` lê o certificado de volta. A lista `Principals` é a linha importante: este certificado
pode entrar como `ana` e como nada mais, seja qual for a conta que alguém peça. A validade começa um
pouco antes do momento da assinatura, para que um servidor com o relógio levemente atrasado não o
recuse.

## Um servidor que confia na autoridade em vez das chaves

O `web` recebe a chave pública da autoridade e duas linhas que mudam como ele decide quem pode entrar:

```
root@web:~# echo 'ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIN1M6z71F2vUOh+XHozQw0N0uet3KVSOd0dmFu/h2Br6 jatoba user CA' > /etc/ssh/user-ca.pub
root@web:~# cat > /etc/ssh/sshd_config.d/10-ca.conf <<'EOF'
TrustedUserCAKeys /etc/ssh/user-ca.pub
AuthorizedKeysFile none
PasswordAuthentication no
LogLevel VERBOSE
EOF
root@web:~# sshd -t && systemctl reload ssh; echo "exit $?"
exit 0
ana@admin:~$ ssh web hostname
web
```

`TrustedUserCAKeys` cita a autoridade. `AuthorizedKeysFile none` desliga de vez os antigos arquivos
de chaves por usuário, então uma linha que alguém acrescente a `authorized_keys` não faz nada: neste
servidor, **o único jeito de entrar é um certificado que a autoridade assinou**. O login pelo `jump`
continua funcionando, porque o `ssh` encontrou o certificado ao lado da sua chave e o ofereceu.

## E quando a hora acaba

A demonstração não espera uma hora. Ela assina um certificado que valia de duas horas atrás até uma
hora atrás e o oferece:

```
ana@admin:~$ ssh-keygen -s ~/user-ca -I ana@jatoba-yesterday -n ana -V -2h:-1h ~/.ssh/id_ed25519.pub
Signed user key /home/ana/.ssh/id_ed25519-cert.pub: id "ana@jatoba-yesterday" serial 0 for ana valid from 2026-10-23T06:41:49 to 2026-10-23T07:41:49
ana@admin:~$ ssh -o BatchMode=yes web hostname; echo "exit $?"
ana@web: Permission denied (publickey).
exit 255
```

Recusado, com a mesma resposta curta que uma chave errada recebe. Ninguém precisou remover nada do
`web`. A revogação continua existindo para um certificado roubado antes de expirar, `RevokedKeys` na
configuração do servidor, mas com uma validade de uma hora ela é a exceção, e não a rotina.
