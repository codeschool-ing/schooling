---
title: "Escolhendo: uma lista de verificação, não um vencedor"
version: 1
---

A pergunta que as pessoas fazem é **"qual é o melhor provedor?"**, e ela não tem resposta, porque
deixa de fora as únicas coisas que a decidem: o que você está construindo, para quem, e quem vai
operar. O que esta seção dá no lugar é a ordem em que perguntar. Cada pergunta elimina candidatos, e
as primeiras eliminam mais.

| pergunte | por que vem aqui | onde este curso trata disso |
| --- | --- | --- |
| De quais serviços gerenciados o projeto precisa? | um serviço que só as hyperscalers vendem elimina o resto de uma vez | esta aula, aulas 4 a 8 |
| Onde estão os usuários, e onde os dados podem ficar? | latência e lei, e alguns provedores não têm região lá | aulas 2 e 9 |
| O que a equipe já sabe? | o provedor que você consegue operar sai mais barato que o que você não consegue | esta aula |
| De que suporte você vai precisar, e a que horas? | uma queda às 3 da manhã é quando o suporte é testado | esta aula |
| Quanto custaria sair? | transferência de dados para fora, e cada serviço proprietário usado | esta aula, aula 10 |
| Que formato a conta vai ter? | muitos medidores, ou poucos preços mensais | aula 10 |

## Os serviços primeiro

Anote cada peça que o seu projeto pressupõe, e marque as que você não está disposto a operar. Se a
lista é uma máquina, um banco PostgreSQL e armazenamento de objetos, **todo provedor desta aula
serve**, e as outras perguntas decidem. Se a lista inclui um data warehouse, uma fila gerenciada ou
um diretório dos funcionários da empresa, a escolha já está entre as hyperscalers, e às vezes já é
uma delas.

## Depois, onde

A aula 9 mede a latência; aqui a pergunta é só se o provedor está lá. Para usuários no Brasil, a AWS
tem `sa-east-1`, o Azure tem Brazil South, o Google Cloud tem `southamerica-east1`, e a Akamai tem
uma região em São Paulo. **A DigitalOcean e a Hetzner não têm nenhuma na América do Sul.** Onde dados
pessoais podem ficar é a outra metade, e a aula 2 a discutiu: uma região no país nem sempre é
exigida, mas quando é, não se negocia.

## A equipe, e o suporte

Uma equipe que opera a AWS há cinco anos vai operá-la melhor do que um provedor mais barato que nunca
usou, e a diferença aparece como incidentes, não como uma linha na fatura. Isso é um motivo para
ficar, não uma lei: habilidades se aprendem, e as trilhas a que este curso pertence existem para
isso. O suporte é a pergunta vizinha. As hyperscalers vendem planos de suporte como um produto à
parte; antes de depender de um provedor, descubra quanto custa, ali, alguém atender você no meio da
noite.

## Quanto custa sair

Sair tem dois preços. Um está na tabela: dados saindo da AWS para a internet custam `0.1500` USD por
GB nos primeiros 10 TB do mês em `sa-east-1`, e dados entrando custam `0.0000`. Tirar 5.000 GB de
arquivos de São Paulo num mês custa 5.000 × 0,1500 = 750 USD a preço de tabela. **Entrar é de graça e
sair não é**, em todas as hyperscalers, e vale lembrar dessa assimetria no dia em que você entra.

O outro preço não está em tabela nenhuma: o trabalho de substituir o que você construiu sobre um
serviço que só um provedor vende. Uma máquina virtual, o PostgreSQL, a API do S3 e o Kubernetes
passam de um provedor para outro com esforço moderado, porque todo provedor vende algo equivalente.
Um projeto construído sobre DynamoDB, BigQuery ou a integração de identidade do Azure só se muda
sendo reescrito. Nenhum dos dois está errado; **escolha o serviço proprietário sabendo quanto custa a
saída**, em vez de descobrir no dia em que precisar dela.

## Dois casos

Uma empresa de três pessoas que vende para clientes no Brasil, com uma aplicação web, PostgreSQL e
imagens enviadas pelos usuários, precisa do núcleo, no país. Os candidatos são as três hyperscalers e
a Akamai, e um provedor brasileiro se o catálogo dele cobrir o núcleo; as habilidades da equipe e o
formato da conta decidem entre eles.

Uma empresa cujos funcionários entram pelo Microsoft 365, rodando SQL Server em máquinas Windows no
próprio prédio, começa com o Azure na frente em identidade e licenças, e a comparação tem de ser
ganha por outro, e não perdida pelo Azure.

Nenhum dos casos produz um vencedor que a próxima empresa possa copiar, e nenhum pretendia
produzir.
