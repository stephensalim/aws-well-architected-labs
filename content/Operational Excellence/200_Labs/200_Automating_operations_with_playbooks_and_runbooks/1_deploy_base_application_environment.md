---
title: "Deploy sample application environment"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 1
pre: "<b>1. </b>"
---

In this section, you will prepare a sample application. The application is an API hosted inside docker container, orchestrated using [Amazon Elastic Compute Service (ECS)](https://aws.amazon.com/ecs/), and with [Application Load Balancer](https://docs.aws.amazon.com/elasticloadbalancing/latest/application/introduction.html) fronting it. 

The API is a private micro-service that sits within your [Amazon Virtual Private Cloud (VPC)](https://aws.amazon.com/vpc/), and communication to the API can only be done privately through connection within the VPC subnet, not via the internet. Therefore in this hypothetical scenario, the business owner agrees to run the API over HTTP protocol, to simplify the implementation. 

The API will take 2 actions that you will trigger by doing a POST call to the */encrypt* / */decrypt* action.
* The *encrypt* action will allow you to pass a secret message along with a 'Name' key as the identifier, and it will return a 'Secret Key Id' that you can use later to decrypt your message.
* The *decrypt* action allows you to then decrypt the secret message passing along the 'Name' key and 'Secret Key Id' you obtained before to get your secret message.

Both actions will subsequently make a write and read call to the application database hosted in RDS, where the encrypted messages are being stored. 
The following step by step instructions will provision the application that you will use with your runbooks and playbooks. 
Explore the contents of the CloudFormation script to learn more about the environment and application.

You will use this sample application as a sandbox to simulate application performance issue, and execute your [Runbooks](https://wa.aws.amazon.com/wat.concept.runbook.en.html) and [Playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) automation. To Investigate and remediate the issue.

#### Actions items in this section :
1. You will prepare the [Cloud9](https://aws.amazon.com/cloud9/) workspace launched with a new VPC.
2. You will execute the application build script from the Cloud9 console to build the sample application. 

![Section1 App Arch](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-application.png)


### 1.0 Prepare Cloud9 workspace.

In this first step you will provision a [Cloudformation](https://aws.amazon.com/cloudformation/) stack that builds a Cloud9 workspace along with the VPC for the sample application. This Cloud9 workspace will be used to execute the provisioning script of the sample application. You can choose the to deploy stack in one of the region below. 

1. Click on the link below to deploy the stack. This will take you to the Cloudformation console in your account. Use `walab-ops-base-resources` as the stack name, and take the default values for all options

    * **us-west-2** : [here](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)
    * **ap-southeast-2** : [here](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)
    * **ap-southeast-1** : [here](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)

2. Once the template is deployed, wait until the CloudFormation Stack reached the **CREATE_COMPLETE** state.

![Section1 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-resources-create-complete.png)


### 1.1 Run build application script.

Next, you will to execute a script to build and deploy you application environment from the Cloud9 workspace you deployed in the first step

  1. From the main console, search and click for the **Cloud9** to get into the Cloud9 console. 
  2. Click **Your environments** section on the left menu, and locate an environment named `WellArchitectedOps-walab-ops-base-resources` as below, then click **Open IDE**.

      ![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-environment-open-ide.png)

  3. This will take you into the IDE environment. At first instance, your environment will bootstrap the lab repository and you should see a terminal output showing git clone output as below. Once it is complete you will see a folder called `aws-well-architected-labs`. 
  
      ![Section 2](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-bootstrap.png)

  4. In the IDE Terminal console copy and paste below command to get into the working folder where the build script is located.

      ```
      cd ~/environment/aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/scripts/
      ```

  5. Then copy and paste below command replacing `sysops@domain.com` and `owner@domain.com` with the email address you would like the application to notify you with. Replace the `sysops@domain.com` value with email representing system operators team, and `owner@domain.com` with email address representing business owner.


      ```
      bash build_application.sh walab-ops-base-resources sysops@domain.com owner@domain.com
      ```

  {{% notice note %}}
  The `build_application.sh` script will build and deploy your sample application, along with the architecture that hosts it.
  The application architecture will have capabilities to notify systems operator and owner personas leveraging [Amazon Simple Notification Service](https://aws.amazon.com/sns/).
  You can use the same email address for `sysops@domain.com` and `owner@domain.com`, but you need to have both values specified.
  {{% /notice %}}

  6. Run the above command to execute the build and provisioning of the application stack. Wait until the script is complete, this process should take about 20 mins.

        ![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-app-build.png)

  {{% notice note %}}
  The `build_application.sh` will build the application docker image and push it to [Amazon ECR](https://aws.amazon.com/ecr/) that [Amazon ECS](https://aws.amazon.com/ecs/) will use. Once this is done, it will deploy another CloudFormation Stack containing the application resources (ECS, RDS, ALB, and others), and wait until the stack creation is complete.
  {{% /notice %}}

  7. In the CloudFormation console, you should see a new stack being deployed called `walab-ops-sample-application`, wait until the stack reached **CREATE_COMPLETE** state and proceed to the next step.
  
      ![Section 2 CreateComplete](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-app-create-complete.png)

### 1.2. Confirm Application Status.

Once the application is deployed successfully, go to your [Cloudformation console](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2) and locate the stack named `walab-ops-sample-application`.

  1. Confirm that the stack is in a **'CREATE_COMPLETE'** state. 
  2. Record the following output details as they will be required later:
  3. Take note of the DNS value specified under **OutputPattern1ApplicationEndpoint**  of the Outputs.

      The following diagram shows the output from the cloudformation stack:

      ![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-dns-outputs.png)


  4. Check for an email on the address you've specified, in **NotificationEmail** parameter.
  5. Click `confirm subscription` to start confirm subscription to the application alarm.

      ![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-email-confirm.png)


### 1.3. Test the Application launched.

In this section you will be testing the encrypt API of the application you just deployed. 
The application will take a JSON payload with `Name` ad the identifier and `Text` key as the value of the secret message.
It will encrypt the value under text key with a designated KMS key and store the encrypted text in the RDS database with the `Name` as the primary key.

{{% notice note %}}
**Note:** For simplicity purposes the sample application will re-use the same KMS keys for each record generated. Use an individual KMS key for each identifier, to limit the blast radius of exposed keys to individual users.
{{% /notice %}}

1. In the **Cloud9** terminal, copy , paste, and run below command replacing the `ApplicationEndpoint` with the **OutputPattern1ApplicationEndpoint** from previous step. This command will run [curl](https://curl.se/) to send a POST request with the secret message payload `{"Name":"Bob","Text":"Run your operations as code"}` to the API.

    ```
    ALBEndpoint="ApplicationEndpoint"
    ```

    ```
    curl --header "Content-Type: application/json" --request POST --data '{"Name":"Bob","Text":"Run your operations as code"}' $ALBEndpoint/encrypt
    ```

2. Once you execute this command you should see an output like below :

    ```
    {"Message":"Data encrypted and stored, keep your key save","Key":"EncryptKey"}
    ```

3. Take note of the encrypt key value under **Key** .

4. Copy, paste, and run below command. paste the encrypt key you took note before under the **Key** section in the command below to test the decrypt API.


    ```
    curl --header "Content-Type: application/json" --request GET --data '{"Name":"Bob","Key":"EncryptKey"}' $ALBEndpoint/decrypt

    ```

5. Once you execute the command you should see an output like below :

    ```
    {"Text":"Run your operations as code"}
    ```

## Congratulations ! 

You have now completed the first section of the Lab.

By now you should have a sample application API we can use throughout the remaining this lab.

This concludes **Section 1** of the lab. Click on **Next Step** to continue to the next section.

{{< prev_next_button link_prev_url="..//" link_next_url="../2_simulate_application_issue/" />}}

___
**END OF SECTION 1**
___

