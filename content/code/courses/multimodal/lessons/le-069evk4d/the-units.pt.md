---
title: Quatro unidades, e nenhuma delas é byte
version: 1
---

A aula 6 de `ai-models` leu a planilha do LiteLLM para modelos de texto, em que tudo tem preço por token. As entradas multimodais usam mais unidades que isso. A mesma planilha, no commit que o `prices.py` da aula 3 fixa:

```
ana@lab:~/mm$ sheet show gpt-4o | grep -E "^(input|output)_cost_per_token "
input_cost_per_token                       2.5e-06
output_cost_per_token                      1e-05
ana@lab:~/mm$ sheet show gemini/gemini-2.5-flash | grep -E "^(input_cost_per_token|input_cost_per_audio_token|output_cost_per_token) "
input_cost_per_audio_token                 1e-06
input_cost_per_token                       3e-07
output_cost_per_token                      2.5e-06
ana@lab:~/mm$ sheet show whisper-1 | grep -E "cost_per_second"
input_cost_per_second                      0.0001
output_cost_per_second                     0.0001
ana@lab:~/mm$ sheet show tts-1 | grep -E "cost_per_character"
input_cost_per_character                   1.5e-05
ana@lab:~/mm$ sheet show gpt-image-1 | grep -E "^(input|output)_cost_per_(image_)?token "; sheet show high/1024-x-1024/gpt-image-1 | grep input_cost_per_image
input_cost_per_image_token                 1e-05
input_cost_per_token                       5e-06
output_cost_per_image_token                4e-05
input_cost_per_image                       0.167
```

| o que é enviado ou feito | unidade | da planilha | um exemplo deste curso |
|---|---|---|---|
| uma imagem para um modelo de chat | **tokens** de entrada, por uma regra de blocos | gpt-4o: US$ 2,50 por milhão | a capa em alto detalhe, 765 tokens: US$ 0,0019 |
| áudio para um modelo de chat | **tokens** de áudio | gemini-2.5-flash: US$ 1,00 por milhão | depende dos tokens por segundo do provedor |
| áudio para um modelo de transcrição | **segundos** | whisper-1: US$ 0,0001 por segundo | a ligação de 55,38 segundos: US$ 0,0055 |
| texto para um modelo de fala | **caracteres** | tts-1: US$ 0,000015 por caractere | uma resposta de 1.000 caracteres: US$ 0,015 |
| uma imagem gerada | por **imagem**, ou tokens de imagem | gpt-image-1 high, 1024 por 1024: US$ 0,167 | a conta da aula 9 |

Duas coisas saem dessa tabela.

**O tamanho do arquivo não está em nenhuma das unidades.** Uma transcrição é cobrada pelos segundos, cheguem eles como um WAV de 1,7 MB ou um Opus de 120 KB; uma imagem é cobrada pelos tokens, que vêm da largura e da altura depois que o provedor a redimensiona, não dos bytes. Bytes importam para os limites e para o tempo de um pedido, e as próximas seções medem os dois, mas não são o que a conta conta.

**Cada unidade precisa da própria estimativa.** Um orçamento escrito como "tokens por usuário" não cobre um modelo de fala cobrado por caractere nem uma transcrição cobrada por segundo. A planilha é o lugar para ler todas as unidades num só formato, e a aula 6 de `ai-models` já disse o que ela não é: uma conta. Preços mudam, e a página de uso do próprio provedor é contra o que uma loja confere.
