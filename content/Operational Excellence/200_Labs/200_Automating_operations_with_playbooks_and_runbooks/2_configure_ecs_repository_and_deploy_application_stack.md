---
title: "Configure ECS Respository and Deploy The Application Stack"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 2
pre: "<b>2. </b>"
---

In this section, we are going to prepare our sample application API. Our API will be hosted inside docker containers orchestrated using [Amazon Elastic Compute Service (ECS)](https://aws.amazon.com/ecs/) with [Application Load Balancer]() fronting it. The API will take 2 actions ; **encrypt** / **decrypt**. :

* **encrypt** action will allow the user to pass on a secret message along with it's key identifier, and it will return a secret key id that they can use to decrypt.
* **decrypt** action will allow the user to pass the key identifier along with the secret key id to obtain the secret message encrypted before. 


Both actions will make a write and read call to the RDS database where encrypted messages are being stored.


In preparation for the deployment, we will need to package our application as a docker image and push it into [ECR](https://aws.amazon.com/ecr/). When this is completed, we will use the image which we placed in ECR to build our application cluster. 

For more information on how ECS works, please refer to this [guide](https://docs.aws.amazon.com/AmazonECS/latest/developerguide/Welcome.html).

When our application stack is completed, our architecture will look like this:

![Section2 App Arch](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-base-application.png)

Move through the sections below to complete the repository configuration and application stack deployment:

### 2.1. Configure the ECS Container Repository.

Our sample application preparation will require running several docker commands to create a local image in your computer which we will push into Amazon ECR. The following diagram shows the image creation process:

![Section2 ecr Arch](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-ecr-architecture.png)

To make this process simple for you, we have created a basic application and script to build the container. 

Complete the instructions as follows to download the application and deploy them to the repository:

{{% notice note %}}
You can either execute the following commands from your own laptop, or follow the steps using AWS Cloud9. If you are running this from your own machine, please ensure to have `Docker version 18.09.9` or above installed. 
{{% /notice %}}

#### 2.1.1. 

From the main console, launch the **Cloud9** service. 

When you get to the welcome screen, select **Create Environment** as shown here:

![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-cloud9-welcome-screen.png)

#### 2.1.2.

Now we will enter naming details for the environment. To do this enter the following into the **name environment** dialog box:

Name: `waopslab-environment`
Description: `Well Architected Operations Lab`

![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-cloud9-environment.png)

When you are ready, click on **Next Step** to continue as shown:


#### 2.1.4.

On the **Configure Settings** dialog box, leave defaults and click **Next Step**

#### 2.1.5.

On the **Review** dialog box, click **Create Environment**

The Cloud9 IDE environment will now build, integrating the AWS command line and all docker components that we require to build out our lab.

This step can take a few minutes, so please be patient.

#### 2.1.6.

Once our environment is built, you will be greeted with a command prompt to your environment.

We will use this to build our application for upload to the repository.

Firstly we will need to download the files which contain all of the application dependencies. To do this, run the following command within the **Cloud9 IDE**:

```
curl -o sample_app.zip https://github.com/stephensalim/walabs-opsexcellence-labs/raw/main/sample_app.zip
```

The command should show the file download as follows:

![Section 2 Cloud9 IDE Welcome Screen](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-cloud9-application-download.png)

#### 2.1.7. 

When you have downloaded the application, unzip it as follows:

```
unzip sample_app.zip
```

#### 2.1.8.

Now we will build our application and upload to the repository. We have built a script to help you with this process, which will query the previous CloudFormation stack which you created for the necessary repository information, build an image and then upload to the new repository.

Execute the script with the argument of `waopslab-base-vpc` and `v1` as follows:
 
```
./build-container.sh waopslab-base-vpc v1
```

Once your command runs successfully, you should be seeing the image being pushed to ECR and URI marked as shown here:

![Section 2 Cloud9 IDE Application Build](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-cloud9-application-build.png)


{{% notice note %}}
Take note of the ECS Image URI produced at the end of the script as we will require it later. This is highlighted in the screenshot above.
{{% /notice %}}

#### 2.1.9. 

Confirm that the ECR repository exists in the ECR console. To do this, launch ECR in your AWS Console. 

You can then follow this [guide](https://docs.aws.amazon.com/AmazonECR/latest/userguide/repository-info.html) to check to your repository as shown:

![Section2 Script Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-ecr-repo-confirm.png)



### 2.2. Deploy The Application Stack

Now that we have pushed the docker image into our [Amazon ECR](https://aws.amazon.com/ecr/) repository, we will now deploy it within [Amazon ECS](https://aws.amazon.com/ecs/). 

Our sample application is configured as follows:

* The service will expose a REST API wth **/encrypt** and **/decrypt** action.
* The **/encrypt** will take an input of a JSON payload with key and value as below `'{"Name":"Bob","Text":"Run your operations as code"}'`
* The **Name** Key will be the identifier that we will use to store the encrypted value of **Text** Value.
* The application will then call the [KMS Encrypt API](https://docs.aws.amazon.com/kms/latest/APIReference/API_Encrypt.html) and encrypt it again using a KMS key that we designate. (For simplicity, in this mock app we will be using the same KMS key for every **Name** you put in, ideally you want to use individual key for each name)
* The encrypted value of **Text** key will then be stored in an [RDS](https://aws.amazon.com/rds/) database, and the app will return a **Encryption Key** value that the user will have to pass on to decrypt the Text later
* The **decrypt** API will do the reverse, taking the **Encryption Key** you pass to decrypt the text `{"Text":"Run your operations as code"}`

{{% notice note %}}
**Note:** In this section we will be deploying a CloudFormation Stack which will launch an ECS cluster. If this is the first time you are working with the ECS service, you will need to deploy a service linked role which will be able to assume the IAM role to perform the required activities within your account. To do this, run the following from the command line using appropriate profile flags:
`aws iam create-service-linked-role --aws-service-name ecs.amazonaws.com `

{{% /notice %}}

Download the application template from [here](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/base_app.yml "Section2 Application template") and deploy according to your preference below.



{{%expand "Click here for CloudFormation command-line deployment steps"%}}

##### Command Line:

To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.

#### 2.2.1. 

Execute below command to create the application stack. Ensure that you pass the ECR Image URI you noted at the end of section **1.2** as follows:


```
aws cloudformation create-stack --stack-name waopslab-base-app \
                                --template-body file://base-app.yml \
                                --parameters ParameterKey=BaselineVpcStack,ParameterValue=waopslab-base-vpc \
                                            ParameterKey=ECRImageURI,ParameterValue=<ECR Image URI> \
                                            ParameterKey=NotificationEmail,ParameterValue=testyser@domain.com \
                                --capabilities CAPABILITY_NAMED_IAM \
                                --tags Key=Application,Value=OpsExcellence-Lab
```

**Note:** Our example below shows sample arguments passed into the command for your reference:

```
aws cloudformation create-stack --stack-name waopslab-base-app \
                                --template-body file://base-app.yml \
                                --parameters ParameterKey=BaselineVpcStack,ParameterValue=waopslab-base-vpc \
                                            ParameterKey=ECRImageURI,ParameterValue=111111111111.dkr.ecr.region.amazonaws.com/pattern1appcontainerrepository-cu9vft86ml5e:latest \
                                            ParameterKey=NotificationEmail,ParameterValue=testyser@domain.com \
                                --capabilities CAPABILITY_NAMED_IAM \
                                --tags Key=Application,Value=OpsExcellence-Lab
```

{{% /expand%}}

{{%expand "Click here for CloudFormation console deployment steps"%}}

##### Console:

If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

#### 2.2.1. 

Follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template via the console.

#### 2.2.2. 

Enter the following details into the stack details:

* Use `waopslab-base-app` as the **Stack Name**.
* Use `waopslab-base-vpc` as the **BaselineVpcStack**.
* Use the URI which you recorded in the application build as the **ECRImageURI**
* Enter an email address you would like to receive notification about this Application as the **NotificationEmail**

An example would be as follows:

![Section2 App Stack Creation](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-application-stack-creation.png)

When you are ready, click **next** to continue.

#### 2.2.3.

On the **Configure Stack Options** place in a Tag with Key `Application` and `OpsExcellence-Lab` for it's value as per screenshot below

![Section2 App Stack Tag](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-application-stack-tag.png)

click **Next**

#### 2.2.4.

On the **Review waopslab-base-app** click **Create Stack**.

**Note** Don't forget to tick the **Capabilities** acknowledgement at the bottom of the screen.

{{% /expand%}}

### 2.3. Confirm Stack Status.

#### 2.3.1.

Once the command deployed successfully, go to your [Cloudformation console](https://console.aws.amazon.com/cloudformation/home?region=ap-southeast-2) to locate the stack named `waopslab-base-app`.

#### 2.3.2.

Confirm that the stack is in a **'CREATE_COMPLETE'** state. 

#### 2.3.3.

Record the following output details as they will be required later:

* Take note of this **stack name**
* Take note of the DNS value specified under **OutputPattern1ApplicationEndpoint**  of the Outputs.

The following diagram shows the output from the cloudformation stack:

![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-dns-outputs.png)

#### 2.3.4.

Check for an email on the address you've specified, in **NotificationEmail** parameter.
Click `confirm subscription` to start confirm subscription to the application alarm.

![Section2 DNS Output](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section2-email-confirm.png)


### 2.4. Test the Application launched.

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

{{< prev_next_button link_prev_url="../1_deploy_the_lab_network_infrastructure/" link_next_url="../3_simulate_application_issue/" />}}



**END OF SECTION 2**
___