---
title: O ataque que pede para entrar
version: 1
---

Todo controle até aqui tratou de pacotes. **O phishing trata de uma pessoa**: uma mensagem montada
para que alguém de dentro abra um documento, digite uma senha na página errada ou aprove um
pagamento. Ele chega pela porta da frente, endereçado a um funcionário real, e funciona porque o
firewall está certo em deixar passar e-mail e páginas web.

A **engenharia social** (*social engineering*) é a família mais ampla: uma ligação do "suporte de
TI" pedindo um código, uma mensagem "do diretor" pedindo uma transferência urgente, um pendrive
deixado no estacionamento. O que têm em comum é que o atacante toma emprestada a autoridade, a
urgência ou a vontade de ajudar, e a pessoa faz o resto.

A rede vê as consequências, não a conversa, e elas seguem um padrão que vale a pena reconhecer:

| etapa | o que acontece | o que a rede consegue ver |
|---|---|---|
| entrega | uma mensagem com um link ou um anexo | o veredito do gateway de e-mail; a consulta de um nome incomum |
| o primeiro clique | uma página pede uma senha, ou um documento executa código | uma conexão para um nome que ninguém na empresa visitou antes |
| um ponto de apoio | o software no laptop contata quem o enviou | conexões regulares para um endereço de fora, em horários estranhos |
| propagação | o software alcança outras máquinas de dentro | uma estação de trabalho se conectando a outras estações, por compartilhamento de arquivos ou área de trabalho remota |
| o golpe final | arquivos cifrados, ou dados copiados para fora | um pico repentino de escritas num servidor de arquivos, ou de uploads |

O **ransomware** é o golpe final que tornou esse padrão famoso: um software que cifra todo arquivo
que consegue alcançar e exige pagamento pela chave, muitas vezes depois de copiar os dados para fora
para ameaçar também publicá-los. Ele raramente para numa máquina só, porque a máquina onde começa
quase nunca é a que guarda o que importa.

Nada nesta aula impede uma pessoa de clicar. O que ela faz é encurtar cada etapa: um nome que não
resolve, um vizinho que não responde, uma máquina que pode ser isolada em segundos e backups que o
software não alcança.
