---
title: A LGPD no BI de todo dia
version: 1
---

A aula 19 encontrou a LGPD onde ela pesa mais, nos dados de saúde. Esta seção é sobre o caso comum,
que é toda empresa deste curso: a Varanda tem nomes, endereços e históricos de compra de clientes,
salários e faltas de funcionários; a Ipê tem rendas e dívidas de tomadores de crédito. **A maior parte
do trabalho de BI não precisa de nenhuma identidade e precisa de alguns detalhes**, e o que a lei pede
a uma equipe de BI se resume a manter as coisas assim e conseguir mostrar que mantém. As aulas 6 e 7
de `data-governance` tratam da lei em si; o que segue é o que ela muda na mesa do analista.

## Quatro hábitos

**Finalidade.** O dado pessoal é coletado para uma finalidade, e usá-lo para outra precisa de base
própria. A Varanda coletou endereços de entrega para entregar sofás. Usá-los para mapear onde moram os
clientes, para escolher o lugar da próxima loja, é outra finalidade, e Lívia perguntou ao encarregado
de proteção de dados da empresa antes de montar o mapa, e não depois. A resposta foi sim, no nível do
bairro e não da rua.

**Minimização.** Um relatório leva os campos de que a pergunta precisa e nenhum outro. A análise de
campanha da aula 18 precisava, por cliente, do grupo em que ele estava e de se fez pedido. Não
precisava do nome, e o arquivo com que Lívia trabalhou não tinha nomes.

**Acesso por papel.** A regra da aula 19, num varejista: os gerentes de loja veem as vendas da própria
loja, os relatórios de RH de Sônia com salários são vistos pelo RH e pelos diretores, e um painel
compartilhado por link é conferido quanto ao que o link expõe antes de ser enviado.

**Agregação, de olho nas células pequenas.** Vendas por bairro não são dado pessoal; vendas por rua,
numa rua com três casas, podem ser. As regras de supressão da aula 19 valem para qualquer tabela que
possa ser cortada fino o bastante para apontar uma pessoa.

## Anonimizado ou pseudonimizado

As duas palavras não são intercambiáveis, e a diferença decide se a lei se aplica.

O **dado pseudonimizado** tem a identidade trocada por um código que a empresa consegue transformar de
volta numa pessoa: cliente 48213 em vez de um nome, com a chave em outra tabela. É o que Débora usou
no Jacarandá para ligar duas internações do mesmo paciente, e o que Lívia usa para acompanhar os
pedidos de um cliente ao longo do tempo. **Continua sendo dado pessoal**, porque a empresa guarda a
chave.

O **dado anonimizado**, nos termos da LGPD, é o que não pode mais ser associado a uma pessoa por meios
razoáveis, e o art. 12 diz que ele não é dado pessoal, a não ser que a anonimização possa ser
revertida. Essa última cláusula é a parte difícil: tirar os nomes não basta quando uma data de
nascimento, um CEP e uma compra juntos apontam uma pessoa. Uma tabela de vendas da Varanda por loja,
mês e categoria é anônima; uma tabela de compras individuais sem o código do cliente, mas com a data,
a loja e a cesta exata, pode não ser.

O teste prático é perguntar o que alguém com o arquivo na mão, e com o que mais estiver fácil de
conseguir, poderia descobrir. Se a resposta inclui uma pessoa, trate o arquivo como dado pessoal.

## Quando um cliente pede

O art. 18 dá ao titular, a pessoa de quem são os dados, direitos que a empresa precisa atender: entre
eles, confirmar que os dados são tratados, ter acesso a eles, corrigi-los e ter eliminados os dados
desnecessários ou excessivos. Os pedidos vão ao encarregado de proteção de dados da empresa, e a parte
da equipe de BI é achar a pessoa em tudo o que ela guarda: as tabelas do data warehouse, as fotos
congeladas, as extrações na pasta de alguém. **Uma equipe de BI que não sabe dizer onde estão os
dados de um cliente não consegue atender o pedido**, e esse é o melhor argumento para manter só as
cópias de que o trabalho precisa.

A eliminação esbarra de frente na seção anterior. As fotos congeladas da Ipê contêm tomadores de
crédito, e um tomador pode pedir para ser apagado. A lei permite guardar dados quando uma obrigação
legal ou regulatória exige, então a foto que um regulador pode pedir para ver fica, guardada à parte e
com acesso restrito, enquanto as cópias feitas por conveniência vão embora. Quais registros caem em
qual obrigação é decisão das áreas de compliance e jurídica, escrita uma vez; a equipe de BI a aplica
sempre do mesmo jeito.
