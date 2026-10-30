"""Lesson 9: Workload Identity Federation."""
from figures import Fig, T, figure


@figure('l09-exchange', 9)
def exchange():
    f = Fig('l09-exchange', 720, 300, T(
        'The exchange, in four steps between three parties. On the left, a GitHub Actions job. At the '
        'top, GitHub\'s identity provider, which signs an OIDC token for the job, step 1. In the middle, '
        'Google\'s Security Token Service, which receives the token with the pool and provider named, '
        'checks the signature, the attribute mapping and the condition, and returns a federated token, '
        'step 2. To the right, IAM Credentials, which trades the federated token for a token of the '
        'deployer service account, step 3. Last, the job calls Google APIs with that token, step 4. A '
        'note: no key crosses at any step.',
        'A troca, em quatro passos entre três partes. À esquerda, um job do GitHub Actions. No alto, o '
        'provedor de identidade do GitHub, que assina um token OIDC para o job, passo 1. No meio, o '
        'Security Token Service do Google, que recebe o token com o pool e o provider nomeados, confere a '
        'assinatura, o mapeamento de atributos e a condição, e devolve um token federado, passo 2. À '
        'direita, o IAM Credentials, que troca o token federado por um token da conta de serviço '
        'deployer, passo 3. Por fim, o job chama as APIs do Google com esse token, passo 4. Uma nota: '
        'nenhuma chave atravessa em passo nenhum.'))
    f.rect(20, 120, 140, 60, stroke='--wire', fill='--panel')
    f.lines(90, 150, [T('a GitHub', 'um job do'), T('Actions job', 'GitHub Actions')], size=10.5)
    f.rect(20, 14, 140, 54, stroke='--paper-dim', fill='--ink', dash='5 3')
    f.lines(90, 41, [T('GitHub\'s identity', 'provedor de'), T('provider', 'identidade do GitHub')],
            size=10)
    f.arrow([(90, 70), (90, 116)], stroke='--paper', width=1.4)
    f.text(98, 92, T('1. a signed OIDC token', '1. um token OIDC assinado'), size=9.5, anchor='start')
    f.rect(250, 110, 180, 80, stroke='--phosphor', fill='--scan', width=1.6)
    f.text(340, 128, 'sts.googleapis.com', size=10, mono=True)
    f.text(340, 148, T('signature, mapping,', 'assinatura, mapeamento,'), size=9.5, fill='--paper-dim')
    f.text(340, 164, T('condition', 'condição'), size=9.5, fill='--paper-dim')
    f.arrow([(162, 140), (246, 140)], stroke='--paper', width=1.4)
    f.text(204, 128, '2', size=10, weight='600')
    f.arrow([(246, 162), (162, 162)], stroke='--phosphor', width=1.4)
    f.text(204, 176, T('federated', 'federado'), size=9, fill='--phosphor')
    f.rect(520, 110, 180, 80, stroke='--phosphor', fill='--panel', width=1.6)
    f.text(610, 128, 'iamcredentials', size=10, mono=True)
    f.text(610, 148, T('federated token for', 'token federado pelo'), size=9.5, fill='--paper-dim')
    f.text(610, 164, T('the deployer\'s', 'do deployer'), size=9.5, fill='--paper-dim')
    f.path('M90 182 C 90 240, 610 240, 610 192', stroke='--paper', width=1.4, arrow=True)
    f.text(350, 236, T('3. trade it for the deployer\'s token, then 4. call Google APIs',
                       '3. trocar pelo token do deployer, e 4. chamar as APIs do Google'), size=9.5)
    f.text(360, 282, T('no key crosses at any step', 'nenhuma chave atravessa em passo nenhum'),
           size=10.5, weight='600', fill='--amber')
    return f, T('An outside token in, a Google token out, and nothing long-lived in between.',
                'Um token de fora entra, um token do Google sai, e nada duradouro no meio.')
