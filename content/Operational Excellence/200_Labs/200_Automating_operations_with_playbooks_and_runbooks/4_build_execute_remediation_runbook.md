---
title: "Build & Execute Remediation Runbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 4
pre: "<b>4. </b>"
---

In the previous section, we have built an automated playbook to investigate the application environment. The output the playbook gathered allows us to come up with a conclusion on the cause of the issue, and for us to decide the next course of action.

In this section we will build an automated [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) to scale up the application cluster. The runbook will also send a notification for systems owner to give them the chance to intervene should they do not want this to go ahead.

### 5.0 Prepare playbook IAM Role & SNS Topic

Instructions to be added

### 5.1 Building the "Approval-Gate" Runbooks.

When building your playbook or runbooks, repeatability is very important. You do not want to repeat the same effort of writing / building same mechanism if it could be re-used for other things in the future.

As described above, our runbook will need an approval mechanism, our approval will wait for a certain amount of time, to give an opportunity for the approver to trigger a deny. When the time lapsed, execution will continue.

  ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-graphics1.png)

Please follow below steps to build the runbook.

{{% notice note %}}
**Note:** For the following step to build and execute the runbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the runbook.
{{% /notice %}}

{{%expand "Click here for Console step by step"%}}

1. Go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. Once you are there, click on **Create Automation**

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation.png)

2. Next, enter in `Approval-Timer` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does. (Systems Manager supports putting in nots as markdown, so feel free to format it as needed.)

      ```
        # What is does this automation do?

        This is an automation to automatically trigger 'Approval' Signal to an execution, after a timer lapse

        ## Steps 

        1. Sleep for X time specified on the parameter input
        2. Automatically signal 'Approval' to the Execution specified in parameter input
      ```

3. Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

4. Under **Input Parameters** field, enter `Timer` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. Then add another parameter this time called `AutomationExecutionId`, type `String` and **Required** is `Yes`.

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-step1.png)

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-step2.png)

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-step2-input.png)

5 . Click on **Create automation** once you are done


Now that we have created the `Approval-Timer`, what we will do next is create the actual Approval runbook that will have the Approval Step. As it executes this runbook will execute the `Approval-Timer` runbook to wait until the time lapse and trigger an automatic approval asynchronously. Please follow below steps to continue.


1. Go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. Once you are there, click on **Create Automation**

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation.png)

2. Next, enter in `Approval-Gate` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does. (Systems Manager supports putting in nots as markdown, so feel free to format it as needed.)

      ```
        # What is does this automation do?

        This is an automation for approval gate mechanism. 
        Place a step executing automation before your desired step to create approval mechanism.
        Automation will trigger an asynchronously timer that will automatically approve once the time has lapsed.
        Automation will then send approval / deny request to the designated SNS Topic.
        When deny is triggered by approver, the step will fail and block the following step from executing.

        Note: Please ensure to have onFailure set to abort in your automation document.

        ## Steps 

        1. Trigger an asynchronously timer that will automatically approve once the time has lapsed.
        2. Send approval / deny request to the designated SNS Topic.

      ```

3. Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

4. Under **Input Parameters** field, enter the following parameters.
   
    * `Timer` as the **Parameter name**, set the type as `String` and **Required** as `Yes`. 
    * `NotificationMessage` as the **Parameter name**, set the type as type `String` and **Required** is `Yes`.
    * `NotificationTopicArn` as the **Parameter name**, set the type as type `String` and **Required** is `Yes`.
    * `ApproverRoleArn` as the **Parameter name**, set the type as type `String` and **Required** is `Yes`.

5. Then under the **Step 1** create a step to execute `aws:executeScript` with name `executeAutoApproveTimer`. Set the Runtime as `Python3.6` and paste in below script into the script section.

    ```
    import boto3
    def script_handler(event, context):
      client = boto3.client('ssm')
      response = client.start_automation_execution(
          DocumentName='Approval-Timer',
          Parameters={
              'Timer': [ event['Timer'] ],
              'AutomationExecutionId' : [ event['AutomationExecutionId'] ]
          }
      )
      return None
    ```

6. Under Additional Inputs place in **InputPayload** with below value :

    ```
      AutomationExecutionId: '{{automation:EXECUTION_ID}}'
      Timer: '{{Timer}}'
    ```

![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation2-step1-input.png)


7. Click on **Create automation** once you are done

    

{{%/expand%}}

{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/runbook_approval_gate.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-runbook-approval-gate` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/runbook_approval_gate.yml "Resources template")


To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.
  
```
aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://runbook_approval_gate.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://runbook_approval_gate.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-approval-gate
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}

### 5.2 Building the "ECS-Scale-Up" runbook.

Now that we have created the repeatable approval mechanism, we can now use it in our runbook for scaling up our ECS service. 

  ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-graphics2.png)

Please follow below steps to build the runbook.

{{% notice note %}}
**Note:** For the following step to build and execute the runbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the runbook.
{{% /notice %}}

