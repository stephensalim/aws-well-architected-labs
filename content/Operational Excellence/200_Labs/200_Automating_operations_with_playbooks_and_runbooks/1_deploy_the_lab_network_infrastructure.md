---
title: "Deploy Lab Network Infrastructure"
date: 2020-04-24T11:16:09-04:00
chapter: false
weight: 1
pre: "<b>1. </b>"
---

In our first sections we will build a network infrastructure for our Application using [Virtual Public Cloud (VPC)](https://docs.aws.amazon.com/vpc/latest/userguide/what-is-amazon-vpc.html), along with it's public and private subnets across two [Availability Zones](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/using-regions-availability-zones.html), and other basic network building blocks for accessing the internet such as [Internet Gateway](https://docs.aws.amazon.com/vpc/latest/userguide/VPC_Internet_Gateway.html) and [NAT gateway](https://docs.aws.amazon.com/vpc/latest/userguide/vpc-nat-gateway.html) 

To simplify the deployment we have created a CloudFormation Template that can be deployed in your AWS account that will deploy the VPC and Application resources shown in diagram below. 

Please follow below steps to continue.

![Section1 Base Architecture](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section1-base-vpc-architecture.png)

In this initial section we will be deploying the VPC network architecture. 

### 1.1. Deploy base VPC infrastructure.

To deploy the VPC infrastructure  you can either deploy the CloudFormation template directly from the command line or via the console. 

You can get the template [here.](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Code/templates/base_vpc.yml "VPC template")

{{%expand "Click here for CloudFormation command-line deployment steps"%}}

#### Command Line Deployment:

To deploy from the command line, ensure that you have installed and configured AWS CLI with the appropriate credentials.

#### 1.1.1. Execute Command
  
  
```
aws cloudformation create-stack --stack-name waopslab-base-vpc \
                                --template-body file://base-vpc.yml 
```
**Note:** Please adjust your command-line if you are using profiles within your aws command line as required.


#### 1.1.2. 

Confirm that the stack has installed correctly. You can do this by running the describe-stacks command as follows:

```
aws cloudformation desribe-stacks --stack-name waopslab-base-vpc 
```

Locate the StackStatus and confirm it is set to **CREATE_COMPLETE** as shown here:

![Section1 CF Outputs](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section1-cloudformation-cli-output.png)
  
#### 1.1.3. 

Take note of this stack output as we will need it for later sections of the lab.

{{% /expand%}}

{{%expand "Click here for CloudFormation console deployment steps"%}}
#### Console:

If you decide to deploy the stack from the console, ensure that you follow below requirements & step:

  1. Please follow this [guide](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/cfn-console-create-stack.html) for information on how to deploy the cloudformation template.
  2. Use `waopslab-base-vpc` as the **Stack Name**, as this is referenced by other stacks later in the lab.


### 1.2. Note Cloudformation Template Outputs

When the CloudFormation template deployment is completed, note the outputs produced by the newly created stack as these will be required at later points in the lab.

You can do this by clicking on the stack name you just created, and select the Outputs Tab as shown in diagram below.


![Section1 Base Outputs](/Operations/200_Automating_operations_with_playbooks_and_runbooks/Images/section1-cloudformation-output.png)



You can now proceed to **Section 2** of the lab where we will build out the actual application stack.

{{% /expand%}}



___
**END OF SECTION 1**
___

