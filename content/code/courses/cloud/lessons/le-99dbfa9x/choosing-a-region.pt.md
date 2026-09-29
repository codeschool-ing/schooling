---
title: Escolhendo uma região
version: 1
---

O hábito que esta seção substitui é escolher só pelo preço, ou não escolher e ficar com o que o
console mostrou primeiro. **Uma região se escolhe com cinco perguntas, e elas não pesam igual.** As
duas primeiras são restrições: uma região que falha em qualquer uma está fora, custe o que custar. As
outras três são trocas, pesadas umas contra as outras entre as regiões que sobraram.

1. O que a lei diz sobre onde os dados podem ficar? É a pergunta de residência de dados da aula 2, e
   quem responde é a região, porque a região é onde os dados ficam fisicamente. Se dados pessoais
   precisam ficar no país, uma região fora dele não é opção, e uma réplica lá também não.
2. O serviço de que você precisa existe lá? Todo serviço gerenciado e tipo de instância que você
   pretende usar, conferido na tabela do próprio provedor antes de qualquer projeto girar em torno
   dele. Uma região sem um serviço do qual você não abre mão está fora, a menos que você refaça o
   projeto.
3. Onde estão os usuários, e quanto isso dá em milissegundos? Use a regra de duas seções atrás, um
   milissegundo de ida e volta a cada 100 km, e depois pense em quantas idas e voltas uma página faz.
   Um relatório interno que roda uma vez por noite não se importa; uma página de pagamento com vinte
   chamadas se importa.
4. Quanto custa lá? A planilha mostrou São Paulo entre 1,54 e 1,62 vezes o preço da Virgínia para as mesmas
   instâncias, e as próximas seções mostram que tirar dados de São Paulo também custa mais.
5. Onde estão os seus outros sistemas? O banco de dados, as APIs dos parceiros, o provedor de
   identidade, o gateway de pagamento. Tudo com que o seu código conversa muitas vezes por pedido
   pertence a um lugar perto dele.

## Uma aplicação, do começo ao fim

Uma rede de clínicas no Brasil quer um sistema de agendamento. Pacientes marcam pelo celular, do país
inteiro, e os registros são dados de saúde de residentes no Brasil.

**A lei vem primeiro.** Suponha que os advogados da clínica concluam que os registros precisam ficar
no Brasil. Isso decide a região dos registros antes de qualquer preço ser comparado: `sa-east-1`, a
única região da planilha dentro do país. Os preços menores da Virgínia são irrelevantes para esses
dados, porque uma região que falha numa restrição não entra na comparação.

**A latência concorda.** Os pacientes estão no Brasil, então um servidor em São Paulo fica a uma
viagem curta para a maioria deles: um paciente em Fortaleza está a 23,7 ms de São Paulo no piso,
enquanto um paciente em São Paulo estaria a 76,6 ms da Virgínia.

**O preço é a troca que sobrou, e ele ainda pode ganhar em algum lugar.** O sistema também gera, uma vez
por noite, relatórios a partir de estatísticas anonimizadas: sem dados pessoais, sem usuário
esperando. Esse job poderia rodar na `us-east-1` numa `m7i.large` a 0,10080 por hora em vez de
0,16065, se a lei permitir que os dados anonimizados saiam e os advogados concordarem que estão
anonimizados. É também exatamente o tipo de job contra o qual a última pergunta avisa: se ele lê o
banco de registros vinte mil vezes por noite atravessando um continente, as idas e voltas e a
transferência para fora de São Paulo podem comer a economia. A resposta costuma ser
"rode ao lado dos dados", e o checklist é o que faz você conferir em vez de supor.

**A pergunta sobre o serviço é a outra restrição, e ela pode derrubar a primeira resposta.** Se o projeto da clínica
depende de um serviço gerenciado que não existe na `sa-east-1`, a escolha deixa de ser entre regiões. É
entre refazer o projeto sem esse serviço e descumprir a lei, e essa é uma decisão de quem responde
pelos dados, não de quem está lendo planilhas de preço.

## O que o checklist não decide

Ele não decide quantas regiões. Tudo acima escolhe uma região para uma carga de trabalho; a seção
sobre várias regiões trata de pagar por uma segunda, para que um desastre na primeira não acabe com o
negócio. Ele também não decide quantas zonas: dentro da região escolhida a resposta é pelo menos duas,
e a próxima seção diz por quê e quanto isso custa.

E ele não fica decidido para sempre. Preços mudam, serviços chegam a regiões novas, e a `sa-west-1`
aparece num arquivo publicado que o CLI 2.37.4 não lista. Uma região escolhida por bons motivos há
três anos merece as mesmas cinco perguntas de novo.
