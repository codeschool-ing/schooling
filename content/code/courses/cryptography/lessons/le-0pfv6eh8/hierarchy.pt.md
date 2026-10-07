---
title: Raízes, ACs emissoras e a cadeia entre elas
version: 1
---

**As autoridades certificadoras se organizam numa hierarquia: uma raiz assina uma ou mais ACs
emissoras, e as ACs emissoras assinam servidores.** Cada certificado nomeia o de cima como emissor, e
seguir esses nomes para cima é a cadeia que um navegador confere. A Vereda tem uma pequena, montada
pelo laboratório, e ela tem a mesma forma de toda AC pública.

## Três níveis

```
ana@lab:~/lab$ for c in root issuing1 portal; do openssl x509 -in pki/$c.pem -noout -subject -issuer; echo; done
subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA

subject=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA

subject=C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example
issuer=C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1
```

Leia os pares de baixo para cima. O certificado do portal foi emitido pela *Vereda Issuing CA 1*. O
certificado da AC emissora foi emitido pela *Vereda Root CA*. E o certificado da raiz foi emitido por
ela mesma: titular e emissor têm o mesmo nome. Uma raiz é **autoassinada**, porque não há ninguém
acima dela para assinar. A autoridade dela não vem do certificado; vem de estar numa lista de raízes
em que alguém decidiu confiar, assunto da próxima seção.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 300\" role=\"img\" aria-label=\"A cadeia de três certificados da Vereda. No topo, a Vereda Root CA, autoassinada, guardada offline e colocada no repositório de confiança dos clientes que devem confiar nela. Ela assina a Vereda Issuing CA 1, que tem pathlen 0. Essa assina o portal.vereda.example, que não é uma AC. O servidor manda o próprio certificado e o da AC emissora; o cliente tem só a raiz.\"><defs><marker id=\"chain-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><rect x=\"40\" y=\"20\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Vereda Root CA</text><text x=\"56\" y=\"64\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">autoassinada, CA:TRUE, pathlen:1</text><rect x=\"40\" y=\"110\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">Vereda Issuing CA 1</text><text x=\"56\" y=\"154\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CA:TRUE, pathlen:0</text><rect x=\"40\" y=\"200\" width=\"300\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"56\" y=\"222\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">portal.vereda.example</text><text x=\"56\" y=\"244\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">CA:FALSE, só servidor TLS</text><polyline points=\"190,82 190,108\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chain-ah-wire)\"></polyline><text x=\"204\" y=\"96\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assina</text><polyline points=\"190,172 190,198\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#chain-ah-wire)\"></polyline><text x=\"204\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assina</text><rect x=\"420\" y=\"20\" width=\"280\" height=\"62\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"436\" y=\"42\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">no repositório de confiança</text><text x=\"436\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">offline, num HSM, na Vereda</text><rect x=\"420\" y=\"110\" width=\"280\" height=\"152\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"5 3\"></rect><text x=\"436\" y=\"132\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">mandados pelo servidor</text><text x=\"436\" y=\"152\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">portal-chain.pem</text><polyline points=\"342,51 418,51\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"342,141 418,141\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"342,231 418,231\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></polyline></svg>", "caption": "Cada certificado é assinado pelo de cima; a raiz, por si mesma.", "same": ["CA:TRUE, pathlen:0"]}
```

## O que cada nível pode fazer

Os certificados dizem para que suas chaves podem ser usadas, em extensões marcadas `critical`, que um
verificador precisa entender ou recusar:

```
ana@lab:~/lab$ openssl x509 -in pki/root.pem -noout -ext basicConstraints,keyUsage
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:1
X509v3 Key Usage: critical
    Certificate Sign, CRL Sign
ana@lab:~/lab$ openssl x509 -in pki/issuing1.pem -noout -ext basicConstraints
X509v3 Basic Constraints: critical
    CA:TRUE, pathlen:0
ana@lab:~/lab$ openssl x509 -in pki/portal.pem -noout -ext basicConstraints,extendedKeyUsage
X509v3 Basic Constraints: critical
    CA:FALSE
X509v3 Extended Key Usage: 
    TLS Web Server Authentication
```

- a raiz é uma AC (`CA:TRUE`) cuja chave pode assinar certificados e listas de revogação, com
  `pathlen:1`: no máximo mais uma AC pode ficar abaixo dela;
- a AC emissora é uma AC com `pathlen:0`: pode assinar servidores, mas não criar outras ACs;
- o certificado do portal **não** é uma AC (`CA:FALSE`), e sua chave só pode autenticar um servidor
  TLS. Um certificado de servidor que pudesse assinar outros certificados deixaria quem comprometesse
  um único servidor web fabricar certificados para qualquer nome.

## Conferindo a cadeia

O `openssl verify` a percorre, recebendo a raiz como confiável e a AC emissora como ajudante não
confiável:

```
ana@lab:~/lab$ openssl verify -attime 1781535600 -show_chain -CAfile pki/root.pem -untrusted pki/issuing1.pem pki/portal.pem
pki/portal.pem: OK
Chain:
depth=0: C = BR, O = Vereda Fisioterapia, CN = portal.vereda.example (untrusted)
depth=1: C = BR, O = Vereda Fisioterapia, CN = Vereda Issuing CA 1 (untrusted)
depth=2: C = BR, O = Vereda Fisioterapia, CN = Vereda Root CA
```

`depth=0` é o portal, `depth=2` é a raiz. Os dois certificados de baixo aparecem como `(untrusted)`
porque só passam a ser aceitos quando a assinatura de cima confere; a raiz é confiável porque foi
passada com `-CAfile`. Um servidor precisa mandar o próprio certificado **e** o da AC emissora; do
cliente se espera que tenha só a raiz. Um servidor que esquece o intermediário é o erro de cadeia
mais comum que existe, e a próxima seção o produz de propósito.

## Por que não assinar servidores direto com a raiz

- **A chave da raiz é a única coisa que não dá para trocar depressa.** Trocar uma raiz significa
  colocar uma nova em todo repositório de confiança, o que leva anos. Por isso ela vive offline, num
  módulo de segurança de hardware dentro de um cofre, e é ligada algumas vezes por ano para assinar
  ACs emissoras e listas de revogação.
- **Uma AC emissora pode ser revogada e substituída** numa tarde, pela raiz, se a chave dela vazar.
- **ACs emissoras podem ser especializadas**: uma para servidores, uma para dispositivos de clientes,
  uma por região, cada uma com restrições sobre o que pode assinar.

Os mesmos motivos valem para uma AC **interna** como a da Vereda. Empresas mantêm uma para serviços
que nunca encaram a internet pública: APIs internas, TLS mútuo entre serviços, clientes de VPN,
Wi-Fi com 802.1X (aula 16). Ferramentas como step-ca, HashiCorp Vault e Microsoft AD CS fazem o
trabalho; as decisões são as de cima, mais uma: uma raiz interna precisa ser **distribuída** para
todo cliente que deve confiar nela, porque nenhum navegador a traz.
