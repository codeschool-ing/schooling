---
title: Usar como está, ou mudar
version: 1
---

Um modelo pré-treinado faz um trabalho geral. A sua tarefa é particular: cinco rótulos que
significam alguma coisa na Lantern Books, um formato de pedido que ninguém mais usa, um tom que a
loja quer nas respostas. Há quatro formas de fechar a distância entre os dois, e o erro comum é
começar pela mais cara porque ela soa mais séria.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 296\" role=\"img\" aria-label=\"Quatro formas de fazer um modelo pré-treinado cumprir a sua tarefa, da mais barata à mais cara: escrever um prompt melhor, acrescentar exemplos resolvidos, recuperar os seus próprios documentos para dentro do prompt, fazer fine-tuning dos pesos. Cada degrau custa mais para construir e manter, e cada um corrige uma lacuna diferente.\"><defs><marker id=\"l1lad-ah\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"30\" y=\"190\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"105\" y=\"206\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">1. o prompt</text><text x=\"105\" y=\"223\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">diga a tarefa com clareza</text><text x=\"105\" y=\"239\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">minutos</text><text x=\"105\" y=\"266\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">corrige: tarefa vaga</text><rect x=\"200\" y=\"145\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"275\" y=\"161\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">2. exemplos</text><text x=\"275\" y=\"178\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mostre casos no prompt</text><text x=\"275\" y=\"194\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">horas</text><text x=\"275\" y=\"221\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">corrige: formato vago</text><rect x=\"370\" y=\"100\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"445\" y=\"116\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">3. recuperação</text><text x=\"445\" y=\"133\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">busque os seus fatos</text><text x=\"445\" y=\"149\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">dias</text><text x=\"445\" y=\"176\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">corrige: fatos ausentes</text><rect x=\"540\" y=\"55\" width=\"150\" height=\"62\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"615\" y=\"71\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" font-weight=\"600\" fill=\"var(--paper)\">4. fine-tuning</text><text x=\"615\" y=\"88\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">mude os pesos</text><text x=\"615\" y=\"104\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">semanas</text><text x=\"615\" y=\"131\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper-dim)\">corrige: comportamento</text><line x1=\"40\" y1=\"286\" x2=\"690\" y2=\"286\" stroke=\"var(--wire)\" stroke-width=\"1.2\" marker-end=\"url(#l1lad-ah)\"></line><text x=\"690\" y=\"274\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">custo de construir e manter</text></svg>", "caption": "Suba só até a lacuna que você mediu. Cada degrau custa mais para construir e para manter.", "same": ["4. fine-tuning"]}
```

**1. O prompt.** Diga a tarefa com clareza, dê os rótulos, diga com o que responder. O
`prompts/triage.txt` da ana tem três linhas e faz exatamente isso. Custa minutos, muda no instante
em que você edita um arquivo e corrige a lacuna mais comum que existe: o modelo não sabia o que você
queria.

**2. Exemplos no prompt.** Quando o modelo entende a tarefa mas erra o formato ou os casos de
fronteira, mostre alguns: um e-mail, o rótulo certo, outro e-mail, o rótulo dele. O curso
`prompt-engineering` trata de quantos e quais. Custa horas escolhendo bons exemplos e alguns tokens
em cada requisição, porque os exemplos vão junto toda vez.

**3. Recuperação.** Quando o que falta é um fato, a lacuna da seção 10, busque o texto relevante e
coloque no prompt: o status do pedido, a política de reembolso, o número de páginas do livro. Isso
é um sistema para construir e manter funcionando, por isso se mede em dias, e é o único dos quatro
que acompanha fatos que mudam.

**4. Fine-tuning.** Treinar os pesos mais um pouco com os seus próprios exemplos, para que o
comportamento fique no modelo e não no prompt. É a ferramenta certa para um comportamento que
dezenas de exemplos não conseguem ensinar, ou para uma tarefa de alto volume em que um modelo
pequeno ajustado pode substituir um grande e geral. É a ferramenta errada para fatos: um modelo
ajustado com o estoque do mês passado não sabe o deste mês, e treiná-lo de novo é o jeito caro de
descobrir que a resposta era recuperação.

## Por que a ordem importa

Cada degrau **custa mais para construir e mais para manter**. Um prompt é um arquivo de texto. Um
modelo com fine-tuning é um conjunto de dados, um treino, uma avaliação, uma decisão de hospedagem
e um plano para ajustar de novo quando o modelo base de onde ele partiu for aposentado, o que a
aula 2 mostra acontecer no calendário do provedor, não no seu.

E cada degrau **corrige uma lacuna diferente**. Fine-tuning não fornece um fato que os exemplos de
treino não continham, e recuperação não ensina um formato. Então a ordem não é só "o mais barato
primeiro". É: **meça o que está errado, depois suba o menor degrau que corrige isso.** A aula 5 é a
medição.

Para a ana, o plano que sai disso é curto. As tarefas dela não precisam de fatos públicos recentes
nem de fatos privados além do próprio e-mail, então recuperação ainda não está no caminho. Ela
começa no degrau 1 com todos os candidatos, sobe para o 2 com qualquer modelo que erre o formato,
e trata fine-tuning como uma pergunta a fazer só se nenhum modelo pronto, com um bom prompt, passar
nos casos dela.
