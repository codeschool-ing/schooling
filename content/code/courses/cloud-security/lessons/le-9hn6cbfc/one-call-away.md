---
title: A defence and a failure, one call apart
version: 1
---

**This section shows the previous one in your lab: an account you have never touched already has a network
in it, a private bucket becomes public with one request, and the request that undoes it is just as
short.** Start moto in the first terminal, empty, and read `env.sh` in both.

## What an empty account already has

Ask the account what networks it holds before you have created anything:

```
ana@laptop:~/aws$ aws ec2 describe-vpcs --query "Vpcs[].[VpcId,CidrBlock,IsDefault]" --output text
vpc-fcbbbe17385be3d51	172.31.0.0/16	True
ana@laptop:~/aws$ aws ec2 describe-security-groups --query "SecurityGroups[].[GroupId,GroupName]" --output text
sg-d591b6e6e30335630	default
ana@laptop:~/aws$ aws ec2 describe-regions --query "length(Regions)"
38
ana@laptop:~/aws$ for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do aws ec2 describe-vpcs --region "$r" --query "Vpcs[?IsDefault].VpcId" --output text; done | wc -l
38
```

**One default network per region, and nobody asked for any of them.** AWS does the same: an account
gets a *default VPC* in each region it has enabled, with a subnet in every Availability Zone, a route
to the internet and a security group, so that a first machine works without any networking
decisions. moto answers with one in each of its 38 regions. Every one is somewhere a resource can be
launched, and an inventory that reads only `sa-east-1` sees one of them. Lesson 8 decides what to do
with them; for now, notice that **the question was one loop, and on premises it would have been a
week with a clipboard**.

## A private bucket

Stop moto with Ctrl+C in the first terminal and start it again, so that what it prints from here on
is this part alone, and the default networks are gone with the rest.

The clinic's booking application exports the day's appointments to a bucket. Create the bucket, and
a small file that stands in for the export:

```sh
cat > appointments.csv <<'EOF'
date,time,patient,doctor
2026-10-23,09:00,Maria Souza,Dr. Lima
2026-10-23,09:30,João Pereira,Dr. Lima
EOF
```

```
ana@laptop:~/aws$ aws s3api create-bucket --bucket clinic-exports --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text
/clinic-exports
ana@laptop:~/aws$ aws s3 cp --no-progress appointments.csv s3://clinic-exports/2026-10-23.csv
upload: ./appointments.csv to s3://clinic-exports/2026-10-23.csv
```

Now ask for that object **the way a stranger would**: with `curl`, which sends no credentials at all.

```
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
403
```

`403` is *forbidden*. A request with no identity behind it is refused, which is the default for every
new bucket and the right one.

## One request later

caio wants the reception's tablet to read the export without anybody typing a password, and somebody
suggests the quickest way. It is a bucket policy that allows `s3:GetObject` to `"Principal": "*"`,
which means **everybody**, signed in or not:

```
ana@laptop:~/aws$ aws s3api put-bucket-policy --bucket clinic-exports --policy '{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-exports/*"}]}'
ana@laptop:~/aws$ curl -s -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
date,time,patient,doctor
2026-10-23,09:00,Maria Souza,Dr. Lima
2026-10-23,09:30,João Pereira,Dr. Lima
200
```

**Two patients' names and their doctor, served to a request that proved nothing about who sent
it.** On AWS that address would be a name on the internet rather than `localhost`, and the result
would be the same for anyone who found it. The command that did it printed nothing. No warning, no
confirmation, no second person: the API did what a valid key asked.

Against a real account created this year, that `put-bucket-policy` would have been refused, because
AWS now switches on a guardrail called **Block Public Access** for every new bucket, and lesson 9
shows why it took a decade of incidents to get there. moto stores that guardrail and enforces none of
it, which is what lets this lab show the failure the guardrail exists to stop.

The first terminal recorded every request since moto started:

```
ana@laptop:~/aws$ moto_server -p 4567
WARNING: This is a development server. Do not use it in a production deployment. Use a production WSGI server instead.
 * Running on http://127.0.0.1:4567
Press CTRL+C to quit
127.0.0.1 - - [23/Oct/2026 00:30:46] "PUT /clinic-exports HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:47] "PUT /clinic-exports/2026-10-23.csv HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:47] "GET /clinic-exports/2026-10-23.csv HTTP/1.1" 403 -
127.0.0.1 - - [23/Oct/2026 00:30:48] "PUT /clinic-exports?policy HTTP/1.1" 200 -
127.0.0.1 - - [23/Oct/2026 00:30:48] "GET /clinic-exports/2026-10-23.csv HTTP/1.1" 200 -
```

Read the two `GET` lines, which are the two from `curl`. The same object, the same address, minutes
apart: refused, then served. **A log line like the second
one is how most exposures are discovered**, usually long after the fact and usually by somebody
else. Lesson 15 is about keeping the line that tells you who changed the policy in between.

## And one request back

The fix is the same size as the fault:

```
ana@laptop:~/aws$ aws s3api delete-bucket-policy --bucket clinic-exports
ana@laptop:~/aws$ curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-exports/2026-10-23.csv
403
```

**Prove a fix the way the fault was found**: by asking again, as the stranger, and reading the answer.
"I removed the policy" is a claim. `403` from an anonymous request is evidence, and it is the habit
every later lesson asks of you.
