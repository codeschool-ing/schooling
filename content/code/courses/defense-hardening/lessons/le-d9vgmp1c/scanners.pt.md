---
title: Scanners que entram, e scanners que adivinham
version: 1
---

**Um scanner de vulnerabilidades ou lê a máquina por dentro ou deduz por fora, e a diferença decide
quanto o relatório dele merece confiança.** O script da seção anterior é o primeiro tipo em miniatura.
O segundo tipo é o que um scanner faz quando não tem credenciais: conecta em cada porta aberta, lê o
que o serviço diz sobre si mesmo e compara com o que sabe.

A partir do `admin`, peça ao `nmap` que identifique os serviços do `web` do jeito que um scanner não
autenticado faz:

```
ana@admin:~$ nmap -sV -p 22,80 web | grep -E "^(PORT|[0-9])"
PORT   STATE SERVICE VERSION
22/tcp open  ssh     OpenSSH 9.6p1 Ubuntu 3ubuntu13.20 (Ubuntu Linux; protocol 2.0)
80/tcp open  http    nginx 1.24.0 (Ubuntu)
```

Ele nomeia cada programa e a versão a partir da primeira coisa que o serviço envia. Para o OpenSSH
isso inclui a revisão de empacotamento do Ubuntu, `3ubuntu13.20`, então aqui uma varredura de fora e
o banco de dados de pacotes concordam. Para o nginx ele diz só `1.24.0 (Ubuntu)`, e **é aí que a
varredura não autenticada erra**. O Ubuntu corrige as falhas do nginx mudando a revisão de
empacotamento e deixando o `1.24.0` como está, então um scanner que lê o banner não distingue um
nginx corrigido de um dois anos atrasado. Conforme foi escrito, ou ele informa toda falha já
corrigida na 1.24.0, um paredão de falsos positivos que ensina as pessoas a ignorá-lo, ou nenhuma.

E a aula 1 tirou a versão do banner do nginx de vez, o que deixa o scanner de fora sem nada. Esconder
uma versão torna mais difícil a primeira pergunta do atacante, e deixa a varredura não autenticada de
quem defende cega exatamente do mesmo jeito. **A verificação autenticada é a que sabe**, e a varredura
de fora tem outro trabalho: achar serviços que ninguém sabia que estavam escutando, que é o uso que a
aula 1 faz dela.

## As ferramentas que fazem isso em escala

Nenhuma delas foi executada para este curso; cada uma é descrita a partir da própria documentação.

| ferramenta | o que é |
|---|---|
| **OpenVAS / Greenbone** | o scanner de rede de código aberto, com um feed de testes; varre com ou sem credenciais |
| **Nessus** (Tenable), **Qualys**, **Rapid7 InsightVM** | scanners comerciais com agentes que vivem em cada máquina e informam de dentro |
| dados **OVAL** | avisos legíveis por máquina que Ubuntu, Red Hat e outros publicam; `oscap oval eval` confere uma máquina contra eles |
| **`pro fix`** no Ubuntu | o cliente da Canonical, que procura um CVE ou USN e diz se, e como, ele se aplica a esta máquina |

**O OVAL é a forma de verdade do feed desta aula.** O Ubuntu publica um arquivo por versão com cada
USN, os pacotes e as versões corrigidas, e o OpenSCAP, que a aula 2 usa para configuração, consegue
avaliá-lo. Baixá-lo exige internet, que o laboratório não tem, então este curso mostra o mecanismo com
um feed que cabe numa tela.

Agentes são o que a maioria das organizações acaba usando, por um motivo que o laboratório já
mostrou: um agente está dentro da máquina, então lê o banco de dados de pacotes como o script leu, e
informa a partir de notebooks que raramente estão na rede do escritório quando o scanner roda.
