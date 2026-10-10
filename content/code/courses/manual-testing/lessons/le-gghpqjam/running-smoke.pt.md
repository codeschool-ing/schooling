---
title: Rodando a fumaça, à mão e num laço
version: 1
---

A lista da seção 03 desta aula pode ser rodada de dois jeitos, e vale conhecer os dois. **À mão, no
navegador, ela leva uns dois minutos. Como um laço curto de shell, leva um comando** e imprime uma
linha por checagem, que pode ser colada numa mensagem do jeito que está.

## À mão

Com o boxoffice recém-iniciado, no navegador:

1. abra `http://127.0.0.1:8000/health`: a página mostra uma linha, `ok boxoffice` e a versão;
2. abra `http://127.0.0.1:8000`: a tabela Shows lista The Seagull, Hamlet e The Little Prince;
3. clique em Sign up: o formulário aparece, com o botão Create account;
4. volte, clique em Book na linha de Hamlet, digite `member@example.org`, digite 2 no campo de
   ingressos e aperte Book: a página seguinte diz Order 1001 reserved;
5. clique em Outbox no pé da página: a página abre, com o título Outbox.

Cada passo tem uma coisa a procurar, decidida antes, e um passo ou a mostra ou não mostra. É isso
que faz dele uma checagem e não uma olhada em volta.

## Num laço

As mesmas cinco checagens cabem em poucas linhas de shell. Cada linha abaixo de `CHECKS` é uma
checagem, com quatro campos separados por `|`: o nome; o formulário a enviar, vazio quando a
checagem só abre uma página; o caminho; e um padrão que a resposta precisa conter. O laço envia
cada pedido com o curl, procura o padrão com o grep e imprime `pass` ou `FAIL`. No fim diz quantas
falharam, e termina com um código de saída de falha se alguma falhou, para que outro programa saiba o
resultado sem ler as linhas.

Salve-o como `smoke.sh` no seu diretório `boxoffice`, ao lado do `boxoffice.py`:

```sh
# smoke.sh: five checks that say whether a build of boxoffice is worth testing.
# Run it with:  sh smoke.sh      while boxoffice is running.
URL=http://127.0.0.1:8000
failed=0
while IFS='|' read -r name form path expect; do
  if curl -s ${form:+-d "$form"} "$URL$path" | grep -q "$expect"; then
    echo "pass  $name"
  else
    echo "FAIL  $name"
    failed=$((failed + 1))
  fi
done <<'CHECKS'
the server answers||/health|^ok boxoffice
the home page lists three shows||/|The Seagull.*Hamlet.*The Little Prince
the sign-up page loads||/signup|Create account
one booking goes through|email=member@example.org&show=S2&quantity=2|/book|Order [0-9]* reserved
the outbox opens||/outbox|<h1>Outbox</h1>
CHECKS
echo "$failed of 5 checks failed"
[ "$failed" -eq 0 ]
```

Dois detalhes carregam mais do que parecem. `${form:+-d "$form"}` acrescenta o `-d` do curl e o
formulário só quando o campo não está vazio, e é assim que um mesmo laço envia tanto um pedido
simples quanto uma reserva. E o padrão da página inicial, `The Seagull.*Hamlet.*The Little Prince`,
pede os três títulos naquela ordem numa mesma linha, e eles estão, porque o boxoffice escreve a
tabela inteira numa linha só.

Reinicie o boxoffice se você acabou de fazer os passos à mão, para que ele comece do zero, e rode o
script no segundo terminal. Acrescentar `; echo $?` imprime o código de saída depois:

```
ana@laptop:~/boxoffice$ sh smoke.sh; echo $?
pass  the server answers
pass  the home page lists three shows
pass  the sign-up page loads
pass  one booking goes through
pass  the outbox opens
0 of 5 checks failed
0
```

Cinco aprovações e um código 0: esta versão vale a pena ser testada. O script precisa de um shell
Unix, então no Windows ele roda no WSL ou no Git Bash que vem com o Git for Windows; fora disso, os
cinco passos à mão fazem o mesmo trabalho. Os caminhos do Windows não foram executados neste curso.

## O que a fumaça deixa para trás

Uma checagem de fumaça que faz algo real muda a aplicação. A checagem de reserva reservou dois
lugares para Hamlet, e a página inicial mostra isso:

```
ana@laptop:~/boxoffice$ curl -s http://127.0.0.1:8000/ | grep -o 'Hamlet</td><td>[^<]*</td><td>[^<]*</td><td>[0-9]*'
Hamlet</td><td>2026-10-17 20:00</td><td>R$ 80,00</td><td>78
```

Hamlet tem 78 lugares restantes em vez de 80, e o próximo pedido será o 1002, não o 1001. Casos que
contam lugares ou citam números de pedido agora esperariam a coisa errada. **Então, depois de uma
rodada de fumaça, reinicie o boxoffice antes de o teste de verdade começar**, o que nesta aplicação
é o reinício inteiro. Um produto que não se reinicia com essa facilidade precisa de dados de fumaça
próprios, separados dos dados que os casos usam, e a aula 20 trata de manter os dados de teste sob
controle.

## Mantendo-a pequena

Um laço tão fácil de estender convida a estendê-lo. Cada checagem acrescentada é um segundo a mais e
mais uma coisa que pode falhar por um motivo que não é a versão, e uma lista de fumaça que cresce até
trinta checagens de descontos e reembolsos virou uma suíte de regressão que roda primeiro, que é o
assunto da aula 10. O teste para uma linha nova é o da seção 03: a versão deixa de valer o teste se
isto falhar?
