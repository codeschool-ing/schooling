#!/usr/bin/env bash
# The terminal sessions quoted in lesson 11 of cloud-security, as a script that
# produces them. The student never sees this file.
#
#   PYTHON3_DIR=/opt/cslab/py312 bash captures.sh > out.txt
#   python3 ../../paste.py . out.txt
#
# Four moto sessions, as the sections ask: "what-it-protects" and
# "managed-keys" each start moto empty with its checking off; "two-locks"
# starts it with INITIAL_NO_AUTH_ACTION_COUNT=3, the bootstrap of lesson 6 and
# with_key, which is that section's second ```sh fence, defined in this shell as
# typed; "envelope" starts it empty again, and "key-lifecycle" continues in the
# same moto. record.txt is the first ```sh fence of "what-it-protects".
#
# STAGED, beyond what ../../from-lessons.sh says for every lesson: commands
# that set a shell variable are run in this script's own shell by `keep`,
# which is what typing them into one terminal does.
#
# The rotation and deletion dates are the time of the run; the prose quotes
# none of them, only that the deletion is thirty days on.
#
# NOT PRODUCED HERE, and said so in the prose: AWS's refusal of an S3 read by a
# principal without kms:Decrypt (moto serves it), of an anonymous read of an
# object under a KMS key, of a disabled key (DisabledException) and of a key
# pending deletion (KMSInvalidStateException); the 7-to-30-day bounds of the
# deletion window (moto accepts others); the aws:SecureTransport policy (moto
# ignores conditions); TLS to AWS's endpoints; the AWS owned key.
#
# Recorded 2026-10-23 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
lab
keep() { printf 'ana@laptop:%s$ %s\n' "$PROMPT_DIR" "$*"; eval "$*" 2>&1 || true; }
FILES='record.txt record.enc big.bin note.txt note.enc'
POLICY='{"Version":"2012-10-17","Statement":[{"Effect":"Allow","Principal":"*","Action":"s3:GetObject","Resource":"arn:aws:s3:::clinic-records/*"}]}'

# ---- what-it-protects ---------------------------------------------------------
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT
bash -e <(sh_fences "$HERE/what-it-protects.md" 1) || exit 1

block sse-s3
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run 'aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --server-side-encryption AES256 --query ServerSideEncryption'

block public
run "aws s3api put-bucket-policy --bucket clinic-records --policy '$POLICY'"
run 'curl -s -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt'

block unpublic
run 'aws s3api delete-bucket-policy --bucket clinic-records'
run 'curl -s -o /dev/null -w "%{http_code}\n" http://localhost:4567/clinic-records/maria-souza.txt'

# ---- managed-keys ---------------------------------------------------------------
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block cmk
keep 'k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)'
export k
keep 'aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"'
run 'aws kms describe-key --key-id alias/clinic-records --query "KeyMetadata.[KeyManager,KeyState,Origin]" --output text'
run 'aws kms list-aliases --query "Aliases[].AliasName"'

block key-policy
run 'aws kms get-key-policy --key-id "$k" --policy-name default --query Policy --output text'

# ---- two-locks ------------------------------------------------------------------
[ "$(sh_fences "$HERE/two-locks.md" 1)" = 'INITIAL_NO_AUTH_ACTION_COUNT=3 moto_server -p 4567' ] \
  || { echo "two-locks fence 1 changed"; exit 1; }
moto_fresh INITIAL_NO_AUTH_ACTION_COUNT=3
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block bootstrap
run 'aws iam create-user --user-name admin --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name admin --policy-arn arn:aws:iam::aws:policy/AdministratorAccess'
keep 'key=$(aws iam create-access-key --user-name admin)'
run 'aws iam list-users'
keep 'export AWS_ACCESS_KEY_ID=$(echo "$key" | jq -r .AccessKey.AccessKeyId) AWS_SECRET_ACCESS_KEY=$(echo "$key" | jq -r .AccessKey.SecretAccessKey)'
run 'aws sts get-caller-identity --query Arn --output text'

eval "$(sh_fences "$HERE/two-locks.md" 2)"

block default-kms
keep 'k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)'
export k
keep 'aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"'
run 'aws s3api create-bucket --bucket clinic-records --create-bucket-configuration LocationConstraint=sa-east-1 --query Location --output text'
run "aws s3api put-bucket-encryption --bucket clinic-records --server-side-encryption-configuration '{\"Rules\":[{\"ApplyServerSideEncryptionByDefault\":{\"SSEAlgorithm\":\"aws:kms\",\"KMSMasterKeyID\":\"alias/clinic-records\"},\"BucketKeyEnabled\":true}]}'"
run 'aws s3api put-object --bucket clinic-records --key maria-souza.txt --body record.txt --query "[ServerSideEncryption,SSEKMSKeyId]" --output text'

block bia
run 'aws iam create-user --user-name bia --query User.Arn --output text'
run 'aws iam attach-user-policy --user-name bia --policy-arn arn:aws:iam::aws:policy/AmazonS3ReadOnlyAccess'
keep 'bia=$(aws iam create-access-key --user-name bia)'

block kms-refused
keep 'aws kms encrypt --key-id alias/clinic-records --plaintext fileb://record.txt --query CiphertextBlob --output text | base64 -d > record.enc'
keep 'with_key "$bia" aws kms decrypt --ciphertext-blob fileb://record.enc --query Plaintext --output text'

block s3-served
keep 'with_key "$bia" aws s3 cp s3://clinic-records/maria-souza.txt -'

# ---- envelope -------------------------------------------------------------------
unset AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY
# shellcheck disable=SC1091
. "$HOME/aws/env.sh"
moto_fresh
trap 'moto_stop; cd ~/aws && rm -f $FILES' EXIT

block envelope-key
keep 'k=$(aws kms create-key --description "clinic records" --query KeyMetadata.KeyId --output text)'
export k
keep 'aws kms create-alias --alias-name alias/clinic-records --target-key-id "$k"'

block limit
run 'head -c 5000 /dev/zero > big.bin && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://big.bin --query KeyId --output text'

block note
run "printf 'door code: 4471' > note.txt && aws kms encrypt --key-id alias/clinic-records --plaintext fileb://note.txt --query CiphertextBlob --output text | base64 -d > note.enc"
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --query KeyId --output text'
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo'

block data-key
run 'aws kms generate-data-key --key-id alias/clinic-records --key-spec AES_256 --query "[KeyId,length(Plaintext),length(CiphertextBlob)]" --output text'

# ---- key-lifecycle, same moto ---------------------------------------------------
block rotation
run 'aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled'
run 'aws kms enable-key-rotation --key-id "$k"'
run 'aws kms get-key-rotation-status --key-id "$k" --query KeyRotationEnabled'
run 'aws kms rotate-key-on-demand --key-id "$k" --output text'
run 'aws kms list-key-rotations --key-id "$k" --query "Rotations[].RotationType" --output text'

block disable
run 'aws kms disable-key --key-id "$k"'
run 'aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text'
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo'

block enable
run 'aws kms enable-key --key-id "$k"'

block deletion
run 'aws kms schedule-key-deletion --key-id "$k" --query DeletionDate --output text'
run 'aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text'
run 'aws kms decrypt --ciphertext-blob fileb://note.enc --query Plaintext --output text | base64 -d; echo'
run 'aws kms cancel-key-deletion --key-id "$k" --output text'
run 'aws kms describe-key --key-id alias/clinic-records --query KeyMetadata.KeyState --output text'
