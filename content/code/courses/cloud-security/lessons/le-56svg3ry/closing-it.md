---
title: Closing the path, in the right order
version: 1
---

**Close the way in before you tidy the permissions.** A key that still works can undo every policy
change you make, since that is exactly what this one was shown doing. So the order is: stop the
key, then remove the user's policies, then the user, and then prove each step by asking again.

## Stop the key

The gentle first move is to deactivate the key rather than delete it. An inactive key can be
switched back on if it turns out a forgotten job depends on it, which is the usual reason people
hesitate here:

```
ana@laptop:~/aws$ aws iam update-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId) --status Inactive
ana@laptop:~/aws$ aws iam list-access-keys --user-name dani --query "AccessKeyMetadata[].[AccessKeyId,Status]" --output text
AKIARZPUZDIKM7XXHV3H	Inactive
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia	dani
```

**moto still accepted it.** The key is marked `Inactive` and the request it signed went through.
AWS refuses every request signed with an inactive key, so on a real account this is where the path
would stop. It is the reason a transcript is never the whole proof in this course: here the lab is
wrong, and the documentation is the source. For a key used today by a person who left, the cautious
reading is that nothing can safely depend on it, and deleting it is the step that is true in both
places:

```
ana@laptop:~/aws$ aws iam delete-access-key --user-name dani --access-key-id $(echo "$dani" | jq -r .AccessKey.AccessKeyId)
ana@laptop:~/aws$ with_key "$dani" aws iam list-users --query "Users[].UserName" --output text

aws: [ERROR]: An error occurred (InvalidClientTokenId) when calling the ListUsers operation: The security token included in the request is invalid.
```

`InvalidClientTokenId`: the key no longer exists, and nothing it signs is obeyed. **That refusal is
the evidence**, as `403` from an anonymous request was in lesson 1.

## Then the user

A user with policies cannot be deleted; AWS makes you take them off first, and the error says so:

```
ana@laptop:~/aws$ aws iam detach-user-policy --user-name dani --policy-arn arn:aws:iam::aws:policy/AdministratorAccess
ana@laptop:~/aws$ aws iam delete-user --user-name dani

aws: [ERROR]: An error occurred (DeleteConflict) when calling the DeleteUser operation: Cannot delete entity, must delete policies first.
ana@laptop:~/aws$ aws iam delete-user-policy --user-name dani --policy-name manage-users
ana@laptop:~/aws$ aws iam delete-user --user-name dani
ana@laptop:~/aws$ bash iam-writers.sh
admin	AdministratorAccess	*
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName" --output text
admin	caio	bia
```

The second `bash iam-writers.sh` is the proof for this half. It prints one row, `admin`, which is
the one it should print; dani's rows are gone with her user.

## Keep it closed

Removing one path does not stop the next contractor's policy being written the same way. Three
guardrails exist for that, and each is enforced by AWS above the policy a hurried administrator
writes:

| guardrail | what it does | in this lab |
|---|---|---|
| a condition on the delegating policy | `iam:PolicyARN` limits *which* policies may be attached, so "attach the reporting policy" cannot become "attach anything" | moto ignores conditions |
| a permission boundary | a ceiling on a user or role: whatever its policies say, it can do no more than the boundary allows | stored, not enforced |
| a service control policy | an organisation-wide `Deny` on IAM writes for everybody except an administrator role | stored, not enforced |

**None of the three was run here**, for the reasons in the right-hand column; what each does is AWS's
documented behaviour. The first is the narrow fix for dani's job, the second the standard way to let
a team create roles without letting those roles exceed the team, and the third the account-wide
floor the other two sit on.

And one process, which is not a setting at all: **removing a person from the identity provider and
removing their IAM user have to be the same step**, on the same checklist, until there are no IAM
users for people left to remove. That is the change this lesson's second section argued for, and it is
the one that would have stopped this story in March.
