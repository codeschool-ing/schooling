---
title: Quando o srv não colabora
version: 1
---

Montar um servidor é o passo em que uma aula de deploy mais trava, e quase sempre num de poucos lugares.
Os quatro primeiros apareceram enquanto esta aula era gravada; os dois últimos estão descritos como as
ferramentas os documentam.

**O ssh não conhece o nome.** Antes de o `~/.ssh/config` ter uma entrada `Host srv`, `srv` é só uma
palavra:

```
ana@laptop:~$ ssh srv true
ssh: Could not resolve hostname srv: Temporary failure in name resolution
```

O ssh perguntou à rede o que é `srv` e ninguém sabia. Confira a grafia do arquivo, e que as linhas estão no
`~/.ssh/config` e não num arquivo de outro nome. No Windows o arquivo é `.ssh\config` na sua pasta de
usuário, sem extensão; um editor que o salva sem avisar como `config.txt` produz exatamente isto.

**As ferramentas ainda não estão lá.** O primeiro boot instala pacotes, e o srv responde ao ssh antes de
terminar:

```
ana@laptop:~$ ssh srv cloud-init status
status: running
ana@laptop:~$ ssh srv podman --version
bash: line 1: podman: command not found
```

Não há nada errado. `cloud-init status --wait` espera até terminar, e aí o `podman` existe. Se o status
terminar em `error` em vez de `done`, `ssh srv sudo cat /var/log/cloud-init-output.log` mostra o que cada
passo imprimiu. A causa de costume é um pacote que não baixou porque a máquina não tem rota para a
internet, e a correção para isso está na configuração de rede do hipervisor, não no srv.yaml.

**O ssh recusa a chave.** É assim que uma chave errada ou um nome de usuário errado aparecem:

```
ana@laptop:~$ ssh ubuntu@srv true
ubuntu@10.20.0.20: Permission denied (publickey).
```

`publickey` entre parênteses é a lista de jeitos que o srv aceita, e a chave oferecida não era um deles.
Aqui o usuário estava errado: as imagens do Ubuntu têm um usuário chamado `ubuntu`, e a lista `users` do
srv.yaml o substituiu. Se o usuário está certo, a chave no srv.yaml não é a do seu
`~/.ssh/id_ed25519.pub`: uma linha partida em duas ao colar é o jeito de costume. O cloud-init lê o
srv.yaml **só no primeiro boot**, então corrigir o arquivo não muda nada numa máquina que já existe. Apague
o srv e monte de novo: `multipass delete --purge srv`, e a linha `launch` mais uma vez.

**O ssh grita que a máquina mudou.** Depois que o srv é montado de novo no mesmo endereço, ele tem chaves
novas, e o ssh lembra das antigas:

```
ana@laptop:~$ ssh srv true
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
@    WARNING: REMOTE HOST IDENTIFICATION HAS CHANGED!     @
@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@@
IT IS POSSIBLE THAT SOMEONE IS DOING SOMETHING NASTY!
Someone could be eavesdropping on you right now (man-in-the-middle attack)!
It is also possible that a host key has just been changed.
The fingerprint for the ED25519 key sent by the remote host is
SHA256:rHl6qcsOJuha/VvhLLJN0qYp7qa4J54W5G5YMIwREHY.
Please contact your system administrator.
Add correct host key in /home/ana/.ssh/known_hosts to get rid of this message.
Offending ECDSA key in /home/ana/.ssh/known_hosts:3
  remove with:
  ssh-keygen -f '/home/ana/.ssh/known_hosts' -R '10.20.0.20'
Host key for 10.20.0.20 has changed and you have requested strict checking.
Host key verification failed.
ana@laptop:~$ ssh-keygen -R 10.20.0.20
# Host 10.20.0.20 found: line 1
# Host 10.20.0.20 found: line 2
# Host 10.20.0.20 found: line 3
/home/ana/.ssh/known_hosts updated.
Original contents retained as /home/ana/.ssh/known_hosts.old
```

Este é o aviso que pegaria alguém se passando pelo seu servidor, então leia-o toda vez em vez de aprender a
ignorá-lo. Quando o motivo é que **você** remontou o srv, `ssh-keygen -R` com o endereço dele esquece as
chaves antigas, e o próximo `ssh srv` faz de novo a pergunta da primeira conexão.

**A máquina não liga.** Um hipervisor precisa do recurso de virtualização do processador, e alguns
computadores vêm com ele desligado no firmware, onde se chama *Intel VT-x*, *AMD-V* ou *SVM*. No Windows
Home não há Hyper-V, e o Multipass precisa do VirtualBox instalado e escolhido com
`multipass set local.driver=virtualbox` antes do primeiro `launch`. Nenhuma das duas falhas foi gravada
aqui.

**`ssh srv` espera e depois desiste.** Se funcionou ontem, o srv pode estar parado, `multipass start srv`,
ou o endereço dele pode ter mudado depois de reiniciar o seu computador. `multipass info srv` mostra o
endereço que ele tem agora, e o `HostName` no `~/.ssh/config` é a única linha a corrigir.
