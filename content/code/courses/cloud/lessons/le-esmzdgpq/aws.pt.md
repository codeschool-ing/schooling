---
title: "AWS: a mais antiga, e o vocabulário"
version: 1
---

A Amazon Web Services abriu ao público o S3, seu armazenamento de objetos, e o EC2, suas máquinas
virtuais, em 2006. Ninguém mais vendia computação assim naquela época: uma máquina por hora, por uma
API, sem contrato e sem vendedor. **Ter chegado primeiro fez dos nomes da AWS as palavras de todo o
setor.**

O exemplo mais claro é o armazenamento de objetos. O Spaces da DigitalOcean, o Object Storage da
Hetzner, o Object Storage da Akamai e o R2 da Cloudflare se descrevem como **compatíveis com S3**:
respondem à API que o S3 definiu, então um programa escrito para o S3 conversa com eles trocando um
endereço e uma chave. Ninguém descreve um produto como compatível com o que chegou em segundo lugar.

## A conta e a região

A unidade que você cria primeiro na AWS é uma **conta**. Tudo o que você constrói pertence a uma
conta, e a cobrança chega por conta. Uma empresa raramente fica com uma só: mantém várias, uma por
equipe ou por ambiente, agrupadas no AWS Organizations para dividir uma fatura e um conjunto de
regras. O curso `aws-foundations` monta isso; aqui basta saber que a conta é a caixa.

Dentro da conta, quase tudo vive numa **região** que você escolhe, e uma região tem um código:

| código | onde |
| --- | --- |
| `sa-east-1` | São Paulo |
| `us-east-1` | Norte da Virgínia |

Uma máquina criada em `sa-east-1` existe só ali. O console mostra uma região por vez, e é por isso
que quem "não encontra o servidor" em geral está olhando a região errada, e não uma conta vazia. A
lição 9 trata do que compõe uma região e de quanto custa, em milissegundos, a distância entre duas
delas.

`us-east-1` é a região mais antiga, e é especial de um jeito que surpreende. Algumas coisas que
servem o mundo inteiro são geridas ali: um certificado TLS para a rede de entrega de conteúdo da
AWS, o CloudFront, tem de ser pedido em `us-east-1`, esteja o resto do seu sistema na região que
for. Até a lista de preços que você vai ler mais adiante nesta lição é servida de um endereço com
`us-east-1` no nome.

## Pelo que ela é conhecida

**Ela é conhecida, antes de tudo, pela amplitude.** No dia em que esta lição foi capturada, o índice
de preços da AWS listava 272 ofertas, uma por serviço com preço. Algumas são o núcleo da seção
anterior, e muitas são coisas que só uma hyperscaler vende: um banco chave-valor gerenciado
(DynamoDB), uma fila (SQS), um data warehouse (Redshift), funções (Lambda, o assunto da lição 8).

Depois, pela **profundidade dentro de cada serviço**. Só o EC2 oferece máquinas às centenas, em
famílias nomeadas pelo uso: uso geral, otimizadas para computação, otimizadas para memória, com
processadores Intel, AMD e os Arm da própria Amazon, os Graviton. A tabela de preços deste curso traz
algumas delas, e num nome como `m7g` o `g` quer dizer Graviton.

E pelo ecossistema. Como a AWS chegou primeiro, ferramentas de terceiros, tutoriais e anúncios de
vaga a pressupõem mais do que a qualquer outro provedor. Isso não é uma propriedade técnica, e ainda
assim é um motivo que equipes dão para escolhê-la.

## O que a amplitude custa

A mesma amplitude é a principal queixa. Há vários jeitos de fazer quase tudo — um contêiner pode
rodar no EC2, no ECS, no EKS, no Fargate, no Lambda — e escolher entre eles é uma habilidade à parte.
O console é enorme. E **a conta tem uma linha para cada coisa**: uma máquina virtual chega como as
horas da máquina, o disco, o endereço público e os dados que ela enviou, cada um medido separadamente.
Você vai ver essas linhas com preço na tabela no fim desta lição, e a lição 10 trata de lê-las como
uma fatura.
