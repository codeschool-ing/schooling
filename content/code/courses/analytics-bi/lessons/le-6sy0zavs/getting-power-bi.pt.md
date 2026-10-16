---
title: Obtendo o Power BI Desktop, e três jeitos de tê-lo
version: 1
---

O Power BI Desktop é gratuito, e é um programa Windows. O caminho depende do computador que você tem.

## Num computador Windows — o caminho recomendado

Instale pela **Microsoft Store**: procure *Power BI Desktop*. A versão da Store se atualiza sozinha
todo mês, o que importa num produto que muda com essa frequência. A Microsoft também oferece um
instalador avulso no centro de downloads; ele faz o mesmo trabalho e não se atualiza sozinho.

Ele roda no computador Windows, enquanto o banco da Lantern roda dentro da máquina virtual da aula 1.
A ponte mais simples entre os dois é um conjunto de arquivos, que a próxima seção exporta.

## Numa máquina virtual Windows, num Mac ou no Linux

Não existe Power BI Desktop para macOS nem para Linux. Uma máquina virtual Windows é o jeito de
rodá-lo: UTM no Apple silicon, VirtualBox nos outros, com Windows 11 dentro. Custa uma licença do
Windows, ou uma cópia de avaliação que expira, e memória: uma máquina Windows rodando o Power BI
quer vários gigabytes próprios além da máquina Ubuntu da aula 1, então num computador com 8 GB as
duas não rodam com conforto ao mesmo tempo. É o caminho mais caro do curso.

## Online, no serviço do Power BI

O serviço roda em qualquer navegador e abre relatórios que outras pessoas publicaram. Ele também
consegue montar alguns relatórios a partir de um modelo que já existe no serviço. O que ele não
substitui, no momento em que isto foi escrito, é o Desktop como o lugar onde um modelo é construído
pela primeira vez a partir de um banco. Ele exige uma conta de trabalho ou de escola; um e-mail
pessoal não é aceito.

## Se nenhum desses estiver ao seu alcance

Então esta aula é lida, e não feita. Nada mais adiante no curso depende do Power BI: a aula 5 segue
com Metabase e Streamlit, que rodam na máquina que você já tem. As ideias desta aula —
relacionamentos, contexto de filtro, medidas que mudam com a pergunta — reaparecem em toda
ferramenta de BI, e o SQL ao lado de cada fórmula é algo que você pode rodar hoje.

## Quando não funciona

- **A Store diz que o aplicativo não está disponível para o seu dispositivo.** O Power BI Desktop
  roda em Windows de 64 bits; computadores Windows com processador ARM são tratados pelas notas de
  compatibilidade da própria Microsoft, que mudam de uma versão para outra.
- **Ele abre e fecha, ou fica muito lento.** É memória. Feche outros programas, ou dê mais memória à
  máquina virtual Windows.
- **Os números chegam multiplicados por cem.** É um problema de idioma dos arquivos, e a próxima
  seção diz como evitar.
