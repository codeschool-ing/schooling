---
title: Quando a instalação falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, antes da primeira aula de
verdade, diante de uma mensagem de erro sobre uma máquina que ainda nem montou. Estas são as falhas
que de fato acontecem, na ordem em que você as encontraria, com o que cada uma significa.

**A máquina virtual não sobe, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte à
virtualização do processador está desligado no firmware do computador. É uma opção do menu da BIOS
ou da UEFI, em geral em *Advanced* ou *CPU configuration*, e vem desligada em muitos notebooks.
Nenhum programa consegue ligá-la por você. No Windows, o Hyper-V e o Subsistema do Windows para
Linux também podem estar segurando esse recurso, e aí o VirtualBox roda lento ou nem roda.

**O `multipass launch` estoura o tempo.** O primeiro lançamento baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta demora mais do que a espera padrão. O `multipass launch`
aceita `--timeout` em segundos; dê 1800 a ele e deixe terminar.

**O `apt-get` diz que não conseguiu um lock.** O Ubuntu roda as próprias atualizações nos primeiros
minutos depois que a máquina liga, e só um programa por vez pode instalar pacotes. Espere até
`ps aux | grep -c [a]pt` imprimir 0 e rode o comando de novo. Apagar o arquivo de lock é o conselho
que você vai achar na internet, e é assim que um banco de pacotes se corrompe.

**O `apt-get` não alcança o repositório.** Dentro da máquina, `curl -sI http://archive.ubuntu.com`
deve responder `200`. Se ele não resolve o nome, a máquina está sem DNS, o que numa VM costuma
significar que a VPN ou o firewall do computador está no caminho; desligar a VPN durante a instalação
é o teste rápido.

**Um servidor não sobe.** Pergunte ao systemd antes de chutar:

```
sudo systemctl status nginx
sudo journalctl -u nginx -n 20
```

As últimas linhas do journal dizem o motivo quase sempre, e dois motivos respondem pela maioria dos
casos neste curso. Outro programa já ocupa a porta, o que a seção sobre o Apache mostra de propósito.
Ou o arquivo de configuração tem um erro, o que a última seção desta aula também mostra de propósito.

**O `curl http://ipelivros.example/` diz que não conseguiu resolver o host.** Faltam os nomes no
`/etc/hosts`. `grep ipelivros /etc/hosts` deve imprimir uma linha; se não imprimir nada, o `lab.sh
install` não terminou, e rodá-lo de novo é seguro, porque ele confere antes de acrescentar qualquer
coisa.

**E quando nada mais funciona**, apague a máquina e monte de novo. Com o Multipass é
`multipass delete --purge web` seguido dos dois comandos da seção anterior, e uns dez minutos. Parece
desistir. É o que profissionais fazem com uma máquina cujo estado ninguém mais sabe explicar, e é o
motivo de este curso montar tudo a partir de um script.
