---
title: An account with four faults in it
version: 1
---

**Before writing a scanner, give it something to find.** This section builds a small copy of the
clinic's account in your lab, with four faults placed on purpose, each one a lesson of this course
left undone. Start moto in the first terminal, empty, and read `env.sh` in both. moto's checking
stays off: nothing here is about a denial.

These commands build it. Paste them into the second terminal as they are; none of them prints
anything you need to read:

```sh
aws iam create-user --user-name caio > /dev/null
aws iam create-user --user-name bia > /dev/null
aws iam enable-mfa-device --user-name caio --serial-number arn:aws:iam::123456789012:mfa/caio \
  --authentication-code1 123456 --authentication-code2 654321
for b in clinic-records clinic-web clinic-exports; do
  aws s3api create-bucket --bucket "$b" --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
done
for b in clinic-records clinic-web; do
  aws s3api put-bucket-encryption --bucket "$b" --server-side-encryption-configuration \
    '{"Rules":[{"ApplyServerSideEncryptionByDefault":{"SSEAlgorithm":"AES256"}}]}'
done
aws s3api put-bucket-policy --bucket clinic-web --policy \
  '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-web/*"}]}'
sg=$(aws ec2 create-security-group --group-name booking-admin --description "booking admin" --query GroupId --output text)
aws ec2 authorize-security-group-ingress --group-id "$sg" --protocol tcp --port 22 --cidr 0.0.0.0/0 > /dev/null
```

What that left behind, fault by fault:

| fault | where | which lesson says why it matters |
|---|---|---|
| a bucket readable by everybody | `clinic-web`, through its policy | 9 |
| a bucket with no default encryption | `clinic-exports` | 11 |
| SSH open to the whole internet | the security group `booking-admin` | 8 |
| a person's user with no second factor | `bia`, who has no MFA device | 6 |

**One of the four is not a mistake.** `clinic-web` holds the clinic's public website, its pages and
its logo, and a website is meant to be read by strangers. A scanner cannot know that, and the
section after next decides what to do about it.

**caio's second factor was accepted with two made-up codes.** `enable-mfa-device` asks for two
consecutive codes from the device being registered, and AWS checks them against the device's secret
before it records anything. moto records the device without checking, which is fine for a lab whose
point is that the device exists. **Not run against AWS**, where those two numbers would be refused.

Ask the account what it holds now, the way a person would before any tool exists:

```
ana@laptop:~/aws$ aws s3api list-buckets --query "Buckets[].Name" --output text
clinic-records	clinic-web	clinic-exports
ana@laptop:~/aws$ aws iam list-users --query "Users[].UserName" --output text
caio	bia
ana@laptop:~/aws$ aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-4201c37563e313c56	default
sg-d877b106d3b8c910b	booking-admin
```

Three lists, and none of them says which entry is wrong. **That is the gap a scanner fills**: the
lists are complete and say nothing, and the rules are in your head. Lesson 1's loop across 38
regions made the same point about size. Here there are three buckets, two users and two groups, and
reading them by eye already takes six more calls. The clinic's real account has more of everything.
