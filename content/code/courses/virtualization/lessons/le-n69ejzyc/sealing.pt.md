---
title: Selando um modelo
version: 1
---

Tirar a identidade de uma máquina para cada cópia fazer a sua se chama **selá-la**, ou *generalizá-la*,
e a máquina selada é um **modelo** (template). Numa imagem de nuvem do Ubuntu, o cloud-init faz a maior
parte:

```
ana@vm1:~$ cat /etc/machine-id; ssh-keygen -lf /etc/ssh/ssh_host_ed25519_key.pub | cut -d" " -f2
f2b0a97d568b4cd0bb0179512eaab5f9
SHA256:SUFzDOz3YLtSwoKTtEuZewisO99n/s8q8qZUtrMDzHM
ana@vm1:~$ sudo cloud-init clean --logs --seed --machine-id --configs all && sudo rm -f /etc/ssh/ssh_host_* && cat /etc/machine-id && ls /etc/ssh/ssh_host_* 2>&1
uninitialized
ls: cannot access '/etc/ssh/ssh_host_*': No such file or directory
ana@host:~$ virsh shutdown vm1
Domain 'vm1' is being shutdown

ana@host:~$ virsh undefine vm1 && cd /var/lib/libvirt/images && sudo mv vm1.qcow2 template.qcow2 && sudo chmod 444 template.qcow2 && ls -l template.qcow2
Domain 'vm1' has been undefined

-r--r--r-- 1 root root 38731776 Sep 25 20:52 template.qcow2
```

Antes: o machine-id da vm1 era `f2b0a97d568b4cd0bb0179512eaab5f9` e a impressão digital da chave de host dela `SHA256:SUFzDOz3YLtSwoKTtEuZewisO99n/s8q8qZUtrMDzHM`. O
`cloud-init clean` esqueceu tudo o que fez no primeiro boot: o `--logs` os logs dele, o `--seed` as
configurações que recebeu e o `--machine-id` o machine-id, agora `uninitialized` para o próximo boot fazer
um novo. O `--configs all` removeu os arquivos que escreveu, **a configuração de rede presa ao MAC da vm1**
entre eles. As chaves de host foram apagadas à mão, e o próximo boot gera novas. Depois a vm1 foi
desligada, tirada do libvirt, e o disco dela guardado, renomeado e tornado **só de leitura**, como a base
do laboratório.

Selar é sempre a última coisa feita num modelo, porque **dar boot nele de novo desfaz a selagem**: o
primeiro boot depois do `cloud-init clean` constrói uma identidade nova, e o modelo levaria essa a toda
cópia. Para atualizar um modelo, faça uma máquina a partir dele, mude essa, e sele essa.

O Windows é selado com o **Sysprep**:

```sh
C:\Windows\System32\Sysprep\sysprep.exe /generalize /oobe /shutdown   # Windows: remove this machine's identity, then switch off
```

**Ele não foi rodado para esta aula.** O `/generalize` tira a identidade, o `/oobe` faz o próximo boot
rodar as telas de primeiro uso, e o `/shutdown` desliga a máquina para ela não dar boot de novo por
acidente. O *Convert to template* do Proxmox e o *Convert to Template* do VMware marcam uma máquina como
modelo, e não a selam: isso ainda é trabalho seu, antes.
