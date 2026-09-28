---
title: "DigitalOcean: uma lista curta, escrita para desenvolvedores"
version: 1
---

A DigitalOcean é uma empresa de Nova York que nasceu para vender a um desenvolvedor um servidor em
menos de um minuto, com um preço na página que dispensava calculadora. As suas máquinas virtuais se
chamam **Droplets**, e o resto da linha de produtos é curto. Volumes é o armazenamento em bloco, e
Spaces o armazenamento de objetos compatível com S3. Ao lado deles ficam bancos de dados
gerenciados, balanceadores de carga, redes privadas e Kubernetes gerenciado. O último é o App
Platform, uma plataforma no sentido da aula 1 que monta e roda uma aplicação a partir do
repositório dela.

## Pensada para desenvolvedores, na prática

"Pensada para desenvolvedores" é um slogan até você olhar o que isso quer dizer aqui. Quer dizer que
**os padrões são escolhidos para uma pessoa com um projeto**: um Droplet é criado num formulário
curto, chega à internet com um endereço público e aceita a chave SSH que você informou. Quer dizer
uma biblioteca grande de tutoriais escritos sobre configurar servidores e programas, que muita gente
leu muito antes de ter conta lá, porque eles explicam administração de Linux, e não a DigitalOcean.

E quer dizer deixar coisas de fora. Não há um catálogo de centenas de serviços gerenciados, nem data
warehouse, nem fila do tipo do SQS. Uma equipe que precise de uma roda num Droplet ou compra de outro
lugar.

## O modelo de preço

O modelo é a parte que vale entender, porque é o oposto da medição que você viu na seção da AWS.
**Cada tamanho de Droplet tem um preço mensal**, e a mesma página o mostra também como valor por
hora. Você paga pelo tempo em que o Droplet existe, e um Droplet que existe o mês todo custa o preço
mensal e nada mais. Uma quantidade de transferência de saída vem com cada Droplet, somada numa cota
da conta, e só a transferência além dessa cota é cobrada por gigabyte.

Compare o que custa ler o preço de uma única máquina em cada tipo de provedor:

| | uma hyperscaler | DigitalOcean |
| --- | --- | --- |
| a máquina | por hora ou por segundo, pelo tamanho | um preço mensal, pelo tamanho |
| o disco | uma linha à parte, por GB-mês | incluído no tamanho |
| o endereço IPv4 público | uma linha à parte, por hora | incluído |
| os dados que ela envia | uma linha à parte, por GB | incluídos até uma cota |

A tabela da AWS neste curso mostra que as linhas à parte são reais: um endereço IPv4 público custa
`0.0050` USD por hora nas duas regiões, e um disco gp3 custa `0.1520` USD por GB-mês em `sa-east-1`.
Nenhuma delas é grande. O ponto é que **na DigitalOcean a conta de um projeto pequeno são poucas
linhas que dá para prever de antemão**, e numa hyperscaler ela é a soma de vários medidores.

Os valores estão nas páginas de preço da DigitalOcean, que este curso não capturou. A comparação
fica com você, com o método do fim desta aula.

## Regiões

A DigitalOcean tem data centers na América do Norte, na Europa, na Ásia e na Austrália, e **nenhum na
América do Sul**. Uma loja no Brasil com clientes no Brasil os atende de outro continente, o que
custa latência (aula 9) e levanta a questão de onde dados pessoais podem ficar (aula 2). Isso não é
motivo para descartá-la; é uma linha da lista de verificação no fim desta aula.
