# Build the image for the application locally
main() {
echo "Building the container with the latest version of the app"
docker build -t engagetech:latest app/

# Get AWS account ID
ACCOUNT_ID=`aws sts get-caller-identity --query 'Account' --output text`
AWS_REPO_URL="$ACCOUNT_ID.dkr.ecr.eu-west-1.amazonaws.com"

# Create a repository on Amazon ECS
echo "Creating ECS registry / repository on AWS"
aws ecr create-repository --repository-name engagetech

# Login to AWS ECS with docker using generated 12 hour valid token
echo "Initiate docker login with temporary IAM credentials"
$(aws ecr get-login --no-include-email)

# Tag the image with latest
echo "Tagging image for AWS ECR porting"
docker tag engagetech:latest $AWS_REPO_URL/engagetech:latest

# Push image to the created AWS repository
echo "Pushing image to AWS ECR"
docker push $AWS_REPO_URL/engagetech:latest

# Deploy the infrastructure using CloudFormation

echo "Starting deplyoment of infrastructure"
echo "Task 1: VPC"
# 1. Deploy the VPC
aws cloudformation create-stack --stack-name vpc \
        --template-body file://$PWD/infra/vpc.yml
check_status_before_next_step "vpc"

echo "Task 2: IAM roles"
# 2. Deploy the IAM roles
aws cloudformation create-stack --stack-name iam \
        --template-body file://$PWD/infra/iam.yml \
        --capabilities CAPABILITY_IAM
check_status_before_next_step "iam"

echo "Task 3: ECS Cluster"
# 3. Deploy the ECS cluster
aws cloudformation create-stack --stack-name ecs-cluster \
        --template-body file://$PWD/infra/ecs-cluster.yml
check_status_before_next_step "ecs-cluster"

echo "Task 4: Container task definitions"
# 4. Deploy the task / containers
aws cloudformation create-stack --stack-name app-task \
        --template-body file://$PWD/infra/app-task.yml
check_status_before_next_step "app-task"

echo "Task 6: Services and load balancer"
# 5. Deploy the load blancer with service and listener
aws cloudformation create-stack --stack-name load-balancer \
        --template-body file://$PWD/infra/load-balancer.yml
check_status_before_next_step "load-balancer"

echo "Deployment complete"
SERVICE_URL=$(aws elbv2 describe-load-balancers \
    --names "ecs-services" \
    --query "LoadBalancers[0].DNSName" \
    --output text)
printf "You can access the service on the following URL: \n ---> \
    http://$SERVICE_URL/now \n"

}
# Helper function to check the deployment status and stop race conditions
# Strict steps must be followed in the exection, as there are dependancies
function check_status_before_next_step {
    while true; do
        STATUS=$(aws cloudformation describe-stacks \
            --stack-name $1 \
            --query 'Stacks[0].StackStatus' \
            --output text)

        if [ $STATUS == "CREATE_IN_PROGRESS" ]; then
            echo "Waiting for stack deployment [$1] status: $STATUS"
        elif [ $STATUS == "CREATE_COMPLETE" ]; then
            echo "Stack deployment [$1] status: $STATUS"
            break
        else
            echo "Error during deplyoment: $STATUS"
            echo "Check AWS console for more information"
            break
            exit 1
        fi

        sleep 3
    done
}

main "$@"
