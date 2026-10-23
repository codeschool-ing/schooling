---
title: The escalation path nobody revoked
version: 1
---

**dani left in March, and her IAM user did not. It still has an access key, and an inline policy
that lets it attach policies to users. That one permission is enough for her key to make itself an
administrator, and in this section you watch it happen in your own lab.** Then you have the finding
the rest of the lesson closes.

Nothing here is a technique for getting into anybody's account. The key in this story already
belongs to the account, the policy was written by its own administrators, and the request uses the
permission exactly as granted. **That is what makes it a configuration defect rather than a
break-in**: AWS did nothing wrong, and no log line would look unusual.

## Checking on

Until now moto has accepted any key. To see a denial, and an escalation, it has to judge requests.
That is a switch read when it starts: **`INITIAL_NO_AUTH_ACTION_COUNT=3` lets the first three
requests through unchecked and judges every request after them.** The three free requests are
spent creating an administrator, since a judge needs somebody to be the account's administrator and
there is nobody yet. Every request counts, including one that fails, so type the three below
carefully.

In the first terminal, stop moto with Ctrl+C and start it again like this:

```sh
INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567
```

In the second terminal, the three requests: a user called `admin`, AWS's `AdministratorAccess`
policy for it, and an access key kept in a shell variable rather than printed. The fourth request
proves the checking is on, and the `export` moves this terminal onto admin's key:

```
ana@laptop:~/aws$ aws iam create-user --user-name admin --query User.Arn --output text
arn:aws:iam::123456789012:user/admin
ana@laptop:~/aws$ aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ key=$(aws iam create-access-key --user-name admin)
ana@laptop:~/aws$ aws iam list-users

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
ana@laptop:~/aws$ export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)
ana@laptop:~/aws$ aws sts get-caller-identity --query Arn --output text
arn:aws:iam::123456789012:user/admin
```

The fourth request was refused because the terminal still carried the `test` key, which moto's IAM
never issued. From the `export` on, this terminal is admin.

One more tool before the story. `with_key` runs a single command with another user's key, without
changing the terminal's own; type it into the second terminal:

```sh
with_key() {
  local k=$1; shift
  AWS_ACCESS_KEY_ID=$(echo "$k" | jq -r .AccessKey.AccessKeyId) \
  AWS_SECRET_ACCESS_KEY=$(echo "$k" | jq -r .AccessKey.SecretAccessKey) "$@"
}
```

## The account as dani left it

caio develops the booking application and has AWS's `PowerUserAccess`, which allows everything
except IAM and Organizations. bia reads reports with `ReadOnlyAccess`. dani's user got an inline
policy in February, so that she could give each new analyst the reporting policy herself, and a key
for the script she ran it from:

```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": ["iam:AttachUserPolicy", "iam:ListAttachedUserPolicies"],
      "Resource": "*"
    }
  ]
}
```

Save it as `manage-users.json` and build the account:

```
ana@laptop:~/aws$ aws iam create-user --user-name caio --query User.Arn --output text
arn:aws:iam::123456789012:user/caio
ana@laptop:~/aws$ aws iam attach-user-policy --user-name caio --policy-arn arn:aws:iam::aws:policy/PowerUserAccess
ana@laptop:~/aws$ aws iam create-user --user-name bia --query User.Arn --output text
arn:aws:iam::123456789012:user/bia
ana@laptop:~/aws$ aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/ReadOnlyAccess
ana@laptop:~/aws$ aws iam create-user --user-name dani --query User.Arn --output text
arn:aws:iam::123456789012:user/dani
ana@laptop:~/aws$ aws iam put-user-policy --user-name dani --policy-name manage-users --policy-document file://manage-users.json
ana@laptop:~/aws$ dani=$(aws iam create-access-key --user-name dani)
```

## What the key can do

The key behaves exactly as its policy says. It cannot list the account's users, because nothing
allows `iam:ListUsers`:

```
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (AccessDenied) when calling the ListUsers operation: User: arn:aws:iam::123456789012:user/dani is not authorized to perform: iam:ListUsers
```

But `iam:AttachUserPolicy` on `"Resource": "*"` allows attaching **any** policy to **any** user,
and the user it was written for is one of them:

```
ana@laptop:~/aws$ with_key "$dani" aws iam attach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
```

**A silent prompt is the finding.** The request succeeded, and from this moment the key of a person
who left seven months ago holds `AdministratorAccess`. The request that failed a minute ago now
works:

