---
title: O que é um ambiente
version: 1
---

Um **ambiente** é um lugar onde um release roda: as máquinas, a configuração, os dados e os serviços
em volta. A maioria das equipes tem pelo menos três, e os nomes são quase universais:

| ambiente | quem usa | para que serve |
|---|---|---|
| **desenvolvimento** | quem desenvolve | testar uma mudança, com dados falsos ou semeados |
| **homologação** (*staging*, *pré-produção*) | a equipe, às vezes o negócio | provar que um release funciona num lugar parecido com a produção |
| **produção** | os clientes | a coisa real, com dados reais e dinheiro real |

Uma imagem errada comum é a de que ambientes diferem no **código**: uma "versão de desenvolvimento" e
uma "versão de produção" do programa. Não deveriam. O programa é o artefato da aula 7, os mesmos bytes
em todo lugar. **O que difere entre ambientes é tudo em volta do programa**: em que porta ele escuta,
a que transportadora pergunta, em que banco grava, quem consegue alcançá-lo e quanto tráfego recebe.

## Por que mais de um

Cada ambiente existe para pegar uma classe de erro antes de o próximo vê-la. O desenvolvimento pega o
erro enquanto ele é cometido. A homologação pega o erro no release, na configuração e na implantação
dele, antes de um cliente: a porta com a letra O da aula 7 era exatamente desse tipo. A produção é
onde nada novo deveria ser aprendido.

O custo é real. Cada ambiente é algo a pagar, manter rodando, manter em sintonia com os outros e
manter seguro. Equipes com poucos usuários e rollback barato às vezes rodam só desenvolvimento e
produção, e essa pode ser a decisão certa: o repositório que publica este curso implanta direto na
produção depois das verificações, como a aula 7 seção 05 notou. A pergunta que esta aula repete é
**o que um ambiente de homologação pegaria que nada mais pega, e isso vale o que custa?**

## Os ambientes do laboratório

Daqui em diante o `shipquote` roda em três ambientes numa máquina só, cada um um diretório com o
próprio `config.env` e o próprio processo: `dev` na porta 8100, `staging` na 8200 e `production` na
8300. Homologação e produção falam cada uma com a própria transportadora, as duas sendo a simulação do
laboratório iniciada duas vezes, nas portas 9091 e 9092, com tokens diferentes. É um modelo, e a seção
06 diz o que uma homologação de verdade acrescenta; as regras que ele demonstra, um artefato,
configuração fora do código e nenhuma mudança feita à mão, não dependem da escala.
