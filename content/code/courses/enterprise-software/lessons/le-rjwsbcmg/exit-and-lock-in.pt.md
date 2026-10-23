---
title: O preço de sair
version: 1
---

"Evite o aprisionamento ao fornecedor" (*vendor lock-in*) é dito em toda reunião de arquitetura e não
decide nada, porque toda opção prende a Serra Alta a alguma coisa. Um produto SaaS a prende ao
contrato e ao modelo de dados de um fornecedor. Uma extensão do SAP a prende ainda mais ao SAP, onde
ela já mora. Uma construção a prende ao código de sete pessoas e ao punhado delas que fica. **Lock-in
não é uma propriedade que uma opção tem ou não tem; é um custo de troca, e um custo tem preço.** Uma
vez com preço, ele entra na planilha ao lado dos outros, e a discussão passa a ser sobre um número que
alguém consegue conferir.

Esta seção precifica a linha de saída das três opções, explica o que cada parte dela paga e mostra
onde o contrato e a arquitetura conseguem diminuí-la.

## Quanto custa sair

Uma saída é contada como o que custaria à Serra Alta sair no fim do período — 31 de dezembro de 2029
— **sem os custos do próprio sistema seguinte**, que pertencem à planilha dele. O que sobra é o preço
de sair:

| parte | o que ela paga |
|---|---|
| exportação dos dados | tirar cada fazenda, cada coleta e cada resultado de laboratório, numa forma que outro sistema consiga carregar |
| sobreposição | o sistema antigo mantido rodando enquanto o seguinte roda em paralelo, em geral três meses |
| integrações a refazer | as interfaces que falavam com o sistema antigo e agora têm de falar com o seguinte |
| retreinamento | os 300 motoristas e as 30 pessoas de escritório, no que substituir o que aprenderam |
| multas de rescisão | o que se deve por sair antes do fim de um prazo |
| aviso prévio | não é custo em si, mas decide quando os outros podem ser evitados |

Para a opção A, no fim do mês 36:

| parte | calculada como | reais |
|---|---|---|
| exportação dos dados | o serviço pago do fornecedor para o histórico completo, no formato documentado dele | 30.000 |
| sobreposição | três meses de assinatura ao preço do ano 3: 3 × R$ 26 × 2.100 fazendas | 163.800 |
| integrações a refazer | 60% da linha de integração: 0,6 × R$ 240.000 | 144.000 |
| retreinamento | motoristas e escritório | 60.000 |
| multas de rescisão | nenhuma: a saída é no fim de um prazo de renovação | 0 |
| **saída** | | **397.800** |

A sobreposição é a maior parte, e surpreende. **Um sistema de coleta não pode ser desligado numa
sexta e substituído na segunda**: a execução em paralelo da aula 13 precisa do sistema antigo
calculando os mesmos pagamentos aos produtores que o novo, mês a mês, até os dois concordarem. Nesses
três meses a Serra Alta paga os dois.

## O contrato decide metade

Três cláusulas do contrato de A decidem quanto custa a saída, e **elas são negociadas na assinatura,
quando a Serra Alta ainda pode ir embora, ou não são negociadas nunca**.

*A exportação.* O fornecedor exporta o cadastro atual das fazendas num arquivo CSV a qualquer
momento, de graça. O histórico completo — trinta e seis meses de coletas e resultados de laboratório —
vem como serviço pago, R$ 30.000, num formato documentado com um dicionário de dados que nomeia cada
campo e sua unidade. Sem esse dicionário a exportação é um arquivo de números cujo significado alguém
tem de redescobrir, que é a aula 14 de novo no pior momento. O contrato também diz que o fornecedor
guarda os dados da Serra Alta por 90 dias depois do fim e então os apaga, então a exportação tem
prazo.

*O aviso prévio.* O primeiro prazo é de 24 meses. Para sair no fim dele, a Serra Alta precisa avisar
com seis meses de antecedência, até o fim do mês 18 — junho de 2028, o mês em que Sebastião se
aposenta. Perca essa data e o contrato renova para o ano 3, R$ 655.200 comprometidos seja o que for
que a Serra Alta decida depois. **O aviso prévio é a parte do lock-in que aparece como uma data**, e
ela pertence ao calendário de alguém, com o nome dessa pessoa, não ao anexo do contrato.

