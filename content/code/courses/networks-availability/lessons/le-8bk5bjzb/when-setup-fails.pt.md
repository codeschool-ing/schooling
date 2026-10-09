---
title: Quando a montagem falha
version: 1
---

A maioria das pessoas que desiste de um curso como este desiste aqui, num erro sobre uma rede que ainda
não terminou de montar. Estas são as falhas que acontecem de verdade, mais ou menos na ordem em que você
as encontraria, com a mensagem que cada uma imprime e o que ela quer dizer.

**A máquina virtual não sobe, e a mensagem fala de virtualização, VT-x, AMD-V ou SVM.** O suporte do
processador a virtualização está desligado no firmware do computador. É uma opção no menu da BIOS ou da
UEFI, em geral em *Advanced* ou *CPU configuration*, e muitos notebooks saem de fábrica com ela
desligada. Nenhum programa consegue ligá-la por você. No Windows, o Hyper-V e o Subsistema do Windows
para Linux também podem segurá-la, e então o VirtualBox roda devagar ou não roda.

**O `multipass launch` estoura o tempo.** O primeiro lançamento baixa uma imagem do Ubuntu de algumas
centenas de megabytes, e uma conexão lenta leva mais que a espera padrão. Acrescente `--timeout 1800` e
deixe terminar.

**O `apt-get` diz que não conseguiu obter uma trava.** O Ubuntu instala as próprias atualizações nos
primeiros minutos depois de a máquina ligar, e só um programa pode instalar por vez. Espere até
`ps aux | grep -c [a]pt` imprimir 0 e rode o comando de novo. Apagar o arquivo de trava é o conselho que
você vai achar na internet, e é assim que um banco de pacotes se corrompe.

**`run it with sudo, from your own account: sudo bash netlab.sh up`.** O script rodou sem `sudo`, ou de
um shell de root, onde ele não consegue saber de quem é a pasta pessoal a criar em cada máquina. Rode-o
exatamente como a mensagem diz, do seu próprio prompt.

**`install first: sudo apt-get install mtr-tiny`.** Falta um pacote da lista da primeira seção, aqui o
`mtr-tiny`. A mensagem cita todos os que faltam; instale-os e rode o `up` de novo.

**`netlab.sh: line 242: syntax error: unexpected end of file`.** A colagem parou antes do fim, e o bash
chegou ao fim do arquivo no meio de uma função. O número é onde a sua cópia acabou. O script inteiro tem
377 linhas, e `wc -l netlab.sh` deve dizer isso; se disser menos, copie de novo com o botão, em vez
de selecionar o texto.

**`Cannot open network namespace "hq3": No such file or directory`.** Não existe máquina com esse nome.
Ou o nome tem um erro de digitação, e `ip netns list` mostra os nomes reais, ou a rede não está montada:
reiniciar a máquina virtual apaga todos os namespaces, e `sudo bash netlab.sh up` os traz de volta.

**`setsid: failed to execute tunnel.py: No such file or directory`.** O programa de túnel da seção sobre
IP-in-IP não está instalado onde as máquinas o procuram. Aquela seção diz como salvá-lo.

**`RTNETLINK answers: File exists`.** Um comando que acrescenta um endereço ou uma rota foi digitado duas
vezes; a primeira já fez o serviço. Não faz mal. Se o estado de uma aula se afastou tanto que você não
sabe mais o que está lá, é para isso que existe o `reset`.

**Um programa parou em todas as máquinas ao mesmo tempo.** As máquinas compartilham uma tabela de
processos, então `sudo pkill nginx` digitado em `web1` também para o nginx de `web2` e de `web3`. Pare um
programa numa máquina só com `sudo bash netlab.sh kill web1 nginx`, digitado na própria máquina virtual;
as aulas fazem assim.

**E quando nada mais funciona**, `sudo bash netlab.sh reset` monta a rede inteira de novo em uns dez
segundos. Além disso, apague a máquina virtual com `multipass delete --purge netlab` e comece a primeira
seção de novo; a parte lenta é o download. Parece desistir. É o que profissionais fazem com uma máquina
cujo estado ninguém consegue mais explicar, e é por isso que este curso monta tudo a partir de um script
que você consegue ler.
