#!/bin/bash
# deploy-complete-infrastructure.sh - Complete AWS Infrastructure Deployment

# Configuration
PROJECT_NAME="aws-demo-project"
STACK_NAME="${PROJECT_NAME}-complete-stack"
REGION="us-east-1"
TEMPLATE_FILE="complete-infrastructure-template.yml"
KEY_PAIR_NAME="my-key-pair"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}🚀 Deploying Complete AWS Infrastructure...${NC}"
echo "Project: $PROJECT_NAME"
echo "Stack: $STACK_NAME"
echo "Region: $REGION"
echo ""

# Check prerequisites
echo -e "${YELLOW}🔍 Checking prerequisites...${NC}"

# Check AWS CLI
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI not found. Please install AWS CLI first.${NC}"
    exit 1
fi

# Check template file
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}❌ Template file not found: $TEMPLATE_FILE${NC}"
    exit 1
fi

# Check AWS credentials
aws sts get-caller-identity > /dev/null 2>&1
if [ $? -ne 0 ]; then
    echo -e "${RED}❌ AWS credentials not configured. Run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Prerequisites check passed${NC}"

# Validate template
echo -e "${YELLOW}📋 Validating CloudFormation template...${NC}"
aws cloudformation validate-template \
    --template-body file://$TEMPLATE_FILE \
    --region $REGION > /dev/null

if [ $? -ne 0 ]; then
    echo -e "${RED}❌ Template validation failed${NC}"
    exit 1
fi

echo -e "${GREEN}✅ Template is valid${NC}"

# Deploy stack
echo -e "${YELLOW}🏗️ Deploying infrastructure stack...${NC}"

aws cloudformation deploy \
    --template-file $TEMPLATE_FILE \
    --stack-name $STACK_NAME \
    --parameter-overrides \
        ProjectName=$PROJECT_NAME \
        KeyPairName=$KEY_PAIR_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Infrastructure deployed successfully!${NC}"
else
    echo -e "${RED}❌ Deployment failed${NC}"
    exit 1
fi

# Get outputs
echo -e "${BLUE}📊 Getting stack outputs...${NC}"
OUTPUTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs')

# Extract key values
ALB_DNS=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="LoadBalancerDNS") | .OutputValue')
APP_URL=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="LoadBalancerURL") | .OutputValue')
RDS_ENDPOINT=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="RDSEndpoint") | .OutputValue')
S3_BUCKET=$(echo $OUTPUTS | jq -r '.[] | select(.OutputKey=="S3BucketName") | .OutputValue')

echo ""
echo -e "${GREEN}🎉 Deployment Complete!${NC}"
echo ""
echo -e "${BLUE}📋 Infrastructure Resources:${NC}"
echo "• Application URL: $APP_URL"
echo "• Load Balancer DNS: $ALB_DNS"
echo "• RDS Endpoint: $RDS_ENDPOINT"
echo "• S3 Bucket: $S3_BUCKET"
echo ""
echo -e "${YELLOW}⏳ Note: EC2 instances may take 5-10 minutes to fully initialize${NC}"
echo ""
echo -e "${GREEN}✨ Infrastructure is ready!${NC}"
