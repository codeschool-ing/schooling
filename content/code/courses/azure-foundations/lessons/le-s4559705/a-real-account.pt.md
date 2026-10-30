---
title: Uma conta de verdade, e a ordem em que protegê-la
version: 1
---

**Você não precisa de conta do Azure para nenhuma lição deste curso.** Esta seção é para depois, ou
para o aluno que quer ver o portal de verdade ao lado do laboratório. **Nada dela foi executado para
o curso**, porque não há conta por trás. Então não há transcrições aqui, só os passos e os motivos da
ordem deles. As telas que ela menciona são da Microsoft, e a Microsoft as redesenha; os nomes das
configurações mudam menos do que os lugares delas.

## Antes de a conta existir

Assinar o Azure pede uma conta Microsoft ou uma conta do GitHub, um número de telefone que recebe um
código e um cartão de pagamento. **Três coisas são criadas nesse momento, e só uma delas se chama
conta**:

- **um tenant**, uma instância do Microsoft Entra ID, o diretório que vai guardar todas as
  identidades; a lição 2 o desenha;
- **uma assinatura**, a unidade que o Azure cobra e o contêiner onde os seus recursos vão morar;
- **você, como a primeira identidade**, feita Global Administrator do tenant e Owner da assinatura:
  os dois papéis mais poderosos que existem, nas mãos de uma pessoa que ainda não configurou um
  segundo fator.

Duas decisões são baratas agora e caras depois:

- **Assine com uma identidade que não esteja presa ao emprego de uma pessoa.** Quem assina é dono do
  tenant. Uma empresa deve fazer isso com um endereço que ela controla, para que o dia em que a pessoa
  que abriu a conta vai embora não seja o dia em que a empresa perde as chaves.
- **Saiba qual oferta você está escolhendo.** Quando este curso foi escrito, a Microsoft oferecia uma
  **conta gratuita**: uma quantia de crédito para gastar no primeiro mês, uma lista de serviços
  gratuitos por doze meses até um valor mensal, e outros gratuitos para sempre até um limite. **A
  conta gratuita é uma possibilidade, não uma promessa**: os valores e a lista já mudaram antes e vão
  mudar de novo. Leia a página atual antes de contar com qualquer número dela, e nunca conte com um
  número tirado de um curso. A outra oferta comum é o **pagamento conforme o uso**, cobrado por mês
  pelo que foi usado.

## A primeira hora, nesta ordem

1. **Proteja com autenticação multifator a identidade que é dona de tudo.** A Microsoft tornou o
   segundo fator obrigatório para entrar no portal do Azure, e depois na CLI e nas outras
   ferramentas, então uma conta nova é convidada a cadastrar um; faça isso com um app autenticador ou
   uma passkey, não com SMS. Tenants novos também começam com os **padrões de segurança** ligados, um
   conjunto fixo de proteções que a lição 11 explica. Deixe-os ligados até que o acesso condicional
   da lição 11 possa substituí-los.
2. **Crie um orçamento com alerta, antes de qualquer coisa que possa custar dinheiro.** No portal fica
   em *Cost Management*, *Budgets*: um orçamento mensal de poucos dólares para a assinatura, com um
   alerta por e-mail em 80% do custo real e outro em 100% da previsão. A lição 13 escreve o mesmo
   orçamento em Bicep e diz o que cada tipo de alerta significa. **Um alerta não para o gasto**; ele
   avisa, e é por isso que vem primeiro, enquanto o valor ainda é pequeno.
3. **Mantenha o limite de gastos, se a oferta tiver um.** Assinaturas compradas com crédito, a da
   conta gratuita entre elas, param os seus recursos quando o crédito acaba, a não ser que alguém
   remova o limite. O pagamento conforme o uso não tem nenhum, e nada vai pará-lo a não ser você.
4. **Crie uma identidade para o dia a dia, e pare de usar a dona.** A lição 6 cria um usuário no
   Entra ID, e a lição 9 dá a ele um papel num grupo de recursos em vez da assinatura inteira. Dali
   em diante as credenciais da dona vão para um lugar seguro e só são usadas para o que precisa
   delas.

## Apontando o laboratório para ela, e de volta

A CLI que você instalou guarda os logins no `AZURE_CONFIG_DIR`, que o `env.sh` aponta para
`~/azure/.azure`. **Use um terminal separado que nunca lê o `env.sh`** e faça login nele com
`az login`: aquela CLI guarda a memória em `~/.azure`, e a do laboratório continua vazia. Dois
terminais com duas memórias são mais difíceis de confundir do que um terminal cujas variáveis você
precisa lembrar. Antes de qualquer comando que cria alguma coisa, `az account show` diz em que
assinatura ela vai cair; leia isso toda vez, porque um tenant com duas assinaturas está a um padrão
digitado errado de cobrar a errada.

Tudo o que este curso compila, o Azure vai executar e cobrar. Uma máquina virtual é cobrada por
segundo enquanto roda, e o disco dela enquanto existir; um endereço IP público, um VPN gateway, um
Azure Firewall e um Application Gateway são cobrados por hora desde o momento em que existem, use-os
alguém ou não. **Ponha tudo o que você criar para praticar num só grupo de recursos, e apague o grupo
no mesmo dia**: `az group delete --name <o grupo>` remove todos os recursos dentro dele. Depois olhe o
*Cost analysis* na manhã seguinte. É a única tela que diz o que você esqueceu.
