---
title: O Whisper e os modelos depois dele
version: 2
---

O título desta aula é **Whisper API**, e o `whisper-1` ainda é um dos nomes que o endpoint aceita. Agora ele tem companhia. A tabela do LiteLLM, lida com o `prices.py` da aula 3, lista os modelos de transcrição assim:

```
ana@lab:~/mm$ python prices.py find transcribe | grep " openai "
gpt-4o-mini-transcribe                       openai                     2027-02-26
gpt-4o-mini-transcribe-2025-03-20            openai                     2027-01-20
gpt-4o-mini-transcribe-2025-12-15            openai                     
gpt-4o-transcribe                            openai                     2027-02-26
gpt-4o-transcribe-diarize                    openai                     2027-02-26
gpt-live-transcribe                          openai                     
gpt-transcribe                               openai                     
ana@lab:~/mm$ for m in whisper-1 gpt-4o-transcribe gpt-4o-mini-transcribe; do printf "%-24s" $m; python prices.py show $m | grep -E "input_cost_per_second|input_cost_per_token|deprecation" | tr -s " " | tr "\n" " "; echo; done
whisper-1               deprecation_date 2027-02-26 input_cost_per_second 0.0001 
gpt-4o-transcribe       deprecation_date 2027-02-26 input_cost_per_second 0.0001 input_cost_per_token 2.5e-06 
gpt-4o-mini-transcribe  deprecation_date 2027-02-26 input_cost_per_second 5e-05 input_cost_per_token 1.25e-06 
```

A tabela tem sete entradas da OpenAI com *transcribe* no nome. Duas são versões datadas do modelo mini, e uma delas acaba antes do nome sem data, em 20 de janeiro de 2027. O `gpt-transcribe` e o `gpt-live-transcribe` não têm data de descontinuação nenhuma.

**O `whisper-1` é cobrado por segundo de áudio**, 0,0001 dólar, que dá 0,006 dólar por minuto e 0,36 dólar por hora. Os dois modelos de transcrição `gpt-4o` são cobrados por token: 2,5e-06 dólar por token de entrada no `gpt-4o-transcribe`, que dá 2,50 dólares por milhão, e metade disso no mini. A tabela também lhes dá um valor por segundo, o mesmo 0,0001 para o `gpt-4o-transcribe` e metade disso para o mini. **Os três trazem data de descontinuação em 26 de fevereiro de 2027.** Nenhum deles foi chamado para este curso, porque isso exige uma chave paga, e a aula 13 transforma esses preços no custo de um mês de ligações de suporte.

O que muda ao passar do `whisper-1` para os modelos mais novos, segundo a documentação da OpenAI, vale conferir contra o seu próprio conjunto de teste em vez de aceitar de confiança:

- **Precisão**: a OpenAI informa taxas de erro menores para os modelos mais novos; o conjunto de teste da aula 7 é como você descobre isso nas suas ligações.
- **Formatos de resposta**: a documentação não lista `srt`, `vtt` nem `verbose_json` para os modelos mais novos (seção 03), então um processo que precisa de segmentos com tempo teria de obtê-los de outro jeito.
- **Streaming**: os modelos mais novos conseguem passar o texto adiante enquanto decodificam, o que importa para legendas ao vivo e agentes de voz (a latência da aula 6).

Os mesmos hábitos da aula 9 valem: cite o modelo num lugar só, leia as datas de descontinuação todo trimestre, e rode o conjunto de teste de novo antes de trocar. Um transcritor melhor na média e pior nos nomes da sua loja é pior para você (aula 7).
