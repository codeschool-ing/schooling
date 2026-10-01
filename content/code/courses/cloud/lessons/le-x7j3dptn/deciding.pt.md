---
title: "Decidir: as características de uma carga contra os modelos"
version: 1
---

A pergunta "nossa empresa deve ser pública, privada ou híbrida?" não tem boa resposta, porque **uma
empresa não é uma carga**. Os modelos descrevem onde um sistema roda e quem divide o hardware dele, e
uma empresa costuma ter sistemas que pertencem a lugares diferentes. A pergunta útil se faz sistema
por sistema, a partir das características de cada um.

## A tabela

Cada linha é uma característica que uma carga pode ter, e para onde ela empurra. Nenhuma linha decide
sozinha; um sistema tem várias características ao mesmo tempo, e a resposta fica onde cai a maior
parte do peso.

| característica da carga | empurra para | porque |
|---|---|---|
| carga com picos ou imprevisível | pública | a capacidade para o pico é alugada só enquanto o pico dura |
| carga estável, igual por anos | privada, ou pública com compromisso | a flexibilidade sob demanda fica sem uso; compare com o preço com compromisso |
| dados pessoais de pessoas no Brasil | uma região cujo local se encaixe nas regras de transferência | a LGPD regula a transferência ao exterior; a região decide onde fica o dado em repouso |
| uma regra que proíbe hardware compartilhado | privada, comunitária ou hosts dedicados | multi-tenancy é exatamente o que a regra exclui |
| latência curta até sistemas na empresa | privada, ou híbrida com essa parte mantida na empresa | toda travessia da emenda custa uma ida e volta |
| um grande conjunto de dados já num lugar | onde os dados estiverem | gravidade dos dados: movê-los custa dias e dólares |
| uma equipe que conhece bem um provedor | esse provedor, não dois | dois sistemas de identidade, duas redes, duas contas |
| um serviço que só um provedor oferece | esse provedor, para essa parte | o bom motivo para multicloud |
| ninguém para cuidar de hardware | pública | os custos esquecidos de ter hardware começam pelas pessoas |

## Uma empresa, do começo ao fim

Uma loja online brasileira tem três sistemas e uma equipe de cinco pessoas que conhece um provedor
público.

A vitrine tem um ano tranquilo e uma Black Friday que traz várias vezes o tráfego de costume. Com
picos, voltada ao cliente, sem regra especial de dados: **pública**, em `sa-east-1`, perto dos
clientes.

O banco de clientes e pedidos guarda nomes, endereços e históricos de compra de pessoas no Brasil. Ele
vai para a mesma região, o que mantém o dado em repouso em São Paulo, e a equipe mapeia cada cópia —
backups, logs, a ferramenta de suporte — antes de dar a pergunta por encerrada.

O ERP cuida do depósito e roda há anos em dois servidores no rack do próprio depósito. Ele conversa
com leitores de código de barras no chão do depósito e com nada na internet. Carga estável, latência local,
hardware já pago: **ele fica na empresa**, e nada nos modelos diz que ele precisa sair.

A vitrine precisa dos níveis de estoque do ERP. Isso torna o arranjo **híbrido**: uma VPN entre o
depósito e a região, uma cópia do estoque empurrada para o lado da nuvem a cada poucos minutos,
pedidos numa fila para o ERP buscar. Uma travessia a cada poucos minutos, não uma por página.

Um segundo provedor não está na lista. Nenhum serviço de que a loja precisa falta no primeiro, nenhum
cliente exige outro, e a equipe tem um só conjunto de habilidades.

A resposta não é uma das quatro palavras. É **uma palavra por sistema**, ligadas onde precisam se
encontrar, e esse é o resultado normal. Note também que os dois servidores do ERP não são uma nuvem
privada pelo teste da seção sobre nuvem privada, e não precisam ser: ninguém pede máquinas a eles.
