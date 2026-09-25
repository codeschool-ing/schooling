---
title: Entra, e depois trava
version: 1
---

O modo passivo leva o problema para o lado do servidor. Toda conexão de dados vai para uma porta entre
40000 e 40009 no `www`, a faixa com que o servidor FTP foi configurado. O firewall na frente dele precisa
deixar essa faixa entrar, além da porta 21. Eis o firewall que esqueceu:

```
ana@www:~$ sudo nft add table inet ftp-guard
ana@www:~$ sudo nft add chain inet ftp-guard input '{ type filter hook input priority 0; }'
ana@www:~$ sudo nft add rule inet ftp-guard input tcp dport 40000-40009 drop
ana@laptop:~$ time curl -sS --connect-timeout 10 -u example:Sunflower-77 ftp://www.example.com/
curl: (28) Connection time-out

real    0m10.010s
user    0m0.003s
sys     0m0.006s
ana@www:~$ sudo nft delete table inet ftp-guard
```

**O login funcionou; a listagem nunca veio.** A porta 21 estava aberta, então a senha foi aceita, e
depois a conexão de dados para a porta passiva foi descartada sem resposta. O curl desistiu depois dos
dez segundos que o `--connect-timeout 10` deu. Um cliente sem limite de tempo próprio fica parado por
minutos, e a pessoa ao telefone diz "conecta, mas congela".

Esse sintoma exato é quase sempre isto. O conserto fica do lado do servidor: abrir a faixa passiva no
firewall dele, a que está escrita na configuração (`pasv_min_port` e `pasv_max_port` no vsftpd).
