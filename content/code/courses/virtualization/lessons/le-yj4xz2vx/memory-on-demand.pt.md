---
title: Memória sob demanda, e o balão
version: 1
---

A memória de um convidado é tirada do host **quando o convidado a toca pela primeira vez**, não quando ele
liga. Aqui o convidado usa 400 MB por um instante e os solta:

```
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"
00007fa383e00000 1048576  446464  446464 rw---   [ anon ]
ana@vm1:~$ python3 -c "b = b\"x\" * (400 * 1024 * 1024)"; free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             961         277         627           0         203         683
ana@host:~$ sudo pmap -x $(pgrep -o qemu-system) | awk "\$2 == 1048576"
00007fa383e00000 1048576  804864  804864 rw---   [ anon ]
```

Antes, 446464 KiB da área de memória do convidado estavam residentes no host; depois, 804864 KiB. Lá dentro, o
programa terminou e o `free` mostra a memória livre de novo, mas **o host não a recebe de volta**: para o
host, uma página que o convidado tocou é uma página em uso, seja lá o que o convidado fez com ela
depois.

É por isso que um host consegue ligar convidados cuja memória soma mais do que ele tem, o que se chama
**overcommit**, e é por isso que funciona até o dia em que todos ficam ocupados. Aí falta memória ao
host, ele começa a usar swap, e no fim mata um processo para sobreviver, e o processo que ele escolhe
costuma ser o maior: um convidado.

O **balão** é o jeito de tomar memória de volta de um convidado ligado. Um driver pequeno no convidado, o
`virtio_balloon`, aloca memória dentro do convidado quando o host pede, para o sistema do próprio
convidado parar de usá-la, e devolve essas páginas:

```
ana@host:~$ virsh setmem vm1 524288 --live

ana@vm1:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             449         231         161           0         204         217
ana@host:~$ virsh dommemstat vm1 | grep -E "^(actual|rss)"
actual 524288
rss 1548340
ana@host:~$ virsh setmem vm1 1048576 --live

ana@vm1:~$ free -m | head -2
               total        used        free      shared  buff/cache   available
Mem:             961         247         657           0         204         713
```

Com o balão inflado para deixar 512 MiB, o `free` do convidado mostra 449 MiB no total, e o `rss` do
processo é 1548340 KiB, menor do que era antes de o convidado tocar os 400 MB dele. Esvaziado de novo, o
convidado tem 961 MiB. É uma ferramenta bruta: um convidado apertado abaixo do que os programas dele
usam começa a usar swap, ou mata algo sozinho. É como o Proxmox e o ESXi movem memória entre convidados
num host ocupado, e por que a memória de um convidado nas interfaces deles pode mudar sem ninguém a
editar.
