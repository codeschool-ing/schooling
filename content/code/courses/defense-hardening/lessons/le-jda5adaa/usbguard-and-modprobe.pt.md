---
title: Fechando a tomada no Linux e no Windows
version: 1
---

**Nada no laboratório consegue ligar um dispositivo USB.** As máquinas são contêineres, e um
contêiner não tem barramento USB nem módulos de kernel próprios: os dois pertencem ao computador em
que os contêineres rodam. É assim que isso aparece de dentro do `web`:

```
ana@web:~$ ls /sys/bus/usb
ls: cannot access '/sys/bus/usb': No such file or directory
ana@web:~$ sudo usbguard generate-policy; echo "exit $?"
ERROR: loadFiles: /sys/bus/usb/devices: No such file or directory
exit 1
ana@web:~$ command -v modprobe || echo "no modprobe here"
no modprobe here
```

Não há `/sys/bus/usb` para ler, então o USBGuard não tem de onde montar uma política, e não há
`modprobe`, porque nenhum módulo pode ser carregado de dentro de um contêiner. **O resto desta seção
não foi executado para este curso.** É ensinado a partir da documentação de cada ferramenta; num
computador Linux seu, com tomadas USB de verdade, cada comando dela funciona como descrito.

## Nenhum driver para armazenamento USB

O Linux chega a um pendrive pelo módulo de kernel `usb-storage`. Se o módulo nunca carrega, um
pendrive é detectado e nunca vira disco. Um arquivo em `/etc/modprobe.d/` faz isso:

```
blacklist usb-storage
install usb-storage /bin/false
```

`blacklist` impede o módulo de carregar sozinho quando um dispositivo aparece. `install … /bin/false`
vai além: qualquer tentativa de carregá-lo, até `modprobe usb-storage` à mão, roda `/bin/false` no
lugar e falha. Confira com `modprobe --showconfig | grep usb.storage`, e lembre que um módulo já
carregado continua carregado até ser removido ou a máquina reiniciar. Barra armazenamento e mais nada:
um dispositivo que se anuncia como teclado passa intocado.

## Uma lista de dispositivos permitidos: o USBGuard

O USBGuard, instalado em todas as máquinas do laboratório, decide por dispositivo. O daemon lê os
atributos de cada dispositivo quando ele se conecta, id de fabricante e de produto, número de série,
classe de interface, a porta em que está ligado, e aplica uma lista de regras em que a primeira que
casa vence:

```
allow id 046d:c52b serial "" name "USB Receiver" with-interface { 03:01:01 03:01:02 }
allow id 0781:5583 serial "4C530001231115" with-interface 08:06:50
block
```

A primeira regra permite um receptor de teclado sem fio específico, e só com as duas interfaces de
teclado e mouse que ele de fato tem. A segunda permite um pendrive pelo número de série. A última
bloqueia todo o resto. `usbguard generate-policy` escreve uma lista inicial a partir do que está
ligado na hora em que roda, e é assim que se monta uma numa máquina de confiança; `usbguard
list-devices` e `usbguard allow-device` a administram depois. A cláusula `with-interface` é a defesa
contra o dispositivo que mente: um "pendrive" que também apresenta uma interface de teclado (classe
`03`) não casa com uma regra escrita para armazenamento (classe `08`).

O limite é o mesmo do filtro de MAC da aula 4, e vale a mesma honestidade: ids de fabricante e
números de série são valores que o dispositivo informa sobre si mesmo. Uma lista de permitidos barra o
pendrive desconhecido achado no estacionamento; não barra um dispositivo feito para copiar um
permitido.

## Windows

O Windows tem os mesmos dois controles na Política de Grupo, que a aula 3 descreveu. As políticas de
**Removable Storage Access**, em Computer Configuration, negam leitura ou gravação em discos
removíveis por classe. As **Device Installation Restrictions** impedem a instalação de dispositivos
que casam com ids ou classes de instalação listados, ou de qualquer dispositivo fora de uma lista de
permitidos. O Microsoft Defender for Endpoint acrescenta o **device control**, com regras por
dispositivo e por usuário, e um modo de auditoria que registra o que teria sido bloqueado. Nenhum
deles foi executado para este curso.

Seja qual for o sistema, comece como este curso sempre começa: em modo de auditoria, meça que
dispositivos as pessoas de fato usam e depois escreva a lista.
