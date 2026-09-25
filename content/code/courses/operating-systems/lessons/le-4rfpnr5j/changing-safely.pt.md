---
title: Mudando uma configuração de um jeito desfazível
version: 1
---

A impressora do escritório deveria ser alcançável pelo nome, `printer.office`, antes de existir um
servidor DNS que a conheça. Isso é uma linha no `/etc/hosts`, e ela é mudada do jeito cuidadoso:

```
ana@server:~$ sudo cp /etc/hosts /etc/hosts.bak
ana@server:~$ echo '192.168.1.50  printer.office' | sudo tee -a /etc/hosts
192.168.1.50  printer.office
ana@server:~$ diff /etc/hosts.bak /etc/hosts
2a3
> 192.168.1.50  printer.office
ana@server:~$ getent hosts printer.office
192.168.1.50    printer.office
ana@server:~$ sudo mv /etc/hosts.bak /etc/hosts
ana@server:~$ cat /etc/hosts
127.0.0.1 localhost
127.0.1.1 server
```

1. **Copie antes.** O `/etc/hosts.bak` é o caminho de volta, feito antes de qualquer mudança.
2. **Mude uma coisa.** O `tee -a` acrescentou uma linha; o `sudo` foi necessário porque o `/etc` é do
   root. (`sudo echo … >> /etc/hosts` falha, porque o `>>` é feito pelo seu shell, como você, antes de o
   sudo rodar. É por isso que se usa o `tee`.)
3. **Veja exatamente o que mudou.** O `diff` comparou a cópia com o arquivo: depois da linha 2, uma linha
   acrescentada.
4. **Teste.** O `getent hosts` pediu ao sistema para resolver o nome, e ele resolveu.
5. **Saiba desfazer.** Mover a cópia de volta restaurou o original, e o `cat` o mostra.

A maioria dos erros de configuração não são configurações erradas. São mudanças que ninguém consegue
desfazer porque ninguém guardou o original, e mudanças que ninguém consegue explicar porque ninguém
anotou o que ficou diferente. Os passos 1 e 3 são a cura inteira.

Depois de mudar a configuração de um serviço, o **`systemctl restart`** da aula 14 o faz ler o arquivo de
novo. O `/etc/hosts` não precisa de reinício: ele é lido a cada consulta.
