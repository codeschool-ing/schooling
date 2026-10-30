---
title: Spacers e padding: espaço que você pede, e espaço em volta de você
version: 1
---

**Um `Spacer` é uma view cujo trabalho inteiro é ocupar espaço, e `padding` é um modificador que
acrescenta espaço em volta de uma view.** Os dois costumam ser confundidos porque ambos fazem
intervalos, e respondem a perguntas diferentes: um spacer afasta os irmãos numa stack, o padding
mantém o conteúdo de uma view longe das bordas dela.

## Spacer

A documentação da Apple para o `Spacer` diz que ele se expande ao longo do eixo principal da stack
tanto quanto a stack permitir, afastando as views irmãs, e nos dois eixos quando não está numa stack.
Ela acrescenta uma frase que vale ler duas vezes: **uma stack sem spacer é só tão larga quanto as
larguras ideais dos filhos**. Então `HStack { Text("SQL Databases"); Text("50 min") }` abraça os dois
textos, e a lista centraliza essa stack pequena na linha; acrescente um `Spacer()` entre eles e a
stack fica com a largura inteira, com os minutos na borda oposta.

`Spacer(minLength: 0)` deixa um spacer encolher até nada quando o espaço acaba. Sem o argumento o
mínimo é um padrão que o sistema escolhe, que impede dois rótulos de se encostarem. O modelo da seção
08 usa um spacer sem mínimo, e diz isso, para que a aritmética dele não precise de um número que não
tem como saber.

## Padding

```swift
WeekView()
    .padding()
    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
```

O `.padding()` sem argumentos acrescenta o que a documentação da Apple para `padding(_:_:)` chama de
uma quantidade padrão específica da plataforma em todas as bordas; `.padding(.horizontal, 16)`
acrescenta 16 pontos só à esquerda e à direita. **O padding é uma view nova em volta da antiga**,
exatamente como o frame da seção 04: ele propõe ao filho o tamanho que recebeu, menos o padding, e
informa o tamanho do filho mais o padding.

É por isso que a ordem acima importa, e por isso a aula 5 começa por ela. O fundo vem depois do
padding, então é desenhado em volta da view com padding e o retângulo arredondado tem espaço dentro.
Troque as duas linhas e o fundo abraça o conteúdo enquanto o padding acrescenta espaço vazio do lado
de fora.

Nada nesta seção foi executado para o curso; ela foi escrita a partir da documentação da Apple para o
`Spacer` e o `padding(_:_:)`, lida em 30 de outubro de 2026.