```
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia	dani
```

```schooling-figure
{"svg": "<svg viewBox=\"0 0 720 262\" role=\"img\" data-fig=\"l06-path\" aria-label=\"The escalation path in this lesson, left to right. A user nobody removed when dani left in March; an access key on it nobody deactivated; an inline policy allowing iam:AttachUserPolicy on every resource. Together they let the key attach AdministratorAccess to its own user, and from then on it may do everything in the account. Under each of the first three links, the fix that cuts it: remove the user, delete the key, or name the one policy that may be attached. Cutting any one closes the path.\"><defs><marker id=\"l06-path-af-ah-amber\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--amber)\"></path></marker><marker id=\"l06-path-af-ah-paper-dim\" viewBox=\"0 0 10 8\" refX=\"9\" refY=\"4\" markerWidth=\"8\" markerHeight=\"7\" orient=\"auto-start-reverse\"><path d=\"M0 0 L10 4 L0 8 z\" fill=\"var(--paper-dim)\"></path></marker></defs><rect x=\"20.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"82.0\" y=\"70.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a user nobody</text><text x=\"82.0\" y=\"83.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">removed</text><path d=\"M146.0 77.0 L158.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M82.0 118.0 L82.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"26.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"82.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">remove the user</text><rect x=\"160.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"222.0\" y=\"70.2\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">a key nobody</text><text x=\"222.0\" y=\"83.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">deactivated</text><path d=\"M286.0 77.0 L298.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M222.0 118.0 L222.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"166.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"222.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">delete the key</text><rect x=\"300.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"362.0\" y=\"58.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">an inline policy</text><text x=\"362.0\" y=\"80.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">iam:AttachUserPolicy</text><text x=\"362.0\" y=\"96.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Mono', monospace\" font-size=\"8.5\" fill=\"var(--paper)\">&quot;Resource&quot;: &quot;*&quot;</text><path d=\"M426.0 77.0 L438.0 77.0\" stroke=\"var(--paper-dim)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-paper-dim)\"></path><path d=\"M362.0 118.0 L362.0 168.0\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\" fill=\"none\" stroke-dasharray=\"3 3\"></path><rect x=\"306.0\" y=\"170.0\" width=\"112.0\" height=\"44.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--phosphor)\" stroke-width=\"1.2\"></rect><text x=\"362.0\" y=\"192.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10\" fill=\"var(--phosphor)\">name the one policy</text><rect x=\"440.0\" y=\"40.0\" width=\"124.0\" height=\"74.0\" rx=\"4\" fill=\"var(--scan)\" stroke=\"var(--amber)\" stroke-width=\"1.3\"></rect><text x=\"502.0\" y=\"63.4\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">attach</text><text x=\"502.0\" y=\"77.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">AdministratorAccess</text><text x=\"502.0\" y=\"90.7\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"10.5\" fill=\"var(--paper)\">to itself</text><path d=\"M566.0 77.0 L578.0 77.0\" stroke=\"var(--amber)\" stroke-width=\"1.2\" fill=\"none\" marker-end=\"url(#l06-path-af-ah-amber)\"></path><rect x=\"580.0\" y=\"40.0\" width=\"120.0\" height=\"74.0\" rx=\"4\" fill=\"var(--panel)\" stroke=\"var(--amber)\" stroke-width=\"1.6\"></rect><text x=\"640.0\" y=\"69.8\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">everything</text><text x=\"640.0\" y=\"84.1\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" font-weight=\"600\" fill=\"var(--amber)\">in the account</text><text x=\"222.0\" y=\"240.0\" text-anchor=\"middle\" dominant-baseline=\"middle\" font-family=\"'IBM Plex Sans', sans-serif\" font-size=\"11\" fill=\"var(--phosphor)\">cut any one link and the path is closed</text></svg>", "caption": "Three ordinary things in a row make the path, and each has its own fix. A review that finds only one of them has still found enough to close it."}
```

Three things lined up, and each is ordinary on its own: a user nobody removed, a key nobody
deactivated, and a permission written for a small job with a `*` where a list of analysts should
have been. **Remove any one and the path is closed.** That is the shape of most escalation findings,
and the reason the next section looks for all three separately.

One caveat about this lab: AWS would also judge a condition on the policy, such as one limiting
which policies may be attached, where moto ignores conditions. The last section comes back to it.
