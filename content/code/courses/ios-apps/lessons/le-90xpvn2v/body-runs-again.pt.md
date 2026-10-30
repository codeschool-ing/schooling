---
title: O body roda de novo, e esse é o projeto
version: 1
---

**O SwiftUI lê o `body` de uma view sempre que algo de que o body depende pode ter mudado, e espera
lê-lo muitas vezes.** Um body não é um construtor que roda uma vez. Ele está mais perto de uma fórmula
de planilha: dadas as entradas atuais, ele diz o que a tela é agora. Quando uma entrada muda, o
SwiftUI pergunta de novo.

Três tipos de entrada fazem o SwiftUI perguntar:

| o que mudou | exemplo no planner | aula |
|---|---|---|
| um valor que o pai passou | a `CourseListView` dá a uma linha um curso diferente | 2 e 8 |
| estado que a view possui | os minutos digitados no `SessionForm` | 6 |
| uma propriedade de um modelo observável que o body leu | as sessões do plano, no `PlannerModel` | 7 |

**A terceira linha é a que surpreende, para o bem.** O SwiftUI não roda de novo todo body que tenha
um modelo dentro. Ele registra quais propriedades do modelo um body leu enquanto rodava, e só uma
mudança numa delas faz o SwiftUI perguntar àquele body de novo. Um body que mostra o título de um
curso não é chamado de novo quando muda uma anotação em outra tela. A seção 05 reconstrói esse
registro em Swift puro, com o mesmo framework Observation que o SwiftUI usa, e conta as execuções.

## O que um body não deve fazer

Como é o SwiftUI que decide quantas vezes um body roda, o body não pode ter opinião sobre isso:

- **nenhum efeito colateral.** Começar um download, gravar um arquivo ou acrescentar a uma lista
  dentro do `body` repete isso a cada execução, e o número de execuções não é seu para saber. Trabalho
  que começa com uma view vai num modificador feito para isso, o `.task`, que a aula 12 usa;
- **nenhum trabalho caro.** Ordenar mil sessões dentro do `body` acontece a cada execução. Calcule
  onde os dados mudam, ou guarde no modelo, como a aula 7 faz;
- **nenhuma suposição sobre ordem.** O body de um pai pode rodar sem o do filho, e o do filho sem o do
  pai.

Nada nesta seção foi executado para o curso. As três entradas são as que a documentação da Apple para
`State`, `Binding` e `Observable` descreve, lida em 30 de outubro de 2026; quantas vezes o SwiftUI lê
um body num app concreto é algo que só uma execução num Mac mostraria, e o curso não cita número
nenhum para isso.
