---
title: Mojibake: texto lido na codificação errada
version: 1
---

**Mojibake é a cara de um texto depois que os seus bytes foram decodificados com a codificação errada
e o resultado foi salvo.** A palavra japonesa quer dizer "transformação de caracteres", e é o único
defeito de texto deste curso que destrói informação se tratado sem cuidado — e a recupera por
completo se tratado com cuidado.

A migração de 2023 da Quitanda Verde leu texto UTF-8 como Latin-1. Em UTF-8, `ã` são dois bytes,
`0xC3 0xA3`. Lidos como Latin-1, em que cada byte é um caractere sozinho, esses dois bytes viram dois
caracteres: `0xC3` é `Ã` e `0xA3` é `£`. A migração salvou `SÃ£o Paulo`, em UTF-8 perfeitamente
válido, e todo sistema desde então guardou o estrago fielmente.

```
ana@lab:~/clean$ python -c "from cities import city; bad = city[city.str.contains('Ã')]; print(bad.value_counts().to_string()); print(bad.iloc[0].encode('latin-1').decode('utf-8'))"
city
SÃ£o Paulo    9
sÃ£o paulo    1
São Paulo
```

O reparo roda o erro de trás para a frente: **codificar o texto como Latin-1 para recuperar os bytes
originais, e então decodificar esses bytes como UTF-8**, como deveriam ter sido lidos desde o início.
A última linha acima é o resultado: `São Paulo`, exato.

A mesma migração atingiu nomes também:

```
ana@lab:~/clean$ python -c "from cities import customers as c; bad = c[c['name'].str.contains('Ã')]['name']; print(len(bad)); print(bad.head(3).to_string(index=False))"
43
              DÃ©bora Souza
             AndrÃ© Correia
PatrÃ­cia GuimarÃ£es Vieira
```

43 clientes têm o nome estragado: `DÃ©bora`, `AndrÃ©`, `GuimarÃ£es`. Essa é a coluna que nunca deve
ser reescrita por um palpite, e aqui o reparo não é palpite: os bytes são recuperados, não
inferidos.

## Reparar só o que está estragado

Rodar o reparo num texto que não é mojibake o quebra: `São` codificado como Latin-1 vira um único byte
`0xE3`, que não é UTF-8 válido, e a decodificação falha — ou, com erros ignorados, descarta a letra em
silêncio. Por isso o reparo se aplica **só aos valores que mostram a assinatura**, como `fix_mojibake`
faz com o seu teste de `Ã`. Esse teste basta para texto em português, em que `Ã` quase nunca começa
uma palavra no meio de uma linha; para outras línguas, a ferramenta é a biblioteca `ftfy`, que
reconhece as assinaturas de muitas codificações. Ela não está instalada neste laboratório, e não foi
executada.
