---
title: O laboratório, e três jeitos de rodá-lo
version: 1
---

**Um pipeline só se entende rodando, e rodando de novo amanhã.** Por isso este curso não entrega uma
máquina pronta. Você monta uma, no seu próprio computador, e cada comando de cada lição é digitado
lá.

O laboratório é uma máquina Linux com isto:

- **PostgreSQL 16**, com três bancos: `shop`, o banco operacional onde os caixas e o site escrevem;
  `wh`, o warehouse que os seus pipelines vão encher; e `airflow`, onde o Airflow guarda os próprios
  registros a partir da lição 8.
- **Python 3.13**, com um ambiente virtual por ferramenta. Airflow, dbt, Prefect e Dagster fixam
  cada um as suas versões das mesmas bibliotecas, e num ambiente só eles brigariam.
- **Os dados da loja**, três meses de vendas sorteados por um gerador com sementes fixas, para os
  seus números serem os que estão impressos aqui.
- **Uma pequena API de preços**, escrita na lição 3, que pagina as respostas, limita a velocidade
  das perguntas e que dá para fazer falhar de propósito.

**Tudo isso vem de quatro arquivos que esta lição mostra inteiros**, e que você salva num diretório
chamado `~/pontofinal`: dois scripts na próxima seção, e o banco da loja e os seus dados na seção
seguinte. Um dos scripts monta tudo; a seção depois dessas diz como rodá-lo.

## Três jeitos de rodá-lo

**Numa máquina virtual — o recomendado.** Uma máquina virtual Ubuntu 24.04 com 4 GB de memória e
10 GB de disco livre. A partir da lição 8 o Airflow roda quatro processos ao mesmo tempo, e na
máquina da gravação eles ocupavam cerca de 1,4 GB de memória juntos antes de qualquer DAG rodar. A
montagem acrescenta um usuário, um servidor de banco e seis ambientes Python, que é exatamente o
tipo de mudança que você não quer no computador onde trabalha. A lição 4 de `virtualization` monta
uma no VirtualBox, se você ainda não tem.

**Instalado no seu próprio computador Linux.** Os mesmos passos, no próprio computador. Tudo vai
para `/opt/etl`, `/var/lib/etl-*` e um usuário chamado `ana`, então fica separado dos seus
arquivos, mas a máquina muda, e tirar tudo depois é trabalho seu, à mão. É o caminho que mais
ensina e o que mais quebra.

**Em containers, só para as ferramentas.** O Airflow publica uma imagem de container oficial e um
arquivo Compose, e o dbt roda em qualquer imagem de Python. Isso dá o software, mas não este
laboratório — a loja, os dados e o relógio dia a dia estão nos quatro arquivos — e o curso não foi
gravado assim. Fica citado aqui para o aluno que já trabalha com containers e quer levar as lições
para esse ambiente.

## Antes dos arquivos

No Ubuntu 24.04, primeiro os pacotes. O Python do próprio Ubuntu 24.04 é o 3.12, e o curso foi
gravado no 3.13, que o PPA deadsnakes oferece:

```sh
sudo add-apt-repository -y ppa:deadsnakes/ppa
sudo apt-get install -y python3.13-venv postgresql-16 make git curl
```

Depois, o usuário. **Toda transcrição deste curso é da `ana`, numa máquina chamada `vm`**, então
criar o mesmo usuário faz todo caminho nelas ser seu também. Ela precisa de `sudo`, porque o
`shop`, o comando que a próxima seção instala, roda como root:

```sh
sudo adduser ana
sudo usermod -aG sudo ana
sudo -iu ana
mkdir ~/pontofinal
```

Esses comandos não foram capturados: a máquina da gravação já tinha os pacotes e o usuário. Daqui
em diante todo comando é da `ana`, e toda transcrição é uma captura.
