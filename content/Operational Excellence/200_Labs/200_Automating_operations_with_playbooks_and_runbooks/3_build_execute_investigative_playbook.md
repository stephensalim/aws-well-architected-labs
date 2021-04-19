---
title: "Build & Execute Investigative Playbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 3
pre: "<b>3. </b>"
---

In the previous section, we sent through large traffic to the API and simulate an increase latency as the application is overwhelmed. 

For a seasoned systems administrator / engineer, who knows the in and out of the architecture investigating the issue might be a relatively straight forward process. One would already know which service or components are involved as well as which metrics and logs is relevant and which one do not. Over time these administrator / engineer would build a certain method around this allowing them to intuitively understand the route to take to investigate the issue.
While there is no problem with this, unless all of those knowledge and method are well documented and able to be handed down, this creates the engineer / administrator becoming a single point of failure.

This is where [playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) comes into place. [Playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) are essentially a documented predefined steps / guide to perform to identify an issue. The results from each step are used to determine the next steps to take until the issue is identified or escalated. For a playbook to be scalable, automating the process is critical. 

There are various different tools you can use to build an automated playbook, and AWS you can use [AWS Systems Manager Automation Document](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html) (now called runbook ). The service allows you to create a series of executable steps to orchestrate your investigation into the issue, you can execute python / nodejs script, call the api of AWS service directly, or execute a remote command into the host operating system where your application is potentially running ( Both in EC2 or on-prem ).

In this part of the lab we will focus on how we build an automated playbook to help troubleshoot the issue with our API.
Please follow below steps to continue.

### 3.0 Prepare Automation Document IAM Role

The Systems Manager Automation Document we are building will require to assume a permission to executes the investigative / remediation steps. For this we will need to create an IAM role to assume permission allowed to conduct these playbook. To simplify the deployment process, we have created a cloudformation template that you can deploy via the console or aws cli.
Please choose one of below deployment step

{{%expand "Click here for CloudFormation Console deployment step"%}}
  1. Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/automation_role.yml "Resources template")
  2. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  3. Use `waopslab-automation-role` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

**Note:** To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.

In the Cloud9 terminal go to the templates folder using the following command.

```
cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
```

Then execute below command :

```
aws cloudformation create-stack --stack-name waopslab-automation-role \
                                --capabilities CAPABILITY_NAMED_IAM \
                                --template-body file://automation_role.yml 
```

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-automation-role
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}

Once you have deployed the cloudformation stack, you should be able to see an IAM role named **AutomationRole** in the IAM console.

  
![Section3 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section3-automationrole.png)

Now that we have the IAM role, let's move on to next step to create the actual playbook.

### 3.1 Building the "Gather-Resources" Playbook.

As an administrator / engineer, before we even investigate anything in the application, we need to know what are the services / components involved. When we receive the alarm from cloudwatch in the inbox, the information presented does not contain straight away these components / services involved, hence in the following steps we will build a playbook to acquire all the related resources using our alarm arn as it's reference. 

When creating a playbook or any code in general, re-usability is something that is very important to consider early on. By codifying your playbook, you are enabling the playbook document to be created once and to be executed in multiple different context, this will prevents your operation engineer having to re-write codes that has identical objectives.   

Please follow below steps to continue.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-architecture-graphics1.png)


{{% notice note %}}
**Note:** For the following step to build and run playbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the playbook.
{{% /notice %}}


{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_gather-resources.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-playbook-gather-resources` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

**Note:** To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.

In the Cloud9 terminal go to the templates folder using the following command.

```
cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
```

Then execute below command :

```
aws cloudformation create-stack --stack-name waopslab-playbook-gather-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://playbook_gather_resources.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-playbook-gather-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://playbook_gather_resources.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-playbook-gather-resources
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}


