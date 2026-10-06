---
title: Os princípios
version: 1
---

Zero Trust costuma ser resumido como **"nunca confie, sempre verifique"**. O slogan é exato e curto
demais para guiar uma ação. O NIST SP 800-207 enuncia a ideia num punhado de princípios; agrupados,
dão quatro que um iniciante consegue aplicar.

**1. A localização não concede nada.** Estar na rede do escritório, na VPN ou no segmento de
servidores não prova nada. Um pedido de dentro é tratado exatamente como um de fora: precisa mostrar
quem é e que tem permissão. A rede continua importando, porque a segmentação da aula 5 ainda limita o
que um atacante alcança, mas ela deixa de ser o que **decide** o acesso.

**2. Todo pedido é verificado, toda vez.** O acesso é decidido por sessão, ou por pedido, a partir de
informação atual. Um login às 9h não quer dizer que a mesma pessoa está no teclado às 16h, num
aparelho diferente, em outro país. A decisão usa **quem** pede (identidade, com login forte, em geral
o MFA da aula 9), **de onde** pede (é um aparelho que a empresa gerencia, está atualizado) e **o
contexto** (a hora, o lugar, quão incomum é o pedido).

**3. Menor privilégio, por pedido.** A resposta a um pedido é acesso àquele recurso, e não à rede em
que ele fica. O princípio da aula 6, aplicado na escala de uma página ou um arquivo em vez de uma
conta inteira.

**4. Presuma a invasão.** Projete como se um atacante já estivesse em algum lugar lá dentro, porque
pode estar. Isso quer dizer limitar até onde uma conta ou um aparelho comprometidos alcançam, cifrar o
tráfego mesmo entre máquinas internas e **vigiar**: toda decisão é registrada, e os logs são o que
avisa o defensor de que a conta da ana está pedindo coisas de um país onde ela nunca esteve.

### O que os princípios não dizem

Eles não dizem "não confie em ninguém" sobre as pessoas. Zero Trust é sobre o **mecanismo** da
confiança: troca uma suposição feita uma vez, na borda da rede, por uma decisão tomada a cada pedido, a
partir de evidência. A equipe é tão confiável quanto antes; o que muda é que o sistema confere, toda
vez, que é mesmo ela.

Eles também não dizem "tire o firewall". O perímetro e os segmentos da aula 5 continuam sendo camadas
no sentido da aula 4. Zero Trust acrescenta um ponto de decisão na frente de cada recurso; não tira as
outras camadas.
