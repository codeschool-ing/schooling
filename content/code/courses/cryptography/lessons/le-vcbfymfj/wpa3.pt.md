---
title: O WPA3, e o que configurar na Vereda
version: 1
---

**O WPA3-Personal substitui o passo que tornava a frase secreta do WPA2 testável offline. A frase não
alimenta mais uma chave fixa; ela alimenta uma troca de chaves, e cada palpite precisa ser feito
contra o ponto de acesso, uma troca de cada vez.** Essa única mudança elimina os dois problemas da
seção anterior.

## SAE: uma troca de chaves que uma senha autentica

O WPA3-Personal entra na rede com o **SAE**, *Simultaneous Authentication of Equals*, uma troca de
chaves autenticada por senha. Cada lado escolhe valores aleatórios novos e roda uma troca
Diffie-Hellman (aula 7) em que a frase secreta determina o elemento do grupo que os dois usam. Se as
duas frases batem, os dois lados chegam ao mesmo segredo. Se não batem, a troca falha e não revela
nada que permita a alguém testar um segundo palpite offline.

Desse projeto decorrem duas consequências:

- **Uma gravação não serve para chutar.** Cada palpite exige uma troca ao vivo com o ponto de acesso,
  que é lenta, aparece nos logs dele e pode ter limite de taxa. Uma frase que cairia em horas offline
  resiste a palpites online por muito tempo.
- **Sigilo futuro.** A chave da sessão vem de valores aleatórios que são descartados depois, então
  descobrir a frase mais tarde, ou sabê-la hoje, não decifra uma sessão gravada. A recepcionista que
  tem a frase não consegue mais ler o tráfego do fisioterapeuta.

O four-way handshake continua rodando depois do SAE, mas a PMK de onde ele parte agora é um segredo
novo a cada sessão, e não uma função da frase secreta.

## Quadros de gerenciamento protegidos

O Wi-Fi também manda **quadros de gerenciamento**: as mensagens que associam um aparelho, e as que o
desconectam. O WPA2 os deixava sem autenticação, então qualquer um no alcance podia mandar um
"desconectar" forjado e derrubar aparelhos da rede, o que também era um jeito de forçar um handshake
novo para gravar. Os **Protected Management Frames** (802.11w) acrescentam uma verificação a eles. O
WPA3 os torna obrigatórios.

## Modo de transição, e as redes sem senha

- O **modo de transição** deixa uma mesma rede aceitar aparelhos WPA3 com SAE e os mais antigos com
  WPA2, na mesma frase secreta. Ele existe para um prédio poder migrar, mas o lado WPA2 mantém todas as
  fraquezas da seção anterior, e uma entrada WPA2 gravada continua testando palpites contra a frase que
  os aparelhos WPA3 também usam. Use-o como uma etapa com data para acabar, não como destino.
- O **Enhanced Open**, construído sobre o OWE (*Opportunistic Wireless Encryption*), cifra uma rede
  que não tem senha, como a de uma sala de espera. Cada aparelho roda um Diffie-Hellman sem
  autenticação com o ponto de acesso. Ele não autentica ninguém, então não impede um ponto de acesso
  falso, mas impede a pessoa da mesa ao lado de ler o tráfego de todo mundo, o que uma rede aberta não
  impede.
- O **WPS**, o pareamento por botão e por PIN dos roteadores mais antigos, tem uma fraqueza de projeto
  conhecida no modo PIN. Desligue-o.

## O que a Vereda configura

A Vereda mantém três redes, cada uma na sua VLAN, e a rede dos pacientes não alcança nada da clínica:

| rede | para | segurança |
| --- | --- | --- |
| `Vereda-Equipe` | notebooks e tablets da equipe | WPA2/WPA3-Enterprise, 802.1X (aula 16) |
| `Vereda-Recepcao` | celulares dos pacientes | Enhanced Open, ou WPA3-Personal com a frase impressa |
| `Vereda-Dispositivos` | a maquininha de cartão, duas impressoras | transição WPA2/WPA3, frase aleatória de 5 palavras, trocada todo ano |

Num ponto de acesso que roda o `hostapd`, o software livre que vai dentro de muitos deles, a rede dos
aparelhos fica assim. Os ajustes que decidem a segurança dela são o `wpa_key_mgmt`, que lista SAE para
os aparelhos WPA3 e WPA-PSK para os mais antigos, e o `ieee80211w`, em que `1` oferece quadros de
gerenciamento protegidos a quem os suporta e `2` os exigiria:

```ini
interface=wlan0
ssid=Vereda-Dispositivos
wpa=2
wpa_key_mgmt=SAE WPA-PSK
rsn_pairwise=CCMP
ieee80211w=1
sae_require_mfp=1
wpa_passphrase=replace-with-a-random-five-word-passphrase
```

O `rsn_pairwise=CCMP` deixa o TKIP de fora, e o `sae_require_mfp=1` torna os quadros de gerenciamento
protegidos obrigatórios para os aparelhos WPA3 mesmo enquanto os WPA2 são aceitos sem eles. Quando o
último aparelho WPA2 for substituído, `wpa_key_mgmt=SAE` e `ieee80211w=2` encerram a transição.
