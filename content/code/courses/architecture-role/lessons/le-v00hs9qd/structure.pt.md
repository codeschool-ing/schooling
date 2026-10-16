---
title: Decisões estruturais, e quais delas são de arquitetura
version: 1
---

A aula 5 tratou de escolher tecnologias: qual banco, qual biblioteca, qual serviço gerenciado.
**As decisões que mais moldam um sistema são de estrutura**: como o sistema é cortado em partes,
como as partes conversam e quem é dono do quê. Elas sobrevivem às tecnologias. A Carreto poderia
trocar o message broker por outro produto no ano que vem, e a decisão de que o Payments fica sabendo
das entregas provadas de forma assíncrona, por um evento, continuaria valendo, com todas as
consequências dela.

A ideia errada é que decisões estruturais são tomadas uma vez, no começo, por quem desenhou o
primeiro diagrama. **Elas são tomadas o tempo todo, a maior parte pelos times, e muitas vezes sem
ninguém perceber que uma decisão estrutural estava sendo tomada.** Um pull request que acrescenta
uma consulta à tabela de outro time é uma decisão sobre a posse dos dados, tenha o autor pensado
nisso desse jeito ou não.

## Cinco tipos de decisão estrutural

O curso `architecture` ensinou os estilos entre os quais essas decisões escolhem: monólitos e
microsserviços, comunicação síncrona e assíncrona, eventos, sagas. Esta aula não os ensina de novo.
Ela trata das decisões como decisões: de que tipo é cada uma, quem deveria tomá-la e como tomá-la
bem. Na Carreto elas vêm em cinco tipos.

**Como o sistema é cortado.** Um monólito modular, serviços separados, ou algo no meio. O próximo
trabalho da Carreto é faturar os embarcadores depois que uma entrega é paga, e a primeira pergunta é
se isso vira um módulo dentro do monólito, que já guarda os cadastros dos embarcadores, ou um serviço
novo do Payments. Essa pergunta é o exemplo trabalhado na terceira seção desta aula.

**Como as camadas dependem umas das outras.** Dentro do Payments, o código que decide quando pagar
não sabe nada do banco parceiro: ele chama uma interface, e um adaptador por trás dela fala a API do
banco. Essa é uma decisão de camadas, com o mesmo formato do adaptador que o Pricing usa para o
provedor de rotas na aula 4, e é ela que deixa o Payments trocar de banco sem mexer nas regras sobre
dinheiro. `design-patterns` aulas 4 e 5 ensinam inversão e injeção de dependência, as técnicas por
baixo disso.

**Síncrono ou assíncrono.** Se quem chama espera a resposta ou entrega uma mensagem e segue em
frente. O registro 7 da aula 5 escolheu assíncrono para Tracking e Payments, e pagou por isso com
eventos duplicados e atrasados. A escolha oposta teria amarrado a disponibilidade do Tracking à do
Payments.

**Quem é dono de quais dados.** A pergunta que a Carreto errou por mais tempo. Durante anos a tabela
`deliveries` do monólito foi lida e escrita pelo monólito, pela primeira versão do Tracking, por um
job de relatório e por um script no Payments. Ninguém conseguia mudar uma coluna sem consultar
quatro times, então ninguém mudava, e a tabela foi ganhando campos cujo significado só uma pessoa
lembrava. A decisão que a Renata defendeu é simples de enunciar: **cada dado tem exatamente um dono,
o dono é o único que escreve, e os outros pedem ao dono**, por uma API ou por um evento.

**Onde uma regra mora.** O frete mínimo da ANTT é checado no Pricing, pela etapa de piso que é a
única saída. No começo, o Shipper app também checava, no próprio código, "por segurança". As duas
cópias divergiram por uma semana depois que a ANTT publicou uma tabela nova, porque só o Pricing a
carregou. Uma regra com duas casas são duas regras, e elas se afastam.

## Quais decisões são de arquitetura

