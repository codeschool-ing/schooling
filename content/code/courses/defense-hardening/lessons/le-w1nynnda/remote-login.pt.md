---
title: A porta que os administradores usam
version: 1
---

**O SSH é o único serviço do `web` que existe para deixar pessoas entrarem, e isso faz das
configurações dele as que mais importam.** O administrador anterior permitiu duas coisas que um
servidor não deveria: root entrar direto, e entrar com senha. Uma senha pode ser adivinhada de
qualquer lugar de onde se alcance a porta; uma chave, não.

## O que o servidor vai fazer de fato

A configuração do `sshd` fica espalhada por vários arquivos, então ler um deles responde à pergunta
errada. `sshd -T` imprime as configurações com que o servidor rodaria, depois de ler todos, e essa é
a resposta que vale:

```
ana@web:~$ sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '
maxauthtries 6
permitrootlogin yes
passwordauthentication yes
x11forwarding yes
ana@web:~$ cat /etc/ssh/sshd_config.d/50-old.conf; grep -n Include /etc/ssh/sshd_config
PermitRootLogin yes
PasswordAuthentication yes
12:Include /etc/ssh/sshd_config.d/*.conf
```

Root pode entrar, senhas são aceitas, o encaminhamento de X11 está ligado e um cliente tem seis
tentativas por conexão. O arquivo que diz isso é o `50-old.conf`, e a linha 12 do arquivo principal
lê cada arquivo de `sshd_config.d` antes de qualquer configuração dele.

## O primeiro valor vence

Aqui o `sshd` é diferente da maioria dos programas que você vai configurar: **para a maioria das
opções, o primeiro valor que ele lê é o que ele guarda.** Os arquivos de `sshd_config.d` são lidos em
ordem de nome, então um arquivo chamado `10-hardening.conf` é lido antes do `50-old.conf`, e os
valores dele vencem sem mexer no arquivo antigo:

```
ana@web:~$ printf "PermitRootLogin no\nPasswordAuthentication no\nX11Forwarding no\nMaxAuthTries 3\n" | sudo tee /etc/ssh/sshd_config.d/10-hardening.conf
PermitRootLogin no
PasswordAuthentication no
X11Forwarding no
MaxAuthTries 3
ana@web:~$ sudo sshd -t && sudo systemctl reload ssh; echo "exit $?"
exit 0
ana@web:~$ sudo sshd -T | grep -E '^(permitrootlogin|passwordauthentication|x11forwarding|maxauthtries) '
maxauthtries 3
permitrootlogin no
passwordauthentication no
x11forwarding no
```

`sshd -t` confere a configuração e não imprime nada se ela for válida; só então o servidor recebe a
ordem de recarregar, então um erro de digitação nunca derruba o SSH. Recarregar não mexe nas sessões
que já estão abertas. `sshd -T` confirma os quatro valores.

Cada um fecha uma coisa específica:

| opção | o que fecha |
|---|---|
| `PermitRootLogin no` | o único nome de conta que todo atacante conhece; administradores entram como eles mesmos e usam `sudo`, o que deixa um nome no log |
| `PasswordAuthentication no` | o chute: só quem tem uma chave privada consegue entrar |
| `X11Forwarding no` | programas gráficos tunelados a partir do servidor, coisa de que um servidor sem tela nunca precisa |
| `MaxAuthTries 3` | menos tentativas por conexão, então chutar exige mais conexões e fica mais fácil de ver |

## Provando do outro lado

Uma configuração é uma afirmação até um cliente ser recusado. Do `desk`, tente a conta do estagiário
com senha e depois a sua, com a sua chave:

```
ana@desk:~$ ssh -o PreferredAuthentications=password -o BatchMode=yes estagio@web true; echo "exit $?"
estagio@web: Permission denied (publickey).
exit 255
ana@desk:~$ ssh web hostname
web
```

A recusa diz o que o servidor oferece, `publickey`, e mais nada; a senha nem chegou a ser pedida. O
seu login continua funcionando. **Mantenha sempre uma sessão aberta enquanto muda o SSH de uma
máquina remota**, e teste a partir de uma segunda antes de fechar a primeira.
Uma configuração errada
que tranca você fora de um servidor em outra cidade é uma viagem, ou uma ligação para quem tem acesso
ao console.

A aula 15 vai mais longe nesse caminho: uma máquina autorizada a alcançar as outras, e chaves que
expiram em uma hora.
