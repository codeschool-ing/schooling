"""Lesson 25: the AWS CLI's settings, profiles and roles."""
from figures import Fig, T, figure


@figure('l25-layers', 25)
def layers():
    f = Fig('l25-layers', 720, 330, T(
        'The three places the AWS command line reads a setting from, nearest first. First the '
        'command itself: options such as --region, --profile and --output. Then the environment: '
        'AWS_REGION, AWS_DEFAULT_REGION, AWS_PROFILE and the key variables. Last the two files, '
        '~/.aws/config and ~/.aws/credentials. The region measured in the lesson came from each '
        'layer in turn: us-west-2a with the option, sa-east-1a from env.sh, us-east-1a from the '
        'profile. For credentials, --profile takes the environment\'s keys out of the way, and '
        'AWS_PROFILE does not.',
        'Os três lugares de onde a linha de comando da AWS lê uma configuração, o mais próximo '
        'primeiro. Primeiro o próprio comando: opções como --region, --profile e --output. Depois o '
        'ambiente: AWS_REGION, AWS_DEFAULT_REGION, AWS_PROFILE e as variáveis de chave. Por último os '
        'dois arquivos, ~/.aws/config e ~/.aws/credentials. A região medida na lição veio de cada '
        'camada por vez: us-west-2a com a opção, sa-east-1a do env.sh, us-east-1a do perfil. Para '
        'credenciais, o --profile tira do caminho as chaves do ambiente, e o AWS_PROFILE não.'))
    rows = [(70, T('1  the command', '1  o comando'), '--region  --profile  --output', 'us-west-2a'),
            (150, T('2  the environment', '2  o ambiente'), 'AWS_DEFAULT_REGION  AWS_PROFILE  AWS_ACCESS_KEY_ID',
             'sa-east-1a'),
            (230, T('3  the files', '3  os arquivos'), '~/.aws/config  ~/.aws/credentials', 'us-east-1a')]
    f.text(610, 26, T('the region, measured', 'a região, medida'), size=10, fill='--paper-dim',
           italic=True)
    for y, name, what, zone in rows:
        f.rect(80, y - 30, 440, 60, stroke='--phosphor', fill='--panel')
        f.text(100, y - 12, name, size=11, anchor='start', weight='600')
        f.text(100, y + 12, what, size=9.5, anchor='start', mono=True, fill='--paper-dim')
        f.rect(560, y - 18, 100, 36, stroke='--wire', fill='--scan')
        f.text(610, y, zone, size=10.5, mono=True)
        f.line(522, y, 558, y, stroke='--paper-dim', width=1.2)
    f.arrow([(40, 44), (40, 256)], stroke='--phosphor', width=1.6)
    f.lines(40, 288, [T('first found', 'o primeiro'), T('wins', 'achado vence')], size=10,
            fill='--phosphor')
    f.text(360, 300, T('credentials: --profile skips the environment\'s keys; AWS_PROFILE does not',
                       'credenciais: --profile pula as chaves do ambiente; AWS_PROFILE não'),
           size=10, fill='--amber')
    return f, T('Nearest wins: the command, then the environment, then the files, with one '
                'exception for keys.',
                'O mais próximo vence: o comando, depois o ambiente, depois os arquivos, com uma '
                'exceção para chaves.')


@figure('l25-role-profile', 25)
def role_profile():
    f = Fig('l25-role-profile', 720, 250, T(
        'What one command with --profile staging does. The profile staging names a role_arn in '
        'shop-staging and a source_profile, lab. The keys of lab sign an sts:AssumeRole call. STS '
        'returns temporary credentials for OrganizationAccountAccessRole in shop-staging, which the '
        'command line keeps in ~/.aws/cli/cache and signs the command with. The next command reuses '
        'the cache until the credentials expire.',
        'O que um comando com --profile staging faz. O perfil staging nomeia um role_arn em '
        'shop-staging e um source_profile, lab. As chaves de lab assinam uma chamada sts:AssumeRole. '
        'O STS devolve credenciais temporárias de OrganizationAccountAccessRole em shop-staging, que a '
        'linha de comando guarda em ~/.aws/cli/cache e com as quais assina o comando. O comando '
        'seguinte reusa o cache até as credenciais vencerem.'))
    boxes = [(90, '[profile staging]', T('role_arn, source_profile', 'role_arn, source_profile')),
             (270, '[lab]', T('its keys sign', 'as chaves assinam')),
             (450, 'sts:AssumeRole', T('in shop-staging', 'em shop-staging')),
             (630, '~/.aws/cli/cache', T('kept until expiry', 'guardado até vencer'))]
    for x, code, note in boxes:
        f.rect(x - 80, 60, 160, 64, stroke='--phosphor', fill='--panel')
        f.text(x, 82, code, size=10, mono=True, weight='600')
        f.text(x, 104, note, size=9.5, fill='--paper-dim')
    for a, b in ((170, 190), (350, 370), (530, 550)):
        f.arrow([(a + 2, 92), (b - 2, 92)], stroke='--phosphor', width=1.4)
    f.arrow([(630, 126), (630, 170)], stroke='--phosphor', width=1.4)
    f.rect(430, 172, 280, 40, stroke='--wire', fill='--scan')
    f.text(570, 192, 'aws ec2 describe-vpcs --profile staging', size=9.5, mono=True)
    f.text(220, 192, T('signed as the role, in the other account', 'assinado como a role, na outra conta'),
           size=10, fill='--amber')
    f.text(90, 36, T('one command', 'um comando'), size=10, fill='--paper-dim', italic=True)
    return f, T('A profile with role_arn assumes the role on the first command and reuses it until '
                'it expires.',
                'Um perfil com role_arn assume a role no primeiro comando e a reusa até vencer.')
