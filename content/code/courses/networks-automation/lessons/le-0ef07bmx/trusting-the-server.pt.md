---
title: Confiando no servidor com quem você fala
version: 2
---

Toda requisição desta aula passou por HTTPS e indicou `lab-ca.pem`, o certificado da autoridade
certificadora do próprio lab, que o `netlab.sh` criou e copiou para a home da `ana`. Esse arquivo é o motivo de a
senha estar segura para ser enviada. Sem ele:

```
ana@ctl:~$ curl -sS https://edge1.example.net/api/v1/system; echo "exit status $?"
curl: (60) SSL certificate problem: unable to get local issuer certificate
More details here: https://curl.se/docs/sslcerts.html

curl failed to verify the legitimacy of the server and therefore could not
establish a secure connection to it. To learn more about this situation and
how to fix it, please visit the web page mentioned above.
exit status 60
ana@ctl:~$ python -c "import requests; requests.get('https://edge1.example.net/api/v1/system')" 2>&1 | tail -1
requests.exceptions.SSLError: HTTPSConnectionPool(host='edge1.example.net', port=443): Max retries exceeded with url: /api/v1/system (Caused by SSLError(SSLCertVerificationError(1, '[SSL: CERTIFICATE_VERIFY_FAILED] certificate verify failed: unable to get local issuer certificate (_ssl.c:1000)')))
```

Os dois se recusaram a conversar. O certificado do roteador foi emitido pela autoridade
certificadora do próprio lab, que não está em nenhum navegador nem em nenhum sistema operacional,
então **nada no `ctl` conseguia verificar que a máquina respondendo em `edge1.example.net` era o
`edge1`**. Essa é exatamente a situação que um atacante no meio do caminho cria, e recusar é o
comportamento correto.

Com a autoridade certificadora indicada, o `openssl` mostra o que está sendo verificado:

```
ana@ctl:~$ openssl s_client -connect edge1.example.net:443 -CAfile lab-ca.pem </dev/null 2>/dev/null | grep -E "^subject=|^issuer=|^Verify return code"
subject=CN = edge1.example.net
issuer=O = Lab, CN = Lab Root CA
Verify return code: 0 (ok)
```

O certificado nomeia `edge1.example.net`, foi emitido por `Lab Root CA`, e a cadeia foi
verificada: `0 (ok)`. Os equipamentos da própria empresa costumam estar nessa situação, com
certificados de uma autoridade interna, e a correção é sempre a mesma: **dê ao cliente o
certificado da autoridade**, com `verify=` no `requests` ou `--cacert` no `curl`.

A correção tentadora é a outra. `requests` aceita `verify=False` e `curl` aceita `-k`, e os dois
fazem o erro sumir não verificando nada. **Um script com `verify=False` envia a senha do roteador
para quem quer que responda**, e o aviso que o `requests` imprime sobre isso é do tipo que as
pessoas aprendem a rolar sem ler. Ele nunca aparece neste curso, e não deveria aparecer num
script que mexe numa rede de produção.

**O token também é uma senha.** Ele fica em `~/.token` durante esta aula porque a aula precisava
dele entre um comando e outro. Um programa o mantém na memória, nunca o escreve num log, e deixa
que ele expire; um token vazado só vale pelos quinze minutos que o roteador dá a ele.
