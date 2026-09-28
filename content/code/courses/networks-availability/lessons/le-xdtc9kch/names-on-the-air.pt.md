---
title: Um SSID é um nome, não uma fechadura
version: 1
---

Esta aula e as duas seguintes não têm transcrições. **O laboratório é um computador Linux sem nenhum
hardware sem fio**, então não há beacon para capturar nem handshake para decodificar. O que os substitui
é o que as normas dizem, desenhado, e alguns números que você mesmo pode calcular e conferir.

Um ponto de acesso anuncia cada uma das suas redes num **beacon**, um pequeno quadro de gerência enviado
mais ou menos dez vezes por segundo. O intervalo padrão do 802.11 é de 100 unidades de tempo de 1,024 ms
cada, ou seja, 102,4 ms. O beacon leva dois nomes que as pessoas confundem:

| | o que é | quantos |
|---|---|---|
| **SSID** | o nome da rede, até 32 bytes, escolhido por uma pessoa | um por rede, o mesmo em todos os APs |
| **BSSID** | o endereço MAC de um rádio que serve essa rede | um por rede, por rádio, por AP |

Uma empresa com 20 APs de banda dupla e duas redes, funcionários e visitantes, tem 2 SSIDs e **80
BSSIDs**. Um celular escolhe a rede pelo SSID e depois se liga a um BSSID, o que ouve melhor. Passar de um
BSSID para outro dentro do mesmo SSID é roaming, e a aula 9 trata de como isso pode dar errado.

## Esconder o nome não esconde nada

**Um SSID oculto não é medida de segurança.** O AP deixa o nome fora dos beacons, mas um cliente que quer
entrar ainda precisa dizer o nome da rede, nos probe requests e no pedido de associação, e esses quadros
não são criptografados. Qualquer um ouvindo enquanto um aparelho entra fica sabendo o nome.

E isso ainda custa alguma coisa. Um aparelho configurado para uma rede oculta não pode esperar ouvir o
nome, então pergunta por ele, pelo nome, aonde quer que vá: no aeroporto, no café, em casa. **Esconder o
SSID do escritório faz todo notebook anunciá-lo em público.**

Filtrar por endereço MAC falha do mesmo jeito. Todo quadro leva o endereço de quem envia em claro, então um
endereço permitido é fácil de observar. E os celulares e notebooks atuais usam por padrão um **endereço MAC
aleatório por rede**, o que quebra a lista justamente para os usuários que ela deveria deixar entrar.

O que decide de fato quem entra é a autenticação com uma chave, e o que impede um vizinho de ler o tráfego
é a criptografia com uma chave. As três próximas seções são essas chaves.

## Cada SSID custa tempo de ar

Cada rede num rádio manda os próprios beacons, na menor taxa permitida, para que o cliente mais fraco
consiga lê-los. Dez SSIDs são dez beacons a cada 102,4 ms antes de alguém mandar qualquer dado. **Uma regra
prática comum é no máximo três ou quatro SSIDs por rádio**, uma orientação da prática de projeto e não um
limite da norma. Então uma rede de visitantes merece um SSID próprio, e "um por departamento" não:
departamentos se separam por VLAN atrás de um SSID só, como mostra a seção sobre o modo enterprise.
