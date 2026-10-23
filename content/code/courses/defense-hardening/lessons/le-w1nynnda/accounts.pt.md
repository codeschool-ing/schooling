---
title: Contas que não deveriam entrar
version: 1
---

**Toda conta que consegue entrar é um caminho de entrada, e um caminho que também é um nome e uma
senha.** Um listener precisa de um bug para ser perigoso. Uma conta só precisa da senha, e senhas são
adivinhadas, reaproveitadas e anotadas em papel. Então as contas de um servidor recebem o mesmo
tratamento que os serviços: liste, pergunte para que cada uma serve, e remova ou trave o que não tiver
resposta.

## Quem é root

Root não é um nome, é o id de usuário 0. O kernel confere o número, nunca o nome, então **qualquer
conta com id 0 é root**, seja qual for o nome dela:

```
ana@web:~$ awk -F: '$3 == 0 {print $1, $6}' /etc/passwd
root /root
suporte /root
```

`suporte` é root com outro nome, com o diretório home do root. Contas assim são criadas para que
alguém entre como root sem a senha do root, e depois esquecidas. É também uma das primeiras coisas
que um invasor acrescenta a uma máquina, e é por isso que uma auditoria faz essa pergunta toda vez, e
por isso a resposta honesta tem de ser uma linha só.

## Quem tem shell e senha

Uma conta só entra de forma interativa se o shell dela for um shell de verdade. Contas de serviço
recebem `/usr/sbin/nologin`, que imprime uma recusa e sai:

```
ana@web:~$ awk -F: '$7 !~ /(nologin|false|sync)$/ {print $1, $3, $7}' /etc/passwd
root 0 /bin/bash
ana 1000 /bin/bash
portal 999 /bin/bash
estagio 1001 /bin/bash
suporte 0 /bin/bash
ana@web:~$ sudo passwd -S -a | grep -v " L "
estagio P 2026-10-23 0 99999 7 -1
suporte P 2026-10-23 0 99999 7 -1
ana@web:~$ sudo grep -r NOPASSWD /etc/sudoers.d
/etc/sudoers.d/ana:ana ALL=(ALL) NOPASSWD:ALL
/etc/sudoers.d/estagio:estagio ALL=(ALL) NOPASSWD:ALL
```

Três achados, um por comando. **`portal` tem shell**: é a conta com que o portal roda, e ninguém
nunca precisa entrar como ela, mas se alguém roubar a senha dela ou achar um jeito de fazer o portal
rodar um comando, um shell é o que essa pessoa ganha. **Duas contas têm senha utilizável**: `passwd
-S` imprime `P` para uma senha que funciona, `L` para uma travada e `NP` para nenhuma, e o `grep`
escondeu as travadas. `estagio`, a conta do estagiário, e `suporte` têm uma cada. **E `estagio` pode
rodar qualquer coisa como root sem digitar senha**, por um arquivo em `/etc/sudoers.d`. A sua aparece
também: essa linha é conveniência do laboratório, e num servidor de verdade o seu `sudo` pediria a sua
senha.

## Tirando o segundo root

O comando óbvio falha, e vale saber por quê:

```
ana@web:~$ sudo userdel suporte; echo "exit $?"
userdel: user suporte is currently used by process 1
exit 8
```

O `userdel` se recusa a apagar uma conta dona de um processo em execução, e o processo 1 roda como id
de usuário 0. Para o `userdel`, `suporte` e `root` são a mesma conta, porque o número é o mesmo.
**Não force, e acima de tudo não acrescente `-r`**: `-r` apaga o diretório home da conta, e o home de
`suporte` é `/root`. O que remove o nome e mais nada é apagar a linha dele dos quatro arquivos que
guardam contas:

```
ana@web:~$ sudo sed -i "/^suporte:/d" /etc/passwd /etc/shadow /etc/group /etc/gshadow; getent passwd 0
root:x:0:0:root:/root:/bin/bash
ana@web:~$ sudo usermod -L -e 1 -s /usr/sbin/nologin estagio; sudo rm /etc/sudoers.d/estagio
ana@web:~$ sudo usermod -s /usr/sbin/nologin portal; sudo systemctl restart portal; systemctl is-active portal
active
ana@web:~$ sudo passwd -S estagio; sudo passwd -S portal; sudo chage -l estagio | head -4
estagio L 2026-10-23 0 99999 7 -1
portal L 2026-10-23 -1 -1 -1 -1
Last password change					: Oct 23, 2026
Password expires					: never
Password inactive					: never
Account expires						: Jan 02, 1970
```

`getent passwd 0` agora só encontra o root. A conta do estagiário não é apagada, porque arquivos e
logs podem ainda trazer o nome dela: `usermod -L` trava a senha, `-e 1` põe a expiração da conta no dia 1 do
calendário Unix, que o `chage` imprime como 2 de janeiro de 1970, e `-s` tira o shell. Cada um sozinho já impediria um login; os três juntos
deixam a intenção inconfundível para a próxima pessoa que ler a conta. O `passwd -S` agora imprime `L`
para as duas contas. O portal continua subindo, como `active` mostra, porque um serviço nunca precisou de shell
de login.

## O que a lista não mostra

Duas coisas fazem parte da mesma pergunta e não estão em `/etc/passwd`. **Chaves SSH** deixam alguém
entrar sem senha nenhuma: o `~/.ssh/authorized_keys` de cada conta é uma lista de quem pode entrar
como ela, e uma chave esquecida de alguém que saiu do escritório é uma conta aberta. E **ser membro de
um grupo** dá poder em silêncio: `getent group sudo` lista todo mundo que pode usar `sudo`, digam o
que disserem os arquivos em `/etc/sudoers.d`. Cada uma é um comando:

```
ana@web:~$ getent group sudo; sudo find / -xdev -name authorized_keys 2>/dev/null
sudo:x:27:ana
/home/ana/.ssh/authorized_keys
```

No `web` o único membro de `sudo` é você, e o único arquivo de chaves é o seu, o que o `build` fez.
Numa máquina herdada, cada linha de cada arquivo de chaves precisa de um nome ao lado.
