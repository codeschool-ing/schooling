---
title: A rede do laboratório
version: 1
---

Primeiro a rede, descrita nas mesmas poucas linhas da rede isolada da aula 11:

```
ana@host:~$ cat labnet.xml
<network>
  <name>labnet</name>
  <bridge name="virbr2"/>
  <ip address="10.20.0.1" netmask="255.255.255.0">
    <dhcp>
      <range start="10.20.0.10" end="10.20.0.50"/>
    </dhcp>
  </ip>
</network>
ana@host:~$ virsh net-define labnet.xml && virsh net-start labnet && virsh net-autostart labnet
Network labnet defined from labnet.xml

Network labnet started

Network labnet marked as autostarted
```

Sem elemento `forward`, então nada sai dela; uma faixa de endereços própria, `10.20.0.0/24`, para não ser
confundida com nenhuma outra rede do host; e **`net-autostart`**, para a rede do laboratório voltar sozinha
quando o host reiniciar. Uma rede que precisa ser ligada à mão é um laboratório que não funciona na manhã
em que você precisa dele.
