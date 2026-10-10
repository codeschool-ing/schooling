---
title: Spikes, alternativas e o pre-mortem
version: 1
---

Uma estimativa e um registro de riscos descrevem um plano. Uma decisão precisa de pelo menos dois,
e o que mais fica fora da página é **não fazer nada**. Esta seção cobre os três movimentos que vêm
antes de uma escolha: comprar a informação que falta à estimativa, comparar as opções com o custo de
não agir, e imaginar que o plano já fracassou, para encontrar os motivos enquanto ainda são baratos.

## Um spike compra informação

Um **spike** é um trabalho curto cujo resultado é uma resposta, não uma funcionalidade. A palavra vem
da Extreme Programming, e a disciplina tem quatro partes: uma pergunta escrita, um tempo limite, uma
resposta escrita, e código que é jogado fora ou marcado claramente como protótipo. Um spike sem
pergunta vira projeto; um spike sem tempo limite vira a funcionalidade, feita às pressas e nunca
arrumada.

**Gaste um spike onde a faixa é mais larga e poucos dias conseguem estreitá-la.** Na tabela de
Renata, a linha mais larga era a das verificações da prova de entrega, de 1 a 9 semanas, e a
largura vinha de uma pergunta que ninguém na mesa sabia responder: o que o Tracking registra no
momento da entrega, e Payments pode confiar nisso a ponto de pagar na hora? Ícaro e um engenheiro do
Tracking levaram três dias para descobrir.

A resposta deles, de dois parágrafos, foi melhor do que o time temia. O Tracking já guarda uma
posição de GPS e uma foto de cada entrega, assinadas pelo app do motorista, junto do registro da
entrega. O que faltava era uma regra para os casos em que a posição fica longe do endereço de
entrega, e um jeito de Payments perguntar. O time estimou a parte de novo, agora em 1, 2 e 4
semanas:

| | antes do spike | depois do spike |
|---|---|---|
| verificações da prova de entrega, média PERT | 3,67 semanas | 2,17 semanas |
| seu desvio padrão | 1,33 | 0,50 |
| total, média PERT | 13,5 semanas | 12,0 semanas |
| total, perto do percentil 85 | 15,5 semanas | 13,5 semanas |

**Seis dias-pessoa tiraram duas semanas do número de planejamento**, e estreitaram a faixa em volta
dele. O spike teria valido a pena também se a resposta fosse ruim. Um resultado que confirmasse as 9
semanas deixaria o plano honesto e o compromisso de Helena mais seguro, e essa é a informação de
qualquer jeito. O que um spike não pode fazer é prometer boa notícia, e um spike feito na esperança
de um número menor é um spike que vai ser lido de forma seletiva.

## Comparando alternativas, começando por não fazer nada

Com a faixa estreitada, Renata escreveu as opções. Três estavam na mesa:

- **A**, construir o pagamento instantâneo sobre a própria API de pagamento por Pix do banco, como
  estimado até aqui;
- **B**, comprá-lo de um provedor de pagamentos, que se conecta a vários bancos e cobra por
  pagamento;
- **C**, não fazer nada: manter a rodada de pagamentos como está.

O time de Payments estimou B do mesmo jeito, em 4, 6 e 11 semanas, com média PERT de 6,5. O
financeiro da Carreto calcula uma semana do time de Payments em cerca de R$ 30.000, e os pagamentos
seriam uns 30.000 por mês. Todo número aqui é uma estimativa e tem a sua faixa no apêndice da página
de Renata; as médias bastam para comparar:

| | A: a API do banco | B: um provedor | C: não fazer nada |
|---|---|---|---|
| esforço, média PERT | 12,0 semanas | 6,5 semanas | nenhum |
| custo de engenharia | R$ 360.000 | R$ 195.000 | nenhum |
| tarifa por pagamento | R$ 0,30 | R$ 1,10 | nenhuma |
| tarifas por mês, 30.000 pagamentos | R$ 9.000 | R$ 33.000 | nenhuma |
| banco fora do ar (R3) | problema da Carreto | quase todo do provedor | não se aplica |
| sair depois | barato | um contrato e uma migração | nada de que sair |
| motoristas esperando o pagamento | não | não | sim, como hoje |

A custa R$ 165.000 a mais para construir e R$ 24.000 a menos por mês para operar, então paga a
diferença em uns sete meses; em três anos, sai cerca de R$ 699.000 mais barato. B entra no ar umas
cinco semanas e meia antes e carrega menos de R3. **Nenhum dos dois números decide sozinho**, e por
isso a página mostra os dois em vez de um vencedor.

