---
title: Um endereço público para o escritório inteiro
version: 1
---

`192.168.10.20` é um **endereço privado**. As faixas `10.0.0.0/8`, `172.16.0.0/12` e `192.168.0.0/16`
são reservadas pela RFC 1918 para uso dentro de qualquer prédio, e a internet não as roteia: milhões de
escritórios usam `192.168.10.20` ao mesmo tempo. Para sair, o escritório pega emprestado o único
endereço público que o provedor lhe deu, `203.0.113.2`. Isso é **NAT**, *network address translation*,
tradução de endereços de rede, e é uma regra no roteador do escritório:

```
ana@router:~$ sudo nft list ruleset
table ip nat {
        chain postrouting {
                type nat hook postrouting priority srcnat; policy accept;
                oifname "eth1" masquerade
        }
}
ana@www:~$ tail -1 /var/log/nginx/access.log
203.0.113.2 - - [25/Sep/2026:13:16:09 -0300] "GET / HTTP/2.0" 200 173 "-" "curl/8.5.0"
```

`masquerade` quer dizer: o que sair pela `eth1`, o lado do provedor, recebe como origem o endereço do
próprio roteador daquele lado. O roteador lembra cada conexão que reescreveu, e quando uma resposta
volta para `203.0.113.2`, ele devolve o endereço do laptop e manda para dentro. O laptop nunca fica
sabendo.

**O servidor web, menos ainda.** O log dele registra cada visitante, e a última linha é o laptop
buscando a página um momento antes: vindo de `203.0.113.2`. Toda máquina do escritório aparece lá fora
como esse único endereço. É por isso que o "bloquear este IP" de um site pode deixar um escritório
inteiro de fora pelo erro de uma pessoa, e por isso que ninguém de fora consegue conectar *para
dentro*, no laptop, a menos que o roteador seja instruído a encaminhar uma porta para ele, o que a aula
7 faz para o SSH.

Ler e planejar faixas privadas é assunto do curso networks-addressing. Para suporte, o sinal a
reconhecer é um endereço que começa com `10.`, de `172.16.` a `172.31.`, ou `192.168.`: ele está dentro
de um prédio, e o roteador de alguém o está traduzindo.
