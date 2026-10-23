---
title: Perfil dos dados: medir antes de mapear
version: 1
---

Uma migração de dados parece um problema de mapeamento: este campo vai para lá, aquele código vira
este. Por isso, a primeira coisa que a maioria dos times escreve é o mapeamento, a partir da
documentação do sistema antigo e do modelo de dados do novo. **O mapeamento é a segunda coisa a
escrever. A primeira é uma medição do que o sistema antigo de fato guarda**, porque a documentação
descreve o que os dados deveriam ser, e trinta anos de uso os transformaram em outra coisa.

Essa medição se chama **perfil dos dados** (*data profiling*). Ela faz perguntas simples a cada
tabela e a cada campo que vai mudar de sistema. Quantas linhas, quantos vazios, quantos valores
distintos? Que valores se repetem onde deveriam ser únicos, que linhas apontam para algo que não
existe, e que números são impossíveis? Nada disso exige uma ferramenta comprada. Uma cópia dos
dados, SQL e uma tarde com a pessoa que conhece o sistema acham quase tudo.

## O que a Serra Alta está mudando de lugar

A aula 13 planejou a aposentadoria do Coleta como um estrangulamento: uma capacidade de cada vez
passa para o novo sistema de fazendas, e o antigo encolhe. Um desses passos é o momento em que o
novo sistema vira o dono das fazendas e dos litros. A aula 15 pergunta se esse sistema deve ser
comprado ou construído; de um jeito ou de outro, os dados precisam ir para lá, e esta aula é sobre
levá-los.

Duas coisas viajam nesse passo:

- *o cadastro de fazendas*: um registro por fazenda, com o código, o CPF ou CNPJ do produtor, o
  município, a rota, o tanque e o número do cadastro de fornecedor da fazenda no SAP, que é quem
  paga (aula 1);
- *o histórico de coletas*: uma linha por fazenda por coleta, com os litros e os resultados de
  laboratório a partir dos quais o pagamento é calculado. Desde 1996, chegou a cerca de 14,6
  milhões de linhas.

O primeiro rascunho de mapeamento de Joana foi escrito a partir da documentação do Coleta, um
fichário de layouts de registro que Sebastião manteve em dia até mais ou menos 2005. Ele dizia que
o campo de município guardava um valor escolhido de uma lista. **O perfil achou 97 grafias
diferentes para os 38 municípios onde a Serra Alta coleta.** A lista existia na tela verde até que
uma mudança em 2006 tornou o campo texto livre, e ninguém atualizou o fichário.

## As perguntas que um perfil faz

Joana e Sebastião rodaram o perfil numa cópia dos dados do Coleta, para que nada do que fizessem
deixasse a máquina de produção lenta. O banco do Coleta é o Db2 for i, que responde SQL como
qualquer outro. Os nomes abaixo estão simplificados; os de verdade são os nomes curtos e crípticos
de campo da época do RPG.

```sql
-- how many farms the master holds
SELECT COUNT(*) FROM farm_master;

-- tax ids that appear on more than one farm
SELECT tax_id, COUNT(*) AS farms
FROM farm_master
WHERE TRIM(tax_id) <> ''
GROUP BY tax_id
HAVING COUNT(*) > 1;

-- every spelling of a municipality, most common first
SELECT municipality, COUNT(*) AS farms
FROM farm_master
GROUP BY municipality
ORDER BY farms DESC;

-- collections that point at no farm at all
SELECT COUNT(*)
FROM collection c
WHERE NOT EXISTS (SELECT 1 FROM farm_master f WHERE f.farm_code = c.farm_code);
```

Cada consulta é uma de sete perguntas, e toda migração faz as sete a cada campo que importa:

| pergunta | o que ela acha | na Serra Alta |
|---|---|---|
| contagens | o tamanho de cada população, e em que estado estão as linhas | 2.140 cadastros de fazenda: 1.897 com coleta neste mês, 243 sem coleta há mais de um ano |
| nulos e vazios | campos que deveriam ter algo e não têm | 17 fazendas sem CPF nem CNPJ, 15 delas entre as 243 |
| valores distintos | texto livre onde se esperava um código | 97 grafias de 38 municípios; só Santos Dumont de quatro jeitos |
| duplicados | uma coisa real registrada duas vezes | 38 CPFs ou CNPJs que aparecem em dois cadastros de fazenda |
| valores inválidos | valores que quebram uma regra própria | 9 CPFs cujos dígitos verificadores não fecham |
| órfãos | linhas que apontam para algo que não está lá | 1.312 coletas, de 1998 a 2003, de 6 códigos de fazenda apagados do cadastro |
| valores fora da curva | números possíveis no tipo e impossíveis no mundo | 23 coletas mais de vinte vezes maiores que o dia mediano da fazenda |

Duas dessas linhas precisam de quem conhece o sistema antes de significarem alguma coisa.

