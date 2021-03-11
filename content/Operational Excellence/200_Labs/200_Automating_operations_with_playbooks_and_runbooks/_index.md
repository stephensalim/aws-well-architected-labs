---
title: "200 - Automating your operations with Playbooks and Runbooks"
## menutitle: "Lab #1"
date: 2020-04-24T11:16:08-04:00
chapter: false
weight: 1
hidden: false
---

## Introduction

This hands-on lab will guide you through the steps to automate your operational activities using playbook and runbooks built with  AWS tools.

At a glance, both Playbook and Runbooks appears to be similar documents that any adequately skilled team members (who are unfamiliar with the workload) can use to execute operational activities. However, the main difference between them is that; a Playbook is intended to document the process /guide to gather applicable information, identify potential sources of failure, isolate faults, and determine root cause of issues. Runbooks contain instructions necessary to successfully complete an activity to resolve the issue. 

Executing both Playbook and Runbook in an automated fashion is critical to achieve operational excellence for your workload. Isolating human element and streamlining the process will make significant impact in the reliability, scalability, traceability of your operations.  

In this lab, we will show how you can build an automated Playbook to investigate an issue in a workload, and a Runbook to remediate the issue using AWS tools, services we will utilize in this lab includes.

* Event Bridge Rules
* Systems Manager Automation Document
* Simple Notification Service


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

{{< prev_next_button link_next_url="./1_deploy_the_lab_network_infrastructure/" button_next_text="Start Lab" first_step="true" />}}

Steps:
{{% children  /%}}
