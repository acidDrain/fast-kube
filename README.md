# Kubernetes Lab

The scripts in this repo are meant to help simplify deploying Kubernetes in AWS, so that you can have a lab to play around in as quickly as possible.

## Getting Started

The scripts in this repo were written with Mac (using bash shell) in mind. We may port to Linux at some point, but Mac is currently the only supported platform.

_NOTE: You must have homebrew installed. You can get homebrew [here](https://docs.brew.sh/Installation)_

### Contents

```shell
.
├── README.md
├── build.sh
├── javascript_server
│   ├── Dockerfile
│   ├── package-lock.json
│   ├── package.json
│   └── server.js
├── kube-create.sh
└── requirements.sh
```

- requirements.sh - install dependencies (run this first)
- kube-create.sh - provision a Kubernetes cluster in AWS
- javascript_server - directory containing a simply nodejs based server that just responds with 200 and "Success" for testing
- build.sh - a script to build a docker image for javascript_server

### Installing Dependencies

The requirements.sh script will install terraform, kops, kubernetes-cli, and awscli.

First, run **`requirements.sh`**

```shell
$ ./requirements.sh

Required packages:
	terraform
	kops
	kubernetes-cli
	awscli


To install Docker for Mac:
	https://docs.docker.com/v17.12/docker-for-mac/install/

Using homebrew to install some required packages

-----------

Use the aws cli to configure the proper credentials
	https://github.com/kubernetes/kops/blob/master/docs/aws.md#setup-iam-user

-----------

Use brew to install required packages? (y/N)

Installing packages

Updating Homebrew...
==> Auto-updated Homebrew!
...
```

### Setting Up kops IAM Account and Permissions

Follow the instructions **[here](https://github.com/kubernetes/kops/blob/master/docs/aws.md#setup-iam-user)** to ensure you have an account in AWS for kops to use to provision your Kubernetes cluster.

### Deploying

Next, run **`kube-create.sh`** -- you can use the -h flag to get help.

NOTE: **`t2.micro`** is free tier eligible in AWS. However, it is also minimal/underpowered. If it's too slow for you, you can bump the instance size, just be aware of additional charges that you'll incur. For a list of AWS instance sizes and prices, click **[here](https://aws.amazon.com/ec2/pricing/on-demand/)**

**Example:**

```shell
$ ./kube-create.sh -n kubelabdemo3 -A 1.1.1.1/32 -m 3 -z 3 -S t2.micro -r us-east-2


1534383232 - INFO - Using Name: kubelabdemo3

1534383233 - INFO - Store doesn't exist - creating bucket: kubelabdemo3.k8s.local-state-store

{
    "Location": "http://kubelabdemo3.k8s.local-state-store.s3.amazonaws.com/"
}
1534383235 - INFO - Checking for existing cluster

1534383236 - INFO - Cluster by name of kubelabdemo3.k8s.local does not exist

1534383236 - INFO - Creating cluster

-------------------------------------------------------------------------------------------------------------------------------

Run this command to setup your environment: source ~/projects/kube-lab.k8s.local/env-kubelabdemo3_setup.sh

-------------------------------------------------------------------------------------------------------------------------------

Finally, to modify your cluster, run the command: kops edit cluster kubelabdemo3.k8s.local

-------------------------------------------------------------------------------------------------------------------------------

To edit the node configuration, use: kops edit ig --name=kubelabdemo3.k8s.local nodes

To edit the master configuration, use: kops edit ig --name=kubelabdemo3.k8s.local master-us-east-2a
(Note: You'll need to run this command for each master)

To apply your changes, use: kops update cluster kubelabdemo3.k8s.local --yes

-------------------------------------------------------------------------------------------------------------------------------
-----------------------------------------------------------COMPLETE!-----------------------------------------------------------
-------------------------------------------------------------------------------------------------------------------------------
```

### Help

```shell
$ ./kube-create.sh -h

kube-create.sh: A tool to create a Kubernetes cluster in AWS and setup remote state in S3

USAGE: kube-create.sh
	-n	<NAME>
	-A	<comma separated list of IP addresses to allow>
	-m	<MASTERS>
	-z	<NUMBER OF ZONES>
	-S	<instance size (e.g. t2.medium)>
	-r	<REGION>

This script will automatically attach the suffix .k8s.local to the name you provide,
so that DNS and service discovery operate with Kubernetes internal DNS,
avoiding the need to register a public domain name.

See https://github.com/kubernetes/kops/blob/master/docs/aws.md#configure-dns
```

### Deleting the Cluster

To delete your cluster:

```shell
$ source env-kubelabdemo3_setup.sh
kops delete cluster $NAME --yes
No cloud resources to delete
Deleted kubectl config for kubelabdemo3.k8s.local

Deleted cluster: "kubelabdemo3.k8s.local"
```
