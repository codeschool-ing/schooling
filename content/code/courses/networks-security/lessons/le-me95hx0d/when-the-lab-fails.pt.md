---
title: Quando o laboratório não sobe
version: 1
---

A maioria das pessoas que desistem de um curso como este desiste aqui, antes da primeira aula de
verdade, diante de um erro sobre uma máquina que ainda nem montaram. Estas são as falhas que
acontecem, na ordem em que você as encontraria. As que têm transcrição foram provocadas de propósito,
no computador em que o curso foi gravado.

**A máquina virtual não inicia, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte
do processador à virtualização está desligado no firmware do computador. É uma opção no menu da BIOS
ou da UEFI, em geral em *Advanced* ou *CPU configuration*, e muitos notebooks saem de fábrica com ela
desligada. Nenhum software consegue ligá-la por você. No Windows, o Hyper-V e o Subsistema do Windows
para Linux também podem ocupá-la, e então o VirtualBox roda devagar ou nem roda.

**O `multipass launch` estoura o tempo.** O primeiro lançamento baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta demora mais do que a espera padrão. O `multipass launch`
aceita `--timeout` em segundos; dê 1800 e deixe terminar.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu instala as suas próprias atualizações
nos primeiros minutos depois que a máquina liga, e só um programa pode instalar pacotes por vez.
Espere alguns minutos e rode o comando de novo. Apagar o arquivo de trava é o conselho que você vai
encontrar por aí, e é assim que um banco de dados de pacotes se corrompe.

**O `up` para na hora e cita pacotes.** O `nslab.sh` confere todos os pacotes antes de montar
qualquer coisa, e diz quais faltam, com o comando que os instala:

```
$ sudo bash nslab.sh up; echo "exit $?"
install first: sudo apt install aide
exit 1
```

Rode a linha que ele imprime e depois o `up` de novo.

**O `up` manda rodá-lo com `sudo`.** Criar namespaces exige root, e o script também precisa saber
para qual conta são as máquinas, e é o `sudo` que conta isso a ele:

```
$ bash nslab.sh up; echo "exit $?"
run it with sudo, from your own account
exit 1
```

Rodar a partir de um shell de root tem a mesma resposta, pelo mesmo motivo: não há conta para dar às
máquinas. Rode a partir da sua própria conta, com `sudo` na frente.

**A primeira linha falha com algo que não faz sentido.** Um arquivo salvo com finais de linha do
Windows põe um retorno de carro invisível no fim de cada linha, e o `bash` o lê como parte do comando.
O erro então cita o que estava na primeira linha que ele rodou:

```
$ sudo bash windows.sh up 2>&1 | cat -v | head -3; file windows.sh
windows.sh: line 8: set: pipefail^M: invalid option name
windows.sh: Bourne-Again shell script, ASCII text executable, with CRLF line terminators
$ sed -i "s/\r$//" windows.sh; cmp windows.sh nslab.sh && echo same
same
```

O `cat -v` mostra o retorno de carro como `^M`; sem ele, o terminal volta ao começo da linha nesse
caractere e imprime o resto por cima, e é por isso que a mensagem parece embaralhada. O `file` diz o
mesmo em palavras: *with CRLF line terminators*. O `sed` os remove, e o arquivo fica então igual ao
que as aulas usaram. O mesmo sintoma numa linha que não é a primeira costuma querer dizer que a
colagem parou no meio; a conferência com `sha256sum` da seção anterior pega isso antes de qualquer
coisa rodar.

**O script extra de uma aula se recusa a rodar.** Três aulas acrescentam algo ao laboratório com um
script próprio, e cada um se recusa a acrescentá-lo duas vezes ou a um laboratório que não está de
pé:

```
$ sudo bash nslab.sh up; sudo bash inline.sh; sudo bash inline.sh; echo "exit $?"
ips is already inline: sudo bash nslab.sh reset, then run this again
exit 1
$ sudo bash nslab.sh reset; sudo bash inline.sh; echo "exit $?"
exit 0
```

A resposta é a mesma da maioria dos problemas deste curso: `reset`, e rodar de novo.

**Algo que funcionava ontem não responde hoje.** Uma máquina reiniciada mantém o `/lab`, mas não os
namespaces, que vivem na memória. `sudo bash nslab.sh up` os monta de novo. Se algo ainda se
comportar de um jeito estranho, `reset`: custa quatro segundos e devolve todas as máquinas ao estado
em que o `nslab.sh` as monta.

**E quando nada mais funcionar**, apague a máquina virtual e monte-a de novo. Com o Multipass, é
`multipass delete --purge nslab` seguido dos comandos da primeira seção. Parece desistir. É o que
profissionais fazem com uma máquina cujo estado ninguém mais consegue explicar, e é por isso que este
curso monta tudo a partir de um script que você pode ler.
