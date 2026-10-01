---
title: Verificando uma cadeia, elo por elo
version: 1
---

Um cliente verifica um certificado subindo a partir dele até uma raiz em que confia, conferindo a cada
passo que a assinatura é válida, que as datas estão em vigor e que o emissor tinha permissão para
assinar. O servidor ajuda enviando o próprio certificado **e o intermediário**, e o cliente fornece a
raiz a partir do seu repositório:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>/dev/null | grep -E "^ *[0-9] s:|^ *i:|^Verify return code"
 0 s:CN = www.example.com
   i:O = Example Corp, CN = Example Corp Issuing CA
 1 s:O = Example Corp, CN = Example Corp Issuing CA
   i:O = Example Corp, CN = Example Corp Root CA
Verify return code: 0 (ok)
```

A profundidade 0 é `www.example.com`, emitido pela CA emissora; a profundidade 1 é a CA emissora,
emitida pela raiz. A raiz não é enviada; o `laptop` já a tem. `Verify return code: 0 (ok)`.

O `openssl verify` faz a mesma subida à mão. Recebendo só a raiz como confiável e o certificado do
servidor, ele não encontra o elo do meio:

```
root@admin:~# cd ca; openssl verify -CAfile root.crt www.example.com.crt
CN = www.example.com
error 20 at 0 depth lookup: unable to get local issuer certificate
error www.example.com.crt: verification failed
```

Erro 20, `unable to get local issuer certificate`: o certificado nomeia um emissor que o verificador
não tem. Com o intermediário fornecido como **não confiável** (*untrusted*), um certificado a ser
verificado no caminho para cima em vez de acreditado por si só, a subida se completa:

```
root@admin:~# cd ca; openssl verify -CAfile root.crt -untrusted issuing.crt www.example.com.crt
www.example.com.crt: OK
```

Essa palavra importa. **Só as raízes são confiáveis; os intermediários são verificados.** Um servidor
que esquece de enviar o seu intermediário produz exatamente o erro 20 nos clientes que ainda não viram
aquele intermediário, que é a falha de cadeia incompleta da aula 6 de `networks` vista do lado da CA.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Como um cliente percorre uma cadeia. O servidor envia dois certificados: o seu, www.example.com, e o da CA emissora. O cliente tem a raiz no seu repositório de confiança. Ele confere que a CA emissora assinou www.example.com, depois que a raiz assinou a CA emissora, e para na raiz porque confia nela. Sem o certificado da CA emissora, a caminhada quebra no primeiro passo: erro 20.\"><defs><marker id=\"cw-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"180\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"196\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">www.example.com</text><text x=\"30\" y=\"213\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">profundidade 0: enviado pelo servidor</text><rect x=\"20\" y=\"100\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"116\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Example Corp Issuing CA</text><text x=\"30\" y=\"133\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">profundidade 1: enviado pelo servidor</text><rect x=\"20\" y=\"20\" width=\"220\" height=\"46\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"30\" y=\"36\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Example Corp Root CA</text><text x=\"30\" y=\"53\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">no repositório de confiança</text><path d=\"M130 180 L130 146\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cw-ah-paper-dim)\"></path><path d=\"M130 100 L130 66\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" marker-end=\"url(#cw-ah-paper-dim)\"></path><text x=\"142\" y=\"164\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinado por?</text><text x=\"142\" y=\"84\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinado por?</text><text x=\"300\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">de confiança: a caminhada para aqui</text><text x=\"300\" y=\"120\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conferido: assinatura, datas, CA:TRUE, pathlen:0</text><text x=\"300\" y=\"200\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">conferido: assinatura, datas, nome, uso da chave</text><text x=\"300\" y=\"230\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">sem a profundidade 1: erro 20, unable to get local issuer certificate</text></svg>", "caption": "Enviados pelo servidor: os dois primeiros. Já no cliente: a raiz. Só a raiz é de confiança; o resto é conferido."}
```
