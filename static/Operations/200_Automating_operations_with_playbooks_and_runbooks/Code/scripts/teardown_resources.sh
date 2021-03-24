#!/bin/bash

ECR_REPONAME='walab-ops-sample-application'
SAMPLE_APPNAME=$ECR_REPONAME
CANARY_RESULT_BUCKET=$(aws cloudformation describe-stacks --stack-name $SAMPLE_APPNAME | jq '.Stacks[0].Outputs[] | select(.OutputKey == "OutputCanaryResultsBucket") | .OutputValue' | sed -e 's/^"//' -e 's/"$//')
MAIN_STACK='walab-ops-base-resources'


echo '############'
echo 'Cleanup Repo'
echo '############'
echo $ECR_REPONAME
aws ecr delete-repository --repository-name $ECR_REPONAME --force

echo '####################'
echo 'Cleanup Canary Bucket'
echo '####################'
echo $CANARY_RESULT_BUCKET
aws s3 rm s3://$CANARY_RESULT_BUCKET --recursive


echo '##########################'
echo 'Deleting Application Stack'
echo '##########################'
aws cloudformation delete-stack --stack-name $SAMPLE_APPNAME
aws cloudformation wait stack-delete-complete --stack-name $SAMPLE_APPNAME

echo '##########################'
echo 'Deleting Base Resources'
echo '##########################'
aws cloudformation delete-stack --stack-name $MAIN_STACK
aws cloudformation wait stack-delete-complete --stack-name $MAIN_STACK

echo '#########################################'
echo 'Application Teardown Complete'
echo '#########################################'