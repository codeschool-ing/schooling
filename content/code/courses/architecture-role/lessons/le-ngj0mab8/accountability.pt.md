---
title: Responder por uma decisão
version: 1
---

*Responsável* é uma daquelas palavras usadas para duas coisas diferentes. **Uns ouvem "a pessoa que
leva a culpa"; outros, "a pessoa que tem de fazer o trabalho".** Não é nenhuma das duas. Responder
por uma decisão é ser a pessoa que presta contas dela: que explica o que foi decidido e por quê, que
assume o que vem depois quando ela dá errado, e que garante que a lição mude alguma coisa. É o
terceiro verbo do papel, e o que dá peso aos outros dois.

## Quem executa e quem responde

A distinção é antiga o bastante para ter uma sigla conhecida. Numa matriz **RACI**, cada tarefa diz
quem é *Responsible* (executa o trabalho), quem é *Accountable* (responde pelo resultado), quem é
*Consulted* (consultado antes) e quem é *Informed* (informado depois). Várias pessoas podem
executar; **exatamente uma deve responder**, porque um resultado pelo qual duas pessoas respondem é
um resultado pelo qual ninguém responde.

O processo de conselho da seção anterior se encaixa bem nesse vocabulário. Quem decide responde pela
decisão. Quem deu conselho foi consultado, e responde pela qualidade do conselho — uma obrigação
real, mas diferente. Quando Kátia decidiu como os dados do Matching seriam separados, ela passou a
responder por isso, e Renata passou a responder pelo conselho que deu.

## Direitos de decisão

A prestação de contas só funciona quando todos sabem **quem tem o direito de decidir o quê**. Isso
se chama *direitos de decisão*, e a maioria das empresas só os tem de forma implícita: eles vivem em
hábitos e memórias, e são descobertos quando duas pessoas acreditam que uma decisão era sua.

O incidente entre times que levou Tomás a criar o papel foi exatamente isso. O Matching achava que o
jeito de guardar o status de uma carga era dele para mudar, e o Payments achava o mesmo. Os dois
tinham alguma razão, e nada escrito em lugar nenhum dizia o contrário. **Um direito de decisão que
não está escrito é resolvido por quem se mexe primeiro.** A página de Renata na primeira sexta-feira
propôs donos para nove perguntas em aberto, e essa foi uma primeira lista, pequena, de direitos de
decisão. A aula 16 monta a versão completa para a Carreto, decidindo que decisões pertencem ao
arquiteto, quais aos tech leads e quais aos times.

## Um espectro de jeitos de decidir