{{%expand "Click here for Console step by step"%}}

  1. To build our playbook, go ahead and go to the AWS Systems Manager console, click on **Create Automation**

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation.png)

  2. Next, enter in `Playbook-Gather-Resources` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does. Systems Manager supports putting in nots as markdown, so feel free to format it as needed. 


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

  3. Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-role.png)

  4. Under **Input Parameters** field, enter `AlarmARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will essentially define a Parameter into our playbook, so that we can pass on the value of the CloudWatch Alarm to the main step that will do the action.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input.png)

  5. Under **Add Step** section enter `Gather_Resources_For_Alarm` under the **Step name**, select `aws::executeScript` as the **Action type**. 
  6. Under **Inputs** set `Python3.6` as the **Runtime**, and specify `script_handler` as the **Handler**.
  7. Paste in below python codes into the **Script** section.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-addstep.png)

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

  8. Under **Additional inputs** specify input value to the step passing in the parameter we created before.
to do this, select `Input Payload` under **Input name** and specify `CloudWatchAlarmARN: '{{AlarmARN}}'` as the **Input Value**. The '{{AlarmARN}}' section essentially references the parameter value we created before.
  
  9. Within the same section, specify the outputs of the step. `Resources` as the **Name** `$.Payload.ApplicationStackResources` as the **Selector** and `String` as the **Type**. For more information about Automation Document syntax, please refer [here](https://docs.aws.amazon.com/systems-manager/latest/userguide/systems-manager-automation.html)

  10. Once your setting looks as per screen shot below, click on **Create Automation**

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-additionals.png)

{{%/expand%}}


Once the automation document is created, we can now give it a test.
  1. You can then find the newly created document under the **Owned by me** tab of the **Document** section of Systems Manager Console.

  ![Section3 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section3-playbook-gather-resource-tab.png)

  2. Click on the playbook called `Playbook-Gather-Resources` and click on **Execute Automation** to execute our playbook.
  3. Paste in the Cloudwatch Alarm ARN (you can refer to the email you received from the simulation we did on section 2), and click on **Execute** to test the playbook.

  ![Section3 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section3-alarm-email.png)

  4. Once the playbook execution is completed, Click on the **Step Id** to see the final message and output of the step. You should be able to see this output listing all the resources of the application
  5. **Copy** the Resources list output from the section as highlighted in the screenshot below. This list consist of the all the resources defined in the Cloudformation stack related to our application. These information includes the Elastic Load Balancer, ECS, and RDS resource id that we can now use to further our investigation of the underlying issue.  
  6. You can **Paste** the output into a temporary location like notepad for now. We will need this value for our next step. 


![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-execute-output.png)


### 3.2 Building the "Investigate-Application-Resources" Playbook.

Now that have have defined a playbook that captures all related AWS resources in the application, the next thing we want to do is to investigate these relevant resources and capture recent statistics, logs to look for insights and better understand the root cause of the issue.

In practice there can be various permutations on what resources you will look at depending on the context of the issue. But in this scenario, we will be looking specifically at the Elastic Load Balancer, the Elastic Compute Service, and Relational Database Statistics and logs. We will then highlight the metrics that is considered outside standard norm threshold.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-architecture-graphics2.png)

Please follow below instructions to build this playbook.

{{% notice note %}}
**Note:** For the majority, this step will be identical with our previous step, we will just be passing in different scripts in each of the step to query the related services and gather it's data. Therefore to reduce the repetition in the steps we will deploy this playbook via cloudformation template.  Please follow the steps below to deploy via cloudformation template via CLI / or Console. 
{{% /notice %}}


{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_investigate_application_resources.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-playbook-investigate-resources` as the **Stack Name**, as this is referenced by other stacks later in the lab.


