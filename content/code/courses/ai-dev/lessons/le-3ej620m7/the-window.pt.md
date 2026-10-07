---
title: Uma janela para a pergunta e a resposta
version: 2
---

Todo modelo tem uma **janela de contexto**: o máximo de tokens que ele dá conta de tratar numa
requisição. O erro comum é lê-la como o tamanho da pergunta que você pode fazer. **Ela é o tamanho
da pergunta e da resposta juntas.** O modelo escreve a resposta na mesma janela de onde leu o
prompt, um token por vez, então cada token de saída que você permite é um token que a entrada não
pode usar.

A requisição leva o segundo número. `max_tokens` é o máximo que o modelo pode escrever, e a API da
Anthropic o exige, porque sem ele o provedor não saberia quanto espaço reservar. Um provedor
publica dois limites por modelo, a janela e o máximo de saída que uma resposta pode ter, e uma
requisição precisa caber nos dois.

## O que acontece depois da borda

O Llama 3.2 foi treinado para uma janela de 128 mil tokens, mas **o Ollama o roda com uma janela de
4.096** a não ser que alguém mande outra coisa, porque cada token de janela custa memória: é a
coluna `CONTEXT` que o `ollama ps` imprimiu na aula 1. Quatro mil tokens são umas poucas páginas,
perto o bastante para chegar lá de propósito. O `~/shop/scratch/window.py` escreve uma senha no
topo de um texto longo, enche o texto com cópias do `CONVENTIONS.md` e pergunta a senha no fim:

```python
import sys

import anthropic
import tiktoken

client = anthropic.Anthropic()
enc = tiktoken.get_encoding("o200k_base")
copies = int(sys.argv[1])
text = ("The password for this exercise is PINEAPPLE.\n\n" + open("CONVENTIONS.md").read() * copies
        + "\n\nWhat is the password for this exercise? Answer with the word only.")
r = client.messages.create(model="llama3.2:3b", max_tokens=20,
                           messages=[{"role": "user", "content": text}])
read = r.usage.input_tokens + (r.usage.cache_read_input_tokens or 0)
print(f"sent about {len(enc.encode(text))}, read {read}: {r.stop_reason}, {r.content[0].text!r}")
```

Ele imprime dois números: quanto o `tiktoken` estima que foi enviado, e quanto o Ollama diz que o
modelo leu. Duas cópias, dez e doze:

```
ana@dev:~/shop$ python scratch/window.py 2
ana@dev:~/shop$ python scratch/window.py 10
ana@dev:~/shop$ python scratch/window.py 12
```

Leia as três linhas como três situações:

- **Duas cópias cabem com folga.** As duas contagens diferem por algumas dezenas de tokens, porque
  o `tiktoken` não é o tokenizador deste modelo e não vê o embrulho em volta de uma mensagem; a
  próxima seção é sobre essa diferença.
- **Dez cópias também cabem, por pouco.** 3.829 tokens lidos, de 4.096, com espaço sobrando para
  os vinte da resposta. A senha lá no topo foi achada.
- **Doze cópias não couberam, e nada disse isso.** Uns 4.512 tokens foram enviados e o modelo leu
  2.050. O Ollama ficou com o fim do prompt, descartou o começo, e a senha foi junto. A requisição
  ainda terminou com `end_turn`, e o modelo ainda respondeu, com uma palavra da parte que recebeu.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 250\" role=\"img\" aria-label=\"Três requisições contra a janela de 4.096 tokens do Ollama para o llama3.2:3b. Duas cópias: 805 tokens lidos, a senha achada. Dez cópias: 3.829 lidos, achada. Doze cópias: uns 4.512 enviados, o começo descartado, 2.050 lidos, e a resposta foi shop.\"><text x=\"150\" y=\"19\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" font-weight=\"600\" fill=\"var(--paper)\">a janela do Ollama para o llama3.2:3b: 4.096 tokens</text><text x=\"140\" y=\"62\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">2 cópias</text><rect x=\"150\" y=\"50\" width=\"78.6\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"236.6\" y=\"62\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">leu 805: PINEAPPLE</text><text x=\"140\" y=\"114\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">10 cópias</text><rect x=\"150\" y=\"102\" width=\"373.9\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"531.9\" y=\"114\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">leu 3.829: PINEAPPLE</text><text x=\"140\" y=\"166\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper)\">12 cópias</text><rect x=\"150\" y=\"154\" width=\"240.4\" height=\"24\" rx=\"2\" fill=\"none\" stroke=\"var(--amber)\" stroke-width=\"1.2\" stroke-dasharray=\"4 3\"></rect><rect x=\"390.4\" y=\"154\" width=\"200.2\" height=\"24\" rx=\"2\" fill=\"var(--phosphor-dim)\" stroke=\"none\" stroke-width=\"1.2\"></rect><text x=\"270.2\" y=\"166\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">descartado</text><text x=\"598.6\" y=\"166\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">leu 2.050: shop</text><path d=\"M550.0 36 L550.0 47\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 77 L550.0 99\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 129 L550.0 151\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><path d=\"M550.0 181 L550.0 206\" stroke=\"var(--paper)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 3\"></path><text x=\"550.0\" y=\"218\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"9.5\" fill=\"var(--paper-dim)\">4096</text><text x=\"150\" y=\"238\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" fill=\"var(--paper-dim)\">a senha era a primeira linha; a parte descartada a levou</text></svg>", "caption": "O prompt e a resposta dividem uma janela. A terceira requisição foi cortada pela frente sem uma palavra, e a senha do topo foi junto com o que foi cortado."}
```

**Esse é o pior dos dois jeitos de uma janela ser imposta.** A API da Anthropic recusa uma
requisição cujo prompt e `max_tokens` não cabem, com um erro `400`, antes de qualquer geração:
não custa nada e diz exatamente o que está errado. O Ollama, e algumas outras APIs e modelos mais
antigos, cortam a entrada ou a saída, e a requisição dá certo com menos do que você mandou. De um
jeito ou de outro, **a verificação fica no seu código, antes de a requisição sair**, que é o que a
aula 2 seção 09 constrói. E onde uma ferramenta encurta as coisas calada, um teste como este, com
um fato no começo que só sobrevive se tudo chegar, é como você descobre.

## Do tamanho das janelas reais

As janelas dos modelos da tabela de preços da aula 2 seção 04 vão de 200 mil tokens a pouco mais
de um milhão, e o máximo de saída por resposta de 64 mil a 128 mil. Um milhão de tokens são
milhares de páginas. É fácil concluir daí que o limite não importa mais, e três coisas dizem o
contrário:

- **Você paga cada token de entrada em cada requisição.** Uma janela que você enche é uma conta que
  você paga, toda vez; a aula 2 seção 05 põe números nisso.
- **Uma janela cheia é mais lenta.** O modelo lê tudo antes de escrever o primeiro token, e a
  espera pelo primeiro token cresce com o prompt. Na máquina da gravação, ler 1.400 tokens levou
  uns vinte segundos; a aula 2 seção 07 mede isso.
- **Uma janela cheia não é uma janela bem lida.** Os modelos são mensuravelmente piores em usar
  informação enterrada no meio de um contexto muito longo do que no começo ou no fim, um resultado
  publicado primeiro como *Lost in the Middle* (Liu e outros, 2023). Pôr o repositório inteiro no
  prompt não é o mesmo que o modelo tê-lo entendido. A aula 6 busca os poucos trechos que importam
  em vez disso.
