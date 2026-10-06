---
title: O servidor prova quem é, e os dois lados selam a conversa
version: 1
---

**Depois dos hellos, o servidor manda sua cadeia de certificados, assina a conversa inteira até ali
com a chave privada do certificado e fecha com um MAC sobre tudo.** O cliente confere as três coisas
e depois manda o próprio MAC. Quatro mensagens cifradas levam as aulas 3, 6, 7, 8 e 9 de uma vez. A
figura mostra a troca inteira da captura da seção anterior, mensagem por mensagem:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 420\" role=\"img\" aria-label=\"O handshake TLS 1.3 entre o cliente e o portal.vereda.example. O cliente manda o ClientHello com as versões aceitas, as suítes de cifras, o nome do servidor e um key share X25519. O servidor responde com o ServerHello, escolhendo TLS 1.3, TLS_AES_256_GCM_SHA384 e o próprio key share X25519; daí em diante os dois derivam as chaves do handshake e o resto é cifrado. O servidor então manda EncryptedExtensions, Certificate com os certificados do portal e da AC emissora, CertificateVerify assinado com a chave P-256 sobre a transcrição, e Finished. O cliente confere a cadeia, as datas e o nome, verifica a assinatura e o MAC do Finished, e manda o próprio Finished, seguido logo dos dados da aplicação.\"><defs><marker id=\"hs-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker><marker id=\"hs-ah-wire\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--wire)\"></path></marker></defs><text x=\"90\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">cliente</text><text x=\"630\" y=\"20\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"11\" fill=\"var(--paper)\">portal.vereda.example</text><polyline points=\"90,32 90,405\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"630,32 630,405\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1\" stroke-dasharray=\"4 3\"></polyline><polyline points=\"92,55 628,55\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-wire)\"></polyline><text x=\"360\" y=\"46\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ClientHello</text><text x=\"360\" y=\"66\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">versões, suítes, SNI, share X25519</text><polyline points=\"628,105 92,105\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-wire)\"></polyline><text x=\"360\" y=\"96\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">ServerHello</text><text x=\"360\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">TLS 1.3, AES-256-GCM, share X25519</text><polyline points=\"628,175 92,175\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">EncryptedExtensions</text><polyline points=\"628,210 92,210\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"201\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Certificate</text><text x=\"360\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">portal + Vereda Issuing CA 1</text><polyline points=\"628,255 92,255\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"246\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">CertificateVerify</text><text x=\"360\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">assinatura P-256 sobre a transcrição</text><polyline points=\"628,300 92,300\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"291\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Finished</text><text x=\"360\" y=\"311\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">MAC sobre a transcrição</text><polyline points=\"92,345 628,345\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"336\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">Finished</text><text x=\"360\" y=\"356\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o MAC do cliente</text><polyline points=\"92,385 628,385\" fill=\"none\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\" marker-end=\"url(#hs-ah-phosphor)\"></polyline><text x=\"360\" y=\"376\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">dados da aplicação</text><rect x=\"150\" y=\"131\" width=\"420\" height=\"2\" rx=\"0\" fill=\"var(--amber)\" stroke=\"var(--amber)\" stroke-width=\"0.5\"></rect><text x=\"360\" y=\"143\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">cifrado daqui em diante, com chaves da troca X25519</text><text x=\"20\" y=\"255\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">confere cadeia,</text><text x=\"20\" y=\"270\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">datas, nome</text></svg>", "caption": "Uma ida e volta: um hello em cada sentido, e todo o resto cifrado.", "same": ["portal + Vereda Issuing CA 1"]}
```

## EncryptedExtensions

A primeira mensagem cifrada traz as respostas do servidor às extensões que não precisam ir em
claro, como qual protocolo de aplicação ele escolheu (`h2` para HTTP/2, quando o cliente ofereceu).
No laboratório ela está vazia, com dois bytes.

## Certificate

O servidor manda sua cadeia: na captura, `portal.vereda.example` e `Vereda Issuing CA 1`. Não a
raiz: o cliente já precisa tê-la, e uma raiz mandada pelo servidor não provaria nada, porque
qualquer um consegue mandar uma. O cliente então roda todas as verificações da aula 9:

- a cadeia leva a uma raiz do seu repositório de confiança, com cada assinatura verificando com a
  chave de cima;
- cada certificado está dentro das datas, no relógio do cliente;
- o nome que o cliente pediu, aqui `portal.vereda.example`, está no Subject Alternative Name;
- os usos de chave permitem um servidor TLS;
- a revogação, se o cliente a conferir.

## CertificateVerify

Uma cadeia prova que uma chave pertence a um nome. Não prova que a máquina que responde **tem**
essa chave: o certificado é público, e qualquer um pode mandar uma cópia. Então o servidor assina um
hash da **transcrição**, todas as mensagens do handshake até ali, com a chave privada do
certificado. A captura mostra o algoritmo: `ecdsa_secp256r1_sha256`, a chave P-256 da aula 9.

Essa é a assinatura que a aula 7 disse derrotar um homem no meio. A transcrição inclui os dois
key shares, então a assinatura amarra a identidade do servidor a **esta** troca. Um atacante no meio
fez uma troca diferente com o cliente e não consegue produzir uma assinatura sobre ela.

## Finished, nos dois sentidos

Cada lado manda uma mensagem **Finished**: um HMAC, com chave derivada do segredo do handshake,
sobre a transcrição inteira. Se algo nos hellos foi alterado no caminho, por exemplo uma lista de
suítes cortada para forçar uma escolha mais fraca, os dois lados calcularam as transcrições sobre
bytes diferentes, os MACs discordam e a conexão cai. O Finished do servidor chega no primeiro voo
dele; o cliente manda o seu e já pode mandar os primeiros dados da aplicação no mesmo voo, que é a
"uma ida e volta" do TLS 1.3.

## E o cliente?

No tráfego web comum, só o servidor prova a identidade; o usuário faz login depois, dentro da
conexão cifrada. O TLS também pode autenticar o cliente: o servidor manda um `CertificateRequest`, e
o cliente responde com o próprio certificado e o próprio `CertificateVerify`. Isso é o **TLS
mútuo**, usado entre serviços internos e para dispositivos, e é o que o 802.1X faz numa rede Wi-Fi
corporativa na aula 16.
