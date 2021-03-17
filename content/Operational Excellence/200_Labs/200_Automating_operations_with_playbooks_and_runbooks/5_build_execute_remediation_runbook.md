---
title: "Build & Execute Remediation Runbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 5
pre: "<b>5. </b>"
---

In the previous section, we have built an automated playbook to investigate the application environment. The output the playbook gathered allows us to come up with a conclusion on the cause of the issue, and for us to decide the next course of action.

In this section we will build an automated [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) to scale up the application cluster. The runbook will send a notification for Systems owner to intervene, it will also send summary to developer.
  

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-architecture.png)

### 4.0 Prepare playbook IAM Role & SNS Topic

Instructions to be added

### 4.1 Playbook Build - Gathering resources in sample application.

As an administrator / engineer, before we even investigate anything in the application, we need to know what are the services / components involved. When we receive the alarm from cloudwatch in the inbox, the information presented does not contain straight away these components / services involved. So the first thing we need to do is to build a playbook step to acquire all the related resources using information tha tis contained in the alarm. please follow below steps to continue.

{{% notice note %}}
**Note:** For the following step to build and run playbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the playbook.
{{% /notice %}}

{{%expand "Click here for Console step by step"%}}

To build our playbook, go ahead and go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. 

Once you are there, click on **Create Automation**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation.png)

Next, enter in `Playbook-GatherAppResources-Canary-CloudWatchAlarm` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does.

```
  # What is does this playbook do?

  This playbook will query the CloudWatch Synthetics Canary, and look for all resources related to the application based on it's Application Tag. This playbook takes an input of the CloudWatch Alarm ARN triggered by the canary

  Note : Application resources must be deployed using CloudFormation and properly tagged accordingly.

  ## Steps taken in the code

  ### Step 1
  1. Describe CloudWatch Alarm ARN, and identify the Canary resource.
  2. Describe the Canary resource to gather the value of 'Application' tag
  3. Gather Cloudformation Stack with the same value of 'Application' tag.
  4. List all resources in Cloudformation Stack.
  5. Parse list of resources into String Output.

```

Systems Manager supports putting in nots as markdown, so feel free to format it as needed. 

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-name-attributes.png)

Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-role.png)

Under **Input Parameters** field, enter `AlarmARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will essentially define a Parameter into our playbook, so that we can pass on the value of the CloudWatch Alarm to the main step that will do the action.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input.png)

Right under **Add Step** section enter `Gather_Resources_For_Alarm` under the **Step name**, select `aws::executeScript` as the **Action type**. 

Under **Inputs** set `Python3.6` as the **Runtime**, and specify `script_handler` as the **Handler**.

Paste in below python codes into the **Script** section.

```
import json
import re
from datetime import datetime
import boto3
import os

def arn_deconstruct(arn):
  arnlist = arn.split(":")
  service=arnlist[2]
  region=arnlist[3]
  accountid=arnlist[4]
  servicetype=arnlist[5]
  name=arnlist[6]
  return {
    "Service": service,
    "Region": region,
    "AccountId": accountid,
    "Type": servicetype,
    "Name": name
  }

def locate_alarm_source(alarm):
  cwclient = boto3.client('cloudwatch', region_name = alarm['Region'] )
  alarm_source = {}
  alarm_detail = cwclient.describe_alarms(AlarmNames=[alarm['Name']])  
  
  if len(alarm_detail['MetricAlarms']) > 0:
    metric_alarm = alarm_detail['MetricAlarms'][0]
    namespace = metric_alarm['Namespace']
    
    # Condition if NameSpace is CloudWatch Syntetics
    if namespace == 'CloudWatchSynthetics':
      if 'Dimensions' in metric_alarm:
        dimensions = metric_alarm['Dimensions']
        for i in dimensions:
          if i['Name'] == 'CanaryName':
            source_name = i['Value']
            alarm_source['Type'] = namespace
            alarm_source['Name'] = source_name
            alarm_source['Region'] = alarm['Region']
            alarm_source['AccountId'] = alarm['AccountId']

    result = alarm_source
    return result

def locate_canary_endpoint(canaryname,region):
  result = None
  synclient = boto3.client('synthetics', region_name = region )
  res = synclient.get_canary(Name=canaryname)
  canary = res['Canary']
  if 'Tags' in canary:
    if 'TargetEndpoint' in canary['Tags']:
      target_endpoint = canary['Tags']['TargetEndpoint']
      result = target_endpoint
  return result


