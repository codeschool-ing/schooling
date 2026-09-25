---
title: TCP ou UDP: quem precisa de quê
version: 1
---

A escolha é de quem desenha o protocolo, não do usuário, mas conhecê-la explica muito comportamento:

| protocolo | transporte | por quê |
|---|---|---|
| web (HTTP/1.1, HTTP/2), e-mail, SSH, transferência de arquivos | TCP | todo byte tem de chegar, em ordem |
| DNS | UDP, TCP para respostas grandes | uma pergunta pequena, uma resposta pequena; um handshake triplicaria o custo |
| chamadas de vídeo e voz | UDP | um pacote atrasado é inútil; melhor pular que esperar |
| jogos online | UDP | a posição mais nova importa, não a de um momento atrás |
| HTTP/3 | UDP, porta 443 | confiabilidade própria, montada por cima, mais rápido para começar que TCP mais TLS |

**O padrão é o tempo.** O TCP é o certo quando um byte faltando estraga o resultado e esperar por ele é
aceitável. O UDP é o certo quando uma resposta atrasada é tão ruim quanto nenhuma, ou quando o programa
prefere lidar com a perda do seu jeito.

O HTTP/3 é o caso interessante. Ele precisa de tudo o que o TCP dá, e monta tudo de novo dentro de um
protocolo chamado **QUIC**, sobre UDP, para que a conexão e a criptografia sejam combinadas juntas, em
menos idas e voltas. É por isso que um firewall que permite TCP 443 e bloqueia UDP 443 não quebra a web:
os navegadores tentam HTTP/3, não recebem nada e voltam para o HTTP/2 sobre TCP, um pouco mais lentos
para começar.
