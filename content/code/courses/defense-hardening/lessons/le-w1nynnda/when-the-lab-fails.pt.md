---
title: Quando o laboratório não sobe
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, antes da primeira aula de
verdade, por causa de um erro sobre uma máquina que ainda nem montou. Estas são as falhas que
acontecem, na ordem em que você as encontraria. As que têm transcrito foram provocadas de propósito,
no computador em que o curso foi gravado.

**A máquina virtual não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte
do processador à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS
ou UEFI, muitas vezes em *Advanced* ou *CPU configuration*, e muitos notebooks vêm de fábrica com ela
desligada. Nenhum software consegue ligá-la por você. No Windows, o Hyper-V e o Subsistema do Windows
para Linux também podem prendê-la, e aí o VirtualBox roda devagar ou não roda.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois do boot de uma máquina, e só um programa por vez pode instalar pacotes.
Espere alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai
encontrar na internet, e é assim que um banco de dados de pacotes se corrompe.

**O `build` para com `Failed getting release file` ou `Temporary failure resolving`.** O computador
não alcança `archive.ubuntu.com`. O `build` é o único passo que precisa da internet; confira se
`curl -I http://archive.ubuntu.com/ubuntu/` responde e rode o `build` de novo. Ele começa do zero
toda vez, então um build pela metade nunca é problema.

**O script manda rodá-lo com `sudo`.** Montar contêineres exige root, e o script também precisa
saber de quem é a conta a colocar nas máquinas, o que o `sudo` informa:

```
$ bash hostlab.sh up; echo "exit $?"
run it with sudo, from your own account
exit 1
```

Rodar a partir de um shell de root dá a mesma resposta, pelo mesmo motivo: não há conta para dar às
máquinas. Rode a partir da sua própria conta, com `sudo` na frente.

**A primeira linha falha com algo que não faz sentido.** Um arquivo salvo com finais de linha do
Windows põe um retorno de carro invisível no fim de cada linha, e o `bash` o lê como parte do
comando. O erro então cita o que estiver na primeira linha que ele executou:

```
$ sudo bash windows.sh up 2>&1 | cat -v | head -3; file windows.sh
windows.sh: line 9: set: pipefail^M: invalid option name
windows.sh: Bourne-Again shell script, Unicode text, UTF-8 text executable, with CRLF line terminators
$ sed -i "s/\r$//" windows.sh; cmp windows.sh hostlab.sh && echo same
same
```

`cat -v` mostra o retorno de carro como `^M`, e `file` diz a causa. A linha do `sed` o remove. Isso
acontece quando o script é colado num editor no Windows e copiado de lá.

**Um shell diz que a máquina não está rodando.** Todas as máquinas somem depois de um `down`, depois
de reiniciar o seu computador ou antes do primeiro `up`, e o script diz o comando que as traz de
volta:

```
$ sudo bash hostlab.sh sh web; echo "exit $?"
web is not running: sudo bash hostlab.sh up web
exit 1
```

**Uma máquina diz `degraded` em vez de `running`.** Um dos serviços dela não subiu. Abra um shell
nela e pergunte qual: `systemctl --failed` diz a unidade, e `journalctl -u` seguido desse nome diz o
motivo. Nada no laboratório deveria ficar degradado depois de um `up` simples, então uma máquina
degradada ali quer dizer que a imagem não é a mesma com que o curso foi gravado: rode o `build` de
novo.

**O disco encheu.** As imagens ocupam 1,8 GB e as sete máquinas 6,4 GB, e cada `up` as substitui em
vez de somar. Uma máquina virtual criada com menos de 20 GB enche na primeira vez que todas as
máquinas rodam juntas. `sudo bash hostlab.sh up web` sobe uma máquina e o switch; `sudo rm -rf
/var/lib/hostlab/machines` libera o espaço que as cópias ocupam, depois de um `down`.
