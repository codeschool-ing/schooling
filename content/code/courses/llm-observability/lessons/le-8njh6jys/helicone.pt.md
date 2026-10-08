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

CAPTURE:gateway

PROSE:gateway

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
