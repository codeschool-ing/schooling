---
title: Apagar um snapshot é uma fusão
version: 1
---

Uma camada não pode simplesmente ser apagada: ela guarda toda escrita desde o snapshot. Apagar o snapshot
e ficar com o presente quer dizer **fundir a camada para baixo**, na de baixo, o que o VMware chama de
*consolidar* e o libvirt chama de *block commit*. Fundir em qual camada é a questão:

```
ana@host:~$ virsh blockcommit vm1 vda --active --pivot
error: internal error: unable to execute QEMU command 'block-commit': Could not open '/var/lib/libvirt/images/lab-base.qcow2': Permission denied

ana@host:~$ ls -l /var/lib/libvirt/images/lab-base.qcow2
-r--r--r-- 1 libvirt-qemu kvm 325386240 Sep 25 20:17 /var/lib/libvirt/images/lab-base.qcow2
ana@host:~$ virsh blockcommit vm1 vda --active --pivot --shallow

Successfully pivoted
ana@host:~$ virsh domblklist vm1
 Target   Source
---------------------------------------------
 vda      /var/lib/libvirt/images/vm1.qcow2

ana@host:~$ virsh snapshot-delete vm1 before-update --metadata && sudo rm /var/lib/libvirt/images/vm1.before-update
Domain snapshot before-update deleted

ana@host:~$ cd /var/lib/libvirt/images && ls -lsh vm1.qcow2
128M -rw-r--r-- 1 libvirt-qemu kvm 1.3G Sep 25 20:28 vm1.qcow2
```

O primeiro `blockcommit` tentou fundir no **fundo da cadeia**, que é o padrão dele, e o fundo aqui é o
`lab-base.qcow2`, o disco de que todo convidado deste curso lê. Ele só falhou porque esse arquivo é só de
leitura. **Isso não é hipotético**: enquanto esta aula era preparada, o mesmo comando, rodado contra uma
base que não era só de leitura, escreveu as mudanças de um convidado na base de todos, e ela teve de ser
refeita. O `lab.sh` deixa a base só de leitura desde então.

O `--shallow` funde uma camada abaixo, no `vm1.qcow2`, e o `--pivot` passa o convidado ligado para ele,
sem pará-lo. Depois, o registro do snapshot e o arquivo agora vazio dele vão embora. O `vm1.qcow2` guarda
as mudanças do convidado, 128M, e a cadeia voltou a ter dois arquivos.

O botão *apagar snapshot* de todo hypervisor faz uma fusão como esta, e ela leva tempo proporcional ao
tamanho da camada, com o convidado rodando. **Apague snapshots quando o servidor estiver tranquilo**, e
nunca apague à mão o arquivo de uma camada: os dados mais novos do convidado estão nele.
