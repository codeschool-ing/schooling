---
title: Uma conta real, e a ordem para protegê-la
version: 1
---

**Você não precisa de uma conta no Google Cloud para nenhuma lição deste curso.** Esta seção é para
depois, ou para o aluno que quer ver a coisa real ao lado do laboratório. **Nada dela foi rodado para
o curso**, porque não há conta por trás. Então não há transcrições aqui, só os passos e os motivos da
ordem deles. As telas que eles citam são do Google, e o Google as redesenha; os nomes das
configurações mudam menos que o lugar delas.

## Antes de a conta existir

O Google Cloud é aberto em `console.cloud.google.com` com uma conta Google e um cartão de pagamento.
Duas decisões são baratas agora e caras depois:

- **Saiba de quem é a conta Google.** Um endereço pessoal do Gmail funciona, e faz de você o dono de
  tudo que criar, sem organização acima; a lição 2 explica quanto isso custa. Uma empresa deveria
  começar de um domínio que controla, com o Cloud Identity ou o Google Workspace, que a lição 10
  descreve, para que o ambiente pertença à empresa e não a quem por acaso fez o cadastro.
- **Saiba qual é a oferta gratuita.** Quando este curso foi escrito, um cliente novo recebe uma quantia
  de crédito para gastar nos primeiros noventa dias, e à parte um **nível gratuito**: alguns serviços
  de graça até um valor mensal, como uma máquina virtual pequena em certas regiões dos EUA. **O nível
  gratuito é uma possibilidade, não uma promessa.** O Google já mudou os termos e pode mudar de novo.
  Leia a página atual antes de contar com qualquer número dela, e nunca conte com um número de um
  curso.

## A primeira hora, nesta ordem

1. **Ligue a verificação em duas etapas da conta Google**, em `myaccount.google.com`, em *Segurança*.
   Uma chave de acesso ou uma chave de segurança é a escolha mais forte; um app autenticador no
   celular vem a seguir. Até isso estar feito, a conta está a uma senha vazada de pertencer a outra
   pessoa, e o cartão por trás dela junto.
2. **Crie um orçamento com alertas, antes de qualquer coisa que possa custar dinheiro.** Em
   *Faturamento*, *Orçamentos e alertas*: um orçamento mensal de poucos dólares na conta de
   faturamento, com e-mail em 50%, 90% e 100% do gasto real. A lição 12 escreve o mesmo orçamento em
   Terraform e diz o que cada tipo de limite quer dizer. **Um orçamento não interrompe o gasto**; ele
   avisa, e é por isso que vem primeiro, enquanto o valor ainda é pequeno.
3. **Nunca baixe uma chave de conta de serviço.** O console oferece uma na página de toda conta de
   serviço, e a lição 8 é sobre por que ela é o último recurso. Uma organização nova, criada de 2024 em
   diante, recusa a criação de chaves por padrão, pela política da organização da lição 4; uma conta
   pessoal sem organização não tem essa proteção.
4. **Logue a CLI em outro lugar que não o laboratório.** O `gcloud` do laboratório guarda as
   configurações em `~/gcp/gcloud` e nunca guardou uma credencial. Abra um terminal separado que nunca
   lê o `env.sh`, rode `gcloud auth login` ali, e a conta real fica em `~/.config/gcloud`. Dois
   terminais com dois diretórios por trás são mais difíceis de confundir que um terminal cujas
   variáveis você precisa lembrar.

## O que custa dinheiro desde o instante em que existe

Tudo que o Terraform só planeja neste curso, o Google vai criar e cobrar. Uma máquina virtual é
cobrada por segundo enquanto roda, e o disco dela enquanto existe; um gateway do Cloud NAT, a
forwarding rule de um balanceador de carga e um endereço externo estático parado cobram, cada um, por
hora. As lições 17 e 20 dão os preços. **Apague o que criar no mesmo dia**, e olhe a página de
relatórios de faturamento na manhã seguinte: é a única tela que diz o que você esqueceu. Apagar o
projeto inteiro, como a lição 3 mostra, é o jeito mais seguro, porque nada dentro de um projeto
sobrevive a isso.
