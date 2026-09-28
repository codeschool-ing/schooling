---
title: "Quando uma máquina não é alcançada: o caminho, em ordem"
version: 1
---

"Não consigo chegar no servidor" tem cinco causas comuns numa VPC, e elas ficam ao longo de um caminho
só: o programa, o security group da máquina, a network ACL da sub-rede, a tabela de rotas da sub-rede,
e a entrada vinda de fora, um endereço público ou um balanceador de carga. Conferir tudo numa ordem
fixa, e ler o sintoma antes de começar, transforma uma tarde mudando configurações ao acaso em poucos
minutos.

## Leia o sintoma primeiro

`networks` ensinou a diferença entre as duas falhas que um cliente relata, e numa VPC ela aponta direto
para metade da lista.

**Um timeout quer dizer que algo descartou o pacote.** Nada respondeu. Security groups e network ACLs
descartam sem dizer nada, uma tabela de rotas sem caminho de volta perde a resposta, e uma instância
sem endereço público não tem nada naquele endereço para responder. Todos esses parecem iguais do lado
do cliente: ele espera e desiste.

**"Connection refused" quer dizer que o pacote chegou.** O próprio sistema operacional da máquina
respondeu, com um reset de TCP, porque nada escuta naquela porta. Então o security group deixou
entrar, a ACL deixou entrar, a rota entregou, e você pode parar de olhar para a rede. O defeito está na
máquina: o serviço não está rodando, roda em outra porta, ou escuta só em `127.0.0.1`.

## A lista

Trabalhe da máquina para fora, porque as verificações de dentro são as mais baratas e as que mais
estão erradas.

1. O serviço está escutando, e em qual endereço? Na instância, pela sessão de console do provedor ou
   por SSH de dentro da VPC, `ss -tln` lista os sockets TCP escutando. `0.0.0.0:8080` aceita conexões
   em todas as interfaces; `127.0.0.1:8080` só aceita da própria máquina, e tudo o que vem de fora é
   recusado. Um serviço que funciona na máquina e é recusado de qualquer outro lugar é isso, quase
   sempre.
2. Os security groups da instância. Há uma regra para esse protocolo e essa porta, e a origem dela
   inclui de onde a conexão vem? Da internet, é o endereço do cliente; através de um balanceador de
   carga, é o grupo do balanceador, não o cliente.
3. A network ACL da sub-rede. As duas direções: a regra de entrada para a porta, e a regra de saída
   para as respostas às portas efêmeras. Confira os números das regras, já que um negar com número
   menor vence.
4. A tabela de rotas da sub-rede. A sub-rede de uma instância pública precisa de `0.0.0.0/0` para o
   internet gateway; uma instância privada que precisa sair precisa dela para um NAT gateway.
5. A entrada. Alcançada diretamente, a instância precisa de um endereço público. Alcançada através de
   um balanceador de carga, olhe o estado de saúde do alvo: um alvo que o balanceador considera não
   saudável não recebe nada, e o motivo da verificação falhar costuma ser um dos passos 1 a 3 visto do
   lado do balanceador.

## Teste do lugar certo

De onde você testa divide o caminho em dois. **De outra instância na mesma VPC**, uma conexão ao
endereço privado, com `nc -zv -w 3 10.0.32.10 8080`, atravessa o security group e, se as duas estão em
sub-redes diferentes, as ACLs, mas não o internet gateway nem o endereço público. Se isso funciona e de
fora não, o serviço está bem e o defeito está entre o lado de fora e a máquina: a origem de uma regra,
a ACL, a rota, o endereço. Se falha também, recomece pelo passo 1.

Mude uma coisa de cada vez, e desfaça o que não ajudou. Um security group aberto para `0.0.0.0/0` "só
para testar" que não resolve nada é um buraco que fica para trás; um que resolve diz que a origem
estava errada, e o conserto certo é a origem, não a regra aberta. Os provedores também registram
pacotes aceitos e recusados se você ligar isso, no que a AWS chama de VPC flow logs, e ler esses
registros é assunto de `observability`.
