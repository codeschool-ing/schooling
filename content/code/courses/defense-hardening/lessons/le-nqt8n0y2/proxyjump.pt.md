---
title: Através do servidor de salto, não em cima dele
version: 1
---

**Um administrador passa por um servidor de salto; não trabalha nele.** O jeito antigo era entrar no
bastião e abrir dali uma segunda sessão SSH, o que deixa um shell na máquina mais sensível da rede e,
pior, exige que a chave do administrador esteja nela. O OpenSSH tem um jeito melhor: o `ProxyJump`,
escrito `-J`, pede ao servidor de salto que abra uma conexão TCP até o destino e leva a sessão SSH de
verdade por dentro dela. A sessão é cifrada de ponta a ponta entre a sua estação e o servidor, e a sua
chave nunca sai da sua estação.

Isso permite não dar shell nenhum ao bastião. Escreva a política SSH dele como root no `jump`:

```
root@jump:~# cat > /etc/ssh/sshd_config.d/10-bastion.conf <<'EOF'
PermitTTY no
ForceCommand /usr/sbin/nologin
AllowAgentForwarding no
X11Forwarding no
PermitOpen web:22
EOF
root@jump:~# sshd -t && systemctl reload ssh; echo "exit $?"
exit 0
```

| linha | o que faz |
|---|---|
| `PermitTTY no` | nenhum terminal interativo para ninguém |
| `ForceCommand /usr/sbin/nologin` | qualquer comando pedido roda `nologin` no lugar, que recusa |
| `AllowAgentForwarding no` | o agente SSH da estação não é oferecido ao bastião |
| `X11Forwarding no` | nenhum encaminhamento gráfico, como na aula 1 |
| `PermitOpen web:22` | o único lugar a que o bastião se conecta em nome de um cliente |

O `sshd -t` confere tudo antes do reload, o hábito da aula 1. Agora tente usar o `jump` como máquina:

```
ana@admin:~$ ssh jump; echo "exit $?"
This account is currently not available.
exit 1
```

Recusado, com a mensagem que o `nologin` sempre imprime. E tente usá-lo como passagem:

```
ana@admin:~$ ssh -J jump web hostname
web
ana@admin:~$ ssh -J jump desk hostname; echo "exit $?"
stdio forwarding failed
exit 255
```

O `web` responde. O `desk` não, porque o `PermitOpen` só cita `web:22`: o bastião se recusa a abrir a
conexão, e o cliente informa isso como `stdio forwarding failed`. **A configuração do próprio bastião
é uma lista do que pode ser administrado através dele**, e um servidor fora da lista não é alcançável
por ali, nem por quem tem uma chave válida.

## Escrevendo uma vez só

Digitar `-J jump` toda vez é o jeito como as pessoas param de fazer isso. Uma entrada na sua
configuração SSH no `admin` transforma isso no caminho padrão até o `web`:

```
ana@admin:~$ cat >> ~/.ssh/config <<'EOF'
Host web
    ProxyJump jump
EOF
ana@admin:~$ ssh web "hostname; echo \$SSH_CONNECTION"
web
192.168.60.40 51316 192.168.60.10 22
```

O segundo comando imprime `SSH_CONNECTION`, que o servidor preenche com a origem da conexão:
`192.168.60.40` é o `jump`. Para o `web`, ninguém se conectou a partir do `admin`. É disso que a
próxima seção depende.
