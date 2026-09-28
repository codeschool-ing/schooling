---
title: Três maneiras de contornar o TLS sem quebrá-lo
version: 1
---

O TLS, bem configurado, não é quebrado por ninguém que esteja no caminho; as aulas 10 a 12 construíram
cada peça em que ele se apoia. **O que dá errado na prática é a configuração.** Cada uma das três
falhas do título desta aula deixa a criptografia intacta e passa ao lado dela, e cada uma tem uma
defesa que o dono de uma rede ou de uma aplicação controla.

| falha | o que o atacante no caminho faz | o que faz funcionar | a defesa |
|---|---|---|---|
| **downgrade** | convence as duas pontas a combinar uma versão ou cifra antiga e fraca | um servidor ou cliente que ainda as aceita | oferecer só versões atuais; a proteção contra downgrade do TLS 1.3 |
| **stripping** | responde ele mesmo à primeira requisição em HTTP puro e nunca deixa a passagem para HTTPS acontecer | um site acessado primeiro por HTTP, contando com um redirecionamento | HSTS, e o preload dele |
| **sem validação** | apresenta um certificado qualquer, e o cliente o aceita | código ou ferramenta com a verificação de certificado desligada | nunca desligá-la; procurar no código onde ela foi desligada |

O atacante em toda linha é alguém **no caminho**: o Wi-Fi do café, um roteador comprometido, a máquina
na LAN que a aula 7 mostrou mentindo no ARP. As três seções a seguir verificam cada defesa no
laboratório. Nenhuma delas precisa de um atacante para ser demonstrada, porque cada uma é uma
propriedade do servidor ou do cliente que pode ser testada diretamente.
