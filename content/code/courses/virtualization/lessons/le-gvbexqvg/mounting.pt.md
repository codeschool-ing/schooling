---
title: Montando no convidado
version: 1
---

Lá dentro, cada pasta é montada pela etiqueta, como qualquer sistema de arquivos do curso de sistemas
operacionais:

```
ana@vm1:~$ sudo mkdir -p /mnt/share /mnt/docs && sudo mount -t 9p -o trans=virtio,version=9p2000.L share /mnt/share && sudo mount -t 9p -o trans=virtio,version=9p2000.L docs /mnt/docs && ls -l /mnt/share /mnt/docs
/mnt/docs:
total 4
-rw-r--r-- 1 ana ana 25 Sep 25 21:25 manual.txt

/mnt/share:
total 4
-rw-r--r-- 1 ana ana 16 Sep 25 21:25 from-host.txt
ana@vm1:~$ cat /mnt/share/from-host.txt /mnt/docs/manual.txt
written on host
how to reset the printer
```

`share` e `docs` são as etiquetas da descrição; `trans=virtio` diz que os arquivos viajam por um canal
virtio, aula 8. As duas pastas mostram os arquivos do host, e o convidado consegue lê-los.

**Uma montagem feita à mão dura até o convidado reiniciar.** Para mantê-la, ela vai para o `/etc/fstab`:

```
ana@vm1:~$ echo "share /mnt/share 9p trans=virtio,version=9p2000.L,nofail 0 0" | sudo tee -a /etc/fstab
share /mnt/share 9p trans=virtio,version=9p2000.L,nofail 0 0
ana@vm1:~$ sudo umount /mnt/share && sudo mount -a && findmnt /mnt/share
TARGET     SOURCE FSTYPE OPTIONS
/mnt/share share  9p     rw,relatime,access=client,trans=virtio
```

O `nofail` importa aqui: se o host um dia ligar sem o compartilhamento, o convidado ainda dá boot, sem a
pasta, em vez de parar num prompt de emergência. O `mount -a` montou tudo o que está no arquivo, e o
`findmnt` mostra o compartilhamento de volta no lugar.
