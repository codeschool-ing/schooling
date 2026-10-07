---
title: SRTP, protegendo uma chamada pacote a pacote
version: 1
---

**O SRTP, Secure Real-time Transport Protocol, cifra e autentica os pacotes de áudio e vídeo de uma
chamada um a um, porque mídia em tempo real não pode esperar retransmissões como um fluxo TLS
pode.** A Vereda faz acompanhamentos de fisioterapia por videochamada, e essas chamadas levam
exatamente o tipo de conversa que a LGPD trata como dado de saúde sensível. Esta seção não tem
captura: o laboratório não tem telefonia, e o protocolo é mostrado como os padrões o descrevem.

## Por que não simplesmente TLS

Voz e vídeo viajam por **RTP**, sobre UDP. Um pacote que chega atrasado é inútil, então nunca é
reenviado; um pacote perdido é só um instante de silêncio ou um quadro congelado. O TLS supõe um
fluxo confiável em que cada byte chega em ordem, que é o contrário. O SRTP (RFC 3711) mantém a
natureza pacote a pacote do RTP e protege cada pacote de forma independente:

- a carga é cifrada, com AES em modo contador ou, nos perfis mais novos, AES-GCM, os modos da aula 1.
  O contador de cada pacote é montado a partir do número de sequência e do carimbo de tempo, então um
  pacote pode ser decifrado sem os anteriores;
- uma etiqueta de autenticação (HMAC-SHA1 truncado em 80 bits no perfil clássico, ou a etiqueta do
  GCM) cobre o cabeçalho e a carga, então um pacote forjado ou alterado é descartado;
- uma janela de repetição recusa pacotes já vistos.

Note o que continua visível: o cabeçalho RTP, com números de sequência e carimbos de tempo, e o
tamanho e o ritmo dos pacotes. Quem observa não consegue ouvir a chamada, mas consegue saber que uma
chamada aconteceu, quanto durou e, mais ou menos, quando cada lado falava.

## De onde vêm as chaves

O SRTP precisa de uma chave combinada entre os dois lados, e é no jeito de combiná-la que as
implantações diferem:

| método | como a chave é combinada | fraqueza |
|---|---|---|
| **SDES** | escrita na sinalização SIP da chamada | quem lê a sinalização tem a chave; ela própria precisa viajar sobre TLS (SIPS, porta 5061) |
| **DTLS-SRTP** | um handshake DTLS (o TLS adaptado ao UDP) entre as duas pontas | nenhuma, em princípio; é o que o WebRTC exige |
| **ZRTP** | uma troca Diffie-Hellman no caminho da mídia, com um código curto que os usuários leem um para o outro | depende de as pessoas compararem mesmo o código |

O **WebRTC**, a tecnologia dentro das videochamadas no navegador, torna o DTLS-SRTP obrigatório: um
navegador não manda mídia sem ele. É por isso que uma chamada de telemedicina no navegador é cifrada
por padrão, enquanto um sistema antigo de telefones de mesa em SIP pode mandar o áudio em texto
claro ou com chaves legíveis na sinalização. Um defensor revisando um sistema de VoIP faz a mesma
pergunta de todo o resto deste curso: de onde vem a chave, e quem mais consegue lê-la?

A cifragem de ponta a ponta só vale quando a mídia corre entre os dois participantes. Muitas
plataformas de vídeo passam a mídia pelos próprios servidores, que a decifram e cifram de novo, então
a plataforma consegue ver a chamada. Chamadas com cifragem de ponta a ponta existem, e uma equipe que
escolhe uma plataforma para consultas de saúde confere de que tipo é a que está comprando.
