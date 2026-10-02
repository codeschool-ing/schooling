---
title: Chaves ficam fora do código
version: 1
---

Uma chave de API é uma senha que gasta dinheiro. **Quem a tem consegue fazer requisições na sua
conta**, até os seus limites, e a conta chega para você. Todo SDK deste curso lê a chave do
ambiente, que é onde ela deve ficar.

## Onde as chaves estão

```
ana@dev:~/shop$ env | grep _API_KEY | cut -d= -f1
ANTHROPIC_API_KEY
GEMINI_API_KEY
OPENAI_API_KEY
```

Três variáveis, uma por provedor, definidas pelo laboratório. Os SDKs leem `ANTHROPIC_API_KEY`,
`OPENAI_API_KEY` e `GEMINI_API_KEY` sem ninguém mandar, então o código desta aula nunca menciona uma
chave. **Uma chave escrita num arquivo-fonte é uma chave em toda cópia desse arquivo**: no
repositório, no histórico dele, em todo fork, e no que quer que um assistente leia do projeto, como
a aula 3 mostrou.

## Sem chave, e com a chave errada

```
ana@dev:~/shop$ env -u ANTHROPIC_API_KEY python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=10, messages=[{"role": "user", "content": "hi"}])' 2>&1 | tail -n 1
TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
ana@dev:~/shop$ ANTHROPIC_API_KEY=lab-anthropic-key-9999 python -c 'import anthropic; anthropic.Anthropic().messages.create(model="scripted-1", max_tokens=10, messages=[{"role": "user", "content": "hi"}])' 2>&1 | tail -n 1
anthropic.AuthenticationError: Error code: 401 - {'type': 'error', 'error': {'type': 'authentication_error', 'message': 'invalid x-api-key'}, 'request_id': 'req_lab_0004'}
```

**A primeira falha antes de qualquer requisição.** O SDK não achou chave e se recusou a montar a
requisição. A segunda fez a requisição com uma chave que o labllm não conhece, e o provedor
respondeu 401. As duas são barulhentas, o que é bom; o caso perigoso é uma chave que funciona e não
deveria estar ali.

## Mantendo uma chave local fora do git

Num notebook, as chaves costumam ficar num arquivo chamado `.env` que um script carrega. O arquivo
nunca pode ir para um commit:

```
ana@dev:~/shop$ printf '.env\n' > .gitignore; git check-ignore -v .env
.gitignore:1:.env	.env
```

O `git check-ignore -v` diz que regra ignora o arquivo, e que a regra existe antes do arquivo.
**Ponha a regra primeiro.** Um `.env` que foi para um commit uma vez fica no histórico mesmo depois
de apagado, e o único conserto é revogar a chave.

## O que fazer com chaves

- **Uma chave por ambiente e por aplicação.** Um vazamento então custa uma revogação, e a página de
  uso do provedor diz que aplicação gastou o quê.
- **Ponha um limite de gasto em cada chave** onde o provedor oferecer. Um limite transforma uma
  chave vazada de uma conta sem teto numa conta com teto.
- **Revogue na suspeita, não na prova.** Uma chave nova custa um deploy. Uma chave velha nas mãos
  erradas custa o que o limite dela permitir.
- **Em produção, um gerenciador de segredos**, não um arquivo no servidor. Ele registra quem leu a
  chave, e trocar a chave não exige editar cada máquina.
