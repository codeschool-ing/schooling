---
title: A cadeia de confiança
version: 1
---

O laptop nunca viu o certificado de `www.example.com`. Ele confia nele por causa de quem o assinou, e
de quem assinou esses. O `openssl s_client` imprime o caminho:

```
ana@laptop:~$ openssl s_client -connect www.example.com:443 -servername www.example.com </dev/null 2>&1 | grep -E "^depth|^ *[0-9] s:|^ *i:|Verify return"
depth=2 O = Example Trust Services, CN = Example Root CA
depth=1 O = Example Trust Services, CN = Example Issuing CA 1
depth=0 CN = www.example.com
 0 s:CN = www.example.com
   i:O = Example Trust Services, CN = Example Issuing CA 1
 1 s:O = Example Trust Services, CN = Example Issuing CA 1
   i:O = Example Trust Services, CN = Example Root CA
Verify return code: 0 (ok)
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A cadeia de confiança de www.example.com. Na profundidade 0, o certificado do servidor, www.example.com, válido por 90 dias, assinado pela Example Issuing CA 1 e mandado pelo servidor. Na profundidade 1, a Example Issuing CA 1, assinada pela raiz, também mandada pelo servidor. Na profundidade 2, a Example Root CA, assinada por ela mesma, válida até 2036, que não é mandada: o laptop já a tem, no repositório de certificados confiáveis. O laptop confere cada assinatura subindo, até chegar a um certificado em que já confia.\"><defs><marker id=\"ch-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"150\" y=\"20\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"40\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Example Root CA</text><text x=\"164\" y=\"60\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinado por ele mesmo, válido até 2036</text><text x=\"20\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">profundidade 2</text><text x=\"470\" y=\"49\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">já está no laptop, no repositório confiável</text><rect x=\"150\" y=\"116\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"136\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">Example Issuing CA 1</text><text x=\"164\" y=\"156\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinado pela raiz</text><text x=\"20\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">profundidade 1</text><text x=\"470\" y=\"145\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandado pelo servidor</text><path d=\"M300 114 L300 80\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"312\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinou</text><rect x=\"150\" y=\"212\" width=\"300\" height=\"58\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"164\" y=\"232\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11.5\" font-weight=\"600\" fill=\"var(--paper)\">www.example.com</text><text x=\"164\" y=\"252\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinado pela Issuing CA 1, válido por 90 dias</text><text x=\"20\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">profundidade 0</text><text x=\"470\" y=\"241\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">mandado pelo servidor</text><path d=\"M300 210 L300 176\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#ch-ah)\"></path><text x=\"312\" y=\"192\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinou</text></svg>", "caption": "O servidor manda o próprio certificado e o intermediário; a raiz já precisa estar no cliente. A verificação sobe pelas setas e só dá certo se terminar numa raiz em que o cliente confia.", "same": ["Example Issuing CA 1", "Example Root CA", "www.example.com"]}
```

Leia os pares `s:` (subject) e `i:` (issuer). **O servidor mandou dois certificados**: o seu, `0`,
emitido pela `Issuing CA 1`, e a própria `Issuing CA 1`, `1`, emitida pela `Root CA`. Ele não mandou a
raiz, e não deveria: **uma raiz só é confiável porque já está no cliente**, posta ali pelo sistema
operacional ou pelo navegador. As linhas `depth=` são as conferências do laptop, da raiz na
profundidade 2 até o site na profundidade 0, e `Verify return code: 0 (ok)` é o resultado.

Por que o certificado do meio? A chave privada da raiz é a coisa mais valiosa que uma autoridade
certificadora tem, então ela é guardada fora de qualquer rede e usada só para assinar alguns
certificados **intermediários**. Os intermediários assinam os certificados do dia a dia. Se um
intermediário for comprometido, ele pode ser revogado e trocado sem pedir a todo computador do mundo
que mude a lista de raízes.
