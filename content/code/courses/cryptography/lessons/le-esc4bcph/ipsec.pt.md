---
title: IPsec, cifragem na camada de rede
version: 1
---

**O IPsec cifra e autentica os próprios pacotes IP, entre dois hosts ou dois gateways, de modo que
toda aplicação cujo tráfego passa por aquele caminho fica protegida sem saber.** O TLS vive dentro
da conexão de uma aplicação; o IPsec vive na pilha de rede do sistema operacional. Ele é a
tecnologia clássica por trás das VPNs site a site, como as clínicas da Vereda se ligando à matriz
pela internet, e de muitas VPNs de acesso remoto.

**Esta seção não tem captura.** O kernel em que o curso foi gravado não oferece a transformação ESP
do IPsec dentro dos namespaces de rede do laboratório, e o curso não mostra saída que não conseguiu
rodar. O que segue é o protocolo como os padrões o descrevem.

## As peças

- O **ESP**, *Encapsulating Security Payload*, é a parte que protege os pacotes. Cada pacote leva um
  **SPI**, um número dizendo qual associação de segurança vale, um número de sequência contra
  repetição, a carga cifrada e uma etiqueta de integridade. Configurações modernas usam AES-GCM, o
  modo autenticado da aula 1. (O **AH**, *Authentication Header*, autentica sem cifrar; ele é pouco
  implantado porque o ESP faz as duas coisas e o AH quebra atrás de NAT.)
- O **IKEv2**, *Internet Key Exchange*, é o handshake que monta as chaves. É a aula 7 de novo: uma
  troca Diffie-Hellman efêmera para o sigilo futuro, autenticada com certificados ou com uma chave
  pré-compartilhada, produzindo as chaves que o ESP usa. Ele roda em UDP 500, e em UDP 4500 quando há
  NAT no caminho.
- Uma **associação de segurança** (SA) é o conjunto combinado de chaves e algoritmos para um sentido
  do tráfego entre dois pares. O IKE as cria, renova as chaves antes que se desgastem e as apaga.

## Dois modos

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 210\" role=\"img\" aria-label=\"Dois formatos de pacote. Modo transporte: o cabeçalho IP original, depois um cabeçalho ESP, depois o cabeçalho TCP e os dados cifrados, depois o trailer e a etiqueta do ESP. Modo túnel: um cabeçalho IP externo novo entre os dois gateways, um cabeçalho ESP, depois o pacote original inteiro cifrado, inclusive o cabeçalho IP dele, depois o trailer e a etiqueta do ESP.\"><text x=\"20\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">modo transporte</text><rect x=\"20\" y=\"36\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho IP</text><rect x=\"150\" y=\"36\" width=\"88\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"194.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><rect x=\"240\" y=\"36\" width=\"328\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"404.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho TCP + dados</text><rect x=\"570\" y=\"36\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634.0\" y=\"54\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">etiqueta ESP</text><text x=\"20\" y=\"112\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">modo túnel</text><rect x=\"20\" y=\"126\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"84.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho IP novo</text><rect x=\"150\" y=\"126\" width=\"68\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"184.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">ESP</text><rect x=\"220\" y=\"126\" width=\"118\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"279.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">IP original</text><rect x=\"340\" y=\"126\" width=\"228\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"454.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">cabeçalho TCP + dados</text><rect x=\"570\" y=\"126\" width=\"128\" height=\"36\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"634.0\" y=\"144\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper)\">etiqueta ESP</text><text x=\"20\" y=\"186\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">o observador só vê os dois gateways</text></svg>", "caption": "Vermelho viaja em texto claro; azul é cifrado. A etiqueta cobre o cabeçalho ESP e tudo o que é cifrado.", "same": ["ESP"]}
```

O **modo transporte** protege a carga de um pacote entre dois hosts e mantém o cabeçalho IP
original, então as pontas ficam visíveis. O **modo túnel** cifra o pacote original **inteiro** e o
embrulha num novo entre dois gateways, então um observador na internet só vê os dois gateways
conversando: nem quais máquinas dentro de cada escritório estão se comunicando, nem em quais portas.
VPNs site a site usam o modo túnel.

## O que um defensor confere

- **IKEv2, não IKEv1**, que tinha um projeto mais fraco e uma configuração errada comum ("aggressive
  mode") que expunha um hash da chave pré-compartilhada a quem pedisse;
- **certificados em vez de chave pré-compartilhada**, ou pelo menos uma longa e aleatória: uma chave
  compartilhada fraca pode ser adivinhada offline, o problema da aula 5 em outra forma;
- **AES-GCM com um grupo Diffie-Hellman de pelo menos 2048 bits, ou uma curva elíptica**, e nada de
  DES, 3DES ou MD5 deixado nas propostas por compatibilidade com um equipamento de que ninguém se
  lembra;
- o WireGuard, um protocolo de VPN mais novo, deixa a maior parte dessas escolhas fixa: X25519,
  ChaCha20-Poly1305, BLAKE2s, chaves em vez de senhas. Menos opções significa menos jeitos de
  configurá-lo mal.
