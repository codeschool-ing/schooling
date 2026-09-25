---
title: Seis coisas antes de alguém usar
version: 1
---

A área de trabalho aparecer não é o fim. Uma instalação nova precisa de seis coisas antes de ir para o
usuário, e fazê-las nesta ordem economiza reinicializações:

1. **Windows Update, até não sobrar nada.** A cópia do Windows do instalador tem semanas ou meses.
   *Configurações > Windows Update > Verificar se há atualizações*, instalar, reiniciar e verificar de
   novo: em geral leva duas ou três rodadas.
2. **Drivers.** O Windows Update traz a maioria. Para o resto, o site de suporte do fabricante,
   encontrado pelo **número do modelo** na etiqueta. O Gerenciador de Dispositivos (aula 1) não deve
   mostrar nenhum triângulo amarelo quando você terminar.
3. **Ativação.** *Configurações > Sistema > Ativação* deve dizer *O Windows está ativado*. Se não
   disser, resolva agora; um Windows não ativado fica cobrando o usuário e restringe a personalização.
4. **Criptografia, e onde está a chave.** A maioria dos computadores novos liga sozinha a
   *criptografia do dispositivo* ou o *BitLocker*. O disco passa a ser lido só com o TPM do
   computador ou com uma **chave de recuperação** de 48 dígitos, que o Windows salva na conta da seção
   anterior. **Descubra onde está essa chave antes de o computador sair da sua mesa.** Uma atualização
   de firmware ou um conserto na placa-mãe pode fazer o Windows pedi-la, e sem ela os dados do disco se
   perdem para sempre.
5. **Uma conta padrão para o dia a dia.** A conta criada na instalação é administradora. A pessoa que
   usa o computador todo dia deve usar uma conta sem direitos de administrador, que é o assunto da
   aula 10.
6. **Os programas do escritório.** A aula 11 trata de instalá-los, pela loja, por instaladores e pelo
   `winget`.

## Anotando

Para cada máquina, uma linha num documento compartilhado: nome, modelo, número de série, edição e
versão do Windows, onde está a chave de recuperação, quem usa. Leva dois minutos. É a lista que você
vai querer no dia em que um computador for roubado, ou quando alguém perguntar quantas máquinas ainda
precisam de atualização.
