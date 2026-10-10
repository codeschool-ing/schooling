---
title: Escolher um modelo antes de escolher uma trava
version: 1
---

**A maioria dos defeitos de concorrência é projetada no dia em que alguém acrescenta threads a um
código que nunca foi feito para tê-las.** As travas desta lição são consertos. A decisão mais barata
vem antes: que modelo de concorrência o programa deve usar, e quão pouco estado ele consegue
compartilhar dentro desse modelo. Duas perguntas decidem a maior parte.

## Em que o tempo é gasto?

A seção 02 mediu a resposta que importa. **Esperar** se sobrepõe em qualquer modelo, então escolha
aquele que torna o compartilhamento menos perigoso. **Calcular** só fica mais rápido com mais
núcleos, e na versão comum do Python isso quer dizer processos.

| o trabalho é principalmente... | em Python | por quê |
|---|---|---|
| esperar muitos sockets, milhares de conexões | `asyncio` | uma thread; uma troca só acontece num `await`, então a maioria das corridas não pode ser escrita |
| esperar, por meio de uma biblioteca que bloqueia e não tem versão async | um `ThreadPoolExecutor` | threads soltam a GIL enquanto esperam |
| calcular, e as partes são independentes | um `ProcessPoolExecutor` | paralelismo de verdade; nada compartilhado, então nada sobre o que correr |
| um fluxo de eventos para transformar e dosar | os fluxos reativos da lição 16 | a contrapressão faz parte do modelo |
| estado duradouro que muitos chamadores mudam | os atores da lição 17 | um dono por pedaço de estado, e mensagens no lugar de travas |

O `asyncio` não está livre de corridas, e vale ser exato sobre o porquê. Uma corrotina que lê um
valor, espera com `await` uma chamada ao banco e escreve de volta um valor novo tem o mesmo vão de
`race.py`, com o `await` no lugar do `sleep(0)`. O que ele remove é o vão *que você não escreveu*:
entre duas linhas sem `await`, nada mais roda.

## Quanto precisa ser compartilhado?

Cada linha da tabela fica mais segura conforme o estado compartilhado encolhe. A ordem para
tentar as coisas, que é também a ordem desta lição lida de trás para a frente:

1. Não compartilhe nada: dê a cada tarefa seus próprios dados, como o pool de processos fez.
2. Compartilhe só valores imutáveis, e publique os novos trocando uma referência.
3. Confine cada coisa mutável a um dono, e mande mensagens para ele.
4. Trave, em volta dos seus próprios dados, por pouco tempo, numa ordem combinada.

**Uma trava é o último recurso e não o primeiro**, porque é a única das quatro cuja correção
depende de todo chamador, agora e no futuro, se comportar. As três primeiras põem a segurança na
estrutura, onde quem lê consegue enxergá-la.

## O que cada linguagem põe na sua mão

| | primeira ferramenta | ao calcular em paralelo | compartilhar com segurança |
|---|---|---|---|
| Python | `asyncio`, ou threads para bibliotecas que bloqueiam | `multiprocessing`; a versão free-threaded a partir do 3.13 | `queue.Queue`, dataclasses congeladas, `threading.Lock` |
| JavaScript / TypeScript | o event loop, `async`/`await` | worker threads, com mensagens | nada é compartilhado por padrão; `SharedArrayBuffer` e `Atomics` quando você opta |
| Java | threads; as virtual threads desde o Java 21 tornam barata uma por requisição | as mesmas threads, em todos os núcleos | `java.util.concurrent`: `ConcurrentHashMap`, `AtomicReference`, travas |
| Go | goroutines | as mesmas goroutines, em todos os núcleos | canais primeiro, `sync.Mutex` quando um canal fica desajeitado |

O provérbio do Go põe o item 3 numa frase: *não se comunique compartilhando memória; compartilhe
memória se comunicando.* O JavaScript fez a mesma escolha por você ao dar a cada worker seu próprio
heap. Java e Python com threads dão memória compartilhada por padrão e deixam a disciplina com
você, e é por isso que a maioria dos exemplos desta lição só podia ter sido escrita nessas duas.

## Onde os padrões ficam agora

O título desta lição prometeu que os padrões quebram, e a quebra tem um padrão próprio. Cada um
supunha que, entre duas de suas linhas, o mundo ficava parado.

| padrão | o que as threads quebram | a correção nesta lição |
|---|---|---|
| qualquer objeto com um contador ou um total | ler-modificar-escrever perde atualizações | uma trava dentro do objeto |
| singleton criado sob demanda | verificar-depois-agir constrói vários | criá-lo antes das threads, ou travar e verificar duas vezes |
| observer | a lista muda durante o percurso | copiar dentro da trava, chamar fora dela |
| objeto de valor | nada; ele já era seguro | nenhuma, e esse é o ponto |

Nenhuma dessas correções é um padrão novo. São os mesmos projetos com mais uma pergunta feita a
eles: *quem mais pode estar aqui ao mesmo tempo?* A lição 19 transforma esse tipo de pergunta num
hábito para escolher qualquer padrão.
