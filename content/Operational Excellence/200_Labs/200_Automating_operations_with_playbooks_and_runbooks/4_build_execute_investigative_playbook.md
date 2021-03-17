---
title: "Build & Execute Investigative Playbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 4
pre: "<b>4. </b>"
---

In the previous section we have built a sample vpc environment with a deployed our application API running in it. 
We then sent through large incoming traffic to the API to simulating an increase with the Application latency driven by the application being overwhelmed. For a seasoned systems administrator / engineer, who knows the ins and outs of the application architecture and it's general behaviour, investigating latency issue might be a relatively simple task to do. He / She would already know which service or components are  involved in the application, and which metrics and data matters and which one don't. Over time these administrator / engineer would build a certain muscle memory around this and they would instinctively be able to perform these tasks when issue occurred.

The problem with this is that all those information and knowledge is contained within the individual admin / engineer, passing on the knowlegde and methodology invovled can be very hard to do. This is where a [playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) comes into place. [Playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) are essentially predefined steps to perform to identify an issue. The results from any process step are used to determine the next steps to take until the issue is identified or escalated. 

This could be just as simple as a wiki page with instructions or guides that a non seasoned admin / engineer can follow to investigate the issue. But to be able to increase scalability, reliability and time taken to execute this playbook, you'd want to look into automating this playbook as much as possible. There are various different tools you can use to build automated playbook, but in AWS we have [AWS Systems Manager Automation Document](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html) that you could utilize to build this. The service allows you to build a series of executable steps to orchestrate your investigation into the issue, you can execute python / nodejs script, call the api of AWS service directly, or execute a remote command into the operating system where your application is running (if your workload runs on EC2).

So, in this section we will focus on how we can troubleshoot the issue with our sample application using an automated playbook we build in AWS Systems Manager Automation Document.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-architecture.png)


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


### 4.2 Playbook Build - Gathering Information from relevant Application resources.

Now that have have defined a playbook that captures all related AWS resources in the application, the next thing we want to do is to investigate relevant resources and capture the most recent statistics, logs to look for insights and better understand the cause of the issue.

In practice there can be various permutations on what resources you will look at depending on the context of the issue. But in this scenario, we will be looking specifically at the Elastic Load Balancer, the Elastic Compute Service, and Relational Database Statistics and logs.

We will then highlight the metrics that is considered outside the threshold.

Please follow below instructions to build this playbook.

{{% notice note %}}
**Note:** For the majority, the tasks to be done this step will be identical with our previous step, we will just be passing in different scripts in each of the step to query the related services and gather it's data. Therefore to reduce the repetition in the steps we will deploy this playbook via cloudformation template
Please follow the steps below to deploy via cloudformation template via CLI / or Console. 
{{% /notice %}}


{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_investigate_application_resources.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-playbook-investigate-resources` as the **Stack Name**, as this is referenced by other stacks later in the lab.


{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_investigate_application_resources.yml "Resources template")


To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.
  
```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://playbook_investigate_application_resources.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-resources \
                                --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://playbook_investigate_application_resources.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-playbook-investigate-resources
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 

{{%/expand%}}

Once the document is using any of the above method created, you can go ahead and do a quick test.
You can find the newly created document under the **Owned by me** tab of the Document resource, click on the playbook called `Playbook-InvestigateAppResources-ELB-ECS-RDS` and click on **Execute Automation** to execute our playbook

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-investigate-execute.png)

Paste in the Resources List you took note from the output of the previous playbook (refer to previous step) under **Resources** and click on **Execute**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-investigate-execute2.png)

Wait until all steps are completed successfully.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-investigate-execute-output.png)


### 4.3 Playbook Build - Chaining 2 Playbooks into 1.

So far we have 2 separate playbooks that does 2 different things, one is to gather the list of resources of the application, and the other is to go through relevant resources and investigate it's logs and statistics.

Each of this playbook can be kept as a repeatable artefact that is re-usable for multiple different purposes.
That said, executing these 2 separate steps and manually passing the output as an input to the other playbook is a tedious task, and it requires human intervention.

Therefore in this step we will automate our playbook further by creating a parent playbook that orchestrates the 2 Investigative playbook subsequently, additionally we will also inject another step to send notification to our Developers and System Owners to notify of this issue.

Follow below instructions to build the Playbook.

{{%expand "Click here for CloudFormation CLI deployment step"%}}
{{%/expand%}}
{{%expand "Click here for CloudFormation Console deployment step"%}}
{{%/expand%}}
{{%expand "Click here for Console step by step"%}}


To build our playbook, go ahead and go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. 

Once you are there, click on **Create Automation**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation.png)

Next, enter in `Playbook-InvestigateApplication-From-CanaryCloudWatchAlarm` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does.

