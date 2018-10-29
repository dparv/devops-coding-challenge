DevOps Coding Test
==================
## Assumptions
The user is running the scripts on a Linux machine, after successfully configuring the AWS config and credentials entries in the home folder (**make sure you are using eu-west-1**), by using the **aws configure** command:

```shell
cat ~/.aws/config
[default]         
output = json     
region = eu-west-1
cat ~/.aws/credentials
[default]             
aws_secret_access_key = ############
aws_access_key_id = ############
```
Downloaded the scripts from the repo:

```shell
git clone https://github.com/dparv/devops-coding-challenge.git .
```
Has an installed working verision of pip
```shell
curl -O https://bootstrap.pypa.io/get-pip.py
```
Has an installed working version of docker and docker engine.

## Option 1: Deploy via bash/aws cli and CloudFormation

### Prerequisites

Install the AWS command line interface and boto3 packages:

```shell
pip install -r ansible/requirements.txt
```

Run the deployment script from the root. The script has several steps to complete to do the full deployment.
```shell
./deploy.sh
```
- Builds a new local docker image with the application in /app
- Creates a repository on AWS ECR
- Tags the image and pushes it to AWS ECR
- Uses CloudFormation to create the following infrastructure
 - 1 VPC and 3 private subnets from infra/vpc.yml
 - IAM role for execution from infra/iam.yml
 - 1 ECS cluster from infra/ecs-cluster.yml
 - 1 container task definition from infra/app-task.yml
 - ECS Service and Load balancer from infra/load-balancer.yml

The deployment script has inline comments for the steps it performs and a verbose output of the actions, being performed on AWS.

After the script finishes, the user is presented with an URL to access the working application load balancer DNS name.

```shell
Deployment complete
You can access the service on the following URL:
 --->     http://XXXXXXXXXXXXX.eu-west-1.elb.amazonaws.com/now 
```

## Option 2: Deploy via Ansible modules

### Prerequisites

Install the ansible requirements from ansible/requirements.txt

```shell
pip install -r ansible/requirements.txt
```

Make sure the following environment variables are properly set:

```shell
export AWS_ACCESS_KEY_ID='###########'
export AWS_SECRET_ACCESS_KEY='###########'
```

To use the ansible deployment method, change the working directory to ansible and run the ansible-playbook executable.

```shell
cd ansible
ansible-playbook playbook.yml
```

The provided ansible code performs the following steps:
- Creates an ECR repository
- Uses the local machine shell to build, tag and push the docker image to ECR*
- Creates a VPC
- Creates IAM role and EC2 security groups (access rules)
- Build an ECS cluster
- Creates a task definition for the containers
- Creates the load balancer
- Creates a service on the ECS cluster

\* The ansible docker modules were not used for the image build for simplicity.  Ansible docker module for AWS integration is more complex.

After the ansible playbook finishes execution, the user is presented with an URL to access the working application load balancer DNS name.

```shell
TASK [services : debug] ********************************************************
ok: [localhost] => {
    "msg": "Load balancer URL: http://XXXXXXXXX.eu-west-1.elb.amazonaws.com"
}

```

## Application and docker image

The application is comprised of a simple flask framework app, displaying the time in UTC
For this minimalistic example `python:3.6-alpine` image is used, because of the optimized size of the container.

The development web server of flask is used, althou it is not a recomended solution. A better design will include an application server and a web server, for example `uWSGI` with `WSGI` module and `nginx` with `proxy_pass` to a UNIX socket.

Internally the application container listents to `TCP:8080`

The application in app/app.py is well documented with inline commends and docstrings.

## Health check script
The monitoring script collects dynamically the DNS names from the load balancers, created in AWS using boto3. Each has the pre-defined name of the option for deployment ['ecs-services', 'ans-time-app-lb']

If you have chosen Option 1, run the script from the root:
```shell
./health_check.py
```
If you have chosen Option 2, run the script from ansible:
```shell
./ansible/health_check.py
```
The health check script is well documented with inline commends and docstrings.

**All provided python code is PEP 8 compliant.**