*Rescisão antes do prazo.* Sair cedo significa pagar o resto do prazo. Se a Serra Alta saísse no
fim do ano 1, deveria os doze meses do ano 2 mesmo assim: R$ 25 × 2.000 fazendas × 12 = R$ 600.000.
Esse é o preço de um prazo de dois anos, e ele compra o preço de R$ 25; um prazo de um ano teria
custado mais por fazenda e menos para sair.

## A arquitetura decide a outra metade

Os 60% da linha de integrações não são um palpite sobre o fornecedor. São consequência de como a Serra
Alta constrói as interfaces dela. A aula 13 apresentou a **camada anticorrupção** para manter o modelo
do Coleta fora do modelo novo. O plano de integração da Serra Alta usa o mesmo padrão do outro lado:
o SAP, o laboratório e o Rota falam com o modelo da própria Serra Alta de uma fazenda, uma coleta e um
pagamento, e só a camada fala com o produto. Sair do produto significa reescrever o lado da camada
voltado para ele, não todas as interfaces atrás dela.

Sem a camada, cada interface seria escrita contra a API do fornecedor, e a linha de integração
inteira seria refeita na saída: R$ 240.000 em vez de R$ 144.000. **A diferença de R$ 96.000 é lock-in
removido de propósito**, paga uma vez no trabalho de integração e recebida no dia em que a Serra Alta
sair — ou nunca recebida, e ainda assim valiosa, porque é também o que deixa a Serra Alta negociar uma
renovação como quem poderia ir embora.

## B e C também têm saída

| parte | A: comprar | B: estender o SAP | C: construir |
|---|---|---|---|
| exportação dos dados | 30.000 | 40.000 | 10.000 |
| sobreposição | 163.800 | 0 | 57.000 |
| integrações a refazer | 144.000 | 90.000 | 180.000 |
| retreinamento | 60.000 | 60.000 | 60.000 |
| **saída** | **397.800** | **190.000** | **307.000** |

B tem a menor saída, por um motivo que vale entender. Sair de B significa
tirar o pagamento aos produtores do SAP. O SAP em si fica, então não há assinatura para sobrepor, e as
fazendas continuam cadastros de fornecedor seja o que for que substitua o cálculo. Tirar o histórico
das tabelas customizadas custa R$ 40.000, e 60% da linha de integração menor de B, R$ 90.000, são
refeitos. A Serra Alta já está presa ao SAP pelas finanças, pelas vendas e pelo estoque; **um lock-in
que ela já tem não custa nada a mais para aumentar**. O lock-in de B aparece em outras linhas: o
código customizado que tem de ser testado de novo a cada atualização do S/4HANA (R$ 150.000 no ano
3), e as duas pessoas do time de Edson que vão entendê-lo.

**Os dados de C são dela**, num banco PostgreSQL cujo esquema a Serra Alta escreveu, então a
exportação custa R$ 10.000 do tempo de alguém. A sobreposição são três meses rodando o próprio sistema
— R$ 9.000 de infraestrutura e R$ 10.000 de operação por mês, R$ 57.000. A linha de integração dela é
a maior das três, então 60% dela, R$ 180.000, é o maior retrabalho. O lock-in que a tabela não
consegue mostrar é o que a seção 04 desta aula nomeou: as poucas pessoas que entendem o código.

## Por que a saída entra inteira

Uma objeção comum: a Serra Alta não pretende sair, então por que somar R$ 397.800 a A? Algumas
planilhas multiplicam a saída por uma probabilidade de sair — uma chance de 20%, digamos — e somam um
quinto dela.

A planilha da Serra Alta a conta inteira, por dois motivos. A probabilidade é um palpite, e
multiplicar um número real por um palpite esconde o palpite dentro de um resultado com cara de
precisão. E **a linha de saída é quanto a opção custa para não ficar encurralada**: uma opção cuja
porta custa mais dá ao fornecedor mais poder em cada renovação, saia alguém por ela ou não. Contá-la
inteira trata o lock-in como o que ele é — um risco com preço — e deixa a seção 06 desta aula comparar
três opções que carregam um cada.
