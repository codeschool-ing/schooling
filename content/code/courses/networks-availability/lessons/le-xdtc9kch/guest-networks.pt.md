---
title: Uma rede de visitantes é uma rede separada
version: 1
---

A crença a substituir: uma rede de visitantes é um segundo SSID com outra senha. Se esse SSID cai na
mesma VLAN dos funcionários, **o visitante está na LAN do escritório**, a um salto do servidor de
arquivos, das impressoras e da página de gerência de todo switch. Uma segunda senha só decide quem entra.
Uma rede de visitantes se define por onde eles caem.

A separação acontece em cada camada, e cada camada tem a sua ferramenta:

| camada | o que separa os visitantes | o que isso impede |
|---|---|---|
| rádio | um SSID próprio | nada, sozinho |
| 2 | uma VLAN própria (aula 19 de `networks-addressing`) | visitantes no mesmo domínio de broadcast dos funcionários |
| 2 | isolamento de clientes | um visitante alcançar outro |
| 3 | um firewall: internet sim, faixas internas não | visitantes alcançarem qualquer coisa lá dentro |
| uso | um limite de taxa por cliente e por SSID | o download de um visitante tomar o tempo de ar dos funcionários |

**A regra do firewall é a que faz o trabalho.** A VLAN de visitantes ganha sub-rede, DHCP e DNS próprios. A política dela a deixa sair para a internet e recusa toda faixa privada que a empresa usa, inclusive os
endereços em que os APs e os switches são gerenciados. Escrita como "recusar 10.0.0.0/8, 172.16.0.0/12 e
192.168.0.0/16, depois liberar o resto", ela continua certa quando alguém acrescenta uma rede interna nova
no ano que vem.

**O isolamento de clientes separa os visitantes entre si.** Num AP é uma configuração: o AP se recusa a
encaminhar quadros de um cliente para outro. Visitantes em APs diferentes se encontram no switch, então a
VLAN precisa da mesma regra ali, como portas isoladas no switch ou um firewall no gateway que recuse
tráfego dentro da sub-rede de visitantes.

## Criptografada ou aberta

Uma rede de visitantes aberta pode ser lida por qualquer um ao alcance, como a seção sobre o WPA2 mostrou.
Duas opções melhores:

- Enhanced Open, o nome que a Wi-Fi Alliance dá ao OWE (RFC 8110): sem senha, mas cada cliente faz uma
  troca de chaves não autenticada com o AP e ganha uma chave própria. Quem só escuta não lê nada. Ele não
  prova que o AP é o verdadeiro, e esse é o preço de não haver segredo nenhum.
- WPA3-Personal com uma passphrase mostrada na recepção e trocada periodicamente, para que os visitantes
  do mês passado não sejam os deste mês.

## O portal cativo

Um portal cativo intercepta a primeira requisição web de um cliente novo e mostra uma página: os termos,
um código de voucher, um cadastro com e-mail. **Um portal cativo é consentimento e registro, não
segurança**: não criptografa nada e não separa nada, então fica em cima da VLAN e do firewall, nunca no
lugar deles.

## Um rádio, duas redes

O projeto inteiro cabe num arquivo de configuração. Abaixo está um trecho do `hostapd.conf`, a
configuração do software de ponto de acesso que muitos APs baseados em Linux rodam. **Ele não foi
executado**: o hostapd precisa de uma interface sem fio e este laboratório não tem nenhuma, então o
arquivo é um exemplo para ler, e os endereços são ilustrativos.

```schooling-example
{"language": "ini", "file": "hostapd.conf", "parts": [{"code": "interface=wlan0\ndriver=nl80211\ncountry_code=BR\nieee80211d=1\nhw_mode=a\nchannel=36\nieee80211n=1\nieee80211ac=1", "note": "O rádio. Uma interface, o país cujas regras ele obedece (aula 7: canais e potência são lei, não gosto), a banda de 5 GHz e o canal 36."}, {"code": "ssid=office\nbridge=br-staff", "note": "A primeira rede. O SSID dela, e a bridge em que o tráfego cai: `br-staff` está ligada à VLAN dos funcionários na porta do switch, então o SSID e a VLAN são uma rede só."}, {"code": "wpa=2\nwpa_key_mgmt=WPA-EAP\nrsn_pairwise=CCMP\nieee80211w=2", "note": "Enquadramento WPA2 com gerência de chaves 802.1X, AES-CCMP para os dados, e `ieee80211w=2`: quadros de gerência protegidos obrigatórios, então um cliente que não sabe protegê-los é recusado."}, {"code": "ieee8021x=1\nown_ip_addr=192.168.10.4\nnas_identifier=ap-hq-1\nauth_server_addr=192.168.10.5\nauth_server_port=1812\nauth_server_shared_secret=a-long-random-secret-per-ap", "note": "De onde vem o veredito. O AP é cliente RADIUS: o próprio endereço, um nome pelo qual o servidor o registra, e o endereço, a porta e o segredo compartilhado do servidor. O laboratório não tem servidor RADIUS, e esses endereços são exemplos."}, {"code": "bss=wlan0_1\nssid=office-guest\nbridge=br-guest", "note": "Uma segunda rede no mesmo rádio. `bss=` dá a ela uma interface própria e portanto um BSSID próprio, e `br-guest` a põe na VLAN de visitantes, que o firewall deixa sair para a internet e para mais nada."}, {"code": "wpa=2\nwpa_key_mgmt=SAE\nsae_password=rotate-this-one-every-month\nsae_pwe=2\nrsn_pairwise=CCMP\nieee80211w=2", "note": "WPA3-Personal: só SAE, então nenhum cliente WPA2 entra para enfraquecê-la. `sae_pwe=2` aceita os dois jeitos de derivar o elemento da senha, o original e o hash-to-element, que o 6 GHz exige."}, {"code": "ap_isolate=1", "note": "Isolamento de clientes. Dois visitantes neste AP não se alcançam através dele; visitantes em outros APs ficam separados pela comutação e pelo firewall da VLAN, não por esta linha."}]}
```

A rede dos funcionários autentica cada pessoa no RADIUS; a de visitantes usa SAE com uma passphrase que
muda todo mês. **O que faz da segunda uma rede de visitantes é a `br-guest`**, a bridge para uma VLAN cujo
firewall a deixa alcançar a internet e mais nada. O `ap_isolate=1` é a segunda proteção, e os limites de
taxa, que não são trabalho do hostapd e ficam no gateway ou na controladora, são a terceira.
