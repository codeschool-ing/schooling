---
title: "Repatriação: voltar para casa"
version: 1
---

*Repatriação* é tirar cargas de uma nuvem pública e levá-las de volta para hardware que a empresa
possui ou aluga, no próprio prédio ou num datacenter de colocation. Duas imagens erradas e opostas
cercam o assunto. Uma diz que a nuvem sempre sai mais barata, porque outra pessoa compra o hardware.
A outra diz que as empresas estão saindo da nuvem porque ela se revelou um golpe. **Nenhuma das duas
fala da carga**, e é a carga que decide.

## O formato da carga

Um preço sob demanda paga mais do que a máquina. Paga o provedor manter capacidade pronta para
clientes que ainda não chegaram, e deixar você devolver a máquina depois de uma hora. Uma carga **com
picos** usa isso: as cem máquinas do teste de carga, a semana da Black Friday, o lote de fim de mês.
Uma carga **estável** — as mesmas máquinas, ocupadas dia e noite, todo dia, por anos — paga por uma
flexibilidade que nunca usa.

A resposta do próprio provedor a uma carga estável vem primeiro, e está na tabela. Para uma
`m7i.large` em `sa-east-1`, contando o mês como 730 horas:

- sob demanda: 0,16065 × 730 = 117,27 USD por mês;
- reserva de 1 ano, sem pagamento adiantado: 0,09956 × 730 = 72,68 USD por mês;
- a economia: 1 − 0,09956 / 0,16065 = 0,38, então o compromisso custa 38% menos.

Um compromisso de um ano tira mais de um terço, sem comprar hardware nenhum. Então a pergunta honesta
da repatriação não é "hardware próprio contra o preço sob demanda". É **hardware próprio contra o
preço com compromisso**, e a lição 10 trata de compromissos e dos outros modelos de cobrança.

## Os custos que as pessoas esquecem

A planilha que faz a repatriação parecer fácil põe o preço de compra de um servidor ao lado de um ano
da conta da nuvem. O que ela deixa de fora:

- as pessoas: alguém instala, atualiza e troca o hardware, o armazenamento e a rede, e alguém fica de
  plantão às três da manhã quando um disco falha;
- o prédio: energia, refrigeração, espaço e segurança física, ou a taxa de colocation que faz as vezes
  deles;
- a renovação: o hardware é trocado a cada poucos anos, então a compra é um custo recorrente diluído,
  não um gasto único;
- o planejamento de capacidade: você compra para o pico, mais o crescimento, mais uma folga, com meses
  de antecedência, e uma previsão errada vira metal ocioso ou uma falta sem conserto rápido;
- os serviços gerenciados: um banco de dados gerenciado vira um banco que a sua equipe opera, com
  backups, atualizações e failover;
- a mudança em si: os dados precisam sair, aos preços de saída da seção sobre a emenda — 50 TB saindo
  de `sa-east-1` deram 7.188,48 USD num único mês.

## Quando ganha, e quando perde

Ela pode ganhar para uma carga grande, estável e bem conhecida, operada por uma equipe que já cuida de
hardware, com poucos serviços gerenciados por baixo. Pode ganhar também em banda: um serviço que manda
200 TB por mês de `sa-east-1` para a internet paga 25.927,68 USD só pela transferência, todo mês,
enquanto banda comprada para um datacenter costuma ser vendida por capacidade, e não por gigabyte
movido.

Ela perde para cargas pequenas, com picos ou crescendo rápido, para equipes sem ninguém para cuidar
de hardware, e para aplicações construídas sobre os serviços gerenciados do provedor, em que sair
significa reconstruí-los. **Repatriação é uma decisão por carga**, não um veredito sobre a nuvem. Uma
empresa pode trazer de volta um sistema estável e deixar todo o resto exatamente onde estava.
