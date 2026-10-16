---
title: O SAFe, e o que muda quando são muitos times
version: 1
---

**Scrum, Kanban e XP descrevem um time. O Scaled Agile Framework, SAFe, descreve como dezenas de times trabalham
juntos num produto.** Dean Leffingwell o publicou em 2011, e hoje é o mais adotado dos frameworks de escala,
sobretudo em bancos, seguradoras e governos. É grande, detalhado e tem críticos; quem testa numa organização grande
tem boa chance de encontrá-lo de qualquer jeito.

O Cine Aurora tem cinco pessoas e não precisa de nada disso. Para ver o que o SAFe muda, imagine o Aurora comprado
por uma rede nacional que vende ingressos para duzentos cinemas, com nove times trabalhando num sistema de venda
só: um para preços, um para assentos, um para o site, um para os terminais da bilheteria, e assim por diante.

## O trem

A estrutura central do SAFe é o **Agile Release Train**, um grupo duradouro de times ágeis, em geral de 50 a 125
pessoas, que planejam, constroem e entregam juntos numa agenda compartilhada.

O trem trabalha em **Planning Intervals**, chamados Program Increments até 2023: em geral de 8 a 12 semanas, feitos
de várias iterações de duas semanas seguidas de uma **iteração de inovação e planejamento**. Todos os times planejam
o intervalo juntos no começo, num evento grande chamado PI Planning, e o trem inteiro mostra seu trabalho integrado
num **System Demo** a cada iteração.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 680 260\" role=\"img\" data-fig=\"l14-train\" aria-label=\"Em cima, um Agile Release Train de cinco times, preços, assentos, site, bilheteria e relatórios, com um System Team embaixo deles que cuida do ambiente compartilhado e das verificações de ponta a ponta. Embaixo, um Planning Interval de oito a doze semanas: PI Planning no começo, quatro iterações terminando cada uma num System Demo, e uma iteração de inovação e planejamento no fim.\"><rect x=\"10.0\" y=\"10.0\" width=\"660.0\" height=\"112.0\" rx=\"8\" fill=\"var(--ink)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><text x=\"24.0\" y=\"26.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--phosphor)\">um Agile Release Train: de 50 a 125 pessoas</text><rect x=\"24.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"83.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">preços</text><rect x=\"152.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"211.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">assentos</text><rect x=\"280.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">site</text><rect x=\"408.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"467.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">bilheteria</text><rect x=\"536.0\" y=\"40.0\" width=\"118.0\" height=\"32.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"595.0\" y=\"56.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper)\">relatórios</text><rect x=\"24.0\" y=\"80.0\" width=\"630.0\" height=\"30.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.2\"></rect><text x=\"339.0\" y=\"95.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-weight=\"600\" fill=\"var(--amber)\">System Team: ambiente compartilhado, verificações de ponta a ponta</text><text x=\"340.0\" y=\"144.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">um Planning Interval, de 8 a 12 semanas</text><rect x=\"10.0\" y=\"160.0\" width=\"86.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"53.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" font-weight=\"600\" fill=\"var(--paper)\">PI Planning</text><rect x=\"104.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"156.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteração 1</text><circle cx=\"208.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"216.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"268.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteração 2</text><circle cx=\"320.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"328.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"380.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteração 3</text><circle cx=\"432.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"440.0\" y=\"160.0\" width=\"104.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\"></rect><text x=\"492.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--paper)\">iteração 4</text><circle cx=\"544.0\" cy=\"214.0\" r=\"4\" fill=\"var(--amber)\"></circle><rect x=\"552.0\" y=\"160.0\" width=\"118.0\" height=\"40.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--wire)\" stroke-width=\"1.2\" stroke-dasharray=\"3 2\"></rect><text x=\"611.0\" y=\"180.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"8.5\" fill=\"var(--paper)\">inovação e planejamento</text><text x=\"330.0\" y=\"234.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9\" fill=\"var(--amber)\">● System Demo</text></svg>", "caption": "Muitos times, uma agenda só. O System Demo mostra o produto integrado a cada iteração, e não o pedaço de cada time.", "same": ["PI Planning", "● System Demo"]}
```

## O que muda para o teste

Com nove times, cada um pode ser perfeitamente ágil por dentro e o produto ainda assim estar quebrado, porque quase
tudo o que dá errado dá errado *entre* times. O time de preços muda como um desconto é guardado; os terminais do
time da bilheteria leem o formato antigo. As verificações dos dois times passam.

Então o SAFe acrescenta teste que nenhum time sozinho possui:

- **um System Team**, que monta e mantém o ambiente compartilhado onde o trabalho de todos os times é integrado, e
  as verificações de ponta a ponta que cruzam as fronteiras entre times;
- **o System Demo**, onde o produto integrado, e não o pedaço de cada time, é mostrado funcionando a cada iteração;
- **a qualidade embutida**, que o SAFe nomeia como um dos seus fundamentos: espera-se que todo time pratique o que
  a aula 11 e o XP descrevem, para o trem não depender do System Team para achar problemas tarde.

## A armadilha em escala

A iteração de inovação e planejamento tem um mau uso conhecido. Times sob pressão a tratam como uma **sprint de
estabilização**: duas semanas no fim de todo intervalo para testar e corrigir tudo o que não ficou terminado. As
próprias orientações do SAFe advertem contra isso, e pelo motivo que este curso repete desde a aula 3: é a fase de
teste da cascata, de volta, com a mesma curva de custo.

Para quem testa, os sinais são reconhecíveis desde a aula 11. Se o System Demo mostra trabalho que nunca foi
integrado antes da demonstração, se defeitos achados num intervalo são planejados para o próximo, se "pronto" para
um time quer dizer "pronto, menos a integração", então o trem reconstruiu a minicascata numa escala maior.

## O que quem testa faz de fato no SAFe

A maior parte do trabalho é a mesma de qualquer time ágil: perguntas no planejamento, exemplos para os critérios de
aceitação, exploração, manter a definição de pronto honesta. O que é novo é a visão entre times. Quem testa e
pergunta no PI Planning *que outro time lê os dados que estamos mudando?* está fazendo em escala o que a Lia faz no
planejamento do Cine Aurora quando pergunta como uma história se combina com as que já foram construídas.
