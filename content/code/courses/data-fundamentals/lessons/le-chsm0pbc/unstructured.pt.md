---
title: Dado não estruturado, e o dado estruturado em volta dele
version: 1
---

**Dado não estruturado não tem nome de campo nenhum: o significado está no conteúdo, e uma pessoa ou um
programa precisa interpretar o conteúdo para tirá-lo de lá.** Texto escrito por gente, fotografias,
áudio e vídeo são os casos de sempre. Na Roda Livre, isso é a caixa de entrada do suporte, as fotos que
os clientes anexam de uma bicicleta danificada, e as gravações das ligações para a central de ajuda.

O nome engana de um jeito que vale corrigir cedo. Um e-mail não é livre de estrutura. Ele chega com um
remetente, uma hora, um assunto, uma lista de anexos com seus tamanhos, e tudo isso são campos com nome.
**O que é não estruturado é o corpo**, a parte que uma pessoa escreveu. O mesmo vale para uma
fotografia, cujo arquivo traz a hora em que foi tirada e as configurações da câmera ao lado de milhões
de pixels que dizem "uma roda torta" para uma pessoa e nada para uma consulta.

Por isso o dado não estruturado quase sempre é guardado em duas partes:

- o objeto em si, guardado como veio, byte a byte: o corpo do e-mail, o `.jpg`, o `.m4a`;
- os metadados sobre ele, como linhas estruturadas comuns: qual cliente, quando, quantos anexos, onde
  o objeto está guardado.

Os metadados são o que se consulta. "Quantas reclamações chegaram na segunda, e de quantos clientes"
precisa só dos metadados. "Que estação as reclamações citam" precisa do corpo, e é aí que está o
trabalho.

## Tirando uma estação do texto

Marta quer as reclamações contadas por estação. A estação está em algum lugar nas palavras, se estiver
em algum lugar. O programa mais simples que tenta é um padrão feito dos doze nomes de estação, procurado
em cada e-mail. Salve isto como `emails.py`:

```python
# shapes/emails.py
import re

STATIONS = {
    'ST01': 'Praça Tiradentes', 'ST02': 'Rua XV', 'ST03': 'Jardim Botânico',
    'ST04': 'Passeio Público', 'ST05': 'Rodoferroviária', 'ST06': 'Largo da Ordem',
    'ST07': 'Shopping Estação', 'ST08': 'Parque Barigui', 'ST09': 'UFPR Politécnico',
    'ST10': 'Batel', 'ST11': 'Mercado Municipal', 'ST12': 'Ópera de Arame',
}
EMAILS = [  # id, received, customer, attachments, body
    ('M01', '2025-09-15 08:12', 'C0042', ['dock.jpg'],
     'The dock at Rua XV would not release my bike, I was late for work.'),
    ('M02', '2025-09-15 09:40', 'C0107', [],
     'Charged twice for one ride from Largo da Ordem to Jardim Botânico.'),
    ('M03', '2025-09-15 11:05', 'C0042', ['tyre.jpg', 'frame.jpg'],
     'Flat tyre on a bike at the Botanical Garden station, photos attached.'),
    ('M04', '2025-09-15 13:30', 'C0311', [],
     'No bikes at all at Rua 15 again this morning!!'),
    ('M05', '2025-09-15 17:52', 'C0019', [],
     'I live in Batel and the app keeps asking for my location.'),
    ('M06', '2025-09-15 19:20', 'C0256', ['call.m4a'],
     'Left a voice message about the station near the Opera de Arame.'),
]
NAMES = {name: code for code, name in STATIONS.items()}
PATTERN = re.compile('|'.join(re.escape(name) for name in NAMES))

print(f'{"id":4}{"received":18}{"customer":10}{"files":7}stations')
for mid, received, customer, files, body in EMAILS:
    found = ' '.join(NAMES[name] for name in PATTERN.findall(body))
    print(f'{mid:4}{received:18}{customer:10}{len(files):<7}{found or "-"}')
```

Os seis e-mails estão colados dentro do programa do jeito que a caixa de suporte poderia exportá-los,
cada um com os metadados primeiro e o corpo por último. Os corpos estão em inglês, como o resto do
programa. Rode:

```
ana@lab:~/roda/shapes$ python emails.py
id  received          customer  files  stations
M01 2025-09-15 08:12  C0042     1      ST02
M02 2025-09-15 09:40  C0107     0      ST06 ST03
M03 2025-09-15 11:05  C0042     2      -
M04 2025-09-15 13:30  C0311     0      -
M05 2025-09-15 17:52  C0019     0      ST10
M06 2025-09-15 19:20  C0256     1      -
```

As colunas de metadados saíram perfeitas, porque nunca estiveram em dúvida. A última coluna é a
interessante. Leia-a contra os seis corpos acima:

- M01 e M02 estão certos. Os nomes foram escritos exatamente como a lista de estações os grafa;
- M03, M04 e M06 não acharam nada, e cada um cita sim uma estação. O cliente escreveu "the Botanical
  Garden", que é o nome do Jardim Botânico em inglês. "Rua 15" é como muita gente em Curitiba escreve Rua XV.
  "Opera de Arame" perdeu o acento, e o padrão compara caracteres, não intenções;
- M05 achou a coisa errada. Batel é uma estação, e também um bairro, e o cliente mora lá. A
  reclamação é sobre o aplicativo pedindo a localização, não sobre uma estação.

Dois certos em seis, três perdidos e um errado, em seis e-mails escritos para ser fáceis. **Um padrão
acha as grafias em que você pensou, e as grafias em que você não pensou são as que os clientes usam.**
Acrescentar `Rua 15` e o nome em inglês ao padrão resolve dois dos três perdidos, e na semana que vem
alguém escreve "Rodoviária".

## Como é uma extração melhor, e do que ela ainda precisa

Existem ferramentas melhores, e vale reconhecer os nomes: um modelo de linguagem a quem se pede a
estação citada numa mensagem, reconhecimento óptico de caracteres para texto dentro de uma imagem,
conversão de fala em texto para uma gravação, um classificador de imagens que diz "pneu furado". Cada
uma transforma conteúdo não estruturado num campo estruturado, e cada uma erra parte das vezes, de
jeitos que um padrão não erra. Nenhuma delas é ensinada aqui.

Dois hábitos valem qualquer que seja a ferramenta. **Guarde o objeto original.** O `ST03` extraído é um
valor derivado, feito por uma versão de um programa, e quando chegar um extrator melhor é sobre os
originais que ele vai rodar. E **guarde o campo extraído junto com a origem dele**: qual programa o fez,
e quando. Uma coluna de estação que mistura valores digitados pela equipe com valores adivinhados por
um padrão é uma coluna em que ninguém consegue confiar, porque ninguém consegue saber qual é qual.
