---
title: Finding every copy, and the country it is in
version: 1
---

**Residency is the one question of the three the API answers: every bucket and every key lives in
exactly one region, and the region is a country. Asking takes a loop. Reading the answer correctly
takes knowing one trap.** Start moto in the first terminal, empty, and read `env.sh` in both.

## The clinic, with one copy abroad

These commands build the account the section reads. Three buckets hold patient data and carry a tag
saying so; the website does not. caio's backup bucket was created in `us-east-1`:

```sh
for b in clinic-records clinic-exports clinic-web; do
  aws s3api create-bucket --bucket "$b" --create-bucket-configuration LocationConstraint=sa-east-1 > /dev/null
done
aws s3api create-bucket --bucket clinic-backups-us --region us-east-1 > /dev/null
for b in clinic-records clinic-exports clinic-backups-us; do
  aws s3api put-bucket-tagging --bucket "$b" --tagging 'TagSet=[{Key=data-class,Value=health}]'
done
aws s3api put-bucket-tagging --bucket clinic-web --tagging 'TagSet=[{Key=data-class,Value=public}]'
aws kms create-key --description records > /dev/null
aws kms create-key --region us-east-1 --description backups > /dev/null
```

The bucket in `us-east-1` is created **without** a `LocationConstraint`. That region is S3's oldest,
and it is the one place a bucket is made by leaving the constraint out; AWS's documentation says it
refuses `LocationConstraint=us-east-1`, which was not run here. Remember it, because it comes back as
the trap below.

## Which regions are Brazil

```
ana@laptop:~/aws$ aws ec2 describe-regions --query "Regions[?starts_with(RegionName, 'sa-')].RegionName" --output text
sa-east-1
```

One. Whatever is not in `sa-east-1` is not in Brazil.

## Every bucket, its region and its class

```
ana@laptop:~/aws$ for b in $(aws s3api list-buckets --query "Buckets[].Name" --output text); do echo "$b $(aws s3api get-bucket-location --bucket "$b" --query LocationConstraint --output text) $(aws s3api get-bucket-tagging --bucket "$b" --query "TagSet[?Key=='data-class'].Value" --output text)"; done
clinic-records sa-east-1 health
clinic-exports sa-east-1 health
clinic-web sa-east-1 public
clinic-backups-us None health
```

**`clinic-backups-us` says `None`, and `None` is not "no region".** `get-bucket-location` answers
`null` for a bucket in `us-east-1`, for the same historical reason it was created without a
constraint, and the command line prints a JSON `null` as `None`. A script that keeps only the lines
naming a foreign region, or one that treats a missing value as harmless, skips exactly the bucket it
was written to find. **The one bucket of patient data outside Brazil is the one whose region reads
as nothing.** moto answers as AWS does here; the trap is real.

The tag is what makes the line mean something. Without `data-class`, the inventory says a bucket is
in Virginia and nothing about whether that matters; with it, `None health` is a sentence: health
data, outside the country. That is why lesson 16 and the `cloud` course's lesson 10 both ask for tags
on every resource. A tag is the cheapest way to make an inventory answer a legal question.

## Keys have a country too

An ordinary KMS key stays in the region it was created in (a multi-Region key is copied to other
regions on purpose, and says so), so the keys tell you where encrypted data is being read. Ask every region, and print only those that hold a key:

```
ana@laptop:~/aws$ for r in $(aws ec2 describe-regions --query "Regions[].RegionName" --output text); do n=$(aws kms list-keys --region "$r" --query "length(Keys)"); [ "$n" != 0 ] && echo "$r $n"; done
sa-east-1 1
us-east-1 1
```

A key in `us-east-1` means something in `us-east-1` is encrypted with it, or is meant to be. It is the
same finding seen from another side, and it would be just as visible if the bucket had a less
honest name than `clinic-backups-us`.

## What the inventory is for

This loop is evidence, of the kind the last section asks for: on this date, these copies existed in
these countries. Run on a schedule, it is a residency rule in lesson 16's sense. It finds the copy
after it is made. The next section stops it being made.
