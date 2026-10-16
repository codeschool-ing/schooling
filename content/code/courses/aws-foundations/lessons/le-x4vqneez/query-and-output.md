---
title: Shaping the answer: --query, --output, --dry-run and pages
version: 1
---

**Every answer the command line prints is a JSON document from the API, cut down by `--query` and
laid out by `--output`.** The two run on your computer, after the answer has arrived: neither
changes what AWS was asked or what it sends back. The two options at the end of this section,
`--dry-run` and the pagination options, are the opposite kind, because they change the requests.

The wrong picture is that `--query` is a filter AWS applies. **It is a JMESPath expression the
command line evaluates on the full answer**. That is why it can count, sort and reshape. It is also
why a filter in `--query` does not make a large listing any cheaper. Some commands have a
server-side `--filters` too, and that one does reduce what is sent.

## JMESPath, the language of `--query`

Lesson 1 met `length()` and a filter. The pieces combine:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)"
1544
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].PolicyName" --output text
AmazonS3ExpressFullAccess	AmazonS3ExpressReadOnlyAccess	AmazonS3FilesCSIDriverPolicy	AmazonS3FilesClientFullAccess	AmazonS3FilesClientReadOnlyAccess	AmazonS3FilesClientReadWriteAccess	AmazonS3FilesFullAccess	AmazonS3FilesReadOnlyAccess	AmazonS3FullAccess	AmazonS3ObjectLambdaExecutionRolePolicy	AmazonS3OutpostsFullAccess	AmazonS3OutpostsReadOnlyAccess	AmazonS3ReadOnlyAccess	AmazonS3TablesFullAccess	AmazonS3TablesLakeFormationServiceRole	AmazonS3TablesReadOnlyAccess
```

`Policies` is the list inside the answer, and `[? … ]` keeps the elements for which the condition is
true. `starts_with` is one of JMESPath's functions, and `.PolicyName` projects one field out of each
element that is left. **Literals go between backticks**, which a shell also uses, so the expression
is wrapped in double quotes and each backtick escaped with a backslash.

Four more shapes cover nearly every query in this course:

| expression | what it does |
|---|---|
| `Vpcs[0]` | the first element of a list |
| `Vpcs[].[VpcId,CidrBlock]` | a list of lists, one row per element, which `--output text` prints as columns |
| `Policies[].{name: PolicyName, v: DefaultVersionId}` | a list of objects with keys you choose, which `--output table` prints with headings |
| `sort_by(Policies, &AttachmentCount)` | the list sorted by a field |

## Four ways to print the same answer

```
ana@laptop:~/aws$ aws sts get-caller-identity --output json
{
    "UserId": "AKIAIOSFODNN7EXAMPLE",
    "Account": "123456789012",
    "Arn": "arn:aws:sts::123456789012:user/moto"
}
ana@laptop:~/aws$ aws sts get-caller-identity --output text
123456789012	arn:aws:sts::123456789012:user/moto	AKIAIOSFODNN7EXAMPLE
ana@laptop:~/aws$ aws sts get-caller-identity --output yaml
Account: '123456789012'
Arn: arn:aws:sts::123456789012:user/moto
UserId: AKIAIOSFODNN7EXAMPLE
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "Policies[?starts_with(PolicyName, \`AmazonS3\`)].{name: PolicyName, versions: DefaultVersionId, attached: AttachmentCount}" --output table
---------------------------------------------------------------------
|                           ListPolicies                            |
+----------+-------------------------------------------+------------+
| attached |                   name                    | versions   |
+----------+-------------------------------------------+------------+
|  0       |  AmazonS3ExpressFullAccess                |  v1        |
|  0       |  AmazonS3ExpressReadOnlyAccess            |  v1        |
|  0       |  AmazonS3FilesCSIDriverPolicy             |  v1        |
|  0       |  AmazonS3FilesClientFullAccess            |  v1        |
|  0       |  AmazonS3FilesClientReadOnlyAccess        |  v1        |
|  0       |  AmazonS3FilesClientReadWriteAccess       |  v1        |
|  0       |  AmazonS3FilesFullAccess                  |  v1        |
|  0       |  AmazonS3FilesReadOnlyAccess              |  v1        |
|  0       |  AmazonS3FullAccess                       |  v2        |
|  0       |  AmazonS3ObjectLambdaExecutionRolePolicy  |  v1        |
|  0       |  AmazonS3OutpostsFullAccess               |  v1        |
|  0       |  AmazonS3OutpostsReadOnlyAccess           |  v1        |
|  0       |  AmazonS3ReadOnlyAccess                   |  v3        |
|  0       |  AmazonS3TablesFullAccess                 |  v6        |
|  0       |  AmazonS3TablesLakeFormationServiceRole   |  v6        |
|  0       |  AmazonS3TablesReadOnlyAccess             |  v3        |
+----------+-------------------------------------------+------------+
```

**`json` is for programs, `text` for the shell, `table` for people, and `yaml` for files.** `text`
puts each value in a column separated by tabs, in an order the API decides, which is why it pairs
well with a `--query` that picks the order itself. `cut` and `read` split it without a parser.
`table` draws borders and titles, and is the one never to feed to another program. The last command
shows what a multiselect hash buys in a table: the headings are the keys the query named.
`yaml-stream` is a fifth format, which prints each page of a long listing as it arrives.

## `--dry-run`: asking whether, without doing

**EC2 accepts `--dry-run` on the calls that create, change or delete**, and answers whether the
call would have been allowed without making it:

```
ana@laptop:~/aws$ aws ec2 run-instances --image-id ami-0629d059c178d0eac --instance-type t3.micro --dry-run; echo "exit $?"

