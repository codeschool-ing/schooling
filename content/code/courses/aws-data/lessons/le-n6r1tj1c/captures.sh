#!/usr/bin/env bash
# The terminal sessions quoted in lesson 18 of aws-data (Lake Formation), as a
# script that produces them. Every transcript in the lesson was copied from its
# output.
#
#   sudo bash ../../lab.sh run captures.sh
#
# moto 5.2.3 keeps Lake Formation's settings, registered locations, LF-tags and
# grants as records, and enforces none of them: no engine runs here to ask it.
# Data cells filters and the credential vending calls are not implemented and
# answer 404; CloudTrail's lookup-events answers 500. The lesson says so where
# each one appears.
#
# The CSV and the Glue table's definition are read out of the-model.md, where
# the student is given them.
#
# STAGED: nothing.
#
# Recorded 2026-10-16 on Ubuntu 24.04, TZ=America/Sao_Paulo.

set -uo pipefail
HERE=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=../../from-lessons.sh
. "$HERE/../../from-lessons.sh"
cd ~/aws || exit 1
L="$LESSONS/le-n6r1tj1c"
A='arn:aws:iam::123456789012:role/analyst'
S='arn:aws:iam::123456789012:role/support'

bash -e <(fence "$L/why-not-iam.md" 1) || exit 1
block iam-object
run 'aws s3 mb s3://quitanda-curated-prod'
run 'aws s3 cp lake/part-0.csv s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv'
run 'aws s3 cp s3://quitanda-curated-prod/curated/orders/dt=2026-10-01/part-0.csv -'

file_fence "$L/the-model.md" orders-table.json > orders-table.json || exit 1
block lf-catalog
run 'aws glue create-database --database-input Name=curated'
run 'aws glue create-table --database-name curated --table-input file://orders-table.json'
run 'aws glue get-table --database-name curated --name orders --query "Table.StorageDescriptor.Columns[].Name" --output text'

block lf-settings
run 'aws lakeformation get-data-lake-settings'

block lf-admin
run "aws lakeformation put-data-lake-settings --data-lake-settings '{\"DataLakeAdmins\":[{\"DataLakePrincipalIdentifier\":\"arn:aws:iam::123456789012:user/moto\"}]}'"
run 'aws lakeformation get-data-lake-settings'

block lf-register
run 'aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/curated --use-service-linked-role'
run 'aws lakeformation list-resources'

block lf-grant
run "aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=$A --permissions DESCRIBE --resource '{\"Database\":{\"Name\":\"curated\"}}'"
run "aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=$A --permissions SELECT --resource '{\"TableWithColumns\":{\"DatabaseName\":\"curated\",\"Name\":\"orders\",\"ColumnNames\":[\"order_id\",\"customer_id\",\"total_cents\",\"dt\"]}}'"
run 'aws lakeformation list-permissions --query "PrincipalResourcePermissions[?Resource.TableWithColumns]"'

block lf-hybrid
run 'aws lakeformation register-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing --use-service-linked-role --hybrid-access-enabled'
run 'aws lakeformation describe-resource --resource-arn arn:aws:s3:::quitanda-curated-prod/marketing'
run "aws lakeformation create-lake-formation-opt-in --principal DataLakePrincipalIdentifier=$A --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"orders\"}}'"

block lf-tags
run 'aws lakeformation create-lf-tag --tag-key sensitivity --tag-values public internal pii'
run "aws lakeformation add-lf-tags-to-resource --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"orders\"}}' --lf-tags TagKey=sensitivity,TagValues=internal"
run "aws lakeformation add-lf-tags-to-resource --resource '{\"TableWithColumns\":{\"DatabaseName\":\"curated\",\"Name\":\"orders\",\"ColumnNames\":[\"phone\"]}}' --lf-tags TagKey=sensitivity,TagValues=pii"
run "aws lakeformation get-resource-lf-tags --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"orders\"}}'"

block lf-tag-grant
run "aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=$S --permissions SELECT --resource '{\"LFTagPolicy\":{\"ResourceType\":\"TABLE\",\"Expression\":[{\"TagKey\":\"sensitivity\",\"TagValues\":[\"internal\",\"pii\"]}]}}'"
run "aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0],keys(Resource)[0]]' --output text"

file_fence "$L/lf-tags-and-filters.md" support-filter.json > support-filter.json || exit 1
block lf-filter
run 'aws lakeformation create-data-cells-filter --table-data file://support-filter.json'
run 'aws lakeformation list-data-cells-filter'

block lf-vend
run 'aws lakeformation get-temporary-glue-table-credentials --table-arn arn:aws:glue:sa-east-1:123456789012:table/curated/orders --permissions SELECT'

block lf-nothing
run "aws lakeformation grant-permissions --principal DataLakePrincipalIdentifier=$A --permissions SELECT --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"ordres\"}}'"
run "aws lakeformation list-permissions --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"ordres\"}}' --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,Permissions[0]]' --output text"
run 'aws glue get-table --database-name curated --name ordres'

block lf-audit
run "aws lakeformation list-permissions --query 'PrincipalResourcePermissions[].[Principal.DataLakePrincipalIdentifier,join(\`,\`,Permissions),Resource.TableWithColumns.Name || Resource.Table.Name || Resource.Database.Name || \`tag policy\`]' --output table"

block lf-revoke
run "aws lakeformation revoke-permissions --principal DataLakePrincipalIdentifier=$A --permissions SELECT --resource '{\"Table\":{\"DatabaseName\":\"curated\",\"Name\":\"ordres\"}}'"
run "aws lakeformation list-permissions --query 'length(PrincipalResourcePermissions)'"

block lf-trail
run 'aws cloudtrail lookup-events --lookup-attributes AttributeKey=EventName,AttributeValue=GrantPermissions --max-results 5'
