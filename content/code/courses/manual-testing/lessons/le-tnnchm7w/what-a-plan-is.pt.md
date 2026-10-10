---
title: Para que serve um plano de teste
version: 1
---

Um plano de teste costuma ser imaginado como um documento longo que alguém escreve porque um
processo exige, e que ninguém lê depois de aprovado. Muitos planos são exatamente isso. **Para que
um plano serve é mais estreito e mais útil: ele registra as decisões sobre o teste antes de o teste
começar.** Assim elas são tomadas uma vez, de propósito, por pessoas que enxergam todas ao mesmo
tempo, e não uma de cada vez por quem estiver testando no dia.

Teste sempre tem mais trabalho possível do que tempo. Os nove requisitos da aplicação deste curso
já permitem mais casos do que alguém rodaria, e um produto real tem centenas de requisitos. Alguém
decide o que é testado e o que não é. A única pergunta é se a decisão fica escrita onde o time pode
discordar dela, ou se é tomada em silêncio por quem ficar sem tempo primeiro.

## As perguntas que um plano responde

A norma de documentação de teste, ISO/IEC/IEEE 29119-3, lista o que um plano contém, e a lista é
longa. Lida como perguntas, ela se resume a sete:

```schooling-figure
{"svg": "<svg viewBox=\"0 0 700 250\" role=\"img\" data-fig=\"l01-plan-questions\" aria-label=\"Sete caixas em volta das palavras um plano de teste. Cada caixa traz uma pergunta e a parte do plano que a responde: o quê e o que não, escopo; onde pode doer, riscos; como, abordagem; quem e com o quê, pessoas e ambiente; quando, cronograma; quando terminamos, critérios de saída; o que nos faz parar, critérios de suspensão.\"><rect x=\"280.0\" y=\"105.0\" width=\"140.0\" height=\"40.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"125.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" fill=\"var(--paper)\">um plano de teste</text><rect x=\"20.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">O quê, e o que não?</text><text x=\"120.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">escopo</text><rect x=\"20.0\" y=\"102.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Onde pode doer?</text><text x=\"120.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--amber)\">riscos</text><rect x=\"250.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Como?</text><text x=\"350.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">abordagem</text><rect x=\"480.0\" y=\"20.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"36.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Quem, e com o quê?</text><text x=\"580.0\" y=\"51.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">pessoas, ambiente</text><rect x=\"480.0\" y=\"102.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"580.0\" y=\"118.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Quando?</text><text x=\"580.0\" y=\"133.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">cronograma</text><rect x=\"20.0\" y=\"185.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"120.0\" y=\"201.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">Quando terminamos?</text><text x=\"120.0\" y=\"216.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">critérios de saída</text><rect x=\"250.0\" y=\"185.0\" width=\"200.0\" height=\"48.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"350.0\" y=\"201.9\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">O que nos faz parar?</text><text x=\"350.0\" y=\"216.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--phosphor)\">critérios de suspensão</text></svg>", "caption": "As sete perguntas dentro de um plano de teste, e o nome que cada resposta recebe. A caixa dos riscos tem outra cor porque as outras decorrem dela."}
```

**O que estamos testando, e o que não?** O escopo: que produto, que versão, que funcionalidades, e
as funcionalidades deixadas de fora de propósito. Uma funcionalidade fora do escopo é uma decisão;
uma funcionalidade que ninguém citou é uma lacuna.

**Onde pode doer mais?** Os riscos, ordenados, porque eles decidem para onde vai o esforço. A maior
parte das outras respostas do plano decorre desta, e por isso a seção 06 desta aula trata dela.

**Como vamos testar?** A abordagem: que níveis e tipos de teste, que técnicas, quanto é manual e
quanto é automatizado.

**Quem, e com o quê?** As pessoas, seus papéis e as habilidades de que precisam, e o ambiente:
máquinas, navegadores, dispositivos, dados, contas.

**Quando?** O cronograma, amarrado às datas do próprio projeto e não a um calendário só dele.

**Como sabemos que terminamos?** Os critérios de saída, escritos antes do primeiro caso rodar,
porque depois "terminado" vira "sem tempo".

**O que nos faz parar?** Os critérios de suspensão: as condições em que o teste pausa porque
continuar seria esforço perdido, como uma versão que não inicia.

## Qual o tamanho de um plano

Um plano para uma mudança de duas semanas numa aplicação web pequena cabe numa página, e a seção 07
desta aula escreve um para o boxoffice. Um plano para o novo sistema central de um banco tem dezenas
de páginas e se divide em dois: um **plano mestre** para o projeto inteiro e um **plano de nível**
para cada nível de teste, sistema ou aceitação, que herda do mestre. Um time ágil muitas vezes não
mantém documento separado nenhum: as mesmas decisões ficam na definição de pronto do time, nos
critérios de aceitação de cada história e numa página da wiki.

O formato é a parte barata. O que faz um plano valer o tempo é que **toda resposta nele pode ser
contestada**. "Vamos testar a fundo" não admite discussão e por isso não decide nada. "Não vamos
testar no Safari nesta versão, porque 3% das visitas do mês passado usaram ele e a versão não muda
nenhum layout" admite discussão, e é isso que a torna útil. A dona do produto que sabe que o maior
patrocinador do teatro usa iPhone agora tem algo a que objetar, antes da versão e não depois dela.

## Um plano não é uma agenda de casos

Um plano diz como o teste vai ser decidido. Ele não lista os casos em si: esses são os **casos de
teste**, escritos numa forma própria, e a aula 2 trata deles. Um plano que tenta listar todos os
casos fica desatualizado no segundo dia, porque os casos mudam toda vez que um requisito muda, e as
decisões acima deles mudam muito menos.

A outra confusão é com a **estratégia de teste**. Numa empresa que testa muitos produtos, a
estratégia é a resposta permanente da organização à pergunta "como": os níveis, as ferramentas, os
tipos de relatório. O plano de cada projeto a cita em vez de repeti-la. Um plano sem estratégia
acima dele simplesmente responde ao "como" por conta própria, que é o caso do boxoffice.
