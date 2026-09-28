---
title: Enterprise, uma chave para cada pessoa
version: 1
---

Uma passphrase compartilhada tem três problemas que nenhum algoritmo resolve. Quando alguém sai, **os
aparelhos de todo mundo precisam da nova**. O log não consegue dizer quem estava conectado, só que um
aparelho conhecia o segredo. E o segredo está num post-it em algum lugar, porque duzentas pessoas tiveram
de digitá-lo.

O WPA2-Enterprise e o WPA3-Enterprise trocam a passphrase pelo **802.1X**: cada pessoa entra com as
próprias credenciais, e o AP só a deixa passar quando um servidor diz sim. Três partes participam.

| papel no 802.1X | quem faz o papel | o que faz |
|---|---|---|
| suplicante | o sistema operacional do cliente | apresenta as credenciais |
| autenticador | o ponto de acesso | repassa, e aplica o veredito |
| servidor de autenticação | um servidor RADIUS | confere as credenciais num diretório |

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 420\" role=\"img\" aria-label=\"Uma sequência entre três partes: um cliente, o suplicante; um ponto de acesso, o autenticador; e um servidor RADIUS, o servidor de autenticação. Entre cliente e AP, o EAP viaja pelo ar em EAPOL; entre AP e servidor, o RADIUS viaja no cabo em UDP 1812. 1: o cliente associa e a porta só deixa passar EAP. 2: o AP pergunta quem é. 3: uma identidade, repassada pelo AP ao servidor. 4: um túnel TLS, em que o cliente confere o certificado do servidor. 5: uma senha ou um certificado do cliente, dentro do TLS. 6: o servidor manda o AP aceitar, com uma chave desta sessão e uma VLAN. 7: o four-way handshake entre cliente e AP, e aí a porta abre.\"><defs><marker id=\"dx-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"110.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cliente</text><text x=\"110\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">suplicante</text><path d=\"M110 80 L110 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"260\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"350.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ponto de acesso</text><text x=\"350\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">autenticador</text><path d=\"M350 80 L350 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><rect x=\"500\" y=\"14\" width=\"180\" height=\"42\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.4\"></rect><text x=\"590.0\" y=\"35.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">servidor RADIUS</text><text x=\"590\" y=\"70\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">servidor de autenticação</text><path d=\"M590 80 L590 410\" stroke=\"var(--wire)\" stroke-width=\"1.4\" fill=\"none\" stroke-dasharray=\"3 4\"></path><text x=\"230\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">no ar: EAP em EAPOL</text><text x=\"470\" y=\"94\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--phosphor)\">no cabo: RADIUS, UDP 1812</text><text x=\"230.0\" y=\"121\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">1  associa: a porta só deixa passar EAP</text><path d=\"M110 130 L344 130\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"230.0\" y=\"163\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">2  EAP: quem é você?</text><path d=\"M350 172 L116 172\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"205\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">3  uma identidade, repassada pelo AP</text><path d=\"M110 214 L584 214\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"247\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">4  TLS: o cliente confere o certificado do servidor</text><path d=\"M590 256 L116 256\" stroke=\"var(--amber)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"350.0\" y=\"289\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">5  senha ou certificado do cliente, dentro do TLS</text><path d=\"M110 298 L584 298\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"470.0\" y=\"331\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">6  aceite: uma chave desta sessão, e uma VLAN</text><path d=\"M590 340 L356 340\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path><text x=\"230.0\" y=\"373\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">7  four-way handshake, e a porta abre</text><path d=\"M350 382 L116 382\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" fill=\"none\" marker-end=\"url(#dx-ah)\"></path></svg>", "caption": "802.1X com um método EAP baseado em TLS, como PEAP, EAP-TTLS ou EAP-TLS. O AP nunca vê a senha: ele repassa, espera o veredito do servidor e recebe uma chave feita para esta sessão."}
```

Até o veredito chegar, **o AP deixa passar EAP e mais nada**: nada de DHCP, nada de DNS, nenhum tráfego
de nenhum tipo. O EAP, Extensible Authentication Protocol, é só um envelope. Entre cliente e AP ele viaja
em quadros EAPOL; entre AP e servidor viaja dentro do RADIUS, em UDP 1812. O que vai dentro do envelope é
o **método EAP**, e três cobrem quase todas as redes:

| método | o cliente se prova com | o que ele exige |
|---|---|---|
| EAP-TLS | o próprio certificado | um certificado em cada aparelho, então uma PKI e gestão de aparelhos |
| PEAP (com MSCHAPv2 dentro) | usuário e senha | um certificado de servidor |
| EAP-TTLS | usuário e senha, ou outro método interno | um certificado de servidor |

**O EAP-TLS é o mais forte, porque não há senha para roubar.** O PEAP é o mais comum, porque os usuários
já têm senhas. Os dois começam do mesmo jeito: o servidor mostra o certificado dele e um túnel TLS é
montado, e a senha só viaja dentro dele.

## A configuração que mais importa

**O cliente precisa conferir o certificado do servidor RADIUS**: que foi emitido pela autoridade
certificadora que você escolheu e que traz o nome do seu servidor. Um cliente que aceita qualquer
certificado monta o túnel TLS com qualquer rede que anuncie o mesmo SSID e faz a troca com ela. Conferir o
certificado é o que faz o túnel levar ao lugar certo. Isso pertence à configuração enviada a todo aparelho
gerenciado, não a uma caixa de diálogo em que o usuário clica no primeiro dia.

## O que o servidor devolve

Quando as credenciais estão certas, o servidor responde com um Access-Accept que leva **material de chave
feito para esta sessão**. O AP o usa como PMK, e o four-way handshake da seção sobre o WPA2 roda como
sempre. Duas coisas decorrem disso:

- cada pessoa tem uma chave diferente, então um colega no mesmo SSID não consegue ler o seu tráfego, nem
  com uma gravação do seu handshake;
- remover uma pessoa é uma mudança só: desative a conta dela e a próxima autenticação falha. Os registros
  de accounting do RADIUS, em UDP 1813, também dizem quem estava conectado, quando e por qual AP.

O aceite também pode levar uma **VLAN** (a RFC 3580 define os atributos). Um SSID pode então pôr os
funcionários numa VLAN e os terceirizados em outra, com o firewall entre elas decidindo o que cada uma
alcança. É assim que um SSID atende a muitos grupos sem pagar o tempo de ar de muitos SSIDs.

## O preço

Um servidor RADIUS passa a estar no caminho de toda conexão nova. **Se ele cair, ninguém novo entra**,
então ele roda em pares, o tipo de dependência de que trata a aula 14. E os aparelhos que não fazem
802.1X, impressoras e sensores principalmente, vão para um SSID separado com passphrase e VLAN próprias.
