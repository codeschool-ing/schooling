---
title: Monitoramento, e o ciclo que um modelo cria
version: 1
---

A auditoria da aula 18 e a correção desta aula foram feitas com os clientes de um dia, 30 de junho de
2025. **Um modelo justo hoje pode deixar de ser**, e nada nele vai anunciar a mudança.

- **Os clientes mudam.** Uma campanha no Norte, uma rota de entrega nova, um aumento de preço como o
  de setembro de 2025: cada um muda quem são os clientes e como se comportam, e o modelo foi ajustado
  aos antigos.
- **A decisão muda.** O clube não era o propósito para o qual o modelo foi construído. Os usos se
  acumulam, e cada um precisa da própria auditoria.
- **O modelo muda o dado.** Este é o **ciclo de retroalimentação** da aula 18. Clientes marcados para
  a oferta de retenção ganham um desconto, e alguns ficam por causa dele. No ano seguinte, quando o
  modelo é retreinado, esses clientes ficam registrados como "ficou", e o modelo aprende que clientes
  como eles ficam. **Ele aprende o próprio sucesso como um fato sobre os clientes**, e piora em marcar
  justamente as pessoas que antes salvava.

As defesas são trabalho de rotina, e por isso muitas vezes ficam de lado.

- **Repita a auditoria com calendário**, todo mês ou a cada retreino, com a mesma tabela, para que uma
  mudança apareça como mudança. O programa de auditoria da aula 18 tem uma dúzia de linhas; dá para
  rodar toda noite.
- **Mantenha um grupo de controle.** Uma fatia pequena e sorteada dos clientes marcados, digamos um em
  dez, não recebe oferta. Eles mostram o que os marcados pelo modelo fazem sem intervenção, o que
  mantém honesto o dado de treino, e são o grupo de controle de um teste A/B da própria oferta: a
  medida da taxa de retenção que a aula 17 chamou de número mais frágil. As aulas 7 a 11 dizem de que
  tamanho ele precisa ser e como lê-lo.
- **Vigie as entradas, não só as saídas.** Se o intervalo mediano do Norte cair de 14 dias para 7
  porque a logística abriu um depósito, o motivo da correção sumiu, e a tabela de entradas da aula 18
  mostra isso antes de qualquer taxa de erro.

Um grupo de controle tem um custo: um cliente marcado em cada dez não recebe uma oferta que talvez o
segurasse. Esse custo é o preço de saber se a oferta funciona, e deve ser decidido às claras, não
deixado de fora por ser desconfortável de escrever.
