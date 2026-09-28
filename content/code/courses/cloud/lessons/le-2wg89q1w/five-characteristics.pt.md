---
title: Cinco características, e um servidor que tem uma delas
version: 1
---

Em 2011 o NIST, o instituto nacional de padrões e tecnologia dos Estados Unidos, publicou um documento
curto, a Special Publication 800-145, *The NIST Definition of Cloud Computing*. Ele nomeia **cinco
características essenciais**, três modelos de serviço e quatro modelos de implantação. Os modelos de
serviço são esta aula, e os de implantação são a aula 2. Ainda é a definição que as pessoas citam,
porque descreve propriedades que um serviço tem, e não produtos que alguém vende, e propriedades não
envelhecem.

Um serviço é computação em nuvem, no sentido do NIST, quando tem as cinco.

## Autosserviço sob demanda

Você obtém computação, uma máquina, um disco ou espaço de armazenamento, **quando pede e sem que uma
pessoa do provedor participe**. O pedido vai para uma API; o software do provedor confere a sua conta e
os seus limites e cria a coisa. Um console onde você clica em "criar" é o mesmo pedido com um formulário
na frente. O que importa é que ninguém do outro lado precisa ler o pedido, então ele é atendido às três
da manhã tão rápido quanto ao meio-dia.

## Amplo acesso pela rede

O serviço é alcançado **pela rede, por meios padronizados**. O console é uma página web, a API é HTTPS,
e as ferramentas de linha de comando são programas que chamam essa mesma API. Então a mesma conta é
administrada de um laptop, de um celular ou de um script rodando em outro servidor, e as máquinas que
você cria são alcançadas pelos protocolos que o curso `networks` ensinou: SSH para entrar, HTTP para
servir uma página.

## Agrupamento de recursos

Os recursos físicos do provedor **atendem muitos clientes ao mesmo tempo**, e são entregues e
recolhidos conforme a demanda muda. Você não sabe em que servidor a sua máquina roda nem que disco
guarda os seus dados; você escolhe o local num nível mais grosso, uma região como `sa-east-1`, e o
provedor coloca você dentro dela. A tabela mostra o agrupamento nos tamanhos que vende: um `t3.micro`
tem 2 vCPU e 1 GiB de memória, muito menos que qualquer servidor que alguém construa. É uma fatia de um
servidor maior, e o resto desse servidor pertence a outros clientes.

## Elasticidade rápida

A capacidade **cresce e diminui depressa, e pode fazer isso sozinha**. Uma loja roda duas máquinas quase
o ano todo, dez na semana de uma promoção e duas de novo depois dela, e do ponto de vista do cliente a
oferta parece ilimitada. A elasticidade é o que o agrupamento compra: as dez máquinas estão lá porque o
provedor mantém capacidade de sobra compartilhada por todos, não porque você as encomendou em outubro.
A aula 4 mostra como o crescer e o encolher são automatizados.

## Serviço medido

O uso é **medido, e o medidor é por onde você paga**. A tabela de preços do curso cota uma máquina por
hora, armazenamento por gigabyte-mês e o Lambda por milhão de requisições e por GB-segundo. Como o
provedor mede, você também pode medir: os mesmos números que formam a conta mostram qual parte de um
sistema está custando quanto, e é disso que trata a aula 10.

## Um servidor alugado, comparado com as cinco

Pegue o tipo antigo de hospedagem da seção anterior: um servidor físico alugado por mês, pedido por um
formulário e instalado por um técnico. Compare com a lista.

| característica | um servidor alugado por mês |
|---|---|
| autosserviço sob demanda | não: uma pessoa instala, e a espera é de dias |
| amplo acesso pela rede | sim: você chega a ele pela internet como a qualquer outra coisa |
| agrupamento de recursos | não: a máquina inteira é sua, e fica parada quando você fica |
| elasticidade rápida | não: uma maior é um novo pedido e uma nova espera |
| serviço medido | não: o preço é o mesmo, use o que usar |

**Uma de cinco.** É o computador de outra pessoa e está na internet, e nenhuma das duas coisas faz dele
nuvem. A distinção não é um rótulo por si só: cada "não" dessa tabela é uma decisão que você toma meses
antes e paga, tenha acertado ou não.

A fronteira entre os dois ficou menos nítida desde 2011. Algumas empresas que alugam servidores
dedicados hoje os entregam por uma API em minutos e cobram por hora, o que as faz subir na tabela, e a
aula 3 encontra provedores dos dois lados. As cinco são o teste a aplicar, seja qual for o nome que a
empresa dá a si mesma.
