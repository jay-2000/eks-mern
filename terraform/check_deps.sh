#!/bin/bash
VPC_ID="vpc-02668c40315e48050"
REGION="ap-south-1"
ACCOUNT_ID="212105053723"

echo "=== FORCE DELETE VPC: $VPC_ID ==="
echo "Region: $REGION"
echo "Account: $ACCOUNT_ID"
echo "================================"

# 1. FIRST, CHECK EVERYTHING IN THE VPC
echo -e "\n1. CHECKING ALL RESOURCES IN VPC:"

# Get ALL resources in the VPC using resource groups tagging API
echo "Searching for all resources..."
RESOURCES=$(aws resourcegroupstaggingapi get-resources --region $REGION --resource-type-filters "ec2:instance" "ec2:network-interface" "ec2:security-group" "ec2:subnet" "ec2:route-table" "ec2:internet-gateway" "ec2:natgateway" "ec2:vpc-endpoint" "elasticloadbalancing:loadbalancer" --query "ResourceTagMappingList[?contains(ResourceARN, 'vpc/$VPC_ID') || contains(ResourceARN, 'vpc-02668c40315e48050')].ResourceARN" --output text)

if [ -z "$RESOURCES" ]; then
    echo "No tagged resources found. Checking untagged resources..."
    
    # Check EC2 instances
    echo "EC2 Instances:"
    aws ec2 describe-instances --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "Reservations[*].Instances[*].InstanceId" --output text
    
    # Check Network Interfaces
    echo -e "\nNetwork Interfaces:"
    aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text
    
    # Check VPC Endpoints
    echo -e "\nVPC Endpoints:"
    aws ec2 describe-vpc-endpoints --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[*].VpcEndpointId" --output text
else
    echo "Found resources:"
    echo "$RESOURCES"
fi

# 2. DELETE IN THIS ORDER (MOST LIKELY CULPRITS):
echo -e "\n2. DELETING RESOURCES IN ORDER:"

# A. Delete VPC Endpoints (often hidden)
echo "A. Deleting VPC Endpoints..."
ENDPOINTS=$(aws ec2 describe-vpc-endpoints --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "VpcEndpoints[*].VpcEndpointId" --output text)
for ENDPOINT in $ENDPOINTS; do
    echo "  Deleting VPC Endpoint: $ENDPOINT"
    aws ec2 delete-vpc-endpoints --vpc-endpoint-ids $ENDPOINT --region $REGION
    sleep 2
done

# B. Delete Network Interfaces (force delete)
echo -e "\nB. Deleting Network Interfaces..."
ENIS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkInterfaces[*].NetworkInterfaceId" --output text)
for ENI in $ENIS; do
    echo "  Force deleting ENI: $ENI"
    aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION --force 2>/dev/null || \
    echo "  Could not delete ENI $ENI, trying to detach first..."
    
    # Try to detach first if attached
    ATTACHMENT=$(aws ec2 describe-network-interfaces --region $REGION --network-interface-ids $ENI --query "NetworkInterfaces[0].Attachment.AttachmentId" --output text 2>/dev/null)
    if [ ! -z "$ATTACHMENT" ] && [ "$ATTACHMENT" != "None" ]; then
        echo "    Detaching attachment: $ATTACHMENT"
        aws ec2 detach-network-interface --attachment-id $ATTACHMENT --region $REGION --force 2>/dev/null || true
        sleep 2
        aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION --force 2>/dev/null || true
    fi
done

# C. Delete Security Groups (except default)
echo -e "\nC. Deleting Security Groups..."
# Get all non-default security groups
SGS=$(aws ec2 describe-security-groups --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "SecurityGroups[?GroupName!='default'].GroupId" --output text)
for SG in $SGS; do
    echo "  Deleting Security Group: $SG"
    # Try multiple times with delay
    for i in {1..3}; do
        aws ec2 delete-security-group --group-id $SG --region $REGION 2>/dev/null && break
        echo "    Attempt $i failed, waiting..."
        sleep 5
    done
done

# D. Delete Route Tables (non-main)
echo -e "\nD. Deleting Route Tables..."
# Get route tables that are not the main route table
MAIN_RTB=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" "Name=association.main,Values=true" --query "RouteTables[0].RouteTableId" --output text)
RTBS=$(aws ec2 describe-route-tables --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "RouteTables[?RouteTableId!='$MAIN_RTB'].RouteTableId" --output text)
for RTB in $RTBS; do
    echo "  Deleting Route Table: $RTB"
    aws ec2 delete-route-table --route-table-id $RTB --region $REGION 2>/dev/null || echo "    Could not delete (may have dependencies)"
done

# E. Delete Network ACLs (non-default)
echo -e "\nE. Deleting Network ACLs..."
# Get non-default network ACLs
NACLS=$(aws ec2 describe-network-acls --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "NetworkAcls[?IsDefault==`false`].NetworkAclId" --output text)
for NACL in $NACLS; do
    echo "  Deleting Network ACL: $NACL"
    aws ec2 delete-network-acl --network-acl-id $NACL --region $REGION 2>/dev/null || echo "    Could not delete"
done

# 3. WAIT AND RETRY VPC DELETION
echo -e "\n3. ATTEMPTING VPC DELETION..."
sleep 10

# Try multiple times
for attempt in {1..5}; do
    echo "  Attempt $attempt to delete VPC..."
    if aws ec2 delete-vpc --vpc-id $VPC_ID --region $REGION 2>/dev/null; then
        echo "  SUCCESS! VPC deleted."
        exit 0
    else
        echo "  Failed. Waiting 30 seconds before retry..."
        sleep 30
    fi
done

# 4. FINAL RESORT: CHECK CLOUDTRAIL FOR RECENT ACTIVITY
echo -e "\n4. CHECKING FOR RECENT ACTIVITY (last 6 hours)..."
START_TIME=$(date -u -d '6 hours ago' +%s)
aws cloudtrail lookup-events --region $REGION --lookup-attributes AttributeKey=ResourceName,AttributeValue=$VPC_ID --start-time $START_TIME --query "Events[*].{EventName:EventName,Username:Username,Time:EventTime}" --output table 2>/dev/null || echo "CloudTrail not available or no events found"

echo -e "\n=== IF STILL FAILING ==="
echo "1. Check AWS Console VPC Resources tab"
echo "2. Wait 1 hour and try again"
echo "3. Contact AWS Support with VPC ID: $VPC_ID"
echo "4. OR use different CIDR block in Terraform"