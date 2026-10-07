---
title: O arquivo que passa por cima do DNS
version: 2
---

Antes de qualquer pergunta de DNS, o sistema lê o **`/etc/hosts`**, e o `/etc/nsswitch.conf` diz isso:

```
ana@laptop:~$ grep hosts /etc/nsswitch.conf
hosts:          files dns
ana@laptop:~$ echo "192.0.2.99 www.example.com" | sudo tee -a /etc/hosts
192.0.2.99 www.example.com
ana@laptop:~$ getent hosts www.example.com
2001:db8:10::80 www.example.com
ana@laptop:~$ dig +short www.example.com
192.0.2.81
ana@laptop:~$ curl -sS -m 3 https://www.example.com/
curl: (28) Connection timed out after 3002 milliseconds
```

`hosts: files dns`: o arquivo primeiro, o DNS só se o arquivo não tiver nada. Uma linha acrescentada ao
arquivo do laptop, e o laptop discorda da internet inteira. **O `dig`, que pergunta direto ao DNS, diz
`192.0.2.81`. O `curl` acreditou no arquivo**, tentou `192.0.2.99`, onde não mora nada, e deu timeout.
O `getent hosts` mostra a pegadinha no meio: ele pede um endereço IPv6 primeiro, o arquivo não tem
nenhum para esse nome, e então ele seguiu para o DNS e imprimiu o registro `AAAA`. Uma linha no
arquivo hosts só vale para o tipo de endereço com que foi escrita.

Essa discordância é o diagnóstico inteiro. Quando o `dig` dá a resposta certa e um programa ainda vai
para o lugar errado, **olhe o arquivo hosts**, onde uma linha esquecida por um desenvolvedor testando
um servidor novo, ou posta por um malware desviando o nome de um banco, vence todo servidor de DNS do
mundo.

O `dig` e o `nslookup` perguntam ao DNS e ignoram o arquivo; o `getent hosts` e o `ping` passam pelo
resolvedor do sistema e o leem. Comparar os dois é um teste de dez segundos que encontra isso toda vez.
No Windows, o arquivo é `C:\Windows\System32\drivers\etc\hosts`, e funciona do mesmo jeito.

Antes de seguir, tire a linha do arquivo do laptop de novo:
`sudo sed -i '/www.example.com/d' /etc/hosts`.
