---
title: Chaves ficam fora do código
version: 2
---

Uma chave de API é uma senha que gasta dinheiro. **Quem a tem consegue fazer requisições na sua
conta**, até os seus limites, e a conta chega para você. Todo SDK deste curso lê a chave do
ambiente, que é onde ela deve ficar.

## Onde as chaves estão

```
ana@dev:~/shop$ env | grep _API_KEY | cut -d= -f1
ANTHROPIC_API_KEY
OPENAI_API_KEY
```

Duas variáveis, as que a aula 1 seção 03 definiu, as duas com a palavra `ollama`. Os SDKs leem
`ANTHROPIC_API_KEY`, `OPENAI_API_KEY` e, para o Google, `GEMINI_API_KEY` sem ninguém mandar, então o
código desta aula nunca menciona uma chave. **Uma chave escrita num arquivo-fonte é uma chave em toda cópia desse arquivo**: no
repositório, no histórico dele, em todo fork, e no que quer que um assistente leia do projeto, como
a aula 3 mostrou.

## Sem chave, e com a chave errada

```
ana@dev:~/shop$ env -u ANTHROPIC_API_KEY python -c 'import anthropic; anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=10, messages=[{"role": "user", "content": "hi"}])' 2>&1 | tail -n 1
TypeError: "Could not resolve authentication method. Expected one of api_key, auth_token, or credentials to be set. Or for one of the `X-Api-Key` or `Authorization` headers to be explicitly omitted"
ana@dev:~/shop$ ANTHROPIC_API_KEY=not-a-real-key python -c 'import anthropic; r = anthropic.Anthropic().messages.create(model="llama3.2:3b", max_tokens=10, messages=[{"role": "user", "content": "hi"}]); print(repr(r.content[0].text))'
'How can I assist you today?'
```

**A primeira falha antes de qualquer requisição.** O SDK não achou chave e se recusou a montar a
requisição. A segunda fez a requisição com uma chave que ninguém emitiu, e o Ollama respondeu: **o
Ollama não confere chaves**, e é por isso que a aula 1 pôde defini-las com uma palavra. Um provedor a
teria recusado com um 401, que o SDK da Anthropic lança como `AuthenticationError`. As duas recusas
são barulhentas, o que é bom; o caso perigoso é uma chave que funciona e não deveria estar ali.

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
