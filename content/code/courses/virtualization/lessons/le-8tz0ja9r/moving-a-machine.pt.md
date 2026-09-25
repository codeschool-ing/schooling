---
title: Movendo uma máquina inteira
version: 1
---

Para levar as configurações além do disco, os hypervisors combinam o **OVF**, o *Open Virtualization
Format*, empacotado num arquivo **OVA** só. Aqui uma máquina do VirtualBox com 2 processadores e 2048 MB
é exportada, e a descrição lá dentro é lida:

```
ana@host:~$ VBoxManage export vmw2 --ovf10 -o ~/vmw2.ova
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Successfully exported 1 machine(s).
ana@host:~$ tar tvf ~/vmw2.ova
-rw-r----- vboxovf10/vbox_v7.0.16r162802 5748 2026-09-25 19:26 vmw2.ovf
-rw-rw---- vboxovf10/vbox_v7.0.16r162802 322117632 2026-09-25 19:26 vmw2-disk001.vmdk
ana@host:~$ tar xOf ~/vmw2.ova vmw2.ovf | grep -E "<(rasd:ElementName|rasd:VirtualQuantity|vssd:VirtualSystemType)>|<Disk "
    <Disk ovf:capacity="3758096384" ovf:diskId="vmdisk1" ovf:fileRef="file1" ovf:format="http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized" vbox:uuid="381ab720-eda4-482e-bc02-9e7eee41d651"/>
        <vssd:VirtualSystemType>virtualbox-2.2</vssd:VirtualSystemType>
        <rasd:ElementName>2 virtual CPU</rasd:ElementName>
        <rasd:VirtualQuantity>2</rasd:VirtualQuantity>
        <rasd:ElementName>2048 MB of memory</rasd:ElementName>
        <rasd:VirtualQuantity>2048</rasd:VirtualQuantity>
        <rasd:ElementName>sataController0</rasd:ElementName>
        <rasd:ElementName>sound</rasd:ElementName>
        <rasd:ElementName>disk1</rasd:ElementName>
        <rasd:ElementName>Ethernet adapter on 'NAT'</rasd:ElementName>
```

O `--ovf10` pede a versão 1.0 do formato, a que todo importador lê. O OVA guarda o `.ovf`, que é XML, e o
disco como um VMDK **streamOptimized**, comprimido para viajar: 307 MiB aqui, contra 817M para o mesmo
disco como VMDK comum. As linhas tiradas do XML são a máquina: `2 virtual CPU`, `2048 MB of memory`, um
disco de `3758096384` bytes, uma controladora, uma placa de rede, uma placa de som.

E o `VirtualSystemType` diz `virtualbox-2.2`: o hardware está descrito como o do VirtualBox. **É dessa
linha que o VMware reclama** quando abre um OVA do VirtualBox, com uma mensagem sobre uma família de
hardware sem suporte, e oferece tentar de novo com a especificação relaxada. Tentar de novo não tem
problema; o que se perde é o que o VMware não tem como equivalente.

Um importador lê a descrição e propõe uma máquina. O VirtualBox consegue mostrar o que faria sem fazer:

```
ana@host:~$ VBoxManage import ~/vmw2.ova --dry-run
0%...10%...20%...30%...40%...50%...60%...70%...80%...90%...100%
Interpreting /home/ana/vmw2.ova...
OK.
Disks:
  vmdisk1       3758096384      -1      http://www.vmware.com/interfaces/specifications/vmdk.html#streamOptimized       vmw2-disk001.vmdk       -1      -1      

Virtual system 0:
 0: Suggested OS type: "Ubuntu_64"
    (change with "--vsys 0 --ostype <type>"; use "list ostypes" to list all possible values)
 1: Suggested VM name "vmw2 1"
    (change with "--vsys 0 --vmname <name>")
 2: Suggested VM group "/"
    (change with "--vsys 0 --group <group>")
 3: Suggested VM settings file name "/home/ana/VirtualBox VMs/vmw2 1/vmw2 1.vbox"
    (change with "--vsys 0 --settingsfile <filename>")
 4: Suggested VM base folder "/home/ana/VirtualBox VMs"
    (change with "--vsys 0 --basefolder <path>")
 5: Number of CPUs: 2
    (change with "--vsys 0 --cpus <n>")
 6: Guest memory: 2048 MB
    (change with "--vsys 0 --memory <MB>")
 7: Sound card (appliance expects "", can change on import)
    (disable with "--vsys 0 --unit 7 --ignore")
 8: Network adapter: orig NAT, config 3, extra slot=0;type=NAT
 9: SATA controller, type AHCI
    (disable with "--vsys 0 --unit 9 --ignore")
10: Hard disk image: source image=vmw2-disk001.vmdk, target path=vmw2-disk001.vmdk, controller=9;port=0
    (change target path with "--vsys 0 --unit 10 --disk path";
    change controller with "--vsys 0 --unit 10 --controller <index>";
    change controller port with "--vsys 0 --unit 10 --port <n>";
    disable with "--vsys 0 --unit 10 --ignore")
```

Cada linha numerada é uma decisão que o importador tomou a partir do OVF, e cada uma pode ser mudada
antes de qualquer coisa ser escrita. **O *File* → *Open* do VMware num `.ova` faz o mesmo**, numa janela,
e o `ovftool` faz na linha de comando.
