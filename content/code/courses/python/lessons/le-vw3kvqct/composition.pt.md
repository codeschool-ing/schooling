---
title: Ter um, em vez de ser um
version: 1
---

```python
class Notificador:
    def __init__(self, transporte):
        self.transporte = transporte      # ele TEM um

    def notificar(self, mensagem):
        self.transporte.entregar(formatar(mensagem))
```

Composição é um objeto guardando outro objeto e chamando-o. Sem herança, sem classe base, e sem
maquinaria compartilhada sobre a qual os dois tenham de concordar.

## A pergunta que decide

**Isto é um TIPO daquilo, ou ele TEM um?**

Um `Aluno` é uma `Pessoa` — herança. Um `Notificador` tem um transporte — composição. Dita em voz
alta, a resposta costuma ser óbvia, e o motivo de as pessoas irem à herança mesmo assim é que ela é
ensinada primeiro e parece reaproveitamento.

## O que dá errado com a escolha errada

O requisito que chega nunca é "mais um tipo". É "o de SMS deveria repetir a tentativa, o de log
não". Repetir não é um tipo de notificação — é algo que acontece em volta de uma. Com herança isso
vai para a classe base atrás de uma bandeira, e a base agora conhece uma subclasse que ela não
deveria conhecer.

Com composição isso é um `TransporteComRepeticao` que guarda outro transporte e o chama de novo.
Nada herda de nada, e o notificador de log não repete porque ninguém o envolveu.

## O que isso faz com um teste

Para testar a subclasse de e-mail você precisa testar a classe base junto, porque elas são um
objeto só. Para testar o notificador composto você entrega a ele um transporte que registra o que
recebeu — um objeto com um método — e o notificador não nota a diferença. **Essa é a diferença
prática, e ela aparece muito antes da diferença de projeto.**

## O custo

Composição é um objeto a mais e um nome a mais. `self.transporte.entregar(...)` é uma palavra mais
longo que `self.entregar(...)`, e onde uma classe genuinamente É uma especialização de outra, essa
palavra não compra nada.

**Nenhuma das duas é o padrão para tudo.** O que é padrão é a PERGUNTA — é um tipo, ou tem um —
feita antes de qualquer uma das duas ser escrita.
