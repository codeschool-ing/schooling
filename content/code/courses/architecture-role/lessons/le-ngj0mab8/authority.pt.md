---
title: De onde vem a autoridade
version: 1
---

Na segunda-feira em que Tomás anuncia o papel, Renata ganha um cargo. É tentador achar que a
autoridade dela agora vem do cargo: ela é a arquiteta, então as decisões estruturais são dela. **Um
cargo dá a um arquiteto o direito de decidir; não faz ninguém seguir a decisão.** A autoridade que
faz as decisões pegarem vem quase toda de outro lugar, e um arquiteto que se apoia só no cargo
descobre isso depressa.

## Dois tipos de autoridade

**A autoridade formal** vem da organização. É o cargo, o anúncio do CTO, uma linha num documento que
diz quem decide o quê. Ela é concedida, pode ser retirada, e é a mesma no primeiro dia e no último.

**A autoridade conquistada** vem das pessoas que trabalham com o arquiteto. Ela se constrói com um
histórico de decisões que deram certo, com explicações que fizeram sentido, com a admissão das que
não deram, e com as relações com os times. Ninguém a concede. Ela cresce devagar, varia de um time
para outro e pode ser gasta.

Renata começa com uma mistura incomum das duas. A autoridade formal dela é nova e não foi testada. A
conquistada é grande em alguns lugares: ela escreveu boa parte do código original de Payments, e o
time de Bruno confia no julgamento dela sobre ele. Em outros, é quase nenhuma. O app Driver é uma
base de código móvel em que ela nunca trabalhou, e o time de Diego Araújo só a conhece como a pessoa
que uma vez quebrou o build deles com uma mudança numa API compartilhada.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 360\" role=\"img\" aria-label=\"Uma grade dois por dois. Eixo horizontal: autoridade conquistada, de baixa a alta. Eixo vertical: autoridade formal, de baixa a alta. Formal baixa e conquistada baixa: uma engenheira com opiniões. Formal alta e conquistada baixa: obedecida no papel e contornada na prática. Formal baixa e conquistada alta: influência sem mandato, onde Renata estava antes do cargo. As duas altas: decisões que ficam, com o cargo raramente usado, onde Renata está com o time de Payments. Com o time do Driver ela tem o cargo e pouca confiança.\"><defs><marker id=\"auth-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><path d=\"M130 300 L690 300\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#auth-ah)\"></path><path d=\"M120 290 L120 24\" fill=\"none\" stroke=\"var(--paper-dim)\" stroke-width=\"1.5\" marker-end=\"url(#auth-ah)\"></path><text x=\"400\" y=\"322\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">autoridade conquistada: histórico, explicações, relações</text><text x=\"64\" y=\"145.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">autoridade</text><text x=\"64\" y=\"160.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">formal:</text><text x=\"64\" y=\"175.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper-dim)\">o cargo</text><rect x=\"130\" y=\"168\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">uma engenheira</text><text x=\"265.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">com opiniões</text><rect x=\"130\" y=\"30\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.5\"></rect><text x=\"265.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">obedecida no papel,</text><text x=\"265.0\" y=\"75.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">contornada na prática</text><rect x=\"410\" y=\"168\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"198.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">influência</text><text x=\"545.0\" y=\"213.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">sem mandato</text><rect x=\"410\" y=\"30\" width=\"270\" height=\"122\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.5\"></rect><text x=\"545.0\" y=\"60.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">decisões que ficam;</text><text x=\"545.0\" y=\"75.5\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">o cargo quase não é usado</text><circle cx=\"610\" cy=\"122\" r=\"6\" fill=\"var(--phosphor)\"></circle><text x=\"600\" y=\"122\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">Renata, com Payments</text><circle cx=\"190\" cy=\"122\" r=\"6\" fill=\"var(--amber)\"></circle><text x=\"202\" y=\"122\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--amber)\">Renata, com o Driver</text><circle cx=\"610\" cy=\"260\" r=\"6\" fill=\"var(--paper-dim)\"></circle><text x=\"600\" y=\"260\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--paper-dim)\">Renata, antes do cargo</text></svg>", "caption": "O cargo leva a arquiteta para cima; só os times a levam para a direita. Renata começa em dois quadrados ao mesmo tempo, conforme o time com quem está falando."}
```

## O que acontece quando só existe uma

**Só a autoridade formal produz obediência e contornos.** Um time mandado fazer algo por alguém em
quem não confia faz ao pé da letra: o desenho segue a instrução, e os problemas que ela causa não
são relatados, porque relatá-los só traria outra instrução. Pior: os times param de contar as coisas
ao arquiteto cedo. Um arquiteto que é evitado fica sabendo das decisões depois que elas foram
tomadas.

**Só a autoridade conquistada produz influência sem mandato.** Era Renata antes do cargo. Os times
pediam o conselho dela e em geral o seguiam, mas quando dois times discordavam sobre uma costura,
ninguém conseguia resolver, e os incidentes entre times da seção anterior aconteceram exatamente
nessa lacuna.

O que faz o papel funcionar é a combinação: **autoridade formal suficiente para resolver o que
precisa ser resolvido, e autoridade conquistada suficiente para que ela quase nunca precise ser
usada.** O cargo funciona melhor como reserva. Cada vez que ele é usado para passar por cima de um
time que discorda, gasta-se um pouco da autoridade conquistada, e ela precisa ser reconstruída.

## Como a autoridade conquistada se constrói

Não há atalho, mas há hábitos que a constroem com segurança e hábitos que a destroem com a mesma
segurança.

Ela se constrói:

- **mostrando o raciocínio, não só a conclusão.** Um time que enxerga por que uma decisão foi tomada
  consegue discutir com ela, e uma decisão que sobreviveu a uma discussão merece mais confiança;
- **acertando de jeitos que as pessoas conseguem conferir.** O primeiro ato útil de Renata como
  arquiteta foi a lista das cinco conexões escondidas com o banco do monólito, na aula 2: qualquer
  um podia verificá-la, e ela explicava um incidente sobre o qual dois times discutiam havia meses;
- **dizendo "eu errei" quando é verdade**, depressa e sem discurso;
- **deixando os times mais rápidos.** Um arquiteto cujo envolvimento atrasa um time paga isso em
  confiança, mesmo quando o envolvimento estava certo.

Ela se destrói decidindo coisas que o arquiteto não entende, mudando de posição sem explicar por quê
e aparecendo só para dizer não.

## O processo de conselho

A conversa de quinta-feira com Kátia foi uma escolha entre dois jeitos de trabalhar. Renata podia
decidir se o Matching ganha banco próprio, e o cargo permitia. Ou podia garantir que a decisão fosse
bem tomada pela pessoa mais próxima dela. Ela escolheu a segunda, usando uma prática descrita por
Andrew Harmel-Law no artigo de 2021 "Scaling the Practice of Architecture, Conversationally".

**O processo de conselho** (advice process) tem uma regra: **qualquer pessoa pode tomar uma decisão
arquitetural, desde que antes de decidir busque o conselho de todos que serão afetados de forma
significativa por ela e de pessoas com experiência no assunto.** Quem decide precisa perguntar e
precisa ouvir. Não é obrigado a seguir os conselhos que recebe. Harmel-Law junta à regra alguns
apoios: as decisões são registradas, um fórum aberto se reúne com regularidade para discutir as
decisões em andamento, e a principal contribuição dos arquitetos passa a ser dar bons conselhos e
manter o processo saudável, não ter poder de veto.

Na Carreto, para o banco do Matching, funciona assim:

1. **Kátia decide**, porque o Matching é o time que vai viver com o resultado.
2. **Ela pergunta a quem é afetado**: Bruno, porque o Payments lê dados que o Matching escreve; o
   time Shipper, que lê a mesma tabela `loads`; e Paula Reis, de Platform, que vai operar o banco
   novo.
3. **Ela pergunta a quem tem experiência**: Renata, que conhece a história da tabela compartilhada,
   e Paula de novo, sobre quanto custa operar um banco novo.
4. **Ela registra a decisão**, com os conselhos que recebeu — inclusive os que não seguiu, e por
   quê.

O conselho de Renata é separar os dados em dois passos em vez de um, e o de Bruno é esperar até o
Payments parar de ler `loads` diretamente. Kátia segue o conselho de Renata e não o de Bruno, e
registra por quê: o primeiro passo não mexe em nada do que o Payments lê.

## Por que um arquiteto escolheria abrir mão da decisão

À primeira vista, o processo de conselho deixa o arquiteto menos poderoso. Na prática ele faz três
coisas que um arquiteto central não consegue. **Ele escala**: cinquenta engenheiros decidem em
paralelo em vez de fazer fila atrás de uma pessoa. **Ele põe as decisões onde está o conhecimento**:
Kátia conhece o código do Matching muito melhor do que Renata. E **ele constrói a autoridade
conquistada de que o papel depende**, porque um conselho que deu certo é lembrado, e ninguém se
ressente de um conselho que era livre para recusar.

Não é um jeito de abolir o papel, e ele tem limites. Depende de as pessoas buscarem mesmo o conselho
de quem é afetado, e um arquiteto precisa perceber quando isso não acontece. Não resolve o caso de
dois times que decidem coisas incompatíveis sobre a mesma costura. E não diz quem responde por uma
decisão que dá errado — que é onde começa a próxima seção.
