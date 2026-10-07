---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, diante de uma mensagem de erro
sobre uma máquina que ainda não terminou de montar. Estas são as falhas encontradas enquanto este curso
era gravado, na ordem em que você as encontraria, com o que cada uma quer dizer. Toda mensagem abaixo
foi impressa pelo script ou pelo sistema, numa máquina de verdade.

**A máquina virtual não liga, e a mensagem fala em virtualização, VT-x, AMD-V ou SVM.** O suporte do
processador à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS ou
da UEFI, em geral em *Advanced* ou *CPU configuration*, e vem desligada em muitos notebooks. Nenhum
software consegue ligá-la por você.

**O script pede sudo.** Ele mexe na configuração de rede do kernel, e só o root pode fazer isso:

```
ana@lab:~$ bash ~/netlab/netlab.sh up office
run it with sudo
```

**O script cita pacotes.** Antes de montar qualquer coisa, ele confere se cada pacote que usa está
instalado e lista os que faltam, já na forma de um comando pronto para rodar:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh up office
install first: sudo apt install bridge-utils frr iputils-arping traceroute conntrack isc-dhcp-server isc-dhcp-client isc-dhcp-relay radvd ndisc6 ipcalc sipcalc wireguard-tools lldpd
```

Rode o comando que ele imprime, ou a linha `apt-get install` da seção anterior, e tente de novo. Se o
`apt-get` disser que não conseguiu obter uma trava (*lock*), o Ubuntu está instalando as próprias
atualizações, o que ele faz nos primeiros minutos depois que uma máquina liga; espere alguns minutos e
rode de novo.

**O kernel não tem módulos.** Isto é o que o script imprimiu num contêiner Linux, cujo kernel veio
com o contêiner e não tem nenhum dos módulos que o laboratório carrega:

```
$ sudo bash ~/netlab/netlab.sh up office
modprobe: WARNING: Module 8021q not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module bonding not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module bridge not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module veth not found in directory /lib/modules/6.18.44-fc-v77
modprobe: WARNING: Module wireguard not found in directory /lib/modules/6.18.44-fc-v77
```

Nenhum pacote resolve isso, porque o kernel não é do contêiner para mudar. O laboratório precisa de
uma máquina Linux inteira, real ou virtual, e é por isso que a seção anterior recomenda uma máquina
virtual, e não o WSL2 ou o Docker.

**Um nome está errado.** `up` monta a rede do arquivo com aquele nome ao lado do script, e `on`
alcança um dispositivo da rede que estiver montada:

```
ana@lab:~$ sudo bash ~/netlab/netlab.sh up offce
no network called offce; try: list
ana@lab:~$ bash ~/netlab/netlab.sh list
office
ana@lab:~$ sudo bash ~/netlab/netlab.sh down
ana@lab:~$ sudo bash ~/netlab/netlab.sh on pc1
no device called pc1
```

`list` imprime as redes que encontra, uma por arquivo, e um nome que não aparece ali é um arquivo que
não foi salvo em `~/netlab`, ou foi salvo com outro nome. `no device called pc1` quer dizer que
nenhuma rede está montada, ou que a montada não tem pc1.

**Um arquivo colado ficou incompleto.** Um arquivo copiado sem as últimas linhas para no meio de um
bloco, e o erro então aponta para um lugar que parece certo. Aqui o `office.sh` foi salvo só com as
primeiras 40 linhas, que terminam no meio das regras do firewall:

```
ana@lab:~$ bash -n ~/netlab/office.sh
/home/ana/netlab/office.sh: line 40: warning: here-document at line 28 delimited by end-of-file (wanted `NFT')
ana@lab:~$ sudo bash ~/netlab/netlab.sh up office
/home/ana/netlab/office.sh: line 40: warning: here-document at line 28 delimited by end-of-file (wanted `NFT')
/dev/stdin:13:1-1: Error: syntax error, unexpected end of file
    counter comment "everything else: dropped"
^
```

`bash -n` lê um arquivo sem rodá-lo e não imprime nada quando o arquivo está inteiro, então é a
conferência a fazer depois de cada colagem. Aqui ele diz que o arquivo acabou na linha 40 ainda
esperando a palavra `NFT`, que fecha o bloco aberto na linha 28. Sem a conferência, o mesmo arquivo
chega ao `nft`, que reclama de uma linha perfeitamente correta; a parte que falta é a seguinte.
Compare o fim do seu arquivo com o fim do bloco na aula.

**E quando a rede parece errada**, monte de novo. `sudo bash ~/netlab/netlab.sh up office` derruba
tudo o que o script criou e monta o escritório do zero, em menos de um minuto. Quando nem isso ajuda,
apague a máquina virtual e faça outra, o que leva cerca de meia hora. Parece desistência. É o que
profissionais fazem com uma máquina cujo estado ninguém mais sabe explicar, e é o motivo de tudo neste
laboratório ser montado a partir de arquivos que você pode ler.
