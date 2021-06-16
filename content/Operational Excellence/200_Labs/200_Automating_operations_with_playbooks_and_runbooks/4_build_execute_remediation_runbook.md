---
title: "Build & Execute Remediation Runbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 4
pre: "<b>4. </b>"
---

In the previous section, you built an automated playbook to investigate the application environment. The playbook collected information and helped you figure out what action to take. In this section, you will build an automated [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) to remediate the issue by manually scaling up the application cluster. In contrast to a playbook, a [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html)  is a procedure that accomplishes a specific task and outcome.

In this scenario, you identified that the the ECS service CPU utilization was at peak, and there was not enough ECS tasks running to serve the incoming requests. This is understood, and the immediate course of action is to increase the number of tasks, scaling up the service, to meet the demand.
Scaling up the service directly may not be a long term solution depending on the cause of the high CPU utilization. Therefore it is important to communicate this issue to the owner of the workload, and to give them the opportunity to take other corrective actions.

{{% notice note %}}
**Note:** In the post-incident review of the event, the team should determine the course of action to implement a more long term solution, such as implementing Automatic Scaling in the ECS Cluster. We will explore this further in a later lab.
{{% /notice %}}

#### Actions items in this section :
1. You will build a runbook to scale up the ECS cluster, with the approval mechanism.
2. You will execute the runbook and observe the recovery of your application. 

### 4.0 Building the "Approval-Gate" Runbooks.

When building your playbook or runbooks you want avoid duplicating effort and writing or building mechanisms that could be be re-used with other tasks in the future.

In this section you will build an approval mechanism runbook component. The component with provide the approver  the opportunity to deny the request if they act within a defined grace period. If the time is exceeded, or the approver approves, the runbook will proceed with its next step activities.

  ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-graphics1.png)

The way to achieve this scenario in Systems Manager Automation document is as below :

1. In the first step, the runbook executes a separate runbook called `Approve-Timer`. The  runbook will then wait for the designated amount of time that you specify. When the wait time is complete, the `Approve-Timer` runbook will send an "approval" signal to the gate.

2. In the second step, the runbook will send the **approval** request to the owner via a designated SNS topic.

    If they choose to approve, the runbook will continue to the next step. If they do not response, the `Approve-Timer` runbook will automatically approve the request.

    If they choose to deny, then the step in the runbook will fail, blocking any further runbook activities.

Follow below instructions to build the runbook.

{{% notice note %}}
**Note:** For the following step to build and run runbook. You can follow a step by step guide via AWS console or you can deploy a CloudFormation template to build the playbook.
{{% /notice %}}

{{%expand "Click here for Console step by step"%}}

1. Go to the AWS Systems Manager console. Click on documents to enter the **Documents** page and then click on **Create Automation** as show in the screen shot below.

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

Now that you have created the `Approval-Timer`, the next thing to do is to create the actual Approval runbook that will have the Approval Step. As it executes this runbook will execute the `Approval-Timer` runbook to wait until the time lapse and trigger an automatic approval asynchronously. Please follow below steps to continue.


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

5. Then under the **Step 1** create a step to execute `aws:executeScript` with name `executeAutoApproveTimer`. Set the Runtime as `Python3.6` and paste in below script into the script section. This code snippet will execute the `Approval-Timer` runbook you created before asyncronously.

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


If you decide to deploy the stack from the console using CloudFormation, follow the steps below and ensure that you use the provide **Stack Name** value:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-runbook-approval-gate` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

1. From the cloud9 terminal, copy, paste and run the following command to navigate into the working script folder

    ```
    cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
    ```


2. Then copy, paste, and execute following commands replacing the `AutomationRoleArn` with the Arn of **AutomationRole** you took note of in step 3.0.

    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                    --parameters ParameterKey=PlaybookIAMRole,ParameterValue=AutomationRoleArn \
                                    --template-body file://runbook_approval_gate.yml 
    ```
    
    With your AutomationRole Arn in place your command will look similar to the following example:

    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                    --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-runbook-role \
                                    --template-body file://runbook_approval_gate.yml 
    ```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

3. Run the describe-stacks command to confirm that the stack has installed correctly by running the following command:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-approval-gate
```

4. Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 

{{%/expand%}}

### 4.1 Building the "ECS-Scale-Up" runbook.

Now that you have created an auto approval mechanism runbook component. The next thing to do is to attach it in the ECS Scale up runbook. 

  ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-graphics2.png)


The next runbook will do the following :

1. Execute the `Approval-Gate` runbook we created in previous step, and the mechanism described previously will follow. 
2. If the `Approval-Gate` returns successful, then we will execute the next step to increase the number of ECS service by our defined task to meet the immediate demand.

Please follow below steps to build the runbook.


{{% notice note %}}
**Note:** For the following step to build and execute the runbook. You can follow a step by step guide via AWS console or you can deploy a cloudformation template to build the runbook.
{{% /notice %}}

{{%expand "Click here for Console step by step"%}}

1. Go to the AWS Systems Manager console, from there click on documents to get into the page as per screen shot. Once you are there, click on **Create Automation**

      ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation.png)

