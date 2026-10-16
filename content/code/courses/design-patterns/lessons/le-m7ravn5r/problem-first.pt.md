---
title: "Problema primeiro: dê nome ao que dói antes de dar nome a um padrão"
version: 1
---

**Um padrão é uma resposta, e uma resposta escolhida antes da pergunta é um custo com um nome
pendurado.** O hábito contra o qual esta lição argumenta é conhecido: você acabou de ler sobre uma
strategy ou um event store, um trecho de código parece um pouco com os exemplos, e o padrão entra.
O código ganha mais classes, e o problema que ele de fato tinha, se tinha algum, fica onde estava.

Os catálogos foram escritos ao contrário. Cada entrada do livro de 1994 da lição 6 começa com uma
*intenção* e uma seção chamada *aplicabilidade*: a situação em que o padrão compensa. Christopher
Alexander, o arquiteto de quem os padrões de software pegaram a ideia emprestada, definia um padrão
como um problema que se repete num contexto, junto com o núcleo da sua solução. Tire o problema e o
que sobra é um formato, e um formato sozinho não diz se ele cabe no seu código.

## Uma força é uma frase sobre mudança ou conhecimento

A palavra para o problema é **força**: uma pressão sobre o código que torna um arranjo melhor que
outro. Uma força útil cabe numa frase, e quase sempre trata de uma de duas coisas. Ou algo muda e
a mudança sai cara, ou alguma parte sabe algo que não devia saber.

- *Todo semestre a biblioteca acrescenta uma categoria de membro, e cada uma obriga a editar a
  função de multa.*
- *Vamos trocar de provedor de e-mail, e o cliente do provedor é chamado de onze lugares.*
- *O relatório de atrasos não pode ser testado sem um servidor SMTP de verdade.*
- *Montar um empréstimo leva nove configurações opcionais, e quem chama vive passando na ordem
  errada.*

Cada uma aponta para uma família de respostas. Nenhuma é o nome de um padrão, e é isso que as
torna úteis: dá para conferir uma frase dessas contra o código e o histórico dele, e não dá para
conferir "isto ficaria mais limpo com uma factory".

## Um trecho de código, três respostas diferentes

Eis uma função que a biblioteca tem há anos. É o tipo de coisa que atrai padrões:

```python
def fine(category: str, days_late: int) -> int:
    if category == "adult":
        return max(days_late, 0) * 50
    elif category == "student":
        return max(days_late, 0) * 25
    elif category == "staff":
        return 0
    raise ValueError(category)
```

Pergunte o que dói, e a resposta depende de fatos que não estão no código.

Se uma categoria nova chega todo semestre e só o número muda, a força é *uma taxa que varia por
categoria*. A resposta é uma tabela, um dicionário de categoria para centavos, e a seção 05 a
constrói. Uma classe strategy por categoria seriam três classes guardando um número cada.

Se os filmes vão passar a ser multados de outro jeito, limitados ao preço do item, a força é *uma
regra que varia pelo tipo de item*. Agora a variação é um cálculo e não um número, e funções
escolhidas pelo tipo valem a pena.

Se a função foi editada duas vezes em três anos e ninguém planeja uma terceira, **não há força, e a
mudança certa é nenhuma**. Um `if` com três ramos que qualquer pessoa lê em dez segundos não é um
problema esperando um padrão.

O código era o mesmo nos três casos. O que decidiu foi o histórico do arquivo e o plano para ele.
Num repositório de verdade, `git log --oneline -- fines.py` responde a primeira metade em segundos:
com que frequência o arquivo mudou, e se as mudanças eram todas do mesmo tipo.

## As forças e as famílias que as respondem

| quando a força é... | olhe para | neste curso |
|---|---|---|
| uma regra, várias versões, escolhida em tempo de execução | strategy, ou um dicionário de funções | lições 6 e 15 |
| várias partes precisam reagir a um evento | observer | lições 6 e 16 |
| uma parte que não é sua tem a interface errada | adapter, camada anticorrupção | lições 6 e 11 |
| um detalhe precisa ser trocável ou falsificável nos testes | uma porta e uma dependência injetada | lições 4 e 5 |
| leituras e escritas puxam um modelo para dois lados | CQRS | lição 8 |
| você precisa responder "o que aconteceu, e quando" | um log de eventos só de acréscimo | lição 9 |
| uma invariante abrange vários objetos | um agregado | lição 12 |

Leia a tabela da esquerda para a direita. Começar pela direita, com um padrão que você gostaria de
usar, e procurar uma linha para justificá-lo é o hábito com que esta seção começou.
