---
title: Todo worker precisa ver o mesmo arquivo
version: 1
---

**Nas aulas 1 e 2, todo job leu `data/raw/clicks` do seu disco, e isso só funcionou porque havia um
disco.** O driver dizia a cada executor "leia este arquivo, deste byte até aquele", e cada executor
abria o caminho na própria máquina. Os três executores estavam na mesma máquina, então os três
acharam o arquivo.

Num cluster de verdade essa instrução falha na hora. Cada worker é um computador diferente com o
próprio disco, e `/home/ana/big/data` não existe em nenhum deles, ou pior, existe em um deles com o
conteúdo de ontem. **Um cluster precisa de um sistema de arquivos cujos caminhos signifiquem a
mesma coisa em toda máquina**, e os dados também precisam se espalhar pelas máquinas, porque o
propósito de um cluster é cada máquina ler a sua parte do próprio disco.

Há dois jeitos de conseguir isso, e esta aula roda os dois:

- **Um sistema de arquivos distribuído**, o HDFS, que espalha os arquivos pelos discos das mesmas
  máquinas que rodam os jobs. Ele veio com o Hadoop em 2006 e ainda é onde a maioria dos clusters
  em datacenter próprio guarda os dados.
- **Um object store**, como o Amazon S3, o Google Cloud Storage ou o Azure Blob Storage, que é um
  serviço separado acessado pela rede. As máquinas que calculam não guardam dado nenhum, e é assim
  que a maioria dos clusters em nuvem é montada.

Num programa Spark eles se parecem, porque só muda o começo do endereço, `hdfs://` ou `s3a://`. Por
baixo eles fazem promessas diferentes, e um job que depende de uma promessa do HDFS se comporta
diferente, e às vezes errado, num object store. As seções 09 e 10 tratam dessa diferença.
