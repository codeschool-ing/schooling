---
title: Criando uma máquina
version: 1
---

Na janela, uma máquina é feita com **Novo**, e o assistente pergunta cinco coisas: um **nome** e onde
guardá-la, uma **ISO** de onde instalar, o **tipo e a versão** do sistema, a **memória e os
processadores**, e um **disco rígido**. As versões recentes oferecem uma *instalação desassistida*
quando reconhecem a ISO, que responde às perguntas do instalador por você com um usuário e uma senha
que você digita no assistente.

Cada um desses tem um equivalente no `VBoxManage`, e a versão digitada é a que vale aprender, porque
pode ser anotada, conferida e repetida para vinte máquinas. Primeiro a máquina em si:

```
ana@host:~$ VBoxManage createvm --name lab1 --ostype Ubuntu_64 --register
Virtual machine 'lab1' is created and registered.
UUID: 73b2f8cf-1d72-4905-a30f-6b83ef141c71
Settings file: '/home/ana/VirtualBox VMs/lab1/lab1.vbox'
ana@host:~$ VBoxManage list ostypes | grep -c "^ID:"
188
```

O `createvm` faz uma máquina vazia, o `--register` a põe na lista do VirtualBox, e a resposta diz onde
ficam as configurações dela. `--ostype Ubuntu_64` é um dos **188** tipos que o VirtualBox conhece. O
tipo define padrões razoáveis para o resto, e importa mais do que parece: o VirtualBox escolhe a placa
de rede, a controladora de disco e o relógio para cada tipo, e um sistema de 64 bits feito com um tipo
de 32 bits nem consegue ligar o instalador.

Depois o hardware dela:

```
ana@host:~$ VBoxManage modifyvm lab1 --memory 2048 --cpus 2 --graphicscontroller vmsvga --vram 16 --nic1 nat --audio-driver none
```

O `modifyvm` muda uma máquina desligada, e não imprime nada quando funciona. Isto deu a ela **2048 MB de
memória**, **2 processadores**, a placa de vídeo **VMSVGA** com 16 MB de memória de vídeo, uma placa de
rede em **NAT**, aula 11, e nenhuma placa de som, que um laboratório não precisa.
