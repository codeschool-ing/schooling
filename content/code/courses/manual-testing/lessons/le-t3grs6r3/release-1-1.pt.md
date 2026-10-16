---
title: A versão 1.1
version: 1
---

O Rui corrigiu dois dos defeitos que você encontrou no boxoffice 1.0: seis ingressos recusados
(aula 4) e o desconto de 25% para um sócio que reserva cinco ou mais (aula 5). **Numa equipe, o
testador recebe uma versão nova** como um pacote, uma implantação no ambiente de teste ou um link
para baixar. Aqui a versão são três edições no `boxoffice.py`, e você mesmo as faz, exatamente como
o Rui as escreveu. Esta seção é a entrega; a próxima a confere.

## As notas da versão

Uma versão chega com uma nota dizendo o que mudou. Esta é a do Rui:

> **boxoffice 1.1**
>
> Corrigido: um pedido de seis ingressos era recusado com "You can book 1 to 6 tickets". Seis agora
> é aceito.
>
> Corrigido: um sócio que reservava cinco ou mais ingressos ganhava 25% de desconto. Os descontos
> não se somam mais e vale o maior, então o pedido ganha 15%. A função `discount` foi reescrita
> para isso.
>
> Conhecidos, não corrigidos nesta versão: um campo de ingressos que não é número ainda responde
> com uma página de erro (aula 4), e um pedido usado ainda pode ser reembolsado (aula 5).

**Notas de versão são uma afirmação, e o testador as lê como tal.** Elas dizem o que o
desenvolvedor quis mudar. Não conseguem listar o que mudou por acidente, porque ninguém anota um
efeito colateral que não percebeu. Lidas por um testador, estas notas dão três coisas:

- duas correções, cada uma com um relatório de defeito por trás, que são as verificações de
  sanidade da próxima seção;
- uma frase sobre onde a mudança foi parar: `discount`, a função que decide todo preço, foi
  reescrita em vez de remendada. O risco A da aula 1, um preço errado, acabou de ficar mais provável;
- dois defeitos conhecidos, que continuam abertos e não precisam de um segundo relatório quando você
  os encontrar de novo.

## Guarde a 1.0 antes

Antes de mudar o programa, guarde uma cópia da versão que você tem. Pare o boxoffice com Ctrl-C no
terminal dele e, em `~/boxoffice`:

```sh
cp boxoffice.py boxoffice-1.0.py
```

No Windows sem WSL, copie o arquivo no Explorador de Arquivos e renomeie a cópia para
`boxoffice-1.0.py`. A aula 10 roda as duas versões lado a lado, porque a pergunta "isso funcionava
antes?" só é respondida por uma versão que ainda existe.

## As três edições

Abra o `boxoffice.py` no seu editor. Cada edição é um par de blocos: encontre o primeiro bloco no
arquivo com a busca do editor (Ctrl+F, ou Cmd+F no Mac), selecione-o inteiro e substitua-o pelo
segundo bloco. Cada primeiro bloco aparece no arquivo exatamente uma vez. Copie cada bloco com o
botão que fica nele em vez de digitar, e mantenha a indentação exatamente como está: o Python lê a
indentação como estrutura, que é o `IndentationError` da aula 1 seção 05.

Você não precisa entender estas linhas para testar o resultado. A maioria dos testadores nunca vê o
código de uma versão, e o que vem a seguir testa a 1.1 apenas pelo comportamento.

**Edição 1, o número da versão.** Encontre esta linha:

```python
VERSION = "1.0"
```

e substitua-a por:

```python
VERSION = "1.1"
```

**Edição 2, a regra de desconto.** Encontre a função inteira, dez linhas:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    if student:
        return 50
    off = 0
    if member:
        off += 10
    if tickets >= 5:
        off += 15
    return off
```

e substitua-a por estas três:

```python
def discount(student, member, tickets):
    """The percentage off an order. Discounts do not add up; the largest one applies."""
    return max(10 if member else 0, 15 if tickets >= 5 else 0)
```

**Edição 3, a verificação da quantidade.** Encontre esta linha, dentro de `book`, mais abaixo:

```python
    if not 1 <= quantity < 6:
```

e substitua-a por:

```python
    if not 1 <= quantity <= 6:
```

Salve o arquivo. Nada muda numa aplicação em execução até ela subir de novo, porque o Python lê o
arquivo uma vez, ao iniciar; a próxima seção a inicia e confere o que você fez.

Se o programa se recusar a subir depois das edições, leia o erro de baixo para cima, como a aula 1
seção 05 mostrou: a última linha diz o que está errado e as de cima dizem onde. O conserto mais
rápido é copiar o `boxoffice-1.0.py` de volta sobre o `boxoffice.py` e fazer as três edições de
novo, o que é mais um motivo para guardar a cópia.
