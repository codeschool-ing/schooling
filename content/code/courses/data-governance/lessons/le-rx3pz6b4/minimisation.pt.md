---
title: Guardando menos
version: 1
---

Todo controle deste curso custa algo para manter, e todos podem falhar. O dado que nunca deixa de
estar protegido é o dado que a empresa não guarda. O **artigo 6º, III** da LGPD faz disso um
princípio — a **necessidade**: limitação do tratamento ao mínimo necessário para a realização das
suas finalidades, com dados pertinentes, proporcionais e não excessivos.

Minimização não é uma decisão só; é uma pergunta feita a toda coluna, de três formas.

**Precisamos coletar?** A Ipê pede data de nascimento no cadastro. Para quê? Para recusar vendas que
um menor não pode fazer, e para conferir uma idade numa receita. As duas precisam de *se o cliente é
adulto* e, no máximo, da idade — não do dia em que ele nasceu. Um formulário que pergunta "você tem
18 anos ou mais?" e um ano serviria às duas, e a medição da aula 5 diz que a data exata é um terço do
que torna únicos 5.988 clientes.

**Precisamos guardar nesta forma?** O CPF era preciso para achar clientes e para lê-lo de volta a
eles. A aula 5 o trocou por um HMAC e um texto cifrado, que servem aos dois usos, e apagou a coluna. A
mesma pergunta aplicada ao `cep` questiona se um endereço de entrega é preciso depois da entrega; ao
`tickets.body`, se o texto é preciso depois que o chamado fecha.

**Precisamos guardar?** Isso é retenção, o assunto da aula 10: uma finalidade tem fim, e o dado
guardado depois dele é dado guardado sem finalidade.

## Quem decide

Um time de dados não decide do que o negócio precisa. Ele consegue fazer três coisas que ninguém mais
vai fazer:

- **dizer quanto cada coluna custa** — a classe, quem a lê, o que exporia num incidente — na tabela de
  classificação, onde o custo fica visível;
- **mostrar o que é de fato usado.** Uma coluna que nenhuma consulta leu em um ano é uma coluna sobre
  a qual vale perguntar a alguém; o catálogo e a linhagem da aula 9 tornam essa pergunta respondível;
- **tornar fácil o desenho mínimo** — um campo de formulário que não existe, uma view que já tem a
  faixa etária, um pipeline que descarta o que o passo seguinte não usa.
