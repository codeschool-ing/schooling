---
title: O computador em que você vai analisar
version: 1
---

**A maior parte deste curso é ler resultados e decidir o que eles querem dizer.** O resto é rodar
as análises que os produzem, e isso precisa de um lugar para rodar. Esta seção monta esse lugar no
seu computador, uma vez, e toda aula seguinte que roda um programa supõe que ele existe.

Você precisa do **Python 3.12 ou mais novo** com três pacotes:

- **pandas**, que lê os arquivos CSV e faz as contas com tabelas e datas;
- **statsmodels**, que traz os modelos de séries temporais e os testes estatísticos;
- **scikit-learn**, que traz o agrupamento e os modelos de aprendizado de máquina das aulas 15 a 19.

Instalar esses três traz numpy e scipy junto, e isso é tudo o que o curso roda.

::: track bi
Na sua trilha o `python` veio três cursos atrás, então a linguagem é conhecida e o pandas talvez
não seja. Tudo bem: cada programa deste curso aparece inteiro, com uma nota ao lado de cada parte
dizendo o que ela faz, e nada pede que você escreva pandas a partir de um arquivo em branco. Leia
as notas, rode o programa e gaste a sua atenção no que ele imprime.
:::

::: track data-science
Na sua trilha o `python-data` ensinou pandas, e o `machine-learning` usou scikit-learn logo antes
deste curso, então as ferramentas daqui você já tem na mão. O que é novo é o statsmodels e as
próprias análises. Os programas são curtos de propósito, e modificá-los é o melhor exercício que
este curso tem.
:::

::: track *
Se você já usou pandas, os programas vão se ler com facilidade. Se não usou, cada um aparece
inteiro com uma nota ao lado de cada parte, e nada pede que você escreva pandas a partir de um
arquivo em branco.
:::

## Três jeitos de ter um ambiente funcionando

| caminho | o que custa | quando escolher |
|---|---|---|
| **instalado no seu computador** (recomendado) | cerca de 420 MB de disco para os pacotes, mais o próprio Python | você tem um notebook ou desktop em que pode instalar programas |
| **numa máquina virtual** | 25 GB de disco e 4 GB de memória para uma máquina Ubuntu 24.04 no VirtualBox | o computador não é seu para mexer, ou você quer exatamente o sistema em que estas aulas foram gravadas |
| **online, num notebook hospedado** | nada para instalar; uma conta no provedor | você está num computador emprestado ou travado |

**O caminho recomendado é o primeiro.** Tudo abaixo foi digitado no Ubuntu 24.04, e no Windows e
no macOS os comandos mudam nos pequenos detalhes que o fim desta seção aponta.

O caminho da máquina virtual é a mesma instalação dentro de uma máquina só dela, em quatro passos:

1. instale o **VirtualBox**, de `virtualbox.org`, que é gratuito;
2. baixe a imagem do **Ubuntu 24.04 Desktop**, de `ubuntu.com`, um arquivo de cerca de 6 GB;
3. no VirtualBox, escolha *New*, aponte a imagem e dê à máquina 4 GB de memória e um disco de
   25 GB;
4. deixe o instalador terminar, entre, abra o *Terminal* e siga o resto desta seção dentro da
   máquina.

Se você quiser a versão longa, com o que cada configuração significa, a aula 4 do curso
`virtualization` é essa máquina montada com calma.

O caminho online é um notebook hospedado, como o Google Colab ou os notebooks do Kaggle, que já vêm
com pandas, statsmodels e scikit-learn instalados. Você cola cada programa numa célula em vez de
salvá-lo num arquivo, e sobe ou gera os arquivos CSV lá. Vêm dois avisos junto. As versões
instaladas lá são as do provedor, então um número pode diferir da aula nas últimas casas
decimais. E os termos também são do provedor: uma camada gratuita que existe hoje pode não existir
no ano que vem, e é por isso que nenhuma aula depende de uma.

## O Python e os três pacotes

Veja qual Python você tem. O Ubuntu 24.04 já traz o 3.12; no Windows e no macOS, instale-o de
`python.org`, e no Windows marque *Add python.exe to PATH* no instalador.

Crie uma pasta para o curso, abra um terminal nela e crie um **ambiente virtual**, uma cópia
particular do Python para esta pasta; depois instale os pacotes dentro dele:

```
ana@vm:~/bi$ python3 --version
Python 3.13.16
ana@vm:~/bi$ python3 -m venv .venv
ana@vm:~/bi$ .venv/bin/pip install --quiet pandas==3.0.6 statsmodels==0.15.0 scikit-learn==1.9.1
ana@vm:~/bi$ .venv/bin/python -c "import pandas, statsmodels, sklearn; print(pandas.__version__, statsmodels.__version__, sklearn.__version__)"
3.0.6 0.15.0 1.9.1
```

A máquina em que estas aulas foram gravadas tem o Python 3.13, e o 3.12 funciona igual.

**O `--quiet` esconde o progresso do pip, e silêncio quer dizer que deu certo.** O download tem
algumas centenas de megabytes, então leva um ou dois minutos. O último comando pergunta ao Python
novo quais versões ele tem, e esses três números são a resposta que importa. As versões estão
fixadas para que os seus resultados saiam como os da aula; uma versão mais nova funciona, e pode
imprimir um número diferente na última casa.

Duas coisas mudam fora do Linux:

- **No Windows**, os programas ficam em `.venv\Scripts\` e não em `.venv/bin/`, então você digita
  `.venv\Scripts\python` onde a aula digita `.venv/bin/python`.
- **No macOS**, os comandos são os mesmos. `python3 --version` diz se você está rodando o Python
  que instalou ou um mais antigo que veio com o sistema.

As aulas sempre chamam `.venv/bin/python` pelo caminho completo. Você talvez tenha aprendido a
*ativar* o ambiente, o que deixa você digitar só `python`; os dois funcionam, e o caminho completo
é o que foi gravado.
