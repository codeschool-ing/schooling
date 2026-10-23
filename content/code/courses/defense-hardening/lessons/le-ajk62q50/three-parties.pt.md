---
title: 802.1X, e as três partes de um login
version: 1
---

**O IEEE 802.1X faz um dispositivo fazer login na porta antes de a porta levar qualquer outra
coisa.** Onde um filtro de MAC confere um endereço que o dispositivo escolheu, o 802.1X pede uma
credencial que a rede emitiu: um certificado e a chave privada dele, ou um usuário e uma senha.
Enquanto o dispositivo não prova que tem uma, a porta encaminha um único tipo de quadro, a própria
conversa de login.

Três partes participam, e vale aprender os nomes porque todo produto os usa:

| | quem é | no laboratório |
|---|---|---|
| **suplicante** | o dispositivo pedindo para entrar, e o software nele que responde | `wpa_supplicant` no `desk` |
| **autenticador** | a porta do switch (ou o ponto de acesso Wi-Fi) que guarda a entrada | `hostapd` no `sw`, na `port-desk` |
| **servidor de autenticação** | o servidor que confere a credencial e diz sim ou não | normalmente um servidor RADIUS; aqui, o do próprio `hostapd` |

A conversa é o **EAP**, o Extensible Authentication Protocol, que leva dentro dele um entre muitos
métodos. Entre o suplicante e o autenticador, o EAP viaja em quadros **EAPOL**, EAP sobre LAN, com um
tipo Ethernet próprio, `0x888e`, enviados para um endereço reservado que nenhuma bridge encaminha.
Entre o autenticador e o servidor ele viaja dentro do **RADIUS**. O autenticador quase só repassa
mensagens: a decisão é do servidor, e o switch só abre ou mantém fechada a porta.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 280\" role=\"img\" data-fig=\"l04-three-parties\" aria-label=\"As três partes do 802.1X. À esquerda o suplicante, o desk, rodando wpa_supplicant. No meio o autenticador, a porta port-desk do switch, com dois caminhos: um que só leva quadros EAPOL e está sempre aberto, e um para todo o resto do tráfego, que fica fechado até o login dar certo. À direita o servidor de autenticação, normalmente RADIUS. O EAP vai em EAPOL entre o desk e a porta, e dentro de RADIUS entre a porta e o servidor. O servidor responde aceita ou recusa, e só então a porta abre.\"><defs><marker id=\"l04-three-parties-dh-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker><marker id=\"l04-three-parties-dh-ah-phosphor\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--phosphor)\"></path></marker></defs><rect x=\"20.0\" y=\"80.0\" width=\"150.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"95.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">suplicante</text><text x=\"95.0\" y=\"124.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">desk</text><text x=\"95.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">wpa_supplicant</text><rect x=\"280.0\" y=\"50.0\" width=\"170.0\" height=\"170.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"365.0\" y=\"70.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">autenticador</text><text x=\"365.0\" y=\"90.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">port-desk</text><rect x=\"295.0\" y=\"110.0\" width=\"140.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"365.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">EAPOL: sempre aberto</text><rect x=\"295.0\" y=\"160.0\" width=\"140.0\" height=\"30.0\" rx=\"2\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"5 3\"></rect><text x=\"365.0\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--amber)\">o resto: fechado</text><text x=\"365.0\" y=\"207.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">até o servidor aceitar</text><rect x=\"560.0\" y=\"80.0\" width=\"140.0\" height=\"90.0\" rx=\"3\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"630.0\" y=\"102.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">servidor de</text><text x=\"630.0\" y=\"120.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper)\">autenticação</text><text x=\"630.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10\" fill=\"var(--paper-dim)\">RADIUS</text><path d=\"M170.0 120.0 L295.0 125.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04-three-parties-dh-ah-phosphor)\" marker-start=\"url(#l04-three-parties-dh-ah-phosphor)\"></path><text x=\"232.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--phosphor)\">EAP em EAPOL</text><path d=\"M450.0 120.0 L560.0 120.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.4\" fill=\"none\" marker-end=\"url(#l04-three-parties-dh-ah-paper-dim)\" marker-start=\"url(#l04-three-parties-dh-ah-paper-dim)\"></path><text x=\"505.0\" y=\"108.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">EAP em RADIUS</text><text x=\"630.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">aceita ou recusa</text><text x=\"360.0\" y=\"258.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--paper-dim)\">no laboratório, o hostapd faz o papel da porta e do servidor</text></svg>", "caption": "A porta leva o login e mais nada até o servidor dizer sim."}
```

## Os dois estados da porta

Até um login dar certo, a porta está **não autorizada**: quadros EAPOL passam, para o dispositivo
poder fazer login, e nada mais passa. Depois de um sucesso ela fica **autorizada**, e o tráfego do
dispositivo flui. Um logoff do dispositivo, o link caindo ou um timer de reautenticação a fecham de
novo.

## Qual método

O método decide o que é a credencial, e a diferença importa:

- **EAP-TLS**: os dois lados apresentam certificados. O dispositivo prova que tem uma chave privada
  que a autoridade certificadora da rede assinou, e confere o certificado do servidor do mesmo jeito.
  Não há senha para adivinhar, pescar ou reaproveitar, e por isso é a escolha mais forte, e é a que a
  próxima seção monta. O custo é emitir e renovar um certificado por dispositivo.
- **PEAP** com MSCHAPv2, ou **EAP-TTLS**: o servidor apresenta um certificado, e o dispositivo manda
  usuário e senha pelo túnel cifrado. Mais fácil de implantar, e só tão forte quanto as senhas, e
  quanto a conferência que o dispositivo faz do certificado do servidor: um suplicante que aceita
  qualquer certificado entrega a senha a quem responder na porta.

Nos dois, **o suplicante precisa conferir o servidor.** Um login que prova o dispositivo para a rede
e não a rede para o dispositivo é meio login.