aws: [ERROR]: An error occurred (DryRunOperation) when calling the RunInstances operation: Request would have succeeded, but DryRun flag is set.
exit 254
ana@laptop:~/aws$ aws ec2 describe-instances --query "length(Reservations)"
0
```

**A successful dry run is an error**, `DryRunOperation`, with the sentence "Request would have
succeeded", and an exit code of 254. A script that tests `$?` has to look at the error code instead,
since both outcomes fail. A caller without the permission gets `UnauthorizedOperation` in AWS. moto
here checks no permissions, so that half was not measured. No instance was made, as the count shows.
The option is EC2's. Most services have nothing like it, and the course leans on moto's permission
checking for the same question elsewhere.

## Pages, which the command line hides

Listings come back from the API in pages: IAM's `ListPolicies` returns 100 policies per call by
default, with a `Marker` that asks for the next page. **The command line follows the markers
itself** and prints one answer, so the 1544 policies above, moto's copy of AWS's managed ones, took
several requests. `--debug` reports each one:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"
16
ana@laptop:~/aws$ aws iam list-policies --scope AWS --page-size 500 --query "length(Policies)" --debug 2>&1 | grep -c "Making request for OperationModel(name=ListPolicies"
4
```

**`--page-size` changes how many items each request asks for, and nothing about the answer**: 16
requests of 100 became 4 of 500, with the same 1544 policies at the end. It matters against a
service that throttles, or a call that times out on a large page. **`--max-items` changes the
answer**: it stops after that many items and prints a `NextToken`, and `--starting-token` carries on
from it:

```
ana@laptop:~/aws$ aws iam list-policies --scope AWS --max-items 2 --query "{names: Policies[].PolicyName, next: NextToken}"
{
    "names": [
        "AIDevOpsAgentAccessPolicy",
        "AIDevOpsAgentActionsPolicy"
    ],
    "next": "eyJNYXJrZXIiOiBudWxsLCAiYm90b190cnVuY2F0ZV9hbW91bnQiOiAyfQ=="
}
ana@laptop:~/aws$ NEXT=$(aws iam list-policies --scope AWS --max-items 2 --output json | jq -r .NextToken)
ana@laptop:~/aws$ aws iam list-policies --scope AWS --max-items 2 --starting-token $NEXT --query "Policies[].PolicyName"
[
    "AIDevOpsAgentFullAccess",
    "AIDevOpsAgentReadOnlyAccess"
]
```

The token is the command line's own, built around the service's marker, and it is only good for the
same command with the same options. `--no-paginate` turns the following off altogether and prints
only the first page the API sent.
