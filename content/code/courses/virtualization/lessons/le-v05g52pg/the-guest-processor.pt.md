---
title: O processador que o QEMU imita
version: 1
---

Dentro do convidado, as mesmas duas perguntas:

```
ana@vm1:~$ lscpu | grep -E "^(Vendor ID|Model name|Virtualization|Hypervisor)"
Vendor ID:                               AuthenticAMD
Model name:                              QEMU Virtual CPU version 2.5+
Virtualization:                          AMD-V
ana@vm1:~$ grep -m1 "^flags" /proc/cpuinfo | grep -owE "vmx|svm|hypervisor"
hypervisor
svm
```

O processador imitado se chama `AuthenticAMD`, o nome que os processadores da AMD dão, com o modelo
`QEMU Virtual CPU version 2.5+`. Ele tem a flag `hypervisor`, então o próprio software do convidado
sabe que é convidado. Ele lista até `svm`, e o `lscpu` informa `AMD-V`: o QEMU copia as flags do
processador que está imitando, e rodar convidados dentro de um convidado é algo que este curso deixa
de lado.

O que o `lscpu` não imprime é uma linha `Hypervisor vendor`. A flag diz "você é convidado"; a linha do
fabricante precisa que o hypervisor diga também o nome, e o processador em software do QEMU não diz.
Compare com o processador do host, acima, onde o KVM diz.

**Flags são afirmações que um processador faz sobre si mesmo**, e o processador de um convidado afirma
o que o hypervisor dele decidir. Leia-as no host para saber o que o processador de verdade oferece, e
num convidado para saber o que aquele convidado recebeu.
