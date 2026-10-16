---
title: Uma conta real, e a ordem em que protegê-la
version: 1
---

**Você não precisa de conta AWS para nenhuma lição deste curso.** Esta seção é para depois, ou para
o aluno que quer ver o console de verdade ao lado do moto. **Nada aqui foi rodado para o curso**,
porque não há conta por trás, então não há transcrições, só os passos e os motivos da ordem deles.
As telas que eles citam são da AWS, e a AWS as redesenha; os nomes das configurações mudam menos que
o lugar delas.

## Antes de a conta existir

Uma conta AWS é criada em `aws.amazon.com` com um endereço de e-mail, uma senha, um número de
telefone que recebe um código e um cartão de pagamento. Duas decisões são baratas agora e caras
depois:

- **Use um endereço que não seja de uma pessoa.** O endereço vira o **usuário root**, a identidade
  que é dona da conta e pode fazer qualquer coisa nela, inclusive encerrá-la. Uma caixa
  compartilhada como `aws-root@suaempresa.example` sobrevive ao dia em que quem abriu a conta sai.
- **Saiba que plano está escolhendo.** Quando este curso foi escrito, uma conta nova começava ou num
  **plano gratuito**, com uma soma de créditos que expiram depois de alguns meses e limites no que
  ela pode criar, ou num plano pago com o antigo **nível gratuito**: um conjunto de serviços
  gratuitos até um valor mensal. **O nível gratuito é uma possibilidade, não uma promessa**: a AWS
  mudou os termos em 2025 e pode mudar de novo, então leia a página atual antes de contar com
  qualquer número dela, e nunca com um número tirado de um curso.

## A primeira hora, nesta ordem

1. **Proteja o usuário root com MFA**, um segundo fator. No console fica sob o nome da conta,
   *Security credentials*, *Multi-factor authentication*. Uma passkey ou um app autenticador no
   celular servem. Até isso estar feito, a conta está a uma senha vazada de pertencer a outra pessoa,
   e o cartão por trás dela junto.
2. **Nunca crie chave de acesso para o usuário root.** A mesma página oferece uma. Uma chave é uma
   senha que não pode ter segundo fator, e a lição 12 explica por que até a chave de um usuário
   comum é o último recurso; para o root é o pior.
3. **Crie um orçamento com alerta, antes de qualquer coisa que possa custar dinheiro.** Em *Billing
   and Cost Management*, *Budgets*: um orçamento mensal de custo de poucos dólares, com um alerta por
   e-mail em 80% do custo real e outro em 100% da previsão. A lição 13 monta o mesmo orçamento no
   moto e diz o que cada tipo de alerta quer dizer. **Um alerta não para o gasto**; ele avisa você,
   e é por isso que vem primeiro, enquanto o valor ainda é pequeno.
4. **Crie uma identidade do dia a dia, e pare de usar o root.** A lição 11 liga o IAM Identity
   Center e cria um usuário para você com um permission set; dali em diante a senha do root vai para
   um lugar seguro e só é usada nas poucas tarefas que a exigem, como encerrar a conta.

## Apontando o laboratório para ela, e de volta

A linha de comando que você instalou fala com a AWS no momento em que o `AWS_ENDPOINT_URL` não está
definido e há credenciais reais. **Use um terminal separado que nunca leia o `env.sh`**, entre ali
com `aws configure sso` como a lição 25 mostra, e mantenha os terminais do moto como estão. Dois
terminais com dois prompts são mais difíceis de confundir que um terminal cujas variáveis você
precisa lembrar.

Tudo neste curso que o moto apenas registra, a AWS vai rodar e cobrar: um NAT gateway cobra por hora
desde o momento em que existe, um balanceador de carga também, e cada endereço IPv4 público também.
As lições 17 e 22 dão os preços. **Apague o que criar no mesmo dia**, e olhe a página da fatura na
manhã seguinte: é a única tela que diz o que você esqueceu.
