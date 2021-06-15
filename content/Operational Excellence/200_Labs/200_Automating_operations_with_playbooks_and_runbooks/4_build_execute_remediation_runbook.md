---
title: "Build & Execute Remediation Runbook"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 4
pre: "<b>4. </b>"
---

In the previous section, you built an automated playbook to investigate the application environment. The playbook collected information and helped you figure out what action to take. In this section, you will build an automated [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) to remediate the issue by manually scaling up the application cluster. In contrast to a playbook, a [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html)  is a procedure that accomplishes a specific task and outcome.

In this scenario, it is visible that the the ECS service CPU utilization was at peak, and there is not enough ECS tasks running to serve incoming requests. This is understood, and the immediate course of action to remediate it is to increase the number of tasks, scaling up the service to meet the demand. 
That said, scaling up the service directly as such, may not be suitable as a long term solution into the fix. Therefore it is important to communicate this issue to the owner of the workload, and to give them the options to intervene if they choose to do so. 

{{% notice note %}}
**Note:** In the post-mortem review of the event, the team should decide on what is the next course of action they should take to implement a more long term solution, such as implementing Automatic Scaling in the ECS Cluster (This will be discussed further in the next Lab )
{{% /notice %}}

#### Actions items in this section :
1. You will build a runbook to scale up the ECS cluster, with the approval mechanism.
2. You will execute the runbook and observe the recovery of your application. 

### 4.0 Building the "Approval-Gate" Runbooks.

As mentioned in previous section, when building your playbook or runbooks, repeatability is very important. You want avoid repeating the same effort of writing / building mechanism if it could be re-used for other things in the future.

In this section you will build a approval mechanism runbook component. The component will issue a timer, and give opportunity for the approver to trigger a deny of the request. If the timer runbook lapsed, or the approver approves, the runbook will proceed to move to next step of it's activity.

  ![Section5 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section5-create-automation-graphics1.png)

The way to achieve this scenario in Systems Manager Automation document is as below :

1. First, the runbook will execute a separate runbook called `Approve-Timer`. This runbook will wait for a designated amount of time that we specify. When the wait time lapse, `Approve-Timer` runbook will automatically send an Approval signal to the gate.

2. Secondly, the runbook will send the Approval request to the owner via the SNS topic designated for them. 

    If they choose to approve, the runbook will continue to the next step (which we will define later). At the same time, if the approval is ignored, the `Approve-Timer` runbook will automatically approve the request.

    Alternatively, if they choose to deny then the step in the runbook will fail, blocking any further steps that we will decide later.

Follow below steps to build this runbook.

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


If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-runbook-approval-gate` as the **Stack Name**, as this is referenced by other stacks later in the lab.

{{%/expand%}}

{{%expand "Click here for CloudFormation CLI deployment step"%}}

1. From the cloud9 terminal, copy, paste and run below command to get into the working script folder

    ```
    cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates
    ```


2. Then copy paste and execute below commands replacing the 'AutomationRoleArn' with the Arn of **AutomationRole** you took note in previous step 3.0.
  
    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                    --parameters ParameterKey=PlaybookIAMRole,ParameterValue=AutomationRoleArn \
                                    --template-body file://runbook_approval_gate.yml 
    ```
    Example:

    ```
    aws cloudformation create-stack --stack-name waopslab-runbook-approval-gate \
                                    --parameters ParameterKey=arn:aws:iam::000000000000:role/xxxx-runbook-role \
                                    --template-body file://runbook_approval_gate.yml 
    ```

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-approval-gate
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
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

**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation describe-stacks --stack-name waopslab-runbook-scale-ecs-service
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** 
{{%/expand%}}

### 4.2 Executing remediation Runbook.

Now that you have built the runbook to remediate this issue, lets execute it to remediate the performance event.

  1. Go to the output tab Cloudformation stack deployed named `walab-ops-sample-application`. Take note following values; OutputECSCluster, OutputECSService, OutputSystemOwnersTopicArn

  ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-output.png)


  2. Also, take note of your the ARN of the IAM user, or IAM role that you will use to assume execute the approval request. To do this you can go to the IAM User console, and click **Users**/**Roles** on the left side menu, and click on the user User/Roles. Form here you should be able so see something like below, take now the ARN value, as we need it for our next step.

  ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-iam.png)


  3. Go to the Systems Manager Automation console, click on **Document** under **Shared Resources**, locate and click an automation document called `Runbook-ECS-Scale-Up`. 
  
  4. Then click *Execute automation* and  passing the values you just noted as per screenshot. (This will be where all the values you took note in step 1-2 be put to use.)

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up.png)

      * Place **OutputECSService** value under for the name of **ECSServiceName**.
      * Place **OutputECSCluster** value under for the name of **ECSClusterName**.
      * Place the IAM user / role you took note on step 2 above under **ApproverArn**.
      * Enter `100` as the **ECSDesiredCount**.
      * You can put in any message to the **NotificationMessage** section. Here is a sample :

        ```
        Hello, your mysecretword app is experiencing performance degradation, To manage customer experience we will have to manually scale up the cluster. Action will take in 10 mins, Please deny if you do not consent.  
        ```  
      * Place **OutputSystemOwnersTopicArn** value under for the name of **NotificationTopicArn**.
      * You can leave **Timer** as it is, this will be the waiting time until it's automatically approved defined in ISO 8601 duration format
  
  5. Once it's done then click on **Execute**. 

  6. Once the runbook is executed, you should see an email coming with instructions on how to approve / deny. Follow the link in the email, using the **User**/**Role** of the ApproverArn you placed in step. It will take you to the SSM Console where you can approve / deny the request. 

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-approveordeny.png)

      If you choose leave / ignore this email, the request will be automatically approved after the Timer set in the playbook.

      If you execute deny the runbook will fail, and nothing will be actioned.

  7. Once the runbook moved on to the next step, You can observe the ECS task increased to the number of desired count you specified. 

      Go to ECS console, and click in **Clusters** and select `mysecretword-cluster`, then click on `mysecretword-service` **Service**. you should see as the number of running tasks reaches 100, the CPUUtilization average comes down. 

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up2.png)

      ![ Section4 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section4-scale-up3.png)


  8. Following after the service is scaled up, you should be seeing the API response time back to normal, and the Alarm gone back to OK state. You can check them via your CloudWatch Console, as per previous step.


This concludes **Section 6** of this lab, click on the link below to move on to the next section.
{{< prev_next_button link_prev_url="../3_build_execute_investigative_playbook/" link_next_url="../5_cleanup/" />}}



___
**END OF SECTION 5**
___