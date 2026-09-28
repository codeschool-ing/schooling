---
title: "IaaS: uma máquina, um disco e uma rede"
version: 1
---

A **infraestrutura como serviço** aluga para você as camadas que uma sala de servidores guardava, e
para aí. Você recebe uma máquina virtual do tamanho que pediu, um disco ligado a ela e um lugar numa
rede virtual, com um endereço. Ao criar a máquina você escolhe uma **imagem**, o sistema operacional de
onde ela parte, como o Ubuntu 24.04. A partir do momento em que ela liga, tudo da rede virtual para cima
é seu.

O Amazon EC2, o Azure Virtual Machines e o Google Compute Engine são IaaS, e também as máquinas que
provedores menores, como DigitalOcean e Hetzner, alugam. A aula 4 trata das máquinas em si, e a aula 5
dos discos delas.

## Quanto custa, linha por linha

Como o IaaS é medido por peça, uma máquina pequena pode ser precificada pela tabela do curso. Pegue a
menor de São Paulo, um disco de 20 GB do tipo SSD comum e um endereço IPv4 público para a internet
chegar a ela. O programa abaixo faz a conta; os preços são linhas da tabela, e nada aqui criou uma
máquina.

```schooling-example
{"language": "python", "file": "estimate.py", "parts": [{"code": "HOURS = 730", "note": "Um mês em horas: 365 dias vezes 24, dividido por 12."}, {"code": "machine = 0.01680 * HOURS", "note": "A linha do `t3.micro` na tabela, sob demanda em `sa-east-1`: dólares por hora, vezes as horas do mês."}, {"code": "disk = 20 * 0.1520", "note": "20 GB de `gp3`, o volume SSD comum, pelo preço da tabela por GB-mês. **Um disco é cobrado pelo tamanho, cheio ou vazio.**"}, {"code": "address = 0.0050 * HOURS", "note": "Um endereço IPv4 público, cobrado por hora como a máquina, tenha alguém se conectado a ele ou não."}, {"code": "print(f\"machine  {machine:6.2f}\")\nprint(f\"disk     {disk:6.2f}\")\nprint(f\"address  {address:6.2f}\")\nprint(f\"total    {machine + disk + address:6.2f}\")", "note": "Duas casas decimais, porque uma conta é em centavos. O total é o que as três peças custam por um mês em São Paulo, antes de qualquer dado sair para a internet."}], "output": "machine   12.26\ndisk       3.04\naddress    3.65\ntotal     18.95"}
```

**Cada linha desse total é algo que você poderia desligar separadamente**, e cada uma é cobrada esteja a
máquina fazendo trabalho útil ou não. Os dados enviados para a internet são cobrados por cima, por
gigabyte, e a aula 10 volta a isso.

## O que sobra para você

O provedor opera as instalações, o hardware, a rede física e a virtualização, e faz isso bem: trocar um
disco com defeito no prédio dele não é tarefa sua, e ninguém nunca vai pedir que você aplique um patch
no hipervisor. Tudo acima dessa linha é seu, e **o provedor não toca nisso**, inclusive nas partes que
parecem manutenção:

- as regras de firewall da rede virtual, que decidem se a porta do banco de dados fica aberta para a
  internet inteira;
- os patches do sistema operacional. Ninguém do provedor entra na sua máquina para atualizá-la; se as
  atualizações chegam sozinhas, é porque a imagem que você escolheu as ligou, e um kernel novo ainda
  espera um reinício que ninguém agenda por você;
- o runtime e a aplicação, as versões deles e as dependências;
- os backups: o provedor vende snapshots do disco, e tirá-los, guardá-los e testar uma restauração é
  tarefa sua;
- os logins: quem tem uma chave SSH da máquina, e se a chave de alguém que saiu ainda está nela;
- perceber que a máquina caiu, ou que o disco dela encheu.

O último item é o que mais surpreende. **Uma máquina virtual pode parar de responder enquanto tudo o que
o provedor vigia parece saudável**: o hardware está bem, o hipervisor está bem, e o servidor web dentro
dela caiu às quatro da manhã. A visão do provedor termina na linha, e o alarme dele também.

## O que você ganha em troca do trabalho

Controle. Qualquer sistema operacional para o qual o provedor tenha imagem, qualquer software, qualquer
porta, qualquer ajuste do kernel. Um programa que precisa de uma biblioteca de sistema específica, um
processo que roda por três dias, um banco de dados ajustado à mão: o IaaS roda todos, porque para o
programa aquilo é só um servidor.

É também o modelo que se muda com mais facilidade. Uma máquina Ubuntu rodando PostgreSQL e uma aplicação
Python é o mesmo sistema em qualquer provedor que alugue máquinas virtuais. Por isso **a ida para a
nuvem costuma começar pelo IaaS**: os servidores que a empresa já tinha são refeitos como máquinas
virtuais com o mínimo de mudança possível, o que o mercado chama de *lift and shift*. É o menor passo a
partir da sala de servidores, e é o que deixa mais trabalho para trás.
