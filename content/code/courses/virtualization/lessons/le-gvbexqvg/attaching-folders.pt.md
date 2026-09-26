---
title: Ligando duas pastas
version: 1
---

Duas pastas no host, uma para compartilhar e trabalhar, e uma para documentos que o convidado só deve
ler. Cada uma é acrescentada à descrição da vm1 como um dispositivo **filesystem**, com uma **etiqueta**
(tag) que o convidado vai usar para achá-la:

```
ana@host:~$ ls -l /srv/share /srv/docs
/srv/docs:
total 4
-rw-r--r-- 1 ana ana 25 Sep 25 21:25 manual.txt

/srv/share:
total 4
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@host:~$ virt-xml vm1 --add-device --filesystem source=/srv/share,target=share,accessmode=mapped
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virt-xml vm1 --add-device --filesystem source=/srv/docs,target=docs,accessmode=mapped,readonly=on
Domain 'vm1' defined successfully.
Changes will take effect after the domain is fully powered off.
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh start vm1
Domain 'vm1' started

ana@host:~$ virsh dumpxml vm1 | grep -A5 "<filesystem"
    <filesystem type='mount' accessmode='mapped'>
      <source dir='/srv/share'/>
      <target dir='share'/>
      <alias name='fs0'/>
      <address type='pci' domain='0x0000' bus='0x05' slot='0x00' function='0x0'/>
    </filesystem>
    <filesystem type='mount' accessmode='mapped'>
      <source dir='/srv/docs'/>
      <target dir='docs'/>
      <readonly/>
      <alias name='fs1'/>
      <address type='pci' domain='0x0000' bus='0x08' slot='0x00' function='0x0'/>
```

O `accessmode=mapped` decide como a posse dos arquivos é tratada, que é o assunto da seção 05. O
`readonly=on` deixou a segunda só de leitura, e a descrição a mostra como `<readonly/>`. Como as mudanças
de hardware da aula 8, um dispositivo novo espera o convidado ser desligado e ligado.

Esse é o jeito do próprio QEMU de compartilhar, chamado **9p**; montagens mais novas usam o **virtiofs**,
que é mais rápido e faz o mesmo trabalho. O VirtualBox e o VMware fazem isso pelos pacotes de convidado
deles, seção 07.
