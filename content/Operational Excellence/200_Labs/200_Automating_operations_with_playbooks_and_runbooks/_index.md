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
* **Brian Carlson**, Well-Architected Operational Excellence Pillar Lead.
## Introduction
 
This hands-on lab will guide you through the steps to automate your operational activities using [Playbook](https://wa.aws.amazon.com/wat.concept.playbook.en.html) and [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) built with AWS tools.

At a glance, both Playbook and Runbooks appears to be similar documents that any adequately skilled team members (who are unfamiliar with the workload) can use to execute operational activities. However, there an essential difference between them. 

A [Playbook](https://wa.aws.amazon.com/wellarchitected/2020-07-02T19-33-23/wat.concept.playbook.en.html) intends to document the process /guide to gather applicable information, identify potential sources of failure, isolate faults, and determine root cause of issues, [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html)  on the other hand contain instructions necessary to successfully complete an activity to resolve the issue. 

In any case, at a certain scale, executing either [Playbook](https://wa.aws.amazon.com/wat.concept.playbook.en.html) / [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) activities manually, is not going to be adequate.  Organization, and Operation teams will have to start looking into streamlining Playbook and Runbook process through automation. Isolating human element from the process will have significant impact to the reliability, scalability, traceability of the workloads operational posture.

In the next few sections of this lab, we will show how you can build an automated [Playbook](https://wa.aws.amazon.com/wat.concept.playbook.en.html) and [Runbook](https://wa.aws.amazon.com/wat.concept.runbook.en.html) to investigate and remediate application issue using a few AWS services.

Services we will utilize in this lab includes.

* Event Bridge Rules
* Systems Manager Automation Document
* Simple Notification Service
* CloudWatch Synthetics 


## Goals:
* Build & Execute Automated Investigative Playbook & Remediative Runbook
* Build & Execute Automated Issue remediation Runbook
* Enabling traceability of Operational Activity in environment.

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
