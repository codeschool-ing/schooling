---
title: Lendo uma tabela de preços
version: 1
---

APIs de modelos cobram **por milhão de tokens**, escrito `MTok`, com um preço diferente para cada
direção. Entrada é o que você manda, saída é o que o modelo escreve, e **a saída custa várias vezes
mais que a entrada**, porque gerar um token é uma passada pelo modelo inteiro e ler um prompt é
feito em bloco. A maioria das tabelas acrescenta uma terceira e uma quarta colunas para entrada em
cache, que a aula 2 seção 07 explica.

Esta é a tabela que o curso usa, impressa pelo `prices.py` ao lado dos arquivos do curso. Ela lê
duas fontes, e a diferença entre elas importa:

- **A própria página de preços da Anthropic**, lida no dia em que o script rodou. Uma página não tem
  versão, então a data faz parte de cada número.
- **A lista de preços do LiteLLM num commit fixado**, para OpenAI e Google. O LiteLLM é um projeto
  de código aberto que guarda preços e limites de todos os provedores num arquivo só. É a cópia de
  um terceiro: as páginas da própria OpenAI e do Google não estavam ao alcance da máquina em que
  este curso foi gravado. O script imprime os modelos da Anthropic pelas duas fontes, para você ver
  a cópia concordar com o original onde os dois existem.

Ele rodou na máquina de gravação, não no laboratório, já que lê a rede:

```
$ python3 prices.py
anthropic: https://platform.claude.com/docs/en/about-claude/pricing, read 2026-10-02
  model                  input  output  cache write 5m  cache read
  Claude Opus 5.5           $4     $20              $5       $0.20
  Claude Sonnet 5.5         $2     $10           $2.50       $0.20
  Claude Haiku 4.5          $1      $5           $1.25       $0.10
anthropic: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  claude-opus-5-5                     $4     $20        $0.2   1000000   128000
  claude-sonnet-5-5                   $2     $10        $0.2   1000000   128000
  claude-haiku-4-5                    $1      $5        $0.1    200000    64000
openai: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  gpt-5.5                             $5     $30        $0.5   1050000   128000
  gpt-5.4                           $2.5     $15       $0.25   1050000   128000
  gpt-5.4-mini                     $0.75    $4.5      $0.075    272000   128000
  gpt-5.4-nano                      $0.2   $1.25       $0.02    272000   128000
google: LiteLLM at commit b9e71e990aed
  model                            input  output  cache read    window  max out
  gemini/gemini-pro-latest            $2     $12        $0.2   1048576    65536
  gemini/gemini-3.5-flash           $1.5      $9       $0.15   1048576    65536
  gemini/gemini-3.5-flash-lite      $0.3    $2.5       $0.03   1048576    65536
```

**Estes números são de 2 de outubro de 2026 e estarão errados quando você ler isto.** Os preços
neste mercado caíram e foram reorganizados várias vezes por ano. O que não envelhece é como ler a
tabela:

- **A unidade é dólar por milhão de tokens.** Tome o Claude Sonnet 5.5 a `$2` de entrada e `$10`
  de saída. Uma requisição com 2.000 tokens de entrada e 500 de saída custa 2.000 × 2 /
  1.000.000 mais 500 × 10 / 1.000.000: US$ 0,004 mais US$ 0,005, nove décimos de centavo.
- **A saída custa cinco ou seis vezes a entrada aqui**: 5× nos três modelos Claude, 6× na maioria
  dos da OpenAI, 6× no Pro do Gemini. Uma funcionalidade que escreve respostas longas custa outra
  ordem de grandeza de dinheiro que uma que lê documentos longos e responde sim ou não.
- **A diferença dentro de um provedor é maior que entre provedores.** O `gpt-5.4-nano` é 25 vezes
  mais barato por token de entrada que o `gpt-5.5`; o Haiku 4.5 custa um quarto do Opus 5.5. A
  aula 10 é sobre escolher, e a versão curta é que o modelo mais barato que passa nos seus próprios
  testes é o certo.
- **`window` e `max out`** são os limites da aula 2 seção 02, na mesma linha do preço, porque
  decidem o que cabe numa requisição.

## Quando os preços mudam

Trate a tabela de preços no seu código como o `prices.py` a trata: **um lugar só, com uma data e
uma fonte ao lado**. A aula 2 seção 05 escreve a função de custo que a lê, e um teste que falha
quando alguém acrescenta um modelo sem preço é um seguro barato contra um painel que mostra, em
silêncio, um modelo novo como gratuito.