**A opção C nunca é de graça, e precisa ser estimada com a mesma seriedade que as outras.** O custo
dela é o motivo de Helena ter perguntado: motoristas indo para um concorrente que paga mais rápido. A
Carreto tem cerca de 9.000 motoristas ativos, e a estimativa da própria Helena, feita com entrevistas
de saída e com o lançamento do concorrente, é que entre 1% e 3% a mais deles sairão por trimestre se
nada mudar: de 90 a 270 motoristas. Essa faixa é tão estimativa quanto as semanas do Bruno, e
escrevê-la permite que Sílvio discuta com ela. Deixar C fora da página faz A e B parecerem as únicas
escolhas, quando a pergunta real é se alguma delas vale mais do que ficar parado.

Escrever as opções lado a lado também produziu uma que não estava na lista. **B com uma porta de
saída**: começar com o provedor, pôr o pagamento atrás de uma interface que Payments controla, e
mudar para a API do banco quando o volume fizer a diferença de tarifa valer o trabalho. Nos termos da aula 5, isso
transforma uma porta de mão única numa porta de mão dupla. O custo extra é a
interface, mais ou menos uma semana, e ela compra o direito de mudar a decisão depois por um preço
conhecido. A comparação completa entre construir e comprar, ao longo de anos e com custos de saída,
é o assunto das aulas 8 e 9 de `tech-strategy`, na trilha de tech lead.

**Quem escolhe não é a arquiteta.** Helena responde pelo que os motoristas recebem, Sílvio pelo
dinheiro, e a aula 13 traçou essa linha. A página de Renata expõe as opções, as faixas, os
principais riscos e o que cada opção supõe, e pede uma decisão até uma data. Deixar as consequências
explícitas é trabalho dela; escolher entre elas é trabalho deles.

## O pre-mortem

Depois que um plano é escolhido, o time para de procurar motivos para ele dar errado: os motivos
passam a soar como deslealdade. O **pre-mortem** de Gary Klein, descrito na *Harvard Business Review*
em 2007, usa esse momento. O grupo ouve que o projeto já fracassou e é convidado a explicar por quê.

A formulação importa mais do que parece. "O que pode dar errado?" convida a uma lista educada. "É
daqui a seis meses, o pagamento instantâneo foi desligado semana passada, e foi um desastre. Levem
cinco minutos e escrevam por quê" transforma o fracasso num fato a explicar em vez de uma previsão a
defender, e dá a todos permissão para dizer o que vinham guardando.

Renata conduziu um quando Helena e Sílvio escolheram B com uma porta de saída. Nove pessoas, vinte
minutos, notas escritas primeiro sozinho, a mesma regra do risk-storming. Quase tudo o que apareceu
já estava no registro. Duas coisas não estavam:

- **O financeiro congelou os pagamentos.** O time do Sílvio concilia o razão com o extrato do banco
  uma vez por mês. Pagamentos instantâneos a cada poucos minutos, por um provedor, fariam da
  conciliação do primeiro mês uma semana de trabalho, e a primeira divergência pararia tudo. Isso
  entrou no registro como R6, com Bruno como dono, mitigado por um relatório diário e automático de
  conciliação.
- **O suporte não conseguia responder aos motoristas.** Um motorista com pagamento atrasado liga para
  o suporte, e o suporte não tinha uma tela que mostrasse onde está um pagamento. Ninguém no projeto
  trabalhava no suporte, e é exatamente por isso que ninguém tinha pensado nisso. Virou uma parte do
  trabalho na estimativa, em 1, 1 e 2 semanas.

**Um pre-mortem olha o plano inteiro; o risk-storming percorre o diagrama.** O primeiro encontra
falhas no ponto em que o sistema encontra pessoas — o financeiro, o suporte, o conselho — e o
segundo as encontra nas partes e nas setas. Eles pegam coisas diferentes, e os dois juntos levaram
menos de uma hora.

O que Renata tinha mandado para Helena antes da decisão cabia numa página: uma faixa para planejar,
os cinco maiores riscos com donos e respostas, três opções incluindo não fazer nada, a que o spike
mudou, e a pergunta que ela precisava ver respondida. Como escrever essa página para uma diretora é
o assunto da aula 4 de `architect-communication`. O que vai nela é esta aula.
