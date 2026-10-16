---
title: Partições não são opcionais
version: 1
---

A leitura do "escolha duas" convida a uma escolha tentadora: abrir mão do P, manter C e A, e construir um
sistema "CA". **Para qualquer coisa com mais de uma máquina, essa opção não existe.** Tolerância a
partições não é um recurso a escolher; partições são um evento que acontece com você, e a única escolha
é o que o sistema faz quando uma acontece.

Uma partição é qualquer situação em que alguns nós não conseguem ouvir outros, e na prática ela tem
muitas causas além de um cabo cortado:

| causa | como um nó a vê |
| --- | --- |
| um switch, um roteador ou a rede de uma zona da nuvem falha | o outro nó para de responder |
| uma regra de firewall mal configurada depois de uma mudança | parte do tráfego passa e parte não |
| uma longa pausa de coleta de lixo num nó | esse nó fica em silêncio por segundos, e depois segue como se nada tivesse acontecido |
| um nó sobrecarregado a ponto de não responder a tempo | impossível de distinguir de uma falha de rede |
| um cluster esticado entre dois data centers | a ligação entre eles é uma coisa só, lenta, que às vezes cai |

A terceira e a quarta linhas são as que mais importam, porque nada está quebrado nelas. **Um nó não
consegue distinguir uma partição de um par lento**: os dois parecem silêncio até um timeout. Então todo
sistema distribuído, no momento em que espera outra máquina, já precisa decidir o que vai fazer quando a
espera acabar, e essa decisão é a posição dele no CAP, tenha alguém a escrito ou não.

## "CA" quer dizer uma máquina

Um servidor PostgreSQL sozinho é consistente e disponível no sentido acima, e não tem partições a tolerar
porque não tem pares. É um projeto legítimo, o monólito da aula 1 com o seu banco único é um, e é o que
"CA" de fato descreve. No momento em que existe uma segunda cópia, para sobreviver à perda da primeira
máquina, a rede entre elas pode quebrar, e a escolha chega.