**Um documento repetido nem sempre é uma fazenda repetida.** Dos 38, 31 são um produtor com duas
propriedades, dois tanques e dois pagamentos separados, o que está certo e precisa continuar como
duas fazendas. Os outros 7 são um tanque cadastrado duas vezes, com um código novo, quando a fazenda
mudou de dono; durante alguns meses houve coletas registradas nos dois códigos. Uma regra que
juntasse todo documento repetido teria juntado as fazendas de 31 produtores numa só e pago cada um
uma vez em vez de duas. Sebastião sabia qual era qual porque tinha cadastrado a maioria delas.

**Um valor fora da curva é uma pergunta, não um erro.** O maior dos 23 é de 41.000 litros num dia,
numa fazenda cujo dia mediano é de 410 litros e cujo tanque comporta 2.000. Esse é um par de zeros
a mais digitado no coletor. Outros entre os 23 eram reais: uma fazenda que recebeu o leite de um
vizinho durante uma semana enquanto o resfriamento do vizinho estava quebrado. O perfil acha os 23;
alguém decide cada um.

## Conferindo contra os outros sistemas

O Coleta não é o único sistema que conhece as fazendas. O SAP tem um cadastro de fornecedor para
cada uma, porque é o SAP que paga (aula 1). Por isso o perfil também comparou o cadastro de
fazendas do Coleta com o cadastro de fornecedores do SAP, e achou mais duas coisas que o fichário
não poderia ter contado a ninguém.

A primeira foi um campo sem dono. **O Coleta ainda guarda uma conta bancária para cada fazenda**,
dos anos antes de 2011, quando ele mesmo gerava o arquivo de pagamento. Desde que o SAP assumiu o
pagamento, o financeiro mantém os dados bancários no cadastro de fornecedores do SAP, e ninguém
mantém a cópia do Coleta. Para 412 fazendas as duas não batem. O campo do Coleta nem tem um formato
só: os registros antigos guardam agência e conta num único campo com hífens, os mais novos em dois
campos.

A segunda foi um vínculo vencido: quatro fazendas apontam para um fornecedor que o financeiro
bloqueou no SAP, porque os pagamentos da fazenda passaram para um cadastro de fornecedor novo depois
de uma troca de dono e ninguém avisou o Coleta.

## O escopo também é um achado

Migrar tudo é o padrão que ninguém escolhe de propósito. O financeiro e o jurídico definiram a regra
da Serra Alta para o que o novo sistema precisa guardar: **o ano corrente e os cinco anteriores**. O
histórico mais antigo vai para um arquivo que pode ser consultado e nunca alterado (a última seção
desta aula trata dele).

O perfil transformou essa frase em números. **1.958 fazendas têm pelo menos uma coleta dentro do
período**, então elas vão; 182 não têm nenhuma, então vão só para o arquivo. Das 14,6 milhões de
coletas, cerca de 4,1 milhões caem dentro do período. Os 1.312 órfãos são todos de antes de 2004 e
vão para o arquivo com uma nota dizendo o que são.

Esses números fazem dois trabalhos. Eles dimensionam cada passo seguinte, de quanto tempo uma carga
leva a quantas fazendas a equipe de Cláudia precisa olhar à mão. E são a medida contra a qual a
reconciliação, mais adiante nesta aula, vai ser feita: 1.958 fazendas é o número que precisa
chegar, menos as duplicadas que são juntadas de propósito.

## Por que agora e não depois

Uma surpresa achada no perfil custa uma reunião. A mesma surpresa achada num ensaio custa um ensaio,
e achada na noite do cutover custa a noite. **Todos os achados da tabela acima apareceriam de
qualquer jeito**; o perfil só decide quando.

Os municípios em texto livre teriam derrubado a carga, porque o novo sistema guarda o município como
o código do IBGE. Os 31 documentos repetidos legítimos também teriam, se alguém pusesse uma
restrição de unicidade no documento porque o fichário dava a entender que existia uma. As contas
bancárias vencidas não derrubariam nada: entrariam perfeitamente, e a primeira fazenda paga numa
conta encerrada as descobriria.

Esse último tipo é o motivo para fazer o perfil de campos que ninguém pretende usar. **Uma carga
falha alto num valor que quebra uma regra, e em silêncio num valor que está errado e bem formado.**
Só a medição, feita antes de alguém escrever uma regra, acha o segundo tipo cedo.

O perfil também não é coisa de uma vez só. O Coleta continua rodando enquanto o novo sistema é
construído, e os dados dele continuam mudando; o time de Joana rodou as mesmas consultas antes de
cada ensaio e comparou os resultados com os da vez anterior. Uma contagem que muda em algumas
fazendas é o negócio andando. Uma que muda em duzentas é um problema novo, e quanto mais cedo for
notado, mais barato sai.
