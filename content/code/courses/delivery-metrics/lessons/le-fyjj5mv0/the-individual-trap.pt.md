---
title: A armadilha de medir uma pessoa
version: 1
---

Todo time que começa a medir fluxo acaba recebendo a mesma pergunta de alguém acima dele: **"qual dos seus devs é o mais produtivo?"** Os números parecem estar ali mesmo. Cada item tem um responsável, cada commit um autor, cada revisão um revisor. Somá-los por pessoa leva minutos. É a coisa mais danosa que você pode fazer com dados de entrega, e os motivos são específicos.

## O que números por pessoa medem

Linhas de código por pessoa medem quem escreve mais linhas, o que recompensa código prolixo e pune quem apaga código. Commits por pessoa medem quem faz commit com mais frequência. Story points por pessoa medem quem estima mais alto, ou quem pega os itens com as estimativas mais generosas. Itens concluídos por pessoa medem quem pega itens pequenos. **Cada um mede um hábito do indivíduo, não uma contribuição para o time**, e cada um recompensa um hábito que piora o time.

## O que números por pessoa não conseguem ver

O trabalho que deixa um time rápido é, na maior parte, invisível no nível de uma pessoa:

- **Revisar.** Depois de 3 de agosto, os devs do time de Billing passaram a revisar antes de começar qualquer coisa nova. Essa regra é o motivo de o tempo de ciclo ter caído três quartos. Ela também baixou a contagem de itens concluídos de cada dev nas semanas que passaram revisando.
- **Desbloquear.** Quem finalmente fizer o `BIL-189` andar, convencendo outro time a fazer a mudança dele, terá feito o trabalho mais valioso do quadro naquela semana sem fechar nenhum item próprio.
- **Parear e ensinar.** Duas pessoas num item o terminam mais cedo e contam uma vez só.
- **Incidentes e plantão.** A pessoa que restaurou o serviço às duas da manhã tem um histórico de commits vazio no dia seguinte.

Um ranking por pessoa pune exatamente essas coisas, e as pessoas respondem ao que é medido, como a aula 7 mostrou. **Ranqueie os devs por itens concluídos e eles vão parar de revisar o trabalho uns dos outros**, e a fila que as aulas 2 e 3 encontraram na frente da Bia vai voltar na frente de todo mundo.

## A discussão de 2023

A pergunta voltou ao debate público em 2023, quando a consultoria McKinsey publicou um artigo argumentando que a produtividade de devs podia ser medida, inclusive no nível dos indivíduos, e propondo métricas para isso. A resposta dos profissionais foi dura; uma das mais lidas foi uma réplica em duas partes de Kent Beck e Gergely Orosz, que argumentava que medir esforço e produção por pessoa muda o comportamento de jeitos que prejudicam os resultados, e que a medição deveria se concentrar no impacto que um time entrega.

Você não precisa resolver essa discussão para agir de acordo com esta aula. O próprio artigo do SPACE alerta contra usar suas dimensões para ranquear indivíduos, e as métricas do DORA são definidas para times e sistemas. **A pesquisa em que o curso se apoia mede times.** Usá-la para medir pessoas é usá-la para algo que ela não foi feita para sustentar.

## A pergunta por trás da pergunta

Quando alguém pergunta qual dev é o mais produtivo, em geral quer saber algo legítimo: se alguém está com dificuldade, se o time tem as pessoas de que precisa, se uma promoção é merecida. Cada uma dessas perguntas tem um instrumento melhor que um ranking, e as próximas seções dizem quais são.
