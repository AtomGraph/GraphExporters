#!/bin/bash

# https://docs.aws.amazon.com/neptune/latest/userguide/iam-auth-connect-command-line.html

print_usage()
{
    printf "Queries Neptune SPARQL endpoint.\n"
    printf "\n"
    printf "Usage:   cat query.rq | %s SPARQL_ENDPOINT ROLE_ARN REGION\n" "$0"
    printf "Example: echo \"ASK {}\" | %s https://neptuneinstance-9yayusfky7oj.cnol6sn9sq5j.us-east-1.neptune.amazonaws.com:8182/sparql arn:aws:iam::580601482069:role/NeptuneClient us-east-1\n" "$0"
}

if [ "$#" -ne 3 ]; then
    print_usage
    exit 1
fi

neptune_sparql_endpoint="$1"
neptune_role_arn="$2" # needs to be Allowed to perform neptune-db:* actions
neptune_region="$3"
aws_profile="default"
tmpfile=$(mktemp)
query=$(cat)

unset AWS_ACCESS_KEY_ID
unset AWS_SECRET_ACCESS_KEY
unset AWS_SESSION_TOKEN

#echo "AWS_ACCESS_KEY_ID: $AWS_ACCESS_KEY_ID"
#echo "AWS_SECRET_ACCESS_KEY: $AWS_SECRET_ACCESS_KEY"
#echo "AWS_SESSION_TOKEN: $AWS_SESSION_TOKEN"

aws sts assume-role \
    --profile "$aws_profile" \
    --duration-seconds 1800 \
    --role-arn "$neptune_role_arn" \
    --role-session-name AWSCLI-Session > "$tmpfile"

AccessKeyId=$(cat "$tmpfile" | jq -r '.Credentials''.AccessKeyId')
SecretAccessKey=$(cat "$tmpfile" | jq -r '.Credentials''.SecretAccessKey')
SessionToken=$(cat "$tmpfile" | jq -r '.Credentials''.SessionToken')

export AWS_ACCESS_KEY_ID="$AccessKeyId"
export AWS_SECRET_ACCESS_KEY="$SecretAccessKey"
export AWS_SESSION_TOKEN="$SessionToken"

# aws sts get-caller-identity

awscurl "$neptune_sparql_endpoint" \
    -X POST \
    -d "query=${query}" \
    --region "$neptune_region" \
    --service neptune-db \
    --header 'Content-Type: application/x-www-form-urlencoded'