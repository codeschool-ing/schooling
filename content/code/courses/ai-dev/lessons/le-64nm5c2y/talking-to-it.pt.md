---
title: Falando com o servidor a partir do Python
version: 1
---

O host da aula 7 seção 03 e todo assistente que suporta MCP fazem as mesmas três coisas como
cliente: iniciar o servidor ou se conectar a ele, listar as ferramentas, chamá-las. O `Client` do SDK
faz o aperto de mão da aula 7 seção 05 por você:

```python
import asyncio
import sys

from mcp import Client, StdioServerParameters


async def main():
    async with Client(StdioServerParameters(command="python", args=["mcp_shop.py"])) as shop:
        if len(sys.argv) < 3:
            for t in (await shop.list_tools()).tools:
                ro = t.annotations.read_only_hint if t.annotations else None
                print(f"{t.name:14} read-only={ro!s:5}  {t.description}")
        else:
            result = await shop.call_tool(sys.argv[1], {"name": sys.argv[2]})
            print("is_error:", result.is_error, "|", result.content[0].text[:90])


asyncio.run(main())
```

```
ana@dev:~/shop$ python scratch/tools.py
get_order      read-only=True   Look up an order by its number: status, dates, lines and shipping, in cents.
read_handbook  read-only=True   Read one page of the support handbook, such as 'returns' or 'shipping'.
issue_refund   read-only=False  Refund part or all of an order to the customer's original payment method.
```

Três ferramentas, e a anotação que mais importa para a próxima seção: duas dizem que só leem, uma diz
que não. O host lê o `read_only_hint` daqui e decide que chamadas precisam de uma pessoa.

## Uma dica não é uma garantia

O `readOnlyHint` é **a descrição que o servidor faz de si mesmo**. Num servidor que você escreveu,
como este, dá para confiar que ele se descreve direito, porque você consegue lê-lo. Um servidor de
outro lugar é diferente: um descuidado ou hostil pode dizer que uma ferramenta só lê e fazê-la fazer
qualquer coisa. A especificação do MCP diz isso mesmo, e trata as anotações como dicas em que um host
não deve se apoiar para segurança a menos que confie no servidor.

Então a pergunta antes de instalar um servidor é a mesma de antes de instalar qualquer programa: quem
o escreveu, o que ele alcança, e você confia nas duas respostas. As permissões da aula 7 seção 08 são
escritas contra essa pergunta.
