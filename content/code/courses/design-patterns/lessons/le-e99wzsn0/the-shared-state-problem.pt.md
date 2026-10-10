---
title: "O problema do estado compartilhado: dois balcões, um exemplar"
version: 1
---

**Quando duas threads podem ler e escrever os mesmos dados, toda regra sobre esses dados precisa
valer a cada instante entre quaisquer dois passos delas.** A maioria das regras não vale. "Só empreste
um exemplar se houver um na estante" são dois passos, uma verificação e uma ação, e uma segunda
thread pode rodar entre eles. Essa brecha é o problema inteiro desta lição, e o modelo de atores é
um jeito de fechá-la.

A crença comum é que isso é raro: duas threads teriam de chegar com microssegundos de diferença.
Numa biblioteca com um balcão, talvez. Um sistema de biblioteca atende um balcão em cada entrada, o
site, os totens de autoatendimento e o processo noturno que renova empréstimos, e todos perguntam
pelos mesmos poucos livros populares nas horas de maior movimento. Raro por requisição é frequente
por dia.

Crie `~/patterns/actors` e trabalhe lá:

```sh
mkdir -p ~/patterns/actors
cd ~/patterns/actors
```

Aqui estão dois balcões emprestando o último exemplar de *Iracema* no mesmo instante:

```schooling-example
{"language": "python", "file": "shared.py", "parts": [
 {"code": "# shared.py\nimport threading\nimport time\n\ncopies = {\"Iracema\": 1}\noutcomes: list[str] = []", "note": "Um exemplar de *Iracema*, num dicionário que qualquer thread alcança. `outcomes` junta o que cada balcão fez, para a impressão acontecer depois que os dois terminarem."},
 {"code": "\n\ndef lend(desk: str, title: str) -> None:\n    if copies[title] > 0:          # check\n        time.sleep(0.01)           # the other desk gets the processor here\n        copies[title] -= 1         # act\n        outcomes.append(f\"{desk} lent {title}\")\n    else:\n        outcomes.append(f\"{desk} refused {title}\")", "note": "A regra, escrita do jeito óbvio: verificar que há um exemplar, depois pegá-lo. A pausa entre os dois passos é encenada, para a execução mostrar toda vez o que de outro modo aconteceria de vez em quando."},
 {"code": "\n\ndesks = [threading.Thread(target=lend, args=(name, \"Iracema\")) for name in (\"north desk\", \"south desk\")]\nfor d in desks:\n    d.start()\nfor d in desks:\n    d.join()\nfor line in sorted(outcomes):\n    print(line)\nprint(\"copies of Iracema:\", copies[\"Iracema\"])", "note": "Duas threads, uma por balcão, iniciadas juntas e esperadas. Os resultados são ordenados antes da impressão, então as duas linhas saem na mesma ordem seja qual for o balcão que terminou primeiro."}
]}
```

```
ana@laptop:~/patterns/actors$ python3 shared.py
north desk lent Iracema
south desk lent Iracema
copies of Iracema: -1
```

Os dois balcões emprestaram o livro e a estante agora tem menos um exemplar. Cada balcão fez
exatamente o que o código diz. Um balcão verificou, viu um exemplar e pausou; o outro verificou, viu
o mesmo exemplar e pausou; depois cada um o pegou. **Nenhuma linha de `lend` está errada; o bug mora
entre duas linhas corretas.** Sem o `time.sleep`, a mesma coisa acontece sempre que o sistema
operacional troca de thread naquele ponto, o que é raro o bastante para passar em todo teste e
frequente o bastante para chegar à produção.

## Três saídas

Há três famílias de resposta, e as próximas lições do curso ficam com uma cada.

| | a ideia | onde no curso |
|---|---|---|
| lock | deixar só uma thread de cada vez entrar no verificar-e-agir | lição 18 |
| imutabilidade | nunca mudar dados compartilhados; construir valores novos | lição 15, e a lição 18 de novo |
| isolamento | não compartilhar os dados; mandar mensagens à única thread dona deles | esta lição |

Um lock mantém o dicionário compartilhado e o protege. Funciona, e põe uma obrigação em todo trecho
de código que toca os dados: pegar o lock, e pegá-lo na mesma ordem que todos os outros, ou duas
threads podem segurar cada uma um lock e esperar pelo da outra para sempre. A lição 18 mostra a
correção e o deadlock. A imutabilidade elimina as escritas, o que elimina a corrida; ela combina mais
com valores do que com uma estante cuja razão de ser é mudar.

**O isolamento elimina o compartilhamento.** Os exemplares de *Iracema* pertencem a um dono, e
ninguém mais pode lê-los ou escrevê-los. Um balcão que quer um exemplar manda ao dono uma mensagem
dizendo isso, e o dono trata suas mensagens uma de cada vez. Não há brecha entre verificar e agir,
porque um único trecho de código verifica ou age, e não faz mais nada no meio.

Esse dono é um ator. Carl Hewitt, Peter Bishop e Richard Steiger descreveram o modelo em 1973, muito
antes de as máquinas com vários núcleos o porem na moda, e desde então ele virou o centro do Erlang,
do Akka na JVM e do Orleans da Microsoft. A próxima seção diz o que é um ator; a seção 04 constrói
um com uma thread e uma fila.

## O que um teste teria visto

Rode o `shared.py` sem o `sleep` e ele quase certamente vai imprimir um empréstimo, uma recusa e zero
exemplares, toda vez que você tentar. Um teste que roda os dois balcões uma vez passa. Essa é a
propriedade perigosa dos bugs de estado compartilhado, e é por isso que este curso enuncia a correção
como regra de projeto: **se só uma thread pode tocar os dados, a intercalação que os quebra não tem
como acontecer**, decida o escalonador o que decidir.
