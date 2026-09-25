---
title: Quatro jeitos de um certificado falhar
version: 1
---

O mesmo servidor web também responde por mais quatro nomes, cada um com um certificado quebrado. Cada
falha tem a sua mensagem, e cada uma aponta para um lugar diferente.

**Expirado.** As datas estão no passado:

```
ana@laptop:~$ curl -sS -o /dev/null https://expired.example.com/
curl: (60) SSL certificate problem: certificate has expired
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect expired.example.com:443 -servername expired.example.com </dev/null 2>/dev/null | openssl x509 -noout -dates
notBefore=Jun  1 00:00:00 2025 GMT
notAfter=Aug 30 00:00:00 2025 GMT
```

**Autoassinado.** Ninguém garantiu por ele; o `issuer` é o próprio certificado:

```
ana@laptop:~$ curl -sS -o /dev/null https://selfsigned.example.com/
curl: (60) SSL certificate problem: self-signed certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect selfsigned.example.com:443 -servername selfsigned.example.com </dev/null 2>/dev/null | openssl x509 -noout -subject -issuer
subject=CN = selfsigned.example.com
issuer=CN = selfsigned.example.com
```

**Nome errado.** O certificado é perfeitamente válido, para outros nomes. O `--resolve` manda
`wrong.example.com` para o endereço do servidor web sem passar pelo DNS, como faria um erro de
digitação num favorito, ou um servidor respondendo por um nome para o qual não foi configurado:

```
ana@laptop:~$ curl -sS -o /dev/null --resolve wrong.example.com:443:192.0.2.80 https://wrong.example.com/
curl: (60) SSL: no alternative certificate subject name matches target host name 'wrong.example.com'
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
```

**Intermediário faltando.** O certificado está bem e o emissor dele está bem, mas o servidor mandou só
o próprio certificado, `0`, e não a `Issuing CA 1`:

```
ana@laptop:~$ curl -sS -o /dev/null https://nochain.example.com/
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
ana@laptop:~$ openssl s_client -connect nochain.example.com:443 -servername nochain.example.com </dev/null 2>&1 | grep -E "^ *[0-9] s:|^ *i:|Verify return"
 0 s:CN = nochain.example.com
   i:O = Example Trust Services, CN = Example Issuing CA 1
Verify return code: 21 (unable to verify the first certificate)
```

O laptop tem a raiz, e não consegue chegar a ela: falta o elo do meio. **Esta é traiçoeira**, porque
alguns navegadores lembram intermediários que viram em outro lugar, ou os buscam, e mostram o site como
bom, enquanto o `curl`, celulares e outros programas falham. "Funciona no meu navegador" não é teste de
cadeia de certificados.

O `openssl` dá a cada falha um número, e é ele que aparece nos logs:

```
ana@laptop:~$ for h in expired selfsigned nochain; do printf "%-11s " $h; openssl s_client -connect $h.example.com:443 -servername $h.example.com </dev/null 2>/dev/null | grep "Verify return"; done
expired     Verify return code: 10 (certificate has expired)
selfsigned  Verify return code: 18 (self-signed certificate)
nochain     Verify return code: 21 (unable to verify the first certificate)
```

| falha | o curl diz | o conserto |
|---|---|---|
| expirado | `certificate has expired` | renovar, e automatizar a renovação |
| autoassinado | `self-signed certificate` | um certificado de uma CA em que os clientes confiam |
| nome errado | `no alternative certificate subject name matches` | um certificado com esse nome no SAN |
| intermediário faltando | `unable to get local issuer certificate` | configurar o servidor com a cadeia completa |

**Nunca "conserte" nenhum deles mandando o cliente não conferir**, o `curl -k` ou o "continuar assim
mesmo" do navegador: a conferência é a única coisa que distingue um servidor de verdade de alguém
fingindo ser ele.
