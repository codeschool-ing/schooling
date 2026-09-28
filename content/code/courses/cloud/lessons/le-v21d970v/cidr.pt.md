---
title: "CIDR: lendo /16 e recortando uma faixa"
version: 1
---

Uma primeira leitura comum de `/24` e `/16` é que o número maior é a rede maior. É o contrário, e
quando você vê por quê, o resto desta seção é aritmética.

Um endereço IPv4 tem 32 bits, escritos como quatro números de 8 bits cada. **O número depois da barra
diz quantos desses 32 bits são fixos**; os que sobram são livres para variar, e cada combinação deles
é um endereço do bloco. Então um bloco tem 2 elevado a (32 − N) endereços. Fixe mais bits e sobram
menos: `/24` deixa 8 bits livres, `/16` deixa 16.

```
ana@laptop:~/cloud$ python3 -c "print(2**(32-16), 2**(32-20), 2**(32-24))"
65536 4096 256
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(ipaddress.ip_network('10.0.0.0/16').num_addresses)"
65536
```

A primeira linha é a fórmula, feita três vezes; a segunda pergunta ao módulo `ipaddress` do Python,
que conhece a notação, sobre a VPC da seção anterior. **Um `/16` tem 65.536 endereços, um `/20` tem
4.096 e um `/24` tem 256.** Esse jeito de escrever uma rede se chama CIDR, de classless inter-domain
routing, e o `/N` é o comprimento de prefixo. Você viu comprimentos de prefixo em `networks`, onde
`/24` queria dizer "os três primeiros números coincidem".

## Quando a barra cai numa fronteira, e quando não cai

Em `/8`, `/16` e `/24` os bits fixos terminam exatamente num ponto, então o bloco se lê direto no
endereço: `10.0.0.0/16` é todo endereço que começa com `10.0`. Qualquer coisa no meio cai dentro de
um dos quatro números, e é aí que as pessoas param de confiar nos próprios olhos.

Pegue `/20`. Dezesseis bits cobrem os dois primeiros números, e **mais quatro bits ficam fixos dentro
do terceiro**. Quatro bits fixos de oito deixam quatro livres, então o terceiro número anda em passos
de 16, que é dois elevado a quatro: um `/20` cobre os terceiros números de 0 a 15, o seguinte de 16 a
31, o seguinte de 32 a 47. Recortando `10.0.0.0/16` em sub-redes `/20`:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress, itertools; vpc = ipaddress.ip_network('10.0.0.0/16'); print(*itertools.islice(vpc.subnets(new_prefix=20), 4), sep='\n')"
10.0.0.0/20
10.0.16.0/20
10.0.32.0/20
10.0.48.0/20
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(len(list(ipaddress.ip_network('10.0.0.0/16').subnets(new_prefix=20))))"
16
ana@laptop:~/cloud$ python3 -c "import ipaddress; print(ipaddress.ip_address('10.0.17.5') in ipaddress.ip_network('10.0.16.0/20'))"
True
```

`itertools.islice` para a lista em quatro; o segundo comando conta a lista inteira. **Cabem dezesseis
sub-redes `/20` num `/16`**, que é 2 elevado a (20 − 16), e cada uma tem 4.096 endereços. O último
comando pergunta se `10.0.17.5` pertence a `10.0.16.0/20`, e pertence: 17 está entre 16 e 31. Essa é
a pergunta que toda tabela de rotas desta aula faz sobre todo pacote.

Um bloco começa num múltiplo do próprio tamanho. `10.0.16.0/20` é uma rede e `10.0.8.0/20` não é,
porque 8 não é múltiplo de 16, e o `ipaddress` recusa em vez de adivinhar qual rede se quis dizer:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; ipaddress.ip_network('10.0.8.0/20')" 2>&1 | tail -1
ValueError: 10.0.8.0/20 has host bits set
```

Os "host bits" são os livres. Em `10.0.8.0` um deles já está ligado, então o endereço está em algum
lugar dentro de um `/20`, e não no começo de um.

## As faixas privadas, lidas com a fórmula

As três faixas da seção anterior são blocos CIDR comuns, e a fórmula dá o tamanho delas:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; [print(n, n[0], n[-1], n.num_addresses) for n in map(ipaddress.ip_network, ['10.0.0.0/8', '172.16.0.0/12', '192.168.0.0/16'])]"
10.0.0.0/8 10.0.0.0 10.255.255.255 16777216
172.16.0.0/12 172.16.0.0 172.31.255.255 1048576
192.168.0.0/16 192.168.0.0 192.168.255.255 65536
```

`172.16.0.0/12` é a que surpreende. Doze bits fixos entram quatro bits no segundo número, então ela
vai de `172.16` a `172.31`, e `172.32.0.1` é um endereço público. O `172.31.0.0/16` da VPC padrão fica
bem no topo dela.

E a sobreposição de que a seção anterior avisou é uma chamada:

```
ana@laptop:~/cloud$ python3 -c "import ipaddress; vpc = ipaddress.ip_network('10.0.0.0/16'); print(vpc.overlaps(ipaddress.ip_network('10.0.128.0/24')), vpc.overlaps(ipaddress.ip_network('10.1.0.0/16')))"
True False
```

Um `/24` em `10.0.128.0` fica dentro de `10.0.0.0/16`, então uma rede que o usa não pode ser ligada
àquela VPC; `10.1.0.0/16` não divide nenhum endereço com ela e pode. Conferir uma faixa proposta
contra tudo o que você já roda é um laço em volta dessa linha, e sai mais barato que a migração.
