---
title: O que se mede, o que se mira e o que se assina
version: 1
---

Um contrato que diz "99,9% de disponibilidade" parece uma garantia de que o serviço vai estar no ar. **Um
SLA não garante nada. É o preço que o fornecedor paga quando o serviço fica aquém**, e o preço quase sempre
é pequeno. Nenhum incidente foi montado no laboratório para esta aula, então não há captura: os números
dela são aritmética, rodada como programa onde há uma conta, e os dois failovers medidos nas aulas 15 e 16.

Três termos andam juntos e vivem sendo confundidos, e a diferença entre eles é quase tudo de que esta
seção trata:

| termo | o que é | um exemplo |
|---|---|---|
| **SLI**, indicador de nível de serviço | uma medida | a fração de requisições respondidas com status de sucesso em até meio segundo, contada no balanceador |
| **SLO**, objetivo de nível de serviço | uma meta interna para essa medida | 99,95% das requisições, em quaisquer 30 dias |
| **SLA**, acordo de nível de serviço | um contrato com um cliente | 99,9% num mês do calendário, ou um crédito na fatura |

O SLI vem primeiro porque nada pode ser prometido sobre o que não se mede. O log do HAProxy da aula 16 já
tem a matéria-prima de um: cada requisição com a hora, o servidor, o status e cinco timers. Contar as
linhas com `200` contra todas as linhas, ao longo de um mês, é um SLI de disponibilidade que reflete o que
os usuários de fato receberam, o que é mais do que um ping na porta da frente consegue dizer.

O SLO fica mais apertado que o SLA de propósito. É o alarme que toca enquanto ainda dá tempo de agir: uma
equipe que mira 99,95% e erra descobre antes de um contrato que promete 99,9% ser quebrado.

## As letras miúdas são a promessa

Dois SLAs que dizem 99,9% podem prometer coisas bem diferentes, e a diferença está em cinco lugares:

- **A janela.** Um mês do calendário zera no dia primeiro; 30 dias corridos nunca esquecem uma semana ruim.
- **O que conta como fora do ar.** Só inalcançável, ou também respondendo com erro, ou também respondendo
  tão devagar que ninguém espera. Um site que leva trinta segundos por página está no ar pela primeira
  definição.
- **Onde se mede.** No monitoramento do próprio fornecedor, dentro da rede dele, ou em algo que vê o que um
  cliente vê de fora.
- **O que fica de fora.** Manutenção anunciada com antecedência, quedas que o cliente causou, recursos
  marcados como beta, eventos fora do controle de qualquer um. Uma lista de exclusões pode tirar a maior
  parte das horas que importam.
- **Como se pede um crédito.** Muitas vezes só se o cliente pedir, dentro de um número de dias, com
  evidência.

E o crédito em si tem teto no valor da mensalidade. Um formato típico, como ilustração e não a tabela de
nenhum fornecedor real, é 10% da mensalidade abaixo do número prometido e 25% bem abaixo dele. **Uma queda
de quatro horas que custa a uma loja um dia de vendas é compensada com uma fração de um mês de
hospedagem.** Então um SLA vale a leitura pelo que diz que o fornecedor mede e mira, e não vale nada como
seguro. O que um negócio precisa de verdade é uma arquitetura que cumpra o número, e é isso que o resto
desta aula pesa.