```
# What is does this playbook do?

This playbook will execute **Playbook-GatherAppResources-Canary-CloudWatchAlarm** to gather Application resources monitored by Canary.

Then subsequently execute **Playbook-InvestigateAppResources-ELB-ECS-RDS** to Investigate the resources for issues. 

Outputs of the investigation will be sent to SNS Topic Subscriber
  
```

Systems Manager supports putting in nots as markdown, so feel free to format it as needed. 

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-name-attributes-2.png)

Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-role.png)

Under **Input Parameters** field, enter `AlarmARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will define a Parameter into our playbook, so that we can pass on the value of the CloudWatch Alarm to the main step that will do the action.

Add another parameter by clicking on the **Add a parameter** link. Enter `SNSTopicARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will  define another Parameter into our playbook, so that we can send notification to the Owner and Developer.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2.png)


Click **Add Step** and  create the first step of `aws:executeAutomation` Action type with StepName `PlaybookGatherAppResourcesCanaryCloudWatchAlarm`
Specify `Playbook-GatherAppResources-Canary-CloudWatchAlarm` as the **Document name** under Inputs, and under **Additional inputs** specify `RuntimeParameters` with `AlarmARN:'{{AlarmARN}}'` as it's value ( refer to screenshot below ) 

This essentially defines that in this step we will be executing the first playbook we created which takes input of the CloudWatch AlarmARN and returns the list of related resources.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step1.png)

Once this step is defined, add another step by clicking on **Add Step** at the bottom of the section.

For this second step, specify the **Step name** as `PlaybookInvestigateAppResourcesELBECSRDS` abd action type `aws:executeAutomation`.
Specify `Playbook-InvestigateAppResources-ELB-ECS-RDS` as the **Document name**, and `RuntimeParameters` as `Resources: '{{PlaybookGatherAppResourcesCanaryCloudWatchAlarm.Output}}'`

This second step will take the output of the first step and pass that to the second Playbook to execute the investigation of relevant resources.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step2.png)

Now for the last step, we want to take the output investigation from the second step and send that to the SNS topic where our owner, developers, and admin are subscribed.

specify the **Step name** as `AWSPublishSNSNotification` abd action type `aws:executeAutomation`.
Specify `AWS-PublishSNSNotification` as the **Document name**, and `RuntimeParameters` as below 

```
TopicArn: '{{SNSTopicARN}}'
Message: '{{ PlaybookInvestigateAppResourcesELBECSRDS.Output }}'
```
This last step will take the output of the second step which contains summary data of the investigation and AWS-PublishSNSNotification which will send an email to the SNS we specified in the parameters.


![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step3.png)

{{%/expand%}}

### 4.4 Playbook Test.

Now that we have built our Playbook to Investigate this issue, lets test this in a simulated scenario.

Go back to your **Cloud9** terminal you created in Section 2, execute the command to send traffic to the application.

```
ALBURL="< Application Endpoint URL captured from section 2>"
ab -p test.json -T application/json -c 3000 -n 60000000 -v 4 http://$ALBURL/encrypt
```

Leave it running for about 2-3 minutes, and wait until the notification email from the alarm arrives.

Once the alarm notification email arrived, capture the CloudWatch Alarm ARN 

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-email.png)

Then go to the Systems Manager Automation document we just created in the previous step, and execute the playbook passing the ARN as the **AlarmARN** input value, along with the **SNSTopicArn**

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook.png)

Wait until the playbook is successfully executed. Once it is done, you should see an email coming through to your email.
This email will contain summary of the investigation done by our playbook.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook-email-summary.png)

Copy and paste the message section, and use a json linter tool such as [jsonlint.com](http://jsonlint.com) to give the json better structure for visibility. 

* You should be seeing that there is a large number of ELB504 Count error and a high number of the Target Response Time from the Load balancer that explains the delay we are seeing.

* But what could have caused that delay ? If you then look at the ECS CPUtilization summary over the period of time, you will see that the CPU averages in 99%, and the total task count running is only 1.

* There are also some other Errors identified in the application logs, which sort of indicates some issue with the application code.
such as ER_CON_COUNT_ERROR: Too many connections.

Looking at these information, it is very likely that the cause of the latency is due to resource constraint at the API level.
If we increase the number of tasks in the ECS service, the application will be able to handle more requests and hopefully it would not be that CPU constrained. The Error message we see in the application log should also subside.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook-summary.png)

So, with all of these information and hypothesis at hand, lets build out a runbook to automate the remediation of the issue.
Let's move on now to the next section in the lab.

This concludes **Section 4** of this lab, click on the link below to move on to the next section.


{{< prev_next_button link_prev_url="../3_simulate_application_issue/" link_next_url="../5_build_execute_remediation_runbook/" />}}

___
**END OF SECTION 4**
___