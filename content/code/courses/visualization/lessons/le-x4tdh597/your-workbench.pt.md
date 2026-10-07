---
title: O computador onde você vai desenhar
version: 1
---

**A maior parte deste curso é julgamento**: olhar para um gráfico e decidir o que ele diz, o que
esconde e o que diria melhor. Isso não precisa de programa nenhum. O resto é prática, e prática
precisa de um lugar para desenhar. Esta seção monta esse lugar no seu próprio computador, uma vez, e
toda aula seguinte que pedir um desenho supõe que ele existe.

Você precisa de duas coisas:

- **uma planilha** que desenhe gráficos: LibreOffice Calc, Microsoft Excel ou Google Planilhas;
- **Python com matplotlib**, a biblioteca de gráficos em que os exemplos do curso foram escritos.

::: track bi
Na sua trilha este curso vem depois de `excel-analytics`, e a planilha que você aprendeu lá desenha
todos os gráficos deste curso. Use-a primeiro. O Python chega mais tarde na sua trilha, num curso
próprio, então aqui você só **roda** os programas curtos que as aulas mostram, copiando-os. Você não
precisa entender cada linha deles para aprender o que o gráfico mostra, e cada um vem explicado ao
lado do código.
:::

::: track data-science
Na sua trilha `python` e `python-data` vieram antes deste curso, então o matplotlib vai parecer
familiar. Use-o primeiro. Mantenha uma planilha à mão também: metade dos gráficos que vão pedir que
você conserte no trabalho foi feita numa, e a aula 20 compara as duas.
:::

::: track *
Se você já programa, comece pelo Python. Se não programa, comece pela planilha e só rode os
programas que as aulas mostram, copiando-os. Todo gráfico do curso pode ser desenhado dos dois
jeitos.
:::

## Três jeitos de ter um ambiente funcionando

| caminho | quanto custa | quando escolher |
|---|---|---|
| **instalado no seu computador** (recomendado) | cerca de 1 GB de disco para LibreOffice e Python juntos | você tem um notebook ou desktop em que pode instalar programas |
| **numa máquina virtual** | 25 GB de disco e 4 GB de memória para um Ubuntu no VirtualBox | o computador não é seu para mudar, ou você quer exatamente o sistema em que as aulas foram gravadas |
| **online** | nada para instalar; precisa de uma conta Google | você está num computador emprestado ou bloqueado |

**O caminho recomendado é o primeiro.** As aulas foram gravadas no Ubuntu 24.04 e todo comando
abaixo é o que foi digitado lá. No Windows e no macOS os comandos mudam em detalhes que os próximos
parágrafos dizem.

O caminho online é o Google Planilhas para a planilha e o Google Colab para o Python, que já vem com
matplotlib instalado. Funciona para todas as aulas, e você só perde o hábito de rodar as coisas na
sua própria máquina.

## A planilha

Instale o **LibreOffice** pelo `libreoffice.org`, ou com `sudo apt install libreoffice-calc` no
Ubuntu. É gratuito e abre os arquivos CSV que o curso usa. Se você já tem o Excel, use-o; as aulas
dão o caminho dos menus nos dois onde ele difere.

## Python e matplotlib

Você precisa de **Python 3.12 ou mais novo**, porque a versão do numpy que o matplotlib instala hoje
recusa qualquer coisa mais antiga. No Ubuntu 24.04 ele já vem instalado. No Windows e no macOS,
instale pelo `python.org` e, no Windows, marque *Add python.exe to PATH* no instalador.

Crie uma pasta para o curso, ponha nela o arquivo `horta.py` da próxima seção e abra um terminal
ali. Depois crie um **ambiente virtual**, uma cópia particular do Python para essa pasta, e instale
o matplotlib nele:

```
ana@vm:~/viz$ python3 --version
Python 3.13.16
ana@vm:~/viz$ python3 -m venv .venv
ana@vm:~/viz$ .venv/bin/pip install --quiet matplotlib==3.11.2
ana@vm:~/viz$ .venv/bin/python -c "import matplotlib; print(matplotlib.__version__)"
3.11.2
```

A máquina em que estas aulas foram gravadas tem o Python 3.13; o Ubuntu 24.04 vem com o 3.12, e qualquer
um dos dois serve.

**`--quiet` esconde o progresso do pip, e silêncio quer dizer que deu certo.** A última linha
pergunta ao Python novo qual matplotlib ele tem, e `3.11.2` é a resposta que importa. A versão está
fixada para que os seus gráficos saiam como os das aulas; uma mais nova também funciona, com
pequenas diferenças no estilo padrão.

Duas coisas mudam fora do Linux:

- **No Windows**, os programas ficam em `.venv\Scripts\` em vez de `.venv/bin/`, então você digita
  `.venv\Scripts\python` onde as aulas digitam `.venv/bin/python`.
- **No macOS**, os comandos são os mesmos, mas o primeiro pode ser o `python3` do python.org em vez
  do mais antigo que vem com o sistema. `python3 --version` diz qual você tem.

As aulas sempre chamam `.venv/bin/python` pelo caminho completo. Talvez você tenha aprendido a
*ativar* o ambiente, o que muda o seu prompt e deixa você digitar só `python`; os dois jeitos
funcionam, e o caminho completo é o que foi gravado.