{{%expand "Click here for Console step by step"%}}

1. Go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. Once you are there, click on **Create Automation**

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation.png)

2. Next, enter in `Runbook-ECS-Scale-Up` in the **Name** and past in below notes in the **Description** box. This is to provide descriptions on what this playbook does. (Systems Manager supports putting in nots as markdown, so feel free to format it as needed.)

      ```
        # What is does this automation do?

        This automation will scale up a given ECS service task desired count by an N number.
        The automation will first trigger an approval / deny request using the Approval-Gate mechanism.
        When the timer lapsed runbook will automatically execute the scale up, when the request is denied within the time, runbook will fail to execute. 

        ## Steps 

        1. Trigger Approval-Gate
        2. Scale ECS Service by number of service
      ```

3. Under **Assume role** field, enter in the ARN of the IAM role we created in the previous step.

4. Under **Input Parameters** field, enter the following parameters.
   
    * `ECSDesiredCount` as the **Parameter name**, set the type as `Integer` and **Required** as `Yes`. 
    * `ECSClusterName` as the **Parameter name**, set the type as `String` and **Required** is `Yes`.
    * `ECSServiceName`, as the **Parameter name**, set the type as `String` and **Required** is `Yes`.
    * `NotificationTopicArn`, as the **Parameter name**, set the type as `String` and **Required** is `Yes`.
    * `ApproverRoleArn`, as the **Parameter name**, set the type as `String` and **Required** is `Yes`.
    * `Timer`, as the **Parameter name**, set the type as `String` and **Required** is `Yes`.

5. Click **Add Step** and  create the first step of `aws:executeAutomation` Action type with StepName `executeApprovalGate`

6. Specify `Approval-Gate` as the **Document name** under Inputs, and under **Additional inputs** specify `RuntimeParameters` with below values :

  ```
    Timer:'{{Timer}}'
    NotificationMessage:'{{NotificationMessage}}'
    NotificationTopicArn:'{{NotificationTopicArn}}'
    ApproverRoleArn:'{{ApproverRoleArn}}'
  ```

6. Next, click **Add Step** once more and  create the second step of `aws:executeAwsApi` Action type with StepName `updateECSServiceDesiredCount`

7. Under **Inputs** specify below settings :

    * **Service** as `ecs`
    * **Api** as `UpdateService`
    
    Then create below input values :

    * `forceNewDeployment` as `true`
    * `desiredCount` as `{{ECSDesiredCount}}`
    * `service` as `{{ECSServiceName}}`
    * `cluster` as `{{ECSClusterName}}`


8 . Click on **Create automation** once this is done


{{%/expand%}}

{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/runbook_scale_ecs_service.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-runbook-scale-ecs-service` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/runbook_scale_ecs_service.yml "Resources template")


To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.
  
```
aws cloudformation create-stack --stack-name waopslab-runbook-scale-ecs-service \
                                --parameters ParameterKey=PlaybookIAMRole,ParameterValue=<ARN of Playbook IAM role (defined in previous step)> \
                                --template-body file://runbook_scale_ecs_service.yml 
```
Example:

```
aws cloudformation create-stack --stack-name waopslab-runbook-scale-ecs-service \
                                --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-playbook-role \
                                --template-body file://runbook_scale_ecs_service.yml 
```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-scale-ecs-service
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}

### 5.3 Executing remediation Runbook.

Now that we have built our runbook to Investigate this issue, lets execute this runbook while our traffic simulation is running, to see what impact this will have to our application the application. 

  1. Go back to your **Cloud9** terminal you created in Section 2, execute the command to send traffic to the application. (If the command is still running from previous step, leave the command running)

  ```
  ALBURL="< Application Endpoint URL captured from section 2>"
  ab -p test.json -T application/json -c 3000 -n 60000000 -v 4 http://$ALBURL/encrypt
  ```
  Leave it running for about 2-3 minutes, and wait until the notification email from the alarm arrives.
  
  2. Once the alarm notification email arrived, confirm in cloudwatch console that the Alarm is currently on 'Alarm State'.

  3. Then go to the Systems Manager Automation document we just created in the previous step, `Runbook-ECS-Scale-Up`.
  
  4. And then execute the runbook passing the values below.

  5. Once the runbook is executed, you should see an email coming with instructions on how to approve / deny.

  6. Execute the approve command / url or don't do anything until the timer lapsed. (If you execute deny the runbook will fail)

  7. Once the runbook moved on to the next step, observe the ECS task increased to the number of desired count you specified.

  8. Once the service is scaled up, you should be seeing the API response time back to normal, and the Alarm gone back to OK state.


This concludes **Section 5** of this lab, click on the link below to move on to the next section.
{{< prev_next_button link_prev_url="../3_build_execute_investigative_playbook/" link_next_url="../5_cleanup/" />}}



___
**END OF SECTION 5**
___