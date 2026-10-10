---
title: O modelo não guarda credencial nenhuma, nunca
version: 1
---

Um dos quatro achados é típico de aplicações com LLM:

```
ana@lab:~/guard$ cat data/repo/prompts/support.txt
You are Tarefa's support assistant. Answer from the help centre.
When a refund is approved, call the payments API with the key
sk-lab-payments-00000000000000000000 and the job number.
```

A chave de pagamentos está no prompt de sistema, porque alguém quis que o modelo chamasse a API de
pagamentos e lhe deu o que ele precisaria. **Tudo o que está num prompt é texto que o modelo pode
repetir.** A aula 5 vigiou um canário nas respostas porque um prompt de sistema pode chegar a uma
resposta; uma chave no mesmo lugar chega a uma resposta do mesmo jeito. Ela também chega a cada cópia
de cada prompt: o log de chamadas da aula 11, os logs do próprio fornecedor nos termos que a aula 12
leu, e qualquer rastro que alguém imprima ao depurar.

A correção não é uma frase melhor no prompt pedindo ao modelo que guarde a chave para si. As aulas 14 e
15 mostraram quanto vale uma frase dessas. **A correção é o modelo nunca guardar credencial nenhuma.** A
aula 10 já desenhou o formato: o modelo propõe uma chamada, o portão decide, e a ferramenta roda com
credenciais próprias que o modelo nunca vê, nem no prompt, nem no resultado de uma ferramenta, nem numa
mensagem de erro. O prompt diz "você pode propor `issue_refund`"; a chave mora com o código que executa
o `issue_refund`.

## Para onde vai cada achado

| achado | onde a credencial deve ficar |
|---|---|
| `app/payments.py`, escrita no código | num cofre de segredos, lido pela ferramenta de reembolso ao iniciar, como o `config.py` lê a chave do fornecedor do ambiente |
| `prompts/support.txt`, no prompt | longe do modelo: a ferramenta a guarda, o prompt só nomeia a ferramenta |
| `deploy/.env`, uma senha num arquivo ao lado do código | no cofre de segredos da implantação, nunca no repositório; um `.env` é para a máquina de quem desenvolve e fica fora do controle de versão |
| `logs/2026-10-01.log`, uma chave num cabeçalho registrado | não é registrada; o logger descarta cabeçalhos de autorização antes de gravar, e a redação da aula 11 pega o que escapar |

A última linha merece uma segunda leitura. O cabeçalho da requisição que leva a chave do fornecedor é
exatamente o que um log de depuração imprime quando alguém registra "a requisição inteira". **O log é
um lugar aonde as credenciais vão para ser lidas por todo mundo que lê logs**, e esse é um grupo maior
e menos cuidadoso que o das pessoas que podem ler o cofre de segredos.

## Quanto custa uma chave vazada

Um achado que chegou ao repositório não se resolve apagando a linha. A chave está no histórico, em
cada clone e em cada cópia dos logs do build, então a única correção é **rotacioná-la**: emitir uma
chave nova, implantá-la e revogar a antiga, para que as cópias não abram nada. É por isso que rotacionar
precisa ser barato o bastante para ser feito numa tarde ruim, e a próxima seção trata de mantê-lo
assim.