Entre "a arquiteta decide" e "o time decide" há várias posições, e um arquiteto escolhe entre elas
cada vez que surge uma decisão. A ideia de um contínuo de estilos de decisão é mais antiga que o
software: Robert Tannenbaum e Warren Schmidt desenharam um para gestores na *Harvard Business
Review* em 1958. Para decisões arquiteturais, cinco posições bastam:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" aria-label=\"Cinco caixas da esquerda para a direita. Um: a arquiteta decide sozinha, por exemplo um incidente às três da manhã. Dois: a arquiteta decide depois de consultar, por exemplo um padrão para todos os serviços. Três: arquiteta e times decidem juntos, por exemplo quem é dono da tabela loads. Quatro: o time decide depois de buscar conselho, por exemplo o banco próprio do Matching. Cinco: o time decide e informa, por exemplo uma biblioteca dentro de um serviço. Para a esquerda, mais rapidez e controle numa decisão; para a direita, mais apropriação e escala para muitas decisões.\"><defs><marker id=\"spec-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"10\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"75.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">1</text><text x=\"75.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a arquiteta</text><text x=\"75.0\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decide sozinha</text><rect x=\"10\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"75.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um incidente às</text><text x=\"75.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">três da manhã</text><rect x=\"150\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"215.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">2</text><text x=\"215.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">a arquiteta</text><text x=\"215.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">decide depois</text><text x=\"215.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">de consultar</text><rect x=\"150\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"215.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">um padrão que todo</text><text x=\"215.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">serviço segue</text><rect x=\"290\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"355.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">3</text><text x=\"355.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">arquiteta e</text><text x=\"355.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">times decidem</text><text x=\"355.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">juntos</text><rect x=\"290\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"355.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">quem é dono da</text><text x=\"355.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">tabela loads</text><rect x=\"430\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"495.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">4</text><text x=\"495.0\" y=\"89.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o time decide</text><text x=\"495.0\" y=\"104.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">depois de buscar</text><text x=\"495.0\" y=\"119.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">conselho</text><rect x=\"430\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"495.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">o banco próprio</text><text x=\"495.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">do Matching</text><rect x=\"570\" y=\"40\" width=\"130\" height=\"110\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"635.0\" y=\"58\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"13\" font-weight=\"600\" fill=\"var(--phosphor)\">5</text><text x=\"635.0\" y=\"96.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">o time decide</text><text x=\"635.0\" y=\"111.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">e informa</text><rect x=\"570\" y=\"170\" width=\"130\" height=\"64\" rx=\"4\" fill=\"none\" stroke=\"var(--wire)\" stroke-width=\"1.5\" stroke-dasharray=\"4 3\"></rect><text x=\"635.0\" y=\"195.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">uma biblioteca</text><text x=\"635.0\" y=\"209.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">dentro de um serviço</text><text x=\"10\" y=\"22\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">quem decide, da arquiteta ao time</text><path d=\"M360 262 L40 262\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#spec-ah)\"></path><path d=\"M360 262 L680 262\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#spec-ah)\"></path><text x=\"20\" y=\"285.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mais rápido, mais controle,</text><text x=\"20\" y=\"299.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">numa decisão</text><text x=\"700\" y=\"285.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">mais apropriação,</text><text x=\"700\" y=\"299.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper)\">escala para muitas decisões</text></svg>", "caption": "Cinco jeitos de decidir, da arquiteta sozinha ao time sozinho. Duas estão em destaque: o retry do Pix desta aula foi decidido no 1 e cabia no 4, onde se decidiu o banco do Matching."}
```

Nenhuma posição é certa em geral. **A escolha depende de como é a decisão**, e quatro perguntas
resolvem a maior parte dos casos:

| pergunta | empurra para a arquiteta decidir | empurra para o time decidir |
|---|---|---|
| quanto custa desfazer? | muito, ou envolve dinheiro ou regulação | pouco; uma porta de mão dupla |
| quantos times ela afeta? | vários, com interesses em conflito | um |
| quão urgente é? | um incidente, em que alguém precisa decidir já | há tempo para perguntar |
| onde está o conhecimento? | espalhado entre times, ou com a arquiteta | dentro do time |

O banco do Matching ficou na quarta posição: caro de desfazer, mas o conhecimento estava no time, e
havia tempo para perguntar. Um incidente às três da manhã fica na primeira: alguém precisa decidir,
e uma reunião é a ferramenta errada. A maior parte das decisões dentro de um time fica na quinta, e
um arquiteto que as puxa para a esquerda virou o aprovador de tudo do começo desta aula.

## Quando dá errado

Na terceira semana de Renata, como a aula 2 contou, Bruno trouxe o plano de pagar os motoristas por
Pix. Sobre o que fazer quando a API do banco demora a responder, ele pediu uma conversa rápida.
Renata respondeu sozinha, em dez minutos, na primeira posição do espectro: tentar de novo até três
vezes. Ela sabia que a API do banco tinha um identificador para cada pagamento e supôs que o banco
recusaria um segundo pedido com o mesmo identificador. Ninguém conferiu. A API do banco só recusa
duplicatas quando o pedido leva uma chave de idempotência separada, e os pedidos da Carreto não a
enviavam.

Na primeira semana de pagamentos reais, o banco ficou lento numa sexta à tarde. Dois motoristas
receberam duas vezes: um pagamento de R$ 2.850 e um de R$ 4.100, R$ 6.950 no total. Ícaro Nunes, o
desenvolvedor júnior de Payments, tinha escrito o código de retry exatamente como foi especificado.

O que Renata fez em seguida é o que responder por uma decisão significa:

1. **Ela disse que a decisão era dela, primeiro e em público.** Na revisão do incidente ela disse
   que tinha tomado a decisão sozinha, depressa, com base numa suposição que não conferiu. Não
   esperou ser perguntada, e não deixou a revisão escorregar para o código que Ícaro escreveu, que
   fazia o que lhe mandaram.
2. **Ela explicou o raciocínio da época.** O que sabia, o que supôs e por que a suposição parecia
   segura. É isso que torna um relato útil e não só arrependido: a próxima pessoa enxerga onde o
   raciocínio quebrou.
3. **Ela garantiu que o estrago fosse tratado.** A correção — mandar uma chave de idempotência em
   cada pedido — entrou no ar na segunda-feira seguinte. O time de Sílvio Matos procurou os dois
   motoristas para recuperar os pagamentos em duplicidade.
4. **Ela mudou o processo, não só o código.** Decisões que movem dinheiro agora passam pelo processo
   de conselho, por menores que pareçam, e a pergunta "o que acontece se este pedido for enviado
   duas vezes?" é feita a todo desenho que conversa com o banco.

Duas coisas merecem atenção. **Responder por uma decisão não é o mesmo que ter culpa por tudo em
volta dela**: a documentação do banco era confusa, e a revisão registrou isso também. E o erro não
foi tanto a política de retry quanto a posição no espectro. Uma decisão que envolve dinheiro e um
sistema externo cabia na quarta posição, e tomá-la na primeira, para economizar uma reunião, foi o
que tirou da conversa as pessoas que teriam perguntado pela chave. A revisão do incidente seguiu o
formato sem culpados que a aula 15 de `architect-communication` ensina a fundo.

## Autoridade e responsabilidade andam juntas

A seção anterior terminou com uma lacuna: o processo de conselho diz quem decide, mas não quem
responde. A resposta desta seção é que **quem decide responde**, e as duas coisas não devem ser
separadas. **Responder sem autoridade é uma armadilha**: um arquiteto culpado por decisões que não
tinha o direito de tomar aprende a fugir do papel. **Autoridade sem responder é pior**: um arquiteto
que decide e nunca presta contas do resultado para de aprender com ele, e os times deixam, em
silêncio, de confiar nas decisões.

A autoridade conquistada de Renata não caiu depois dos pagamentos em dobro. Com o time de Bruno ela
subiu, porque quem viu como ela lidou com o caso eram as pessoas que esperavam que ela culpasse o
desenvolvedor júnior. É mais uma diferença entre os dois tipos de autoridade da seção anterior: o
cargo não cresce quando alguém admite um erro, e a confiança muitas vezes cresce.
