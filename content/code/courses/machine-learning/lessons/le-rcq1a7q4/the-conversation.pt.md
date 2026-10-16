---
title: Quatro posições, e o que dizer a cada uma
version: 1
---

As tabelas desta aula chegam a quem decide, e quatro posições voltam. Cada uma é defendida de boa-fé, cada
uma tem metade de razão, e cada uma tem resposta.

**1. "É só tirar a idade do modelo, e o problema some."** O primeiro instinto do jurídico.

A segunda tabela do `by_age.py` é a resposta. Tirar a idade baixou a chance de crédito dos jovens que saem
de 26,7% para 19,4%, e o modelo continuou separando as faixas: as colunas que ficaram identificam quem tem
65 anos ou mais com AUC de 0,872, e duas delas, `app_user` e o boleto, mudam muito com a idade. **O desconhecimento mudou quem se
beneficia sem tirar a idade da decisão.** A versão útil do instinto é deixar a idade fora do modelo e
dentro da auditoria.

**2. "É um desconto, não um empréstimo. Ninguém sai prejudicado."** A visão do marketing.

O benefício negado é o prejuízo. Se um grupo tem sistematicamente menos chance de receber algo de valor,
isso é tratamento desigual mesmo quando ninguém é cobrado de nada. A Lei Geral de Proteção de Dados, a
LGPD, lista a **não discriminação** entre os princípios do tratamento de dados pessoais (art. 6º, IX):
dados não podem ser tratados para fins discriminatórios ilícitos ou abusivos. Um benefício pequeno baixa o
que está em jogo; não tira a pergunta.

**3. "Dê a toda faixa de idade a mesma parte dos créditos."** Um conselheiro que quer uma regra simples.

O `parity.py` pôs preço nisso: R$ 1.088 em seis meses, menos gente que sai alcançada, e créditos
deslocados para longe dos mais jovens, o grupo que mais sai. A resposta é a tabela de definições:
**partes iguais é o objetivo certo quando o benefício deve ser distribuído por igual, e o errado quando ele
é para quem precisa.** Recall igual serve melhor a este crédito: quem vai sair tem a mesma chance de oferta em qualquer faixa.

**4. "O modelo é matemática. Ele não pode ser enviesado."** Um engenheiro que não leu esta aula.

O modelo aprende com o que aconteceu, e reproduz o que aprende: os jovens saem mais, então o modelo dá
mais crédito a eles; os assinantes mais velhos usam menos o app, então `days_since_login` falta mais para
eles, e o modelo trata essa lacuna como informação. **Um modelo é tão justo quanto os seus dados e o seu
objetivo, e os dois foram escolhidos por pessoas.** As tabelas são como alguém descobre para que lado ele
pende.

## O que a Ana escreve no enquadramento

O enquadramento da aula 1 ganha três linhas. **A idade fica fora do modelo e guardada para auditoria.**
Todo mês, a Ana imprime
o recall do crédito por faixa de idade, com o intervalo de bootstrap da aula 2, e investiga qualquer
faixa cujo recall caia claramente abaixo das outras. E um assinante que pergunte por que
recebeu ou não recebeu um crédito ganha uma resposta: a LGPD dá às pessoas o direito de pedir a revisão de
decisões tomadas unicamente com base em tratamento automatizado que afetem os seus interesses (art. 20), e
os valores SHAP da aula 19 são o que torna uma resposta possível.
