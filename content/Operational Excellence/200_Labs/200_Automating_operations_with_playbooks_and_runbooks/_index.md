---
title: "200 - Automating your operations with Playbooks and Runbooks"
## menutitle: "Lab #1"
date: 2020-04-24T11:16:08-04:00
chapter: false
weight: 1
hidden: false
---

## Authors
* **Stephen Salim**, Well-Architected Geo Solutions Architect.

##### Contributors
* **Brian Carlson**, Well-Architected Operational Excellence Pillar Lead.
* **Jang Whan Han**, Well-Architected Geo Solutions Architect.

## Introduction

This hands-on lab will guide you through the steps to automate your operational activities using  [Runbooks](https://wa.aws.amazon.com/wat.concept.runbook.en.html) and [Playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) built with AWS tools.

At a glance, both Runbooks and Playbooks appears to be similar documents that any appropriately skilled team members, with the necessary permissions, can use to perform operational activities. However, there an essential difference between them:

* A [Playbook](https://wa.aws.amazon.com/wellarchitected/2020-07-02T19-33-23/wat.concept.playbook.en.html) documents a process that guides you through an activity. For example, gathering applicable information, identifying potential sources of failure, isolating faults, or determining the root cause of issues. Playbooks can follow multiple paths and yield more than one outcome. 

* A [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) contains the procedure necessary for you to successfully complete an activity. For example, creating a user, or resolving a specific issue. When successfully executed a specific outcome is expected.

Executing either [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) or [Playbook](https://wa.aws.amazon.com/wat.concept.playbook.en.html)  activities manually is prone to error, does not scale, and will not be adequate to support your needs as you grow. Your will want to evaluate ways to streamline Runbook and Playbook activities through automation to relieve your operational burden. 

Automation can support improved reliability by preventing the introduction of errors through manual processes, scalability by deploying and decommissioning resources dynamically, traceability of the workloads operational posture through logs of the automation activity, and response time by triggering automation in response to events. We will go into traceability of activities in more detail in our next lab.


In this lab, we will show how you can build an automated [Runbooks](https://wa.aws.amazon.com/wat.concept.runbook.en.html) and [Playbooks](https://wa.aws.amazon.com/wat.concept.playbook.en.html) to investigate and remediate your application issue using AWS services. Services we will use in this lab include:

* Systems Manager Automation
* Simple Notification Service
* CloudWatch Synthetics

## Goals: 

* Build & execute automated playbooks to support your investigations
* Build & execute automated runbooks to remediate specific faults
* Enabling traceability of operations activities in your environment


## Prerequisites:
* An [AWS account](https://portal.aws.amazon.com/gp/aws/developer/registration/index.html) that you are able to use for testing, that is not used for production or other purposes.  
* An IAM user or role in your AWS account with full access to CloudFormation, EC2, VPC, IAM.  

## Costs
{{% notice note %}}
NOTE: You will be billed for any applicable AWS resources used if you complete this lab that are not covered in the [AWS Free Tier](https://aws.amazon.com/free/).
{{% /notice %}}

{{< prev_next_button link_next_url="./1_deploy_base_application_environment/" button_next_text="Start Lab" first_step="true" />}}

Steps:
{{% children  /%}}
