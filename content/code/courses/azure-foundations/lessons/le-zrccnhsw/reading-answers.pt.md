---
title: Lendo uma resposta com o dig
version: 1
---

**Uma resposta de DNS não é um fato só; é uma cadeia, e cada elo tem o seu dono e o seu tempo de
vida.** A imagem errada é a de uma lista telefônica com um nome de um lado e um endereço do outro.
Nomes reais na internet são muitas vezes apelidos de apelidos, cada elo guardado numa zona diferente
por uma empresa diferente, e o endereço no fim é a última coisa da cadeia, não a primeira. Esta lição
é sobre a parte dessa cadeia que o Azure guarda, e começa lendo uma inteira.

Crie o diretório da lição e pergunte o endereço do portal do Azure:

```sh
mkdir -p ~/azure/dns && cd ~/azure/dns
```

```
ana@laptop:~/azure/dns$ dig portal.azure.com +noall +answer +nottlid
portal.azure.com.	IN	CNAME	portal-prod-02-linkage.trafficmanager.net.
portal-prod-02-linkage.trafficmanager.net. IN CNAME azureportal.z01.azurefd.net.
azureportal.z01.azurefd.net. IN	CNAME	azurefd-p-prod.trafficmanager.net.
azurefd-p-prod.trafficmanager.net. IN CNAME shed.s-part-19.p-0010.p-msedge.net.
shed.s-part-19.p-0010.p-msedge.net. IN CNAME p-0010.p-msedge.net.
p-0010.p-msedge.net.	IN	A	150.171.84.10
```

Cada linha é um **registro**: um nome, a classe `IN`, um **tipo**, e o valor. Cinco deles são `CNAME`,
que diz "este nome é outro nome; pergunte por aquele", e o último é um `A`, um endereço IPv4. O
resolvedor seguiu a cadeia por você e imprimiu cada elo. Leia os nomes em vez do endereço: o primeiro
salto é `trafficmanager.net`, o Azure Traffic Manager, depois `azurefd.net`, o Azure Front Door,
depois a rede de borda da Microsoft. **Cada um desses é um serviço que escolhe o próximo elo no
momento em que você pergunta**, por onde você está e pelo que está saudável. É por isso que a lição
22 consegue montar um serviço global só com DNS e que esta cadeia exata não vai ser a que você recebe.

`+noall +answer` deixa só a seção de resposta; `+nottlid` omite a coluna que o dig normalmente imprime
entre o nome e o `IN`: o **TTL**, o número de segundos que um resolvedor pode guardar o registro antes
de perguntar de novo. Ele fica de fora aqui porque conta para trás enquanto você olha, e uma
transcrição que mudasse a cada segundo não diria nada. Na sua máquina, rode o comando sem o
`+nottlid` duas vezes com alguns segundos de intervalo e veja os números caírem.

## Os registros que uma zona guarda

Todo registro acima mora em alguma **zona**: uma parte da árvore de nomes pela qual uma parte responde.
Estes são os tipos que esta lição escreve nas zonas da loja, e a regra de cada um que pega as pessoas:

| tipo | guarda | a regra que pega as pessoas |
|---|---|---|
| `A`, `AAAA` | um endereço IPv4 ou IPv6 | um nome pode ter vários, e um cliente pode escolher qualquer um |
| `CNAME` | outro nome | **um nome com CNAME não pode ter nenhum outro registro**, então o topo de uma zona, que precisa ter `NS` e `SOA`, nunca pode ser um CNAME |
| `MX` | o nome de um servidor de e-mail, com uma preferência | o valor é um nome, nunca um endereço |
| `TXT` | texto livre | onde um domínio prova a um serviço que é seu |
| `NS` | os servidores de nomes que respondem por uma zona | no pai, eles entregam a zona; na zona, eles a repetem |
| `SOA` | o registro da própria zona: o servidor primário, o número de série, os temporizadores | um por zona, feito pelo Azure, editado raramente |

## O que este laboratório não conseguiu perguntar

O `dig` consegue perguntar qualquer um desses tipos, e a delegação da próxima seção é conferida com
`dig NS`. **Na máquina onde este curso foi gravado ele não recebe resposta**: ali os nomes são
resolvidos por um resolvedor que responde perguntas de endereço para uma lista curta de hosts e nada
mais, então perguntas `NS`, `SOA` e `TXT` voltam vazias e nenhuma transcrição delas é mostrada. No seu
computador os mesmos comandos respondem a partir do DNS real, e as duas seções depois desta dizem o
que digitar e que tipo de resposta esperar.
