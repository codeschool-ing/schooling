---
title: "NAT: uma saída que não é entrada"
version: 1
---

Um servidor de banco de dados, ou a aplicação na frente dele, não tem por que ser alcançável pela
internet. Ainda assim precisa sair: baixar atualizações de segurança, buscar um pacote, chamar a API de
um provedor de pagamentos. Dar a ele um endereço público e uma rota para o internet gateway resolve o
segundo problema reabrindo o primeiro. **Um NAT gateway é a saída que não é entrada.**

## Como ele funciona

O NAT gateway fica numa sub-rede **pública**, com um endereço público próprio, e a tabela de rotas da
sub-rede privada manda para ele tudo o que está fora da VPC:

| destino | alvo |
|---|---|
| `10.0.0.0/16` | `local` |
| `0.0.0.0/0` | o NAT gateway |

Quando uma instância privada, digamos `10.0.32.10`, abre uma conexão com um espelho de pacotes, o
pacote vai para o NAT gateway. O gateway **reescreve a origem** para o próprio endereço público, anota a
conexão numa tabela e manda o pacote adiante pelo internet gateway. A resposta volta para o endereço do
NAT gateway, o gateway acha a conexão na tabela, reescreve o destino de volta para `10.0.32.10` e
entrega.

Um pacote que chega ao NAT gateway sem uma conexão na tabela, alguém na internet tentando abrir uma
conexão para dentro, não casa com nada e não vai a lugar nenhum. Essa é toda a propriedade de
segurança, e é a mesma que o roteador da sua casa dá a cada celular ligado nele: a conversa tem de começar
do lado de dentro. Ela é **de mão única por construção**, e não por causa de uma regra que alguém
poderia errar.

## Quanto custa, com a conta à vista

Um NAT gateway é cobrado de dois jeitos ao mesmo tempo: por cada hora em que existe, e por cada
gigabyte que passa por ele, em qualquer direção. A lista pública:

```
ana@laptop:~/cloud$ python3 prices.py ec2 | grep -E 'sa-east-1|NAT'
                                        sa-east-1    us-east-1
  NAT gateway, per hour                    0.0930       0.0450
  NAT gateway, per GB processed            0.0930       0.0450
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0930, 2), round(100 * 0.0930, 2), round(730 * 0.0930 + 100 * 0.0930, 2))"
67.89 9.3 77.19
ana@laptop:~/cloud$ python3 -c "print(round(730 * 0.0450, 2), round(100 * 0.0450, 2), round(730 * 0.0450 + 100 * 0.0450, 2))"
32.85 4.5 37.35
```

Um mês são 730 horas na aritmética da AWS. Digamos que as instâncias privadas puxem 100 GB de
atualizações e imagens por ele nesse mês. Em `sa-east-1` as horas dão 730 × 0,0930 = 67,89 dólares e
os dados 100 × 0,0930 = 9,30, **77,19 dólares por um NAT gateway por um mês**; em `us-east-1` o mesmo
mês é 32,85 mais 4,50, 37,35. Isso antes das próprias instâncias, e antes de um segundo gateway: um NAT
gateway vive numa zona, então um layout em duas zonas costuma rodar um em cada.

Dois detalhes mudam o tamanho do número. A cobrança de processamento vale para bytes que entram tanto
quanto para os que saem, então uma frota que baixa muito paga em cada download, mesmo que os dados
que entram da internet sejam gratuitos na tabela. E bytes que saem para a internet pagam a linha de
transferência de dados além do processamento, 0,15 dólar por GB nos primeiros 10 TB em `sa-east-1`.

**Esta é uma das surpresas clássicas da aula 10.** É uma conta de encanamento, e cresce com tráfego que
ninguém considera tráfego. O pior caso é uma frota privada copiando terabytes para o serviço de
armazenamento do próprio provedor pelo NAT gateway quando existia um caminho gratuito. A seção de
caminhos privados desta aula é esse caminho.

Os números são a lista pública da AWS para `sa-east-1` e `us-east-1`, em dólares e sem impostos, nas
versões de oferta que o `prices.py` imprime. São uma lista, não uma fatura; aqui não há conta.
