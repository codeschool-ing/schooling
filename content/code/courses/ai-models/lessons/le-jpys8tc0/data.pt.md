---
title: Para onde o e-mail vai
version: 1
---

Toda requisição que o programa da ana faz carrega o e-mail de um cliente: um nome, um número de
pedido, às vezes um endereço, de vez em quando uma queixa sobre a mãe de alguém. **Para onde esse
texto viaja é uma propriedade do tipo de modelo**, e muitas vezes é o critério que decide antes
mesmo de custo ou qualidade serem medidos.

## Fechado: para o provedor, nos termos dele

Com um modelo fechado o e-mail sai dos seus sistemas e é processado pelo provedor. O que acontece com
ele depois é definido pelos **termos de serviço e pelo contrato de tratamento de dados** do provedor,
que dizem por quanto tempo as requisições ficam guardadas, se são usadas para treino e quem dentro
do provedor pode vê-las. Os termos de API para empresas dos grandes provedores dizem que as entradas
não são usadas para treino por padrão, e a maioria oferece retenção mais curta para clientes que
pedem. Leia a versão que vale para a sua conta, não um resumo dela.

O que você pode escolher, mesmo com um modelo fechado, muitas vezes é **onde** ele é processado. As
plataformas de nuvem que revendem modelos fechados vendem rotas regionais, e a tabela dá preço a
elas:

```
ana@desk:~/desk$ sheet where anthropic.claude-sonnet-5-5 | grep -E "^(global|us|eu|jp)\."
eu.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
global.anthropic.claude-sonnet-5-5                   bedrock_converse                  2       10
jp.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
us.anthropic.claude-sonnet-5-5                       bedrock_converse                2.2       11
```

O mesmo modelo, quatro rotas. `eu.` mantém o processamento dentro de regiões europeias, `jp.` dentro
do Japão, `us.` dentro dos Estados Unidos, a dez por cento acima da rota `global`, que pode mandar a
requisição para onde houver capacidade. **Esses dez por cento são o preço de uma garantia sobre
geografia**, que alguns contratos e algumas leis exigem.

## Aberto: para onde você o rodar

Com pesos abertos, na sua máquina ou na sua conta de nuvem, o e-mail não vai a lugar nenhum para onde
você não o mandou. Esse é o argumento inteiro, e para algumas organizações ele encerra a conversa:
prontuários, processos jurídicos, qualquer coisa que um contrato diga que não pode sair.

Repare no que ele **não** diz. Um modelo aberto servido por **um host** (as entradas baratas da seção
05) coloca o e-mail nas máquinas desse host, nos termos desse host, exatamente como um provedor
fechado faria. Pesos abertos só mantêm os dados dentro quando você mesmo os roda, que é o assunto da
aula 3 e o custo da aula 3.

## A Lantern Books, até aqui

| pergunta | fechado | aberto, hospedado | aberto, rodado por ela |
|---|---|---|---|
| condições de licença a conferir | termos de serviço | a licença do modelo e os termos do host | a licença do modelo |
| preço | por token, um autor | por token, muitos hosts | por hora de uma máquina |
| muda quando | o provedor aposenta | o host retira | a ana decide |
| o e-mail vai para | o provedor, numa região que ela escolhe | o host | lugar nenhum |

Nenhuma dessas colunas vence sozinha. A aula 3 pergunta quando a última se paga; a aula 4 transforma
as linhas em critérios com números; a aula 5 acrescenta a linha que falta nesta tabela: **se o modelo
faz a tarefa, para começo de conversa**.
