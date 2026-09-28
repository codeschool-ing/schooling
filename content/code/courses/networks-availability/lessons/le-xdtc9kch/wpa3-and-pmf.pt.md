---
title: WPA3-Personal, SAE e quadros de gerência protegidos
version: 1
---

O WPA3-Personal mantém a passphrase e o four-way handshake, e muda de onde vem a PMK. Em vez de passar a
passphrase por um hash, os dois lados rodam o **SAE, Simultaneous Authentication of Equals**, uma troca de
chaves da família Diffie-Hellman com a senha misturada nela. Cada lado envia valores que dependem da senha
e de segredos que ele sorteou para esta troca, e os dois terminam com a mesma PMK, **uma nova e aleatória
a cada vez**. O four-way handshake da figura acima roda então sobre essa PMK exatamente como antes.

Essa única mudança resolve os dois problemas da seção anterior.

**Uma gravação não basta mais para testar palpites.** Os valores que vão pelo ar dependem de segredos
aleatórios que nunca saem de nenhum dos lados, então não há nada neles contra o que conferir um palpite.
Cada palpite exige uma troca SAE ao vivo com o AP, o que é lento, visível e algo que o AP pode limitar e
registrar. Uma senha fraca continua sendo má ideia, e deixou de ser um problema offline.

**Ele tem sigilo futuro.** A PMK não é função só da senha, então descobrir a senha depois não decifra nada
gravado antes, e um membro da rede não consegue derivar as chaves de outro a partir de uma gravação do
handshake dele.

## Quadros de gerência protegidos

No 802.11 original, **os quadros de gerência não eram autenticados de jeito nenhum**. Um quadro de
desautenticação, aquele que manda um cliente se desconectar, era aceito de qualquer um que pusesse nele o
endereço do AP, então desconectar um cliente era trivial e o cliente não tinha como perceber. Os
**quadros de gerência protegidos**, PMF, da emenda 802.11w, assinam os quadros de gerência enviados depois
do handshake com chaves derivadas dele. Um cliente com PMF ignora uma desconexão que não consegue
verificar.

**O PMF é opcional no WPA2 e obrigatório no WPA3.** Beacons e probe responses vêm antes de existir
qualquer chave e não são cobertos, e nenhum protocolo impede um transmissor de afogar o canal: esse é um
problema físico, encontrado por análise de espectro (aula 10).

## O modo de transição, e quando sair dele

A maioria das redes não consegue mudar para WPA3 num dia, porque alguns aparelhos só falam WPA2. O **modo
de transição** roda os dois num SSID só, com a mesma passphrase: os clientes WPA3 usam SAE, os outros usam
o handshake do WPA2, e o PMF vira opcional para que os antigos consigam entrar.

O custo é que **a passphrase fica exatamente tão exposta quanto no WPA2**: qualquer handshake WPA2 gravado
nessa rede permite os palpites offline descritos acima, não importa o que os clientes WPA3 façam. A
especificação do WPA3 acrescenta uma indicação de **Transition Disable**, para que um cliente que entrou
uma vez com WPA3 se recuse a usar WPA2 nessa rede de novo, o que protege os clientes modernos de serem
levados de volta ao método antigo. Ela não protege a passphrase. Duas saídas:

- aposentar o último aparelho WPA2 e passar o SSID para só SAE;
- levar os aparelhos antigos para um SSID próprio, numa VLAN própria, com outra passphrase.

**No 6 GHz não existe modo de transição.** A Wi-Fi Alliance só permite WPA3 ou Enhanced Open ali, com PMF
obrigatório (a aula 6 trata da banda), então uma rede de 6 GHz é WPA3 desde o primeiro dia.

| | WPA2-Personal | WPA3-Personal (SAE) |
|---|---|---|
| de onde vem a PMK | PBKDF2 da passphrase | uma troca SAE nova |
| palpites a partir de uma gravação | sim, offline | não, uma troca ao vivo por palpite |
| sigilo futuro | não | sim |
| um membro lendo o tráfego de outro | possível, com um handshake gravado | não |
| quadros de gerência protegidos | opcionais | obrigatórios |
| revogar uma pessoa | trocar a passphrase de todos | trocar a passphrase de todos |