2. Next, enter `Runbook-ECS-Scale-Up` in the **Name** field and paste the notes that follow below in the **Description** box. Providing a description of what your playbook do will help your team members learn and apply the runbook correctly.
Systems Manager has markdown support for the notes text. You can format your text to make it easier for team members to consume.

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

5. Click **Add Step** and create the first step using the `aws:executeAutomation` Action type with the Step Name `executeApprovalGate`

6. Specify `Approval-Gate` as the **Document name** under Inputs, and under **Additional inputs** specify `RuntimeParameters` with below values :

  ```
    Timer:'{{Timer}}'
    NotificationMessage:'{{NotificationMessage}}'
    NotificationTopicArn:'{{NotificationTopicArn}}'
    ApproverRoleArn:'{{ApproverRoleArn}}'
  ```

6. Click **Add Step** once more and then create the second step using the `aws:executeAwsApi` Action type with StepName `updateECSServiceDesiredCount`

7. Under **Inputs** specify below settings:

    * **Service** as `ecs`
    * **Api** as `UpdateService`
    
    Then create following input values:

    * `forceNewDeployment` as `true`
    * `desiredCount` as `{{ECSDesiredCount}}`
    * `service` as `{{ECSServiceName}}`
    * `cluster` as `{{ECSClusterName}}`


8 . Click on **Create automation** once complete


{{%/expand%}}

{{%expand "Click here for CloudFormation Console deployment step"%}}

Download the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/runbook_scale_ecs_service.yml "Resources template")


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-runbook-scale-ecs-service` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

1. From the cloud9 terminal, copy, paste and run below command to get into the working script folder

    ```
    cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
    ```

2. Then copy paste and execute below commands replacing the 'AutomationRoleArn' with the Arn of **AutomationRole** you took note in previous step 3.0.
  
    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-scale-ecs-service \
                                    --parameters ParameterKey=PlaybookIAMRole,ParameterValue=AutomationRoleArn \
                                    --template-body file://runbook_scale_ecs_service.yml 
    ```
    Example:

    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-scale-ecs-service \
                                    --parameters ParameterKey=arn:aws:iam::000000000000:role/AutomationRole \
                                    --template-body file://runbook_scale_ecs_service.yml 
    ```

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-scale-ecs-service
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}

### 4.2 Executing remediation Runbook.

Now that you have built the runbook to remediate this issue, lets execute it to remediate the performance event.

  1. Go to the output tab Cloudformation stack deployed named `walab-ops-sample-application`. Take note following values: OutputECSCluster, OutputECSService, and OutputSystemOwnersTopicArn

  ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-output.png)

  2. Locate the ARN of the IAM user that you will use the perform the approval request. You can find this by navigating to the IAM User console and  clicking **Users** on the left side menu, and then Click on the **User** name. You will see something similar to the example below. Take note of the ARN value, as you will use it in the next step.

  ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-iam.png)

  3. Go to the Systems Manager Automation console, click on **Document** under **Shared Resources**, locate and click an automation document called `Runbook-ECS-Scale-Up`. 
  
  4. Then click *Execute automation* providing the values you noted in steps 1 and 2. Once populated the fields will appear similar to the following example screenshot.

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up.png)

      * Place **OutputECSService** value under for the name of **ECSServiceName**.
      * Place **OutputECSCluster** value under for the name of **ECSClusterName**.
      * Place the IAM user Arn you took note on step 2 above under **ApproverArn**.
      * Enter `100` as the **ECSDesiredCount**.
      * Place a message in the **NotificationMessage** field that can help the approver make an informed decision to approve or deny the recommended action. 
      
        For example:
        ```
        Hello, your mysecretword app is experiencing performance degradation. To maintain quality customer experience we will manually scale up the supporting cluster. This action will be taken 10 minutes after this message is generated unless you do not consent and deny the action within the grace period.
        ```  

      * Place **OutputSystemOwnersTopicArn** value under for the name of **NotificationTopicArn**.
      * You can leave **Timer** as it is. This is the wait time until automatic approval unless a deny is received. The time is defined in ISO 8601 duration format.
  
  5. Once it's done then click on **Execute**. 

  6. Once the runbook is executed, you should receive an email with instructions on how to approve or deny. Follow the link in the email using the User of the ApproverArn you placed in the Input parameters. The link will take you to the SSM Console where you can approve or deny the request.
  

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-approveordeny.png)

      If you choose approve, or do not respond to the email, the request will be automatically approved after the Timer set in the playbook expires.

      If you deny the runbook will fail, and no action will be taken.

  7. Once the runbook completes the next step, you can see that the ECS task count increased to the value you specified. 

      Go to ECS console, and click on **Clusters**, and select `mysecretword-cluster`. Click on the  `mysecretword-service` **Service**. you should see the number of running tasks increasing to 100 and average CPUUtilization decreasing.

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up2.png)

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up3.png)

  8. After the service is scaled up, you should see the API response time return to normal and the Alarm return to the OK state. You can check both using your CloudWatch Console, following the steps you used in "2. Simulate Application Issue", "Section 2.1 Observing the alarm being triggered".


This concludes **Section 4** of this lab, click on the link below to move on to the next section.
{{< prev_next_button link_prev_url="../3_build_execute_investigative_playbook/" link_next_url="../5_cleanup/" />}}



___
**END OF SECTION 4**
___