---
title: Os níveis A, AA e AAA
version: 1
---

**Todo critério de sucesso tem um nível, A, AA ou AAA, e uma página está em conformidade com um nível
quando atende a todos os critérios desse nível e dos níveis abaixo dele.** Os níveis ordenam os critérios
pelo quanto importam e pelo quanto custam, não pela dificuldade para quem desenvolve.

| nível | o que reúne | na WCAG 2.2 | por exemplo |
|---|---|---|---|
| **A** | as barreiras que deixam pessoas totalmente de fora | 31 critérios | 1.1.1 Conteúdo não textual: uma imagem que carrega significado tem uma alternativa em texto |
| **AA** | as barreiras que tornam a página difícil de usar para muita gente | mais 24, 55 no total | 1.4.3 Contraste (Mínimo): o texto tem pelo menos 4,5:1 contra o fundo |
| **AAA** | refinamentos que ajudam muito algumas pessoas e nem sempre podem ser atendidos | mais 31, 86 no total | 1.4.6 Contraste (Melhorado): pelo menos 7:1 |

**AA é o alvo**, e é para ele que apontam as leis da penúltima seção e a política de quase toda
organização. O próprio W3C não recomenda exigir AAA de um site inteiro, porque certos conteúdos não
conseguem atender a certos critérios AAA de jeito nenhum. Isso não é licença para ignorá-los: um critério
como o 2.4.13 *Aparência do foco* custa algumas linhas de CSS, e a aula 11 o atende mesmo assim.

**Uma declaração de conformidade é sobre uma página inteira.** "Quase AA" não é um nível; um critério
falhando e a página fica no nível de baixo, ou em nenhum. É por isso que este curso testa as páginas do
planner inteiras, com uma máquina para o que uma máquina consegue decidir e uma pessoa para o resto.