{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

In the Cloud9 terminal go to the templates folder using the following command.

```
cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
```

Then execute below command :

  
```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://playbook_investigate_application_resources.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-resources \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=arn:aws:iam::000000000000:role/xxxx-playbook-role \
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
You can find the newly created document under the **Owned by me** tab of the Document resource.

  1. Click on the playbook called `Playbook-Investigate-Application-Resources` and click on **Execute Automation** to execute our playbook.
  2. Paste in the Resources List you took note from the output of the previous playbook (refer to previous step) under **Resources** and click on **Execute**

  3. Under **Executed Steps** you should be able to each of the step the playbook has executed. If you view the content of the document you will be able to see the code and find out what exactly each step does. But for simplicity, we have created a list on the objective of each step, and what data it will produce.

      ![Section3 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section3-steps-explain.png)


      * **Gather_ELB_Statistics:** Go through resource list, and locate the elb resource. Query data from it's cloudwatch metrics looking at below metric and statistics in the last 60 minutes.

          {{%expand "Click here for List of Metrics"%}}

          * TargetResponseTime | Average
          * HTTPCode_Target_2XX_Count | Sum
          * HTTPCode_Target_3XX_Count | Sum
          * HTTPCode_Target_4XX_Count | Sum
          * HTTPCode_Target_5XX_Count | Sum
          * TargetConnectionErrorCount | Sum
          * UnHealthyHostCount | Average
          * ActiveConnectionCount | Sum
          * HTTPCode_ELB_3XX_Count | Sum
          * HTTPCode_ELB_4XX_Count | Sum
          * HTTPCode_ELB_5XX_Count | Sum
          * HTTPCode_ELB_500_Count | Sum
          * HTTPCode_ELB_502_Count | Sum
          * HTTPCode_ELB_503_Count | Sum
          * HTTPCode_ELB_504_Count | Sum

          {{%/expand%}}

      * **Gather_RDS_Config:**  Go through resource list, and locate the RDS resource. Describe RDS Instance Config & Parameters.

      * **Gather_RDS_Statistics:** Go through resource list, and locate the RDS resource. Query data from it's cloudwatch metrics looking at below metric and statistics in the last 60 minutes.

          {{%expand "Click here for List of Metrics"%}}

          * BinLogDiskUsage | Sum
          * BurstBalance | Average
          * CPUUtilization | Average
          * CPUCreditUsage | Sum
          * CPUCreditBalance | Maximum
          * DatabaseConnections | Sum
          * DiskQueueDepth | Maximum
          * FailedSQLServerAgentJobsCount | Average
          * FreeableMemory | Maximum
          * MaximumUsedTransactionIDs | Maximum
          * NetworkReceiveThroughput | Average
          * OldestReplicationSlotLag | Average
          * ReadIOPS | Average
          * ReadLatency | Average
          * ReadThroughput | Maximum
          * ReplicaLag | Average
          * ReplicationSlotDiskUsage | Maximum
          * SwapUsage | Maximum
          * TransactionLogsDiskUsage | Maximum
          * TransactionLogsGeneration | Average
          * ReplicationSlotDiskUsage | Maximum                                                            
          * WriteIOPS | Average    
          * WriteLatency | Average    
          * WriteThroughput | Average                        

          {{%/expand%}}

      * **Gather_ECS_Statistics:** : Go through resource list, and locate the ECS Service resource. Query data from it's cloudwatch metrics looking at below metric and statistics in the last 6 minutes.

          {{%expand "Click here for List of Metrics"%}}

          * CPUUtilization | Maximum
          * MemoryUtilization | Maximum                       

          {{%/expand%}}

      * **Gather_ECS_Error_Logs** : Go through resource list, and locate the ECS Service resource. Search in Cloudwatch logs for any Error occurrence.

      * **Gather_ECS_Config** : Go through resource list, and locate the ECS Service resource. Describe the ECS service configuration.

      * **Inspect_Playbook_Results** : Go through the output of above steps, inspect results, and check if it is above the threshold.

          {{%expand "Click here for List of Threshold"%}}

          Elastic Load Balancer
          * TargetResponseTime  = 5
          * TargetConnectionErrorCount= 0
          * UnHealthyHostCount = 0
          * ELB5XXCount = 0
          * ELB500Count = 0
          * ELB502Count = 0
          * ELB503Count = 0
          * ELB504Count = 0
          * Target4XXCount = 0
          * Target5XXCount = 0

          EC2 Container Service
          * CPUUtilization = 80
          {{%/expand%}}

  4. Wait until all steps are completed successfully.



### 3.3 Building the "Investigate-Application-From-Alarm" Playbook.

So far we have 2 separate playbooks that does 2 different things, one is to gather the list of resources of the application, and the other is to go through relevant resources and investigate it's logs and statistics.

Each of this playbook can be kept as a repeatable artefact that is re-usable for multiple different purposes.
That said, executing these 2 separate steps and manually passing the output as an input to the other playbook is a tedious task, and it requires human intervention.

Therefore in this step we will automate our playbook further by creating a parent playbook that orchestrates the 2 Investigative playbook subsequently, additionally we will also inject another step to send notification to our Developers and System Owners to notify of this issue.

![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-architecture-graphics3.png)

Follow below instructions to build the Playbook.

{{% notice note %}}
**Note:** For the following step to build and run playbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the playbook.
{{% /notice %}}

{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/playbook_investigate_application.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-playbook-investigate-application` as the **Stack Name**, as this is referenced by other stacks later in the lab.
  3. In the parameter input screen, under **PlaybookIAMRole** enter ARN of Playbook IAM role (defined in previous step), under **NotificationEmail** enter your designated email for playbook notification

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}


