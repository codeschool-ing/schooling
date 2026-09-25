---
title: Vendo a expiração antes de ela chegar
version: 1
---

Um certificado expirado é a queda de certificado mais comum, e a mais evitável: a data dele foi escrita
nele no dia em que foi feito. O `openssl x509 -checkend` responde "ele ainda vale daqui a tantos
segundos?":

```
ana@laptop:~$ echo | openssl s_client -connect www.example.com:443 -servername www.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 2592000
notAfter=Dec 24 17:03:48 2026 GMT
Certificate will not expire
ana@laptop:~$ echo | openssl s_client -connect expired.example.com:443 -servername expired.example.com 2>/dev/null | openssl x509 -noout -enddate -checkend 0
notAfter=Aug 30 00:00:00 2025 GMT
Certificate will expire
```

`2592000` segundos são 30 dias. **`Certificate will not expire` quer dizer que ele vale por pelo menos
mais trinta dias**; o expirado falha até com `-checkend 0`. As datas são julgadas pelo relógio do
próprio cliente, e por isso um PC com o relógio errado diz que todo certificado está expirado, ou
ainda não vale, mande o servidor o que mandar. O comando também sai com um status, 0 ou 1,
e isso facilita rodá-lo numa tarefa agendada (aula 14 de operating-systems) que manda um aviso com um
mês de antecedência.

Serviços de monitoramento fazem o mesmo de fora, e isso também pega um certificado que foi renovado no
disco mas nunca carregado por um servidor que não foi reiniciado. **Conferir o certificado que o
servidor de fato manda, como estes comandos fazem, é a única conferência que conta**: o arquivo no
disco é o que deveria ser servido, não necessariamente o que é.
