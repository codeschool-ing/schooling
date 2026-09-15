---
title: O `sudo` que não funciona, e quatro que funcionam
version: 1
---

Esta seção existe por causa de uma linha. Todo mundo digita, ela falha, e toda resposta a ela na
internet é um conserto sem explicação.

```
ana@vm:~$ sudo echo x > /root/marker.txt
bash: /root/marker.txt: Permission denied
```

O `sudo` está bem ali. O comando é `echo`, que não tem como falhar. E ele diz permissão negada.

## Leia quem está falando

**`bash:`** — não `sudo:`, não `echo:`. A seção 17 da aula 1 construiu esse hábito e é aqui que ele
se paga.

O shell lê a linha inteira **antes de qualquer coisa rodar**. Ele vê um redirecionamento,
`> /root/marker.txt`, e o redirecionamento é trabalho dele — ele abre aquele arquivo e só então
inicia o comando com a saída já apontada para lá. Então a ordem é:

1. O **bash** — ainda `ana` — tenta criar `/root/marker.txt`. Recusado.
2. O `sudo` nunca é alcançado. O `echo` nunca é alcançado.

**O `sudo` eleva o comando. Ele não tem como elevar o shell que está preparando a linha**, porque
esse shell é o seu shell de login e começou muito antes de você digitar `sudo`.

## Os consertos, e o que cada um custa

```
ana@vm:~$ sudo sh -c 'echo x > /root/marker.txt'
ana@vm:~$ sudo ls -l /root/marker.txt
-rw-r--r-- 1 root root 2 Sep 14 22:46 /root/marker.txt
```

**`sudo sh -c '...'`** — inicie um *shell novo* como root e entregue a linha inteira a ele,
redirecionamento incluído. As aspas importam: sem elas o redirecionamento volta a ser do shell de
fora.

**`... | sudo tee arquivo`** — o preferido para escrever um arquivo:

```
echo 'net.ipv4.ip_forward=1' | sudo tee /etc/sysctl.d/99-forward.conf
echo 'uma linha' | sudo tee -a /var/log/notes.log        # -a acrescenta
```

O `tee` lê a entrada dele e escreve num arquivo *e* na tela. Aqui é o `tee` que abre o arquivo, e o
`tee` está rodando sob `sudo`. Ele também te mostra o que escreveu, o que é uma conferência
gratuita.

**`sudo -i`** para uma sessão, quando você tem mesmo dez coisas a fazer:

```
ana@vm:~$ sudo -i
[sudo] password for ana:
root@vm:~# whoami
root
root@vm:~# pwd
/root
root@vm:~# echo $HOME
/root
root@vm:~# exit
logout
ana@vm:~$ whoami
ana
```

Repare que o prompt virou `#`, que o `pwd` é `/root`, e que o `$HOME` mudou. A seção 06 te mandou
olhar aquele último caractere antes de apertar enter em qualquer coisa destrutiva; é este o momento
em que isso importa.

**`sudo -i` contra `sudo -s` contra `sudo su -`.** O primeiro é um shell de login completo como
root: ambiente do root, casa do root, `.bashrc` do root. O `sudo -s` mantém o *seu* ambiente com os
privilégios do root, o que às vezes é o que você quer e mais frequentemente é uma surpresa. O
`sudo su -` funciona e são duas ferramentas fazendo o trabalho de uma.

## `sudo !!` é o que você vai usar todo dia

```
apt install nginx
sudo !!
```

`!!` é o comando anterior, expandido pelo shell antes de rodar, então a segunda linha vira
`sudo apt install nginx`. É a memória muscular de *esqueci o sudo*, e poupa redigitar uma linha
longa.

**Olhe no que ele expandiu antes de apertar enter** quando o comando anterior era longo — porque o
`!!` vai alegremente repetir algo que você não pretendia, como root.

## O ambiente deixou de ser o seu

```
Defaults    env_reset
Defaults    secure_path="/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin:/snap/bin"
```

Essas duas linhas estão no `/etc/sudoers` de quase toda máquina, e explicam duas confusões.

**`env_reset`** joga fora suas variáveis de ambiente. Então o `sudo` não enxerga seu `$http_proxy`,
seu `$JAVA_HOME`, nem a variável que você exportou há um instante. O `sudo -E` as mantém, e é
recusado em máquinas onde as regras proíbem.

**`secure_path`** substitui seu `$PATH` por um fixo. É por isso que um programa que você instalou em
`~/bin` dá `command not found` sob `sudo` e funciona sem ele. Dê o caminho completo, ou coloque o
programa em algum lugar do caminho seguro.

Os dois são medidas de segurança, e não chateações: um `$PATH` que você controla mais um comando de
root é um jeito de fazer o root rodar o seu programa em vez do verdadeiro.

## Quatro hábitos

**`sudo -l` quando você chega em algum lugar.** Ele te diz o que você pode fazer antes de você
descobrir sendo recusado.

**Nunca dê `sudo` em algo que você não leu.** `curl https://… | sudo bash` é o mecanismo de entrega
de ataque mais bem-sucedido do Linux, e está em instruções de instalação por toda parte. Baixe,
leia, depois rode.

**Prefira uma regra estreita a uma larga.** Se um deploy precisa reiniciar um serviço, escreva
aquela regra em `/etc/sudoers.d/` — com `visudo -f` — em vez de colocar a conta no grupo `sudo`.

**E `sudo -k` antes de se afastar.** O cache de quinze minutos é uma comodidade para você e uma
porta aberta para quem sentar em seguida.
