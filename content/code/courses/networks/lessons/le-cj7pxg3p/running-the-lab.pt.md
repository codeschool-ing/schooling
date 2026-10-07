---
title: Montando o laboratório e entrando nele
version: 1
---

Antes da primeira montagem, confira se os quatro arquivos chegaram inteiros. Uma colagem que parou no
meio é o jeito mais comum de isso dar errado, e dá para ver na contagem de linhas. As somas de
verificação vão além: se as suas baterem com estas, os seus arquivos são os bytes que este curso
rodou.

```
ubuntu@netlab:~$ wc -l ~/netlab/*
  172 /home/ubuntu/netlab/dns.sh
  262 /home/ubuntu/netlab/netlab
  202 /home/ubuntu/netlab/services.sh
  137 /home/ubuntu/netlab/web.sh
  773 total
ubuntu@netlab:~$ sha256sum ~/netlab/*
daf483d8acf2d462d38865bdca7bbb5c58d06a712cb5a1a0f1a74e3cb1fbcfa3  /home/ubuntu/netlab/dns.sh
7db7f1e9c08a4d7e9ae56a5ad210fffb62b4df31b33b99b2736403e5391b685c  /home/ubuntu/netlab/netlab
3ceccc37953adaac60fce0cc4b4216f1392cb969c2ed4dba7db8c34d01cdeca6  /home/ubuntu/netlab/services.sh
7e8aecfb9c0a408b30171beea77bc2f941bb7e312ac036f9cea29da7e0731309  /home/ubuntu/netlab/web.sh
```

Agora monte. **O `up` não imprime nada quando dá certo**, e leva uns dez segundos. Depois o `shell`
abre um shell numa das máquinas, como `ana`, a técnica de suporte do escritório:

```
ubuntu@netlab:~$ sudo bash ~/netlab/netlab up
ubuntu@netlab:~$ sudo bash ~/netlab/netlab shell laptop
To run a command as administrator (user "root"), use "sudo <command>".
See "man sudo_root" for details.

ana@laptop:~$ hostname
laptop
ana@laptop:~$ ip -br addr
lo               UNKNOWN        127.0.0.1/8 
eth0@if424       UP             192.168.10.20/24 
ana@laptop:~$ curl -sI https://www.example.com/ | head -1
HTTP/2 200 
ana@laptop:~$ exit
exit
ubuntu@netlab:~$ sudo bash ~/netlab/netlab exec router root 'ip route'
default via 203.0.113.1 dev eth1 
192.168.10.0/24 dev eth0 proto kernel scope link src 192.168.10.1 
203.0.113.0/24 dev eth1 proto kernel scope link src 203.0.113.2 
```

Leia os prompts, porque eles dizem onde cada comando rodou. `ubuntu@netlab` é a sua máquina virtual.
`sudo bash ~/netlab/netlab shell laptop` mudou o prompt para **`ana@laptop`**: dali em diante, cada
comando roda no laptop, com o endereço do laptop e a visão que o laptop tem da rede, até o `exit`
trazer você de volta. As duas linhas sobre o `sudo` são a saudação do Ubuntu para uma conta nova, e
aparecem uma vez. O último comando mostra a outra forma: **`exec` roda um comando numa máquina e
volta**, aqui como `root` no roteador.

Daqui em diante, uma transcrição que começa com `ana@laptop:~$` quer dizer "num shell no `laptop`", e
uma que começa com `ana@www:~$` quer dizer um shell no `www`. Quando uma transcrição mostra um comando
rodando numa máquina enquanto outra máquina faz alguma coisa, abra um segundo terminal no seu
computador com `multipass shell netlab` e inicie lá o shell da segunda máquina. Quando o `sudo` dentro
do laboratório pedir uma senha, é a da `ana`, `office-2026`; as transcrições não mostram a pergunta
porque ela é feita no terminal e não impressa na saída.

Quatro comandos são tudo de que o laboratório precisa:

| comando | o que faz |
|---|---|
| `sudo bash ~/netlab/netlab up` | monta o laboratório; não faz nada se ele já está montado |
| `sudo bash ~/netlab/netlab reset` | desmonta e monta de novo, sem nenhum defeito |
| `sudo bash ~/netlab/netlab down` | desmonta |
| `sudo bash ~/netlab/netlab shell HOST` | um shell numa máquina; acrescente `root` depois do nome para ser root lá |

**O laboratório vive na memória e não sobrevive a uma reinicialização** da máquina virtual. Depois de
uma, rode `up` de novo. E quando uma aula quebrou algo de propósito, como várias fazem, o `reset` é o
caminho de volta para a rede do desenho. Algumas aulas preparam um defeito antes de você olhar para
ele, uma rota removida ou um servidor parado; cada uma diz o que digitar para prepará-lo você mesmo.
