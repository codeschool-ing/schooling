---
title: Round robin, e pesos para servidores desiguais
version: 1
---

A regra mais simples é revezar. **O round robin manda cada requisição nova para o próximo servidor da
lista**, voltando ao primeiro depois do último, e não precisa de informação nenhuma sobre os servidores:

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    server web1 192.0.2.21:80
    server web2 192.0.2.22:80
    server web3 192.0.2.23:80
ana@laptop:~$ for i in $(seq 6); do curl -s http://www.example.com/; done
served by web1
served by web2
served by web3
served by web1
served by web2
served by web3
```

Seis requisições, duas para cada, na ordem em que os servidores estão escritos. Com muitos clientes o
efeito é o mesmo: cada servidor recebe uma parte igual das requisições, o que é exatamente certo quando os
servidores são iguais e as requisições custam mais ou menos o mesmo.

Muitas vezes os servidores não são iguais. Uma máquina mais nova, com o dobro de núcleos, deveria receber o
dobro de trabalho, e o round robin não sabe disso. **Um peso diz quantas vezes cada servidor é a vez dele
em cada rodada:**

```
ana@lb1:~$ sed -n "/^backend/,\$p" /etc/haproxy/haproxy.cfg
backend web
    balance roundrobin
    server web1 192.0.2.21:80 weight 2
    server web2 192.0.2.22:80 weight 1
    server web3 192.0.2.23:80 weight 1
ana@laptop:~$ for i in $(seq 8); do curl -s http://www.example.com/; done | sort | uniq -c
      4 served by web1
      2 served by web2
      2 served by web3
```

Oito requisições, e `web1`, com peso 2, atendeu **4 delas**, enquanto `web2` e `web3` atenderam 2 cada. As
partes são os pesos sobre o total: 2 de 4 é metade das requisições, 1 de 4 é um quarto. Os pesos também
servem para pôr um servidor em serviço aos poucos. Um servidor novo, ou recém-atualizado, pode começar com
peso baixo e subir depois de mostrar que aguenta, o que o HAProxy permite em tempo de execução, sem
reiniciar.

A única suposição do round robin está na expressão "mais ou menos o mesmo". Ele conta requisições, não
trabalho. Uma requisição que transmite um arquivo grande e uma que devolve uma linha de texto são, as duas,
uma vez, e a próxima seção mostra quanto isso custa.