In the Cloud9 terminal go to the templates folder using the following command.

```
cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
```

Then execute below command :
  
```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-application \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://playbook_investigate_application.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-playbook-investigate-application \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://playbook_investigate_application.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-playbook-investigate-application 
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 

Check for an email on the address you've specified, in **NotificationEmail** parameter.
Click `confirm subscription` to start confirm subscription to the application alarm.

  ![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-email-confirm.png)


{{%/expand%}}

{{%expand "Click here for Console step by step"%}}

  1. To build our playbook, go ahead and go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. Once you are there, click on **Create Automation**

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation.png)

  2. Next, enter in `Playbook-Investigate-Application-From-Alarm` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does. Systems Manager supports putting in nots as markdown, so feel free to format it as needed. 


  ```
  # What is does this playbook do?

  This playbook will execute **Playbook-Gather-Resources** to gather Application resources monitored by Canary.

  Then subsequently execute **Playbook-Investigate-Application-Resources** to Investigate the resources for issues. 

  Outputs of the investigation will be sent to SNS Topic Subscriber
    
  ```

  3. Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.
  
  4. Under **Input Parameters** field, enter `AlarmARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will define a Parameter into our playbook, so that we can pass on the value of the CloudWatch Alarm to the main step that will do the action.
  
  5. Add another parameter by clicking on the **Add a parameter** link. Enter `SNSTopicARN` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. This will  define another Parameter into our playbook, so that we can send notification to the Owner and Developer.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2.png)


  6. Click **Add Step** and  create the first step of `aws:executeAutomation` Action type with StepName `PlaybookGatherAppResourcesCanaryCloudWatchAlarm`

  7. Specify `Playbook-Gather-Resources` as the **Document name** under Inputs, and under **Additional inputs** specify `RuntimeParameters` with `AlarmARN:'{{AlarmARN}}'` as it's value ( refer to screenshot below ) This defines that in this step we will be executing the `Gather-Resources` playbook we created which takes input of the CloudWatch AlarmARN and returns the list of related resources.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step1.png)

  8. Once this step is defined, add another step by clicking on **Add Step** at the bottom of the section.
  
  9. For this second step, specify the **Step name** as `PlaybookInvestigateAppResourcesELBECSRDS` abd action type `aws:executeAutomation`.
  
  10. Specify `Playbook-Investigate-Application-Resources` as the **Document name**, and `RuntimeParameters` as `Resources: '{{PlaybookGatherAppResourcesCanaryCloudWatchAlarm.Output}}'` This second step will take the output of the first step and pass that to the second Playbook to execute the investigation of relevant resources.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step2.png)

  11. Now for the last step, we want to take the output investigation from the second step and send that to the SNS topic where our owner, developers, and admin are subscribed.

  12. Specify the **Step name** as `AWSPublishSNSNotification` abd action type `aws:executeAutomation`. 
  13. Specify `AWS-PublishSNSNotification` as the **Document name**, and `RuntimeParameters` as below. This last step will take the output of the second step which contains summary data of the investigation and AWS-PublishSNSNotification which will send an email to the SNS we specified in the parameters.


  ```
  TopicArn: '{{SNSTopicARN}}'
  Message: '{{ PlaybookInvestigateAppResourcesELBECSRDS.Output }}'
  ```

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-parameter-input-2-step3.png)

  14. As described in the previous step, our playbook will run investigative tasks, and send the result to an SNS topic where our Systems administrator / engineer will subscribe to. 
  To do this we will need to create an SNS topic that our playbook will send notification to. Please follow the instructions specified in this [link](https://docs.aws.amazon.com/sns/latest/dg/sns-create-topic.html) and create a Standard SNS topic and name it `PlaybookNotificationSNSTopic`

  15. Once you've created the topic, go ahead and subscribe your an email using this instruction [here](https://docs.aws.amazon.com/sns/latest/dg/sns-email-notifications.html)

{{%/expand%}}



### 3.4 Executing investigation Playbook.

Now that we have built all of our our Playbook to Investigate this issue, lets test our traffic high traffic simulation is running, to see what our we'll discover. 

  1. Go to the Output section of the deployed cloudformation stack `walab-ops-sample-application`, and take note of below output values.

  2. Go to the Systems Manager Automation document we just created in the previous step, `Playbook-Investigate-Application-From-Alarm`.
  
  3. And then execute the playbook passing the ARN as the **AlarmARN** input value, along with the **SNSTopicArn**.
    

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook.png)


  4. Wait until the playbook is successfully executed. Once it is done, you should see an email coming through to your email. This email will contain summary of the investigation done by our playbook.

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook-email-summary.png)

  5. Copy and paste the message section, and use a json linter tool such as [jsonlint.com](http://jsonlint.com) to give the json better structure for visibility. The result you are seeing from your playbook execution might vary slightly, but the overall findings should show as below. go to the next step for explanation on our findings

  ![Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-create-automation-playbook-test-execute-playbook-summary.png)

  6. From the report being generated you You would be seeing a large number of ELB504 Count error and a high number of the Target Response Time from the Load balancer that explains the delay we are seeing from our canary alarm. 
  
      If you then look at the ECS CPUtilization summary, you will see that the CPU averages in 99%, and the while the total ECS task count running is only 1. If you refer to the previous step, we have explained that our playbook will create an average of the maximum value of the ECS service's CPUUtilization, in the last 6 minutes time window. ( So this information should be very recent)
      
      There are also some other Errors identified in the application logs, which sort of indicates some issue with the application code. such as ER_CON_COUNT_ERROR: Too many connections.

      Therefore, looking at these information, it is likely that the immediate cause of the latency is resource constraint at the application API level running in ECS. Ideally, if we can increase the number of tasks in the ECS service, the application should be able handle more requests and won't have constraints on the CPU Utilization. With all of these information provided by our playbook findings, we should now be able to determine what is the next course of action to attempt remediation to the issue. Let's move on now to the next section in the lab, to build that remediation runbook.

This concludes **Section 3** of this lab, click on the link below to move on to the next section.

{{< prev_next_button link_prev_url="../2_simulate_application_issue/" link_next_url="../4_build_execute_remediation_runbook/" />}}

___
**END OF SECTION 3**
___