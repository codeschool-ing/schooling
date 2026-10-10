---
title: O laboratório é o seu próprio computador
version: 1
---

Nada neste curso roda numa máquina nossa. **Você monta o laboratório no seu próprio computador, e
todo comando de toda lição é digitado lá.** Ele é pequeno: um ambiente Python com as bibliotecas que
o curso fixa, um diretório para o projeto e um arquivo SQLite com a loja. Nenhum servidor de banco
de dados, nenhum contêiner e nenhuma conta em lugar nenhum.

Toda transcrição do curso foi gravada assim, num Ubuntu 24.04 com quatro núcleos de processador e sem
placa de vídeo, por uma usuária chamada `ana` numa máquina chamada `dev`. O seu prompt vai trazer os
seus nomes. O projeto fica em `~/ml` e o ambiente em `~/mlenv`, e se você usar os mesmos dois
caminhos, todo comando do curso funciona como está impresso.

## Três formas de ter o laboratório

| | o que é | quanto custa ao seu computador |
| --- | --- | --- |
| **instalado** (recomendado) | Python 3.12 e as bibliotecas do curso no computador que você usa todo dia: direto no Linux, num Mac, ou no Windows dentro do WSL, a camada Linux da Microsoft | 1,0 GB de disco até a última lição, quase tudo no ambiente em `~/mlenv`; o maior programa do curso, a página do MLflow, ocupa uns 480 MB de memória enquanto roda, iniciada do jeito que a lição 7 a inicia |
| numa máquina virtual | Ubuntu Server 24.04 LTS no VirtualBox, no Windows ou no Linux, ou no UTM num Mac, com os mesmos passos lá dentro | a parte da própria VM, reservada enquanto ela roda: 2 núcleos de processador, 4 GB de memória e 25 GB de disco |
| online | uma máquina Linux que outra pessoa mantém: um ambiente de desenvolvimento na nuvem como o GitHub Codespaces, ou um servidor pequeno alugado por hora | nada no seu computador além de um navegador; uma conta no provedor, e os termos dele sobre quantas horas são gratuitas |

**Instalado é a recomendação porque o laboratório é leve e não se espalha.** Tudo o que o curso
instala vai para dois diretórios na sua pasta pessoal, `~/mlenv` e `~/ml`, e apagá-los remove tudo;
os únicos pacotes do sistema são três que o Ubuntu já oferece. Nada aqui quer placa de vídeo, serviço
que sobe com o sistema ou porta aberta para a rede.

**Uma máquina virtual é o caminho se você prefere não mexer no seu sistema**, ou se o seu computador
roda algo velho demais para o Python 3.12 instalar. Dê a ela pelo menos os tamanhos da tabela. Os
passos da próxima seção rodam então dentro da VM, exatamente como estão escritos.

**Online funciona para o curso inteiro, com uma diferença que você vai notar.** As lições 7 e 8
iniciam dois programas que respondem numa porta da máquina, a página do MLflow e o serviço web do
modelo, e os leem num navegador. No seu computador esse endereço é `127.0.0.1`; numa máquina que
outra pessoa mantém, o provedor encaminha a porta para um link próprio, e a documentação dele diz
como. **Nenhuma lição depende da cota gratuita de um provedor**: pode existir uma quando você ler
isto, e ela é do provedor para mudar.

## O que você já precisa saber

Este curso pressupõe `python` e `pipelines-etl`. Você vai ler programas Python de cinquenta a cem
linhas, rodá-los e mudar uma linha aqui e ali; vai ler SQL com um `WITH` e um `GROUP BY`. Ninguém vai
pedir que você deduza nada, e nada exige mais matemática do que uma porcentagem e uma média.