def locate_app_tag_value(resource):
  result = None
  if resource['Type'] == 'CloudWatchSynthetics':
    synclient = boto3.client('synthetics', region_name = resource['Region'] )
    res = synclient.get_canary(Name=resource['Name'])
    canary = res['Canary']
    if 'Tags' in canary:
      if 'Application' in canary['Tags']:
        apptag_val = canary['Tags']['Application']
        result = apptag_val
  return result

def locate_app_resources_by_tag(tag,region):
  result = None
  
  # Search CloufFormation Stacks for tag
  cfnclient = boto3.client('cloudformation', region_name = region )
  list = cfnclient.list_stacks(StackStatusFilter=['CREATE_COMPLETE','ROLLBACK_COMPLETE','UPDATE_COMPLETE','UPDATE_ROLLBACK_COMPLETE','IMPORT_COMPLETE','IMPORT_ROLLBACK_COMPLETE']  )
  for stack in list['StackSummaries']:
    app_resources_list = []
    stack_name = stack['StackName']
    stack_details = cfnclient.describe_stacks(StackName=stack_name)
    stack_info = stack_details['Stacks'][0]
    if 'Tags' in stack_info:
      for t in stack_info['Tags']:
        if t['Key'] == 'Application' and t['Value'] == tag:
          app_stack_name = stack_info['StackName']
          app_resources = cfnclient.describe_stack_resources(StackName=app_stack_name)
          for resource in app_resources['StackResources']:
            app_resources_list.append(
              { 
                'PhysicalResourceId' : resource['PhysicalResourceId'],
                'Type': resource['ResourceType']
              }
            )
          result =  app_resources_list
  
  return result
def script_handler(event, context):
  result = {}
  arn = event['CloudWatchAlarmARN']
  alarm = arn_deconstruct(arn)
  # Locate tag from CloudWatch Alarm

  alarm_source = locate_alarm_source(alarm) # Identify Alarm Source
  tag_value = locate_app_tag_value(alarm_source) #Identify tag from source
  
  if alarm_source['Type'] == 'CloudWatchSynthetics':
    endpoint = locate_canary_endpoint(alarm_source['Name'],alarm_source['Region'])
    result['CanaryEndpoint'] = endpoint
    
  # Locate cloudformation with tag
  resources = locate_app_resources_by_tag(tag_value,alarm['Region'])
  result['ApplicationStackResources'] = json.dumps(resources) 
  
  return result
```

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-addstep.png)

Under **Additional inputs** specify input value to the step passing in the parameter we created before.
to do this, select `Input Payload` under **Input name** and specify `CloudWatchAlarmARN: '{{AlarmARN}}'` as the **Input Value**. the '{{AlarmARN}}' section essentially references the parameter value we created before.
Within the same section, specify the outputs of the step. `Resources` as the **Name** `$.Payload.ApplicationStackResources` as the **Selector** and `String` as the **Type**.

For more information about Automation Document syntax, please refer [here](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html)

Once your setting looks as per screen shot below, click on **Create Automation**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-additionals.png)

{{%/expand%}}

{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_gather-resources.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-playbook-gather-resources` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_gather-resources.yml "Resources template")


To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.
  
```
aws cloudformation create-stack --stack-name waopslab-playbook-gather-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://playbook_gather-resources.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-playbook-gather-resources \
                                --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://playbook_gather-resources.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-playbook-gather-resources
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}


Once the document is using any of the above method created, you can find the newly created document under the **Owned by me** tab of the Document resource, click on the playbook called `Playbook-GatherAppResources-Canary-CloudWatchAlarm` and click on **Execute Automation** to execute our playbook

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-execute.png)

Paste in the Cloudwatch Alarm ARN (you can refer to the email you received from the simulation we did on section 3), and click on **Execute**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-execute2.png)

You can observe the playbook executing, and once it is completed, you can click on the **Step Id** to see the final message. output of the step. And in our case, the step had executed the python script to find the resources related to the application, using CloudWatch Alarm ARN. and once it is successful, you should be able to see this output listing all the resources of the application

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-execute-output.png)

Copy the Resources list output from the section in the screenshot above ( marked in red box )
Paste the output into a temporary location, as we will need this value for our next step. 



___
**END OF SECTION 5**
___