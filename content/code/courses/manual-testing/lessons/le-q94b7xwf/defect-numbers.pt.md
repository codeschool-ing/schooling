---
title: Números de defeito que dizem algo
version: 1
---

Quando os relatos moram numa ferramenta, contá-los sai de graça, e alguém vai contar. O primeiro
número que todo mundo pega é a contagem: quantos defeitos foram achados, quantos estão abertos,
quantos cada testador registrou. **Uma contagem de relatos mede o relatar, não o produto**, e no
momento em que ela é usada para julgar pessoas, o relatar muda para agradá-la. Os números que valem
ser mantidos são os que respondem a uma pergunta que o time de fato tem, e que ninguém consegue
melhorar sem melhorar o trabalho.

## Três que merecem o lugar

**Idade dos defeitos abertos, por severidade.** Há quanto tempo cada relato aberto espera desde que
foi registrado? Lida por severidade, responde *estamos deixando coisas sérias por fazer?* Um defeito
crítico aberto há dois dias é um time trabalhando; um aberto há dois meses é uma decisão que
ninguém tomou. No boxoffice, o relato aberto mais antigo é o traceback, encontrado pela aula 4 na
versão 1.0 e ainda aberto na 1.1 com P2. A idade dele diz algo que a prioridade sozinha não diz:
ele perdeu em toda triagem até agora, e em algum momento um relato que sempre perde deve ou ganhar
uma vez ou ser adiado de propósito.

**Taxa de reabertura.** Dos defeitos marcados como corrigidos, quantos voltaram do reteste? Ela
responde *nossas correções se sustentam?* Uma taxa alta quer dizer correções que saem sem teste, ou
relatos tão pouco claros que o desenvolvedor corrige outra coisa, e ler os relatos reabertos separa
as duas causas. É uma razão, então precisa de período e de denominador: *6 dos 40
corrigidos no último trimestre voltaram, 15%*. O boxoffice tem duas correções até agora, a regra dos
seis ingressos e o desconto de membro, e nenhuma foi reaberta. Isso dá 0%, e dois é pouco demais
para significar alguma coisa; o relato honesto disso diz *duas correções, nenhuma reaberta* e não
tira conclusão.

**Defeitos que escaparam.** Dos defeitos achados num período, quantos foram achados por clientes
depois da versão sair, e não pelo time antes? Responde *o que nosso teste está deixando passar?*, e
a parte útil não é o número, é a lista: cada defeito que escapou é uma pergunta sobre por que
nenhum caso, sessão ou verificação chegou nele. Um defeito que o gerente do teatro acha na sessão de
aceitação da aula 12 não escapou. Um que um cliente acha na porta na noite de estreia escapou.

Os três têm uma propriedade em comum: **o único jeito de o número parecer melhor é fazer o trabalho
melhor.** Não dá para baixar a idade de um defeito crítico sem corrigi-lo ou adiá-lo de propósito,
e as duas coisas ficam visíveis.

## Teatro

Alguns números parecem gestão e premiam o trabalho errado. Vale reconhecê-los, porque muitas vezes
já estão num painel quando você chega.

**Defeitos achados por testador.** Premia dividir um defeito em vários relatos, que é exatamente o
que a seção 04 desta aula passou o tempo desfazendo: *payed* e *useed* registrados em separado
contam dois. Pune quem passa uma manhã tornando um relato reproduzível, e quem testa a parte estável
do produto, onde defeitos são raros e o risco é alto. E ainda põe testadores uns contra os outros
sem ninguém perceber, já que um defeito que um relata é um que o outro não pode relatar.

**Total de defeitos abertos, sem severidade.** Trinta defeitos triviais de texto e um defeito
crítico de reembolso dão trinta e um, e trinta e um críticos também. Um gráfico do total caindo
pode querer dizer que o time corrigiu o crítico, ou que fechou trinta erros de grafia e deixou o
reembolso de lado.

**Meta de zero defeitos abertos na versão.** Soa como qualidade. Na prática produz defeitos
rejeitados que deviam ter sido adiados, adiados que deviam ter sido corrigidos e, o pior, não
registrados, por testadores que aprenderam o que um relato novo faz com o gráfico. A lista de
adiados da triagem da seção 03 existe porque alguns defeitos não valem ser corrigidos agora; uma
meta de zero faz essa decisão honesta parecer fracasso.

**Defeitos por desenvolvedor.** Diz aos desenvolvedores que um relato é uma acusação, e a aula 15
já disse o que acontece com um relato lido assim: ele é discutido em vez de resolvido.

## Um número é uma pergunta

A regra por baixo é antiga e tem nome, a lei de Goodhart: quando uma medida vira meta, deixa de ser
uma boa medida. **Antes de relatar um número, escreva a pergunta que ele responde e o que você faria
de diferente se ele subisse.** *A taxa de reabertura foi de 5% para 20% neste trimestre, então vamos
ler cada relato reaberto e procurar a causa comum* é um número fazendo o seu trabalho. *Achamos 212
defeitos* é um número procurando uma pergunta, e a aula 19 trata do que pôr diante das pessoas que
leem esses relatos no lugar disso.
