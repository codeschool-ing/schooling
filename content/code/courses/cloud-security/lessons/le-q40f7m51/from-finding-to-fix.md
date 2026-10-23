---
title: From a finding to a fix, and back again
version: 1
---

**A finding is a question addressed to a person: is this what you meant? There are three honest
answers. Fix it, accept it with a reason and an end date, or find out who owns it and ask them.** A
fourth answer is the common one and the wrong one: leave it in the list, where it teaches everybody
that the list is noise.

## Who owns it

Before anything can be fixed, somebody has to be the one to fix it. The scanner says *what*; it
cannot say *whose*. That is why lesson 17 and the `cloud` course's lesson 10 both ask for tags on
every resource: an `owner` tag turns "port 22 is open on `sg-…`" into a message with a name on it.
The clinic is small enough to answer from memory. caio launched `booking-admin` to reach the booking
server; bia's user is bia's; the buckets are the clinic's.

## Accepting one, on purpose

`clinic-web` is public because it is the website. The rule is right in general and wrong here, so it
gets an exception. **An exception carries a reason somebody can disagree with and a date after which
it stops counting.** Without the date it is permanent, and in a year nobody remembers why the website
bucket was allowed to be public, or whether the patient exports were moved into it since.

```sh
cat > accepted.txt <<'EOF'
public-bucket clinic-web 2027-04-30 the public website: pages and logo only, reviewed by ana
EOF
```

## Fixing the other three

Each fix is one call, the size of the fault, and each comes from the lesson that explained it:

```
ana@laptop:~/aws$ aws s3api put-bucket-encryption --bucket clinic-exports --server-side-encryption-configuration '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
ana@laptop:~/aws$ aws ec2 revoke-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ aws iam enable-mfa-device --user-name bia --serial-number arn:aws:iam::123456789012:mfa/bia --authentication-code1 123456 --authentication-code2 654321
```

`$sg` still holds the group's id from the previous section, in the same terminal. In practice the
port-22 fix is the one that needs a conversation: caio still has to reach the booking server, and
lesson 8 gives him a way that is not the whole internet. The MFA fix is bia's to make, on her own
phone; here it stands in for her doing so, with moto accepting the codes as before.

**Then prove it the way the faults were found**, by running the same scanner:

```
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
accepted  public-bucket       clinic-web            until 2027-04-30: the public website: pages and logo only, reviewed by ana
0 open, 1 accepted
exit 0
```

Nothing open, one exception with its reason and its date, and an exit code of `0`.

## Drift: the same fault, next week

A clean report describes one moment. A week later caio is debugging from a café, opens SSH to the
world "for five minutes", and forgets:

```
ana@laptop:~/aws$ aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 --query Return
true
ana@laptop:~/aws$ python3 scan.py; echo "exit $?"
accepted  public-bucket       clinic-web            until 2027-04-30: the public website: pages and logo only, reviewed by ana
OPEN      admin-port-open     sg-d877b106d3b8c910b  port 22 open to 0.0.0.0/0
1 open, 1 accepted
exit 1
```

**This is drift**: the configuration moved away from the state that was checked, through the same
API that fixed it. Nothing stops it, because caio is allowed to change his own security group, and
the next morning's scan is what catches it. A scan that runs once a quarter would have caught it in
January.

Two things shrink drift instead of only catching it. **Write the configuration as code**, so the fix
lives in a file that is reviewed and applied again, and a hand change is undone by the next apply —
lesson 12. And **run the check before the change**, not only after: lesson 14 puts a scanner in the
deployment flow, where a pull request that opens port 22 fails before it reaches the account.
