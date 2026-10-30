---
title: A tabela de preços, e por que este curso não conseguiu lê-la
version: 1
---

**O Azure publica todo preço que cobra, para toda região, por uma interface pública que não pede
conta nem chave**: a Retail Prices API, em `https://prices.azure.com/api/retail/prices`. Ela responde
a um filtro com páginas de JSON, um item por medidor, e cada item traz o serviço, a região, o produto,
a unidade, o preço em dólares americanos e a data em que o preço passou a valer. Um medidor é a coisa
que o Azure conta: gigabytes guardados numa camada por um mês, dez mil operações de escrita, um
gigabyte enviado para a internet.

O programa abaixo é a tabela de preços do curso. Ele pede um serviço em `brazilsouth`, guarda as
respostas num arquivo para que uma segunda execução não pergunte nada a ninguém, e imprime uma linha
por medidor:

```schooling-example
{"language": "python", "file": "prices.py", "parts": [
{"code": "import json, pathlib, sys, urllib.parse, urllib.request\n\nAPI = \"https://prices.azure.com/api/retail/prices\"\nREGION = \"brazilsouth\"\nCACHE = pathlib.Path(\"prices-cache\")\n", "note": "Sem chave e sem login: a Retail Prices API é pública. O cache é um diretório de arquivos JSON, um por serviço, para que a tabela possa ser impressa de novo sem rede."},
{"code": "\ndef fetch(service):\n    cached = CACHE / f\"{service}.json\"\n    if cached.exists():\n        return json.loads(cached.read_text())\n    query = f\"serviceName eq '{service}' and armRegionName eq '{REGION}' and priceType eq 'Consumption'\"\n    url = API + \"?\" + urllib.parse.urlencode({\"$filter\": query})\n    items = []\n    while url:\n        with urllib.request.urlopen(url, timeout=30) as answer:\n            page = json.load(answer)\n        items += page[\"Items\"]\n        url = page.get(\"NextPageLink\")\n    CACHE.mkdir(exist_ok=True)\n    cached.write_text(json.dumps(items))\n    return items\n", "note": "O filtro é OData, a linguagem de consulta da API. `priceType eq 'Consumption'` deixa de fora as reservas, que são um desconto em troca de um compromisso e assunto do `azure-foundations`. Um serviço pode ter milhares de medidores espalhados por muitas páginas, e o `NextPageLink` é como a API diz que há mais."},
{"code": "\ndef sheet(service, words):\n    rows = [i for i in fetch(service)\n            if all(w.lower() in (i[\"productName\"] + \" \" + i[\"meterName\"]).lower() for w in words)]\n    for i in sorted(rows, key=lambda i: (i[\"productName\"], i[\"meterName\"])):\n        print(f\"{i['productName'][:34]:34} {i['meterName'][:30]:30} \"\n              f\"{i['retailPrice']:>12.6f} {i['unitOfMeasure']:>10}  {i['effectiveStartDate'][:10]}\")\n\n\nif __name__ == \"__main__\":\n    sheet(sys.argv[1], sys.argv[2:])\n", "note": "As palavras depois do serviço estreitam a lista, então `python prices.py Storage Hot LRS` imprime a camada Hot com redundância local e não as outras milhares de linhas. A última coluna é a data em que o preço passou a valer, que é a data com que se deve citá-lo."}
]}
```

## Por que não há transcrição embaixo dele

**Este programa não foi executado quando o curso foi gravado.** A máquina de onde vem cada transcrição
deste curso chega à internet por um proxy que só deixa passar os endereços que o dono dela listou, e
`prices.azure.com` não era um deles em 30 de outubro de 2026. O programa aparece porque é assim que
você obtém os preços de hoje, e foi escrito contra o formato de resposta que a Microsoft documenta. O
que o curso não consegue mostrar é a resposta em si: se a primeira execução no seu computador falhar,
o erro é real e este curso nunca o encontrou.

Então **este curso não cita nenhum preço do Azure como sendo do Azure.** Onde uma lição precisa de um
número para fazer conta, ela escreve um número redondo e avisa: *"a um preço ilustrativo de 0,02 USD
por GB-mês"* é uma instrução para fazer a soma com esse número, não uma afirmação sobre o que o Azure
cobra. Rode a tabela, leia o preço real e faça a mesma soma com ele. O formato da conta é o que dura.
Os preços mudam a cada poucos meses; os fatos em que as lições se apoiam (os dias mínimos de uma
camada, quais operações são cobradas, quais transferências são gratuitas) mudam raramente, e as
lições os tiram da documentação da Microsoft e dizem isso.

## Rodar você mesmo

Em `~/azure`, com rede:

```sh
python prices.py Storage Hot LRS
```

A primeira execução leva um minuto, porque só o Storage tem milhares de medidores numa região. A
saída é uma linha por medidor, com o preço, a unidade e a data. **Leia a unidade antes do preço.**
Uma linha de armazenamento tem preço por `1 GB/Month`, e uma linha de operações por `10K`, dez mil
operações. O erro mais comum com uma fatura do Azure é multiplicar uma contagem de operações por um
preço que vale para dez mil delas.
