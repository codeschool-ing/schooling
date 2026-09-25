---
title: A lista de autoridades em que uma máquina confia
version: 1
---

Todo sistema traz um **repositório de certificados confiáveis** (*trust store*): os certificados raiz
que ele aceita no topo de uma cadeia. No Ubuntu, eles ficam em `/etc/ssl/certs`, reunidos num arquivo
único que programas como o `curl` leem:

```
ana@laptop:~$ ls /etc/ssl/certs/*.pem | wc -l
123
ana@laptop:~$ grep -c "BEGIN CERTIFICATE" /etc/ssl/certs/ca-certificates.crt
122
ana@laptop:~$ openssl x509 -in /etc/ssl/certs/example-root-ca.pem -noout -subject -issuer -enddate
subject=O = Example Trust Services, CN = Example Root CA
issuer=O = Example Trust Services, CN = Example Root CA
notAfter=Sep 22 17:03:47 2036 GMT
```

122 certificados no arquivo, e cada um é uma organização que pode garantir qualquer nome da internet. A
raiz do próprio laboratório está entre eles, acrescentada quando o laboratório foi montado; o
`subject` e o `issuer` dela são iguais, e é isso que a torna uma raiz. Ela vale até 2036, como raízes
costumam valer por uma década ou mais.

Num Ubuntu de verdade, a lista vem do pacote `ca-certificates`, que segue a lista da Mozilla, e as
atualizações chegam com as do sistema (aula 16 de operating-systems). O Windows tem a sua lista,
atualizada pelo Windows Update; o macOS tem uma no keychain do sistema; o Firefox traz a dele;
programas Java muitas vezes trazem outra. **Um certificado pode ser aceito por um programa e recusado
por outro na mesma máquina**, e quando isso acontece os dois repositórios são a primeira coisa a
comparar.
