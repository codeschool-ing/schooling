---
title: "Hetzner: alemã, servidores dedicados e servidores na nuvem"
version: 1
---

A Hetzner é uma empresa alemã, fundada em 1997, dona dos seus próprios data centers, que ela mesma
opera. Ela vende duas coisas que vale manter separadas, porque envolvem trocas diferentes.

## Servidores dedicados

Um **servidor dedicado** é uma máquina física alugada por mês. Ninguém mais roda nela: você fica com
o processador inteiro, a memória inteira e os discos, em geral sem virtualização nenhuma entre você
e o hardware. Isso é mais antigo que a nuvem, e ainda é o jeito mais barato de comprar muita
computação que roda o dia todo, todos os dias. A Hetzner mantém até um leilão de servidores usados,
cujo preço cai enquanto esperam.

Em troca, fica com você tudo o que a aula 1 arquivou como "responsabilidade sua". Um disco que falha é
trocado pela equipe da Hetzner quando você pede, mas o RAID que manteve os dados vivos, os backups, o
sistema operacional e as atualizações dele são seus. **Um servidor dedicado leva de minutos a horas
para chegar, não segundos, e não cresce com uma chamada de API.** Você o compra para uma carga que já
conhece.

## Hetzner Cloud

A Hetzner Cloud é o outro produto: máquinas virtuais criadas em segundos por uma API, com volumes,
redes privadas, balanceadores de carga, firewalls e, desde 2024, armazenamento de objetos compatível
com S3. A cobrança é por hora até um teto mensal, com uma quantidade generosa de transferência
incluída, o mesmo formato do modelo da DigitalOcean.

A lista para aí. **O catálogo é essencialmente a camada IaaS**: não há fila gerenciada, nem data
warehouse, e o banco, o cache e o que mais a sua aplicação precisar ficam para você rodar nas
máquinas. Para uma equipe à vontade com isso, o motivo para aceitar é o preço.

## Preços baixos, descritos sem números

A Hetzner é conhecida por preços baixos, e a fama é merecida: para a mesma quantidade de
processadores e de memória, os preços de tabela dela ficam bem abaixo dos das hyperscalers. Este
curso não capturou as páginas de preço da Hetzner, então não há número aqui para citar. **De onde vem a diferença** diz se ela se aplica a você:

- o catálogo é curto, então o preço não carrega a engenharia de centenas de serviços;
- a empresa constrói e opera os próprios data centers, em poucos lugares, e os enche de máquinas que
  vende como são, em vez de vesti-las de serviços gerenciados.

Nenhum dos dois motivos é uma fraqueza da máquina que você aluga. Os dois são motivos para ela vir
com menos coisa em volta.

## Onde ela está

Os data centers próprios da Hetzner ficam na Alemanha, em Nuremberg e Falkenstein, e na Finlândia,
em Helsinque. A Hetzner Cloud também tem locais nos Estados Unidos e em Singapura. **Ela não tem
nenhum na América do Sul.**

Ser uma empresa alemã com data centers na União Europeia é um argumento por si só para clientes de lá. Os dados deles ficam sob a lei europeia e em prédios europeus, o que pesa para o GDPR, o equivalente
europeu da LGPD que a aula 2 discutiu. Para um público brasileiro, o mesmo fato pesa no sentido contrário, e a distância através do Atlântico é mais uma linha que a aula 9 transforma em milissegundos.
