---
title: "Deploy sample application environment"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 1
pre: "<b>1. </b>"
---

In this section, we are going to prepare our sample application API. The application is essentially an API that hosted inside docker containers orchestrated using [Amazon Elastic Compute Service (ECS)](https://aws.amazon.com/ecs/) with [Application Load Balancer]() fronting it. The API will **encrypt** / **decrypt** a secret message that the user pass on.  

* The **encrypt** action will allow the user to pass on a secret message along with it's key identifier, and it will return a secret key id that they can use to decrypt.
* The **decrypt** action will allow the user to pass the key identifier along with the secret key id to obtain the secret message encrypted before. 

Both actions will subsequently make a write and read call to the RDS database where the encrypted messages are being stored. 

To simplify the application provisioning process, we have created a script you can execute. Please follow below steps to prepare the Cloud9 workspace and execute the script to build our application.

When our application stack is completed, our architecture will look like this:
![Section1 App Arch](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-application.png)


### 1.0 Deploy baseline resources.

Our baseline resource includes the VPC where our application will be deployed, as well as the Cloud9 IDE environment where we will use to package and deploy our application. Click on the link below to deploy the base resources in your region. Follow the options and whenever possible, take the default values in the options.

{{% notice note %}}
For simplicity keep the cloudformation stack name as `walab-ops-base-resources`, and take the default values on the others.
{{% /notice %}}

* **us-west-2** : [here](https://console.aws.amazon.com/cloudformation/home?region=us-west-2#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)
* **ap-southeast-2** : [here](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)
* **ap-southeast-1** : [here](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-1#/stacks/create/review?stackName=walab-ops-base-resources&templateURL=https://sssalim-cfn-template-temp.s3-ap-southeast-2.amazonaws.com/base_resources.yml)

Once the template is deployed, wait until the CloudFormation Stack reached the **CREATE_COMPLETE** state.

![Section1 ](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-resources-create-complete.png)


### 1.1 Run build application script.

Next, we are going to execute the script to build and deploy our application environment

  1. From the main console, launch the **Cloud9** service. 
  2. Under **Your environments** section locate an `WellArchitectedOps-walab-ops-base-resources` environment and click **Open IDE**.

      ![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-environment-open-ide.png)

  3. This will take you into the IDE environment. At first instance, your environment will bootstrap the lab repository, once it is complete you should see a folder called `aws-well-architected-labs` as below. 
  
      ![Section 2](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-bootstrap.png)

  4. In the Terminal console run below command.

      ```
      cd aws-well-architected-labs/static/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/scripts/
      bash build_application.sh walab-ops-base-resources <youremail@domain.com>
      ```
        
{{% notice note %}}
Change the `<youremail@domain.com>` with your email address.
This email will be used to receive application notifications.
{{% /notice %}}

  5. The script should then execute to build and deploy the application stack.  Wait until the script is complete, this process should take about 20 mins.

        ![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-app-build.png)

  6. In the CloudFormation console, you should see a new stack being deployed called `walab-ops-sample-application`, wait until the stack reached **CREATE_COMPLETE** state and proceed to the next step.
  
      ![Section 2 CreateComplete](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-cloud9-application-build.png)

### 1.2. Confirm Application Status.

Once the command deployed successfully, go to your [Cloudformation console](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2) to locate the stack named `walab-ops-sample-application`.

  1. Confirm that the stack is in a **'CREATE_COMPLETE'** state. 
  2. Record the following output details as they will be required later:
  3. Take note of the DNS value specified under **OutputPattern1ApplicationEndpoint**  of the Outputs.

      The following diagram shows the output from the cloudformation stack:

      ![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-dns-outputs.png)


  4. Check for an email on the address you've specified, in **NotificationEmail** parameter.
  5. Click `confirm subscription` to start confirm subscription to the application alarm.

      ![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-email-confirm.png)


### 1.3. Test the Application launched.

In this part of the Lab, we will be testing the encrypt API of the sample application we just deployed. Our application will basically take a JSON payload with `Name` and `Text` key, and it will encrypt the value under text key with a designated KMS key. Once the text is encrypted, it will store the encrypted text in the RDS database with the `Name` as the primary key.


{{% notice note %}}
**Note:** For simplicity our sample application is not generating individual KMS keys for each record generated. Should you wish to deploy this pattern to production, we recommend that you use a separate KMS key for each record.
{{% /notice %}}

From your **Cloud9** terminal, replace the < Application Endpoint URL > with the **OutputPattern1ApplicationEndpoint** from previous step.

```
ALBURL="< Application Endpoint URL >"

curl --header "Content-Type: application/json" --request POST --data '{"Name":"Bob","Text":"Run your operations as code"}' $ALBURL/encrypt
```

Once you've executed this you should see an output similar to this:

```
{"Message":"Data encrypted and stored, keep your key save","Key":"<encrypt key (take note) >"}
```
Take note of the encrypt key value under **Key** and place it under the same **Key** section in the command below to test the decrypt API.


```
curl --header "Content-Type: application/json" --request GET --data '{"Name":"Bob","Key":"<encrypt key (taken from previous command ) >"}' $ALBURL/decrypt

```

If the the application is functioning as it should, then you should see response like below 

```
{"Text":"Run your operations as code"}
```


This completes **section 2** of the lab. Proceed to **section 3** to continue with the lab.

{{< prev_next_button link_prev_url="..//" link_next_url="../2_simulate_application_issue/" />}}

___
**END OF SECTION 1**
___

