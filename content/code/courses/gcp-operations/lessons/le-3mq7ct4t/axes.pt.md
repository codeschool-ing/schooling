---
title: Três jeitos de cortar uma fatura, e o que cada um responde
version: 1
---

**Uma fatura do Google Cloud pode ser cortada de três jeitos, e cada um responde uma pergunta diferente.** Por
**projeto**: qual ambiente ou produto gastou. Por **pasta**: qual parte da organização, já que uma pasta agrupa
projetos e a fatura sobe por ela. Por **rótulo**: qual time, serviço ou centro de custo, atravessando projetos. Os três
se completam em vez de competir: o projeto é a fronteira mais dura (permissões, cotas e faturamento param nele), a
pasta é o organograma, e o rótulo é o único que atravessa os dois. Esta etapa vem da documentação do Google; a próxima
faz as perguntas a um mês de dados no seu computador.

| corte | definido por | responde | não responde |
|---|---|---|---|
| projeto | o projeto em que o recurso é criado | quanto custou produção contra desenvolvimento? | qual time dentro de produção |
| pasta | onde o projeto fica na hierarquia | quanto custou a divisão da loja? | nada dentro de um projeto |
| rótulo | uma chave e um valor em cada recurso | quanto o time `data` gastou, onde quer que tenha rodado? | nada sobre um recurso sem rótulo |

## Rótulos, e o que eles não são

Um **rótulo** (*label*) é uma chave e um valor num recurso (`team=shop`), escrito por quem o cria e copiado em cada
linha da fatura que esse recurso produz. Os `default_labels` da lição 5 os põem em tudo o que o Terraform cria. Três
fatos decidem quanto eles valem:

- **Nem todo recurso aceita rótulo.** A maioria aceita; algumas linhas da fatura (suporte, algumas cobranças de rede,
  impostos) não trazem nenhum, então até um projeto perfeitamente rotulado tem um resto.
- **Rótulos não são retroativos.** Um rótulo acrescentado hoje aparece nas linhas de hoje, não nas do mês passado. Um
  relatório de custo por rótulo só é tão antigo quanto a rotulagem.
- **Um rótulo é texto livre.** `team=shop`, `team=Shop` e `Team=shop` são três times para uma consulta. Os rótulos da
  loja vêm dos `default_labels` do Terraform, e esse é o principal motivo de serem consistentes.

**Tags** são outra coisa com nome parecido: ficam presas à hierarquia de recursos, são controladas pelo IAM e podem
ser usadas em políticas da organização e regras de firewall. Para relatório de custo, o que a exportação de
faturamento carrega são os rótulos.

## Projetos são a fronteira mais barata de acertar

A maioria das perguntas de custo se responde antes de qualquer rótulo: produção e desenvolvimento em projetos
separados fazem de "quanto custa produção?" a linha do projeto. Os dois projetos da loja, `planner-prod` e
`planner-dev`, são essa divisão. Um time que roda os dois ambientes num projeto só precisa rotular cada recurso com
perfeição para recuperar o que uma fronteira de projeto teria dado de graça.
