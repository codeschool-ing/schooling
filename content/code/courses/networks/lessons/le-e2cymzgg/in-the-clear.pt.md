---
title: Tudo às claras
version: 1
---

O FTP puro não cifra nada. Da máquina do ISP, por onde passa todo pacote entre o escritório e o `www`,
um login e uma listagem ficam assim:

```
ana@isp:~$ sudo timeout 6 tcpdump -i eth0 -n -l "tcp port 21" 2>/dev/null | grep -oE "FTP: .*"
FTP: 220 (vsFTPd 3.0.5)
FTP: USER example
FTP: 331 Please specify the password.
FTP: PASS Sunflower-77
FTP: 230 Login successful.
FTP: PWD
FTP: 257 "/" is the current directory
FTP: EPSV
FTP: 229 Entering Extended Passive Mode (|||40008|)
FTP: TYPE A
FTP: 200 Switching to ASCII mode.
FTP: LIST
FTP: 150 Here comes the directory listing.
FTP: 226 Directory send OK.
FTP: QUIT
FTP: 221 Goodbye.
```

**A conversa inteira, e a senha nela, `PASS Sunflower-77`.** Qualquer um no caminho vê o mesmo: o ISP,
o Wi-Fi do hotel, alguém na rede do escritório com um laptop e dez minutos. Os arquivos viajam do mesmo
jeito, nas conexões de dados. É o HTTP puro da aula 5 de novo, com uma senha por cima.

Essa senha também é a da conta de hospedagem, então quem a lê pode trocar o site. **Uma senha de FTP
puro deve ser tratada como já conhecida**: nunca igual a nenhuma outra senha, e trocada quando o FTP for
substituído por um dos jeitos cifrados abaixo.
