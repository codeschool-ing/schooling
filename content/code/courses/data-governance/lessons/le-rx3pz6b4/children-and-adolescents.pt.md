---
title: Crianças e adolescentes
version: 1
---

A view de perfil da aula 2 tinha uma faixa que ninguém esperava na lista de clientes de uma
farmácia: **under 18.** A LGPD dá ao dado de crianças e adolescentes um artigo próprio, e a primeira
coisa a saber é quantos são:

```sql
-- Customers under eighteen on the lab's today, by age.
SET ROLE ipe_owner;
SELECT extract(year FROM age(DATE '2026-07-01', birth_date))::int AS age,
       count(*) AS customers,
       count(*) FILTER (WHERE marketing_opt_in) AS accepted_marketing
FROM sales.customers
WHERE age(DATE '2026-07-01', birth_date) < interval '18 years'
GROUP BY 1 ORDER BY 1;
```

```
ana@lab:~/gov$ psql -f minors.sql
SET
 age | customers | accepted_marketing 
-----+-----------+--------------------
  16 |         5 |                  3
  17 |        15 |                  9
(2 rows)
```

Vinte clientes: cinco com 16 anos e quinze com 17, e **doze deles aceitaram marketing.**

## O que o artigo 14 pede

O **artigo 14** diz que o tratamento de dados de crianças e adolescentes deve ser feito **no seu
melhor interesse**, e acrescenta regras específicas. A lei brasileira usa as idades do Estatuto da
Criança e do Adolescente: *criança* tem menos de 12 anos, *adolescente* tem de 12 a 17.

- **Para crianças**, o texto do artigo pede o consentimento específico de pelo menos um dos pais ou
  do responsável legal, com exceções estreitas (contatar os pais, proteger a criança), e esforços
  razoáveis para conferir que o consentimento veio mesmo do responsável. Em 2023 a ANPD publicou um
  enunciado (Enunciado CD/ANPD nº 1) lendo o artigo como compatível também com as outras bases legais
  dos artigos 7º e 11 — sempre sob o teste do melhor interesse.
- **Para os dois**, o controlador não pode condicionar a participação em jogos, aplicativos ou outras
  atividades ao fornecimento de mais dados pessoais do que o estritamente necessário, e deve publicar
  com clareza o que coleta e como usa, numa linguagem que o jovem entenda.

A Ipê não tem crianças no dado; tem adolescentes. O dado deles é dado pessoal com o teste do melhor
interesse por cima — e o consentimento de marketing de um adolescente, o histórico de compras numa
farmácia e uma receita de anticoncepcional são exatamente a combinação em que "melhor interesse" não
é abstração.

O Brasil acrescentou depois o **ECA Digital** (Lei 15.211, de 2025), com deveres para produtos e
serviços digitais dirigidos a crianças e adolescentes, ou de uso provável por eles — e fez da ANPD o
órgão que o fiscaliza. Um time de dados não precisa lê-lo cláusula por cláusula; precisa saber que a
idade é uma coluna que importa à lei, e conseguir responder à pergunta que esta seção acabou de
responder.

## O que o time de dados pode fazer

**Medir**, como acima — uma consulta que qualquer um roda todo mês, guardada com os resultados.

**Conferir o que a idade muda.** Doze adolescentes aceitaram marketing: o sistema de marketing da
Ipê os trata de outro jeito, e deveria? As linhas de pedido deles incluem produtos cuja compra por
alguém de dezesseis anos já é sensível. As respostas são do encarregado e do negócio; os números
são trabalho do time de dados.

**Perguntar por que o dado contradiz as regras.** Se os termos de uso da Ipê dizem que os clientes
precisam ser adultos, vinte linhas mostram que o formulário de cadastro não confere, ou que alguém
mente a idade — e um controle que devia existir não existe. É um achado para as verificações de
qualidade da aula 9 tanto quanto para a lei.