Nem toda decisão estrutural precisa de um arquiteto. A aula 1 deu a definição de trabalho, a de
Booch: arquitetura é o conjunto das decisões significativas, onde o significado se mede pelo custo
de mudar. Na prática a Renata aplica três testes, e uma decisão que passa em qualquer um deles é de
arquitetura:

1. **Custa caro reverter.** Mudar dados de dono, dividir um serviço ou alterar um contrato público
   leva semanas e uma migração, e por isso recebe o cuidado de uma porta de mão única.
2. **Atravessa a fronteira de um time.** As consequências dela caem num time que não a tomou: um
   evento novo, uma API alterada, uma tabela compartilhada.
3. **Define um atributo de qualidade do sistema todo.** Ela decide quão disponível, quão rápido ou
   quão seguro vai ser algo de que vários times dependem.

O resto pertence ao time, e um arquiteto que estica a mão para isso atrapalha. **A maioria das
decisões de design não é de arquitetura, e é para isso que existe um teste.** Uma tabela com exemplos
da Carreto deixa a linha concreta:

| decisão | cara de reverter? | atravessa times? | quem decide |
|---|---|---|---|
| os nomes dos módulos internos do Payments | não | não | o time de Payments |
| qual framework de testes o Matching usa | não | não | o time de Matching |
| o Tracking guardar posições no PostgreSQL por mês | sim | não | o Tracking, com registro e um revisor de fora |
| os campos do evento DeliveryProved | um pouco | sim | Tracking e Payments, com a Renata |
| faturamento como módulo do monólito ou serviço novo | sim | sim | Payments e Shipper, com a Renata, pelo processo de aconselhamento |
| um dono para cada tabela | sim | sim | proposto pela Renata, acordado no fórum de arquitetura |

Os testes importam mais que a tabela, porque a tabela vai errar sobre a próxima decisão. **Uma
decisão muda de linha quando as consequências dela mudam.** O cache das cotações do Pricing no
Matching, na aula 4, começou na primeira linha, interno a um time, e subiu no momento em que podia
quebrar a garantia do Pricing.

## As decisões que ninguém toma

As decisões estruturais mais difíceis de administrar são as que acontecem por acúmulo. Ninguém
decidiu que a tabela `deliveries` teria cinco escritores. Um script foi acrescentado às pressas,
depois um job de relatório, depois um atalho durante um incidente, cada um razoável no seu dia. A
aula 17 chama o resultado de arquitetura acidental: uma estrutura que nunca foi escolhida, só
alcançada.

**Parte do trabalho do arquiteto é perceber uma decisão estrutural enquanto ela ainda é pequena.** A
Renata lê pull requests que mexem em tabelas compartilhadas, esquemas de eventos e APIs públicas, não
para aprová-los, mas para reconhecer quando um deles está decidindo algo em silêncio. Quando vê um,
ela não bloqueia. Ela dá nome à decisão na revisão ("isto faz do Pricing um segundo escritor da
tabela deliveries; é essa a decisão que queremos?") e deixa o time decidir com a decisão à vista. A
aula 9 mostra como as mais importantes dessas linhas podem ser checadas por um programa, em vez de
pela atenção dela.

## Uma decisão não é um diagrama

Mais uma coisa para separar. Uma decisão estrutural muitas vezes é desenhada, e o desenho não é a
decisão. A aula 2 fez o ponto geral; aqui ele fica concreto. O diagrama do pagamento em 24 horas da
aula 4 mostra uma seta do Tracking para o Payments. **A decisão é tudo o que a seta não diz**: que é
um evento e não uma chamada, que o Payments precisa tolerar duplicatas, que os campos são um
contrato, que uma checagem noturna cobre mensagens perdidas. Essas frases moram no registro 7, e a
seta só aponta para elas.

A próxima seção trata da parte mais difícil de acertar nessas decisões: elas trocam uma qualidade
por outra, e uma troca vaga não tem como ser discutida.
