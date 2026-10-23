---
title: O que muda quando o data center é uma API
version: 1
---

**On-premises, a infraestrutura é um lugar, e mudá-la exige entrar no lugar. Na nuvem, a
infraestrutura é uma API na internet, e mudá-la exige ter uma chave.** Quase tudo o que é diferente
na defesa de uma nuvem vem dessa troca.

A imagem errada comum vai no sentido oposto: a de que a nuvem é mais segura porque outra pessoa vigia
o prédio, ou mais arriscada porque os servidores não são seus. As duas falam do prédio, e o prédio é
a parte que deixou de importar. Os vigias do provedor são bons. O que eles vigiam não é onde os
incidentes de nuvem começam.

## Seis coisas que mudam de lugar

**1. A entrada para os controles é pública.** A rede de gerência de um data center fica atrás de uma
porta, de um leitor de crachá e de um firewall. A interface de gerência da AWS são endereços
`https://` que qualquer pessoa na internet alcança, e o que decide se uma requisição é obedecida é a
credencial que ela carrega. Por isso **a identidade é chamada de novo perímetro**: a pergunta "quem
alcança os controles" virou "quem tem uma chave válida", e as aulas 6 e 7 tratam de manter esse
conjunto pequeno.

**2. A configuração é o sistema.** O firewall, a criptografia do disco e a lista de quem pode ler um
arquivo são todos configurações na mesma API, mudadas pelo mesmo tipo de chamada. On-premises,
publicar um compartilhamento de arquivos na internet exige uma equipe de servidores, uma equipe de
rede, uma regra de firewall e um pedido de mudança. Na nuvem é uma requisição, vale em segundos, e
ninguém mais precisa concordar. A aula 9 é essa requisição e o que ela já custou.

**3. Inventário é uma consulta.** Você não pode andar entre os racks, mas pode perguntar: todo
bucket, todo usuário, toda rede, em toda região. Isso corta dos dois lados. A resposta é completa e
instantânea, o que nenhuma planilha de servidores jamais foi. E um recurso numa região para a qual
ninguém olha continua rodando, alcançável e na conta.

**4. As coisas duram pouco.** Uma máquina pode viver vinte minutos, e o endereço que ela tinha vai
depois para a máquina de outra pessoa. Uma investigação não consegue tirar o disco de um servidor
que não existe mais, então o que você vai querer saber depois precisa ser registrado enquanto
acontece. A aula 15 trata do que registra.

**5. Você não toca no fio.** Não há switch para espelhar, cabo para grampear, porta de console. O
que você enxerga da sua própria rede e das suas próprias chamadas de API é o que o provedor oferece
para registrar, e quase tudo isso **fica desligado até você ligar, e é cobrado quando você liga**.

**6. A conta é um sensor.** Uma chave roubada é muitas vezes posta para minerar criptomoeda nas
maiores máquinas que a conta permite, e o primeiro sintoma é uma fatura dez vezes maior que a do mês
passado. A aula 10 do curso `cloud` criou alertas de orçamento por causa do dinheiro; o mesmo alerta
é um alarme de segurança.

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 330\" role=\"img\" data-fig=\"l01-steps\" aria-label=\"O que é preciso para tornar arquivos guardados alcançáveis pela internet. On-premises, quatro passos de quatro pessoas diferentes: a equipe de servidores compartilha o diretório, a equipe de rede põe o servidor onde a internet o alcança, a equipe do firewall abre uma regra e um comitê de mudanças aprova. Qualquer uma delas pode dizer não. Na nuvem, uma requisição à API, put-bucket-policy, enviada por quem tiver uma chave autorizada a enviá-la, vale em segundos, e ninguém mais precisa concordar.\"><defs><marker id=\"l01-steps-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><text x=\"180.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">on-premises</text><text x=\"540.0\" y=\"24.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"12\" font-weight=\"600\" fill=\"var(--paper)\">na nuvem</text><path d=\"M360.0 14.0 L360.0 316.0\" stroke=\"var(--wire)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"4 4\"></path><rect x=\"40.0\" y=\"50.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"68.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">compartilhar o diretório</text><text x=\"56.0\" y=\"86.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">equipe de servidores</text><text x=\"304.0\" y=\"75.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">1</text><path d=\"M180.0 102.0 L180.0 112.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"114.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"132.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">pô-lo onde a internet alcança</text><text x=\"56.0\" y=\"150.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">equipe de rede</text><text x=\"304.0\" y=\"139.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">2</text><path d=\"M180.0 166.0 L180.0 176.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"178.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"196.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">abrir uma regra no firewall</text><text x=\"56.0\" y=\"214.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">equipe do firewall</text><text x=\"304.0\" y=\"203.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">3</text><path d=\"M180.0 230.0 L180.0 240.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l01-steps-af-ah-paper-dim)\"></path><rect x=\"40.0\" y=\"242.0\" width=\"280.0\" height=\"50.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\"></rect><text x=\"56.0\" y=\"260.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">aprovar a mudança</text><text x=\"56.0\" y=\"278.0\" text-anchor=\"start\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">comitê de mudanças</text><text x=\"304.0\" y=\"267.0\" text-anchor=\"end\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--paper-dim)\">4</text><text x=\"180.0\" y=\"316.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">qualquer uma de quatro pessoas pode dizer não</text><rect x=\"400.0\" y=\"130.0\" width=\"280.0\" height=\"70.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.4\"></rect><text x=\"540.0\" y=\"154.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"10.5\" fill=\"var(--paper)\">aws s3api put-bucket-policy</text><text x=\"540.0\" y=\"178.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"9.5\" font-style=\"italic\" fill=\"var(--paper-dim)\">quem tem uma chave que pode enviá-la</text><text x=\"540.0\" y=\"228.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">vale em segundos</text><text x=\"540.0\" y=\"248.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--amber)\">ninguém mais precisa concordar</text></svg>", "caption": "O mesmo resultado, quatro aprovações contra uma requisição. A nuvem não tirou a decisão; tirou as pessoas que ficavam na frente dela."}
```

## O que não muda

As ideias não mudam. Confidencialidade, integridade e disponibilidade; menor privilégio; defesa em
profundidade; saber o que você tem antes de defender: o curso `security-fundamentals` as ensinou para
qualquer computador, e nenhuma é aposentada aqui. O que muda é **onde cada ideia é aplicada**. Menor
privilégio era uma questão de quem tinha login em qual servidor, e agora é um documento de política
anexado a uma identidade. Segmentação eram VLANs e um firewall num rack, e agora é uma tabela de rotas
e um security group que são, de novo, configurações.

Esse é o fio deste curso: **na nuvem, quase toda defesa é uma configuração, e quase toda falha
também.** A próxima seção mostra as duas no seu laboratório.
