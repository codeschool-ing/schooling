---
title: O Helicone, e o gateway que você já tem
version: 2
---

O Helicone é de código aberto, e os autores publicam uma imagem que roda tudo dele num contêiner só: o
gateway e a API dele, as telas, PostgreSQL, ClickHouse e MinIO. **Este curso não o roda.** A imagem é
um download de 3,5 GB, e várias vezes isso depois de descompactada, mais disco que todo o resto do curso
junto, para ver um proxy repassar pedidos. O que um gateway vê pode ser mostrado com muito menos, porque
você já tem um.

O `flaky.py` da aula 4 fica entre os programas e o Ollama e repassa todo pedido, e escreve cada um que
repassa no `flaky.log`. Sem ninguém mandá-lo falhar, ele é um gateway que só registra. Inicie-o em
segundo plano, a partir de `~/obs`, e mande uma pergunta por ele apontando o SDK para a porta dele em vez
da do Ollama:

```sh
python flaky.py &
```

```
ana@dev:~/obs$ OPENAI_BASE_URL=http://127.0.0.1:11435/v1 python assistant.py "How long is a gift card valid?"
According to [1], a gift card is valid for two years from the day it was bought.
trace f8a3280bafe8212c496c197fd05c6bd3
ana@dev:~/obs$ cat flaky.log
{"n": 1, "path": "/v1/embeddings", "status": 200}
{"n": 2, "path": "/v1/chat/completions", "status": 200}
ana@dev:~/obs$ python tree.py f8a3280b
trace f8a3280bafe8212c496c197fd05c6bd3   start(ms) took(ms)
      0   2,536 ms  ask
      0      46 ms    embed
     46       0 ms    search
     47   2,489 ms    generate
     47   2,489 ms      chat llama3.2:3b
  2,536       0 ms    check_citations
```

Duas linhas, um embedding e um chat completion: tudo o que passou pelo fio. O `flaky.py` escreve só o
caminho e o status, e um gateway de verdade guarda os corpos também, então teria a pergunta no primeiro
e o prompt e a resposta no segundo. O que nenhum gateway pode ter está nas linhas do `tree.py` entre
eles: a busca, com a pontuação que decidiu quais trechos entraram no prompt, e a verificação de
citações. Nem sabe quem perguntou. Sem cabeçalhos, as duas chamadas não levam usuário, sessão nem
funcionalidade.

## O que o Helicone acrescenta a isso

A mesma posição, com o trabalho feito: cada pedido guardado com os tokens, o custo e a latência como o
fornecedor informou, telas para lê-los por usuário e por propriedade, e cabeçalhos que dizem o que o
gateway não consegue descobrir sozinho. Um programa manda `Helicone-User-Id` para o usuário,
`Helicone-Session-Id` para chamadas que andam juntas, e `Helicone-Property-<Nome>` para qualquer coisa
pela qual filtrar, a funcionalidade por exemplo, e troca a URL base pela do gateway. Nada mais no
programa muda.

Um gateway tem uma configuração que vale procurar antes de qualquer outra. Um que repassasse para
qualquer endereço citado num cabeçalho seria um relé aberto: qualquer um capaz de alcançá-lo poderia
fazê-lo chamar qualquer máquina que ele alcança, inclusive os serviços internos atrás dele, o ataque
chamado **server-side request forgery** (SSRF). Um gateway que vale a pena rodar só repassa para os
fornecedores que lhe foram informados, e um servidor de modelos na sua própria rede é mais um endereço
que alguém acrescenta a essa lista de propósito.

## O que não foi rodado

Nem o Helicone hospedado, onde a maioria das equipes o usa, nem a imagem auto-hospedada. O que a
documentação descreve e este curso não verificou: os painéis de pedidos, custo e latência por usuário e
por propriedade; o cache e os limites de taxa configurados por cabeçalhos; e as sessões que agrupam uma
cadeia de chamadas. Cada um é a versão de gateway de algo que as aulas 3 a 5 construíram a partir de
spans, e a comparação que importa é a da última seção, não uma lista de funcionalidades.
