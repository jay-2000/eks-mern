#!/bin/bash
REGION="ap-south-1"
VPC_ID="vpc-02668c40315e48050"
SUBNETS=("subnet-0f245160c684b3f22" "subnet-04633d738cea4e0b2" "subnet-08ce27426ca929766")

echo "=== Cleaning up resources in VPC: $VPC_ID ==="

# 1. Delete Load Balancers
echo "Checking for Load Balancers..."
LBS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
for LB in $LBS; do
    echo "Deleting Load Balancer: $LB"
    aws elbv2 delete-load-balancer --load-balancer-arn $LB --region $REGION
done

# 2. Delete NAT Gateways
echo "Checking for NAT Gateways..."
NAT_GWS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text)
for NAT in $NAT_GWS; do
    echo "Deleting NAT Gateway: $NAT"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION
done

# 3. Wait for NAT Gateway deletion
if [ ! -z "$NAT_GWS" ]; then
    echo "Waiting for NAT Gateways to be deleted..."
    sleep 120
fi

# 4. Delete Network Interfaces
echo "Checking for Network Interfaces..."
for SUBNET in "${SUBNETS[@]}"; do
    ENIS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=subnet-id,Values=$SUBNET" --query "NetworkInterfaces[?Status!='available'].NetworkInterfaceId" --output text)
    for ENI in $ENIS; do
        echo "Deleting Network Interface: $ENI in subnet $SUBNET"
        aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION
    done
done

# 5. Detach and Delete Internet Gateway
echo "Checking Internet Gateway..."
IGW=$(aws ec2 describe-internet-gateways --region $REGION --filters "Name=attachment.vpc-id,Values=$VPC_ID" --query "InternetGateways[0].InternetGatewayId" --output text)
if [ ! -z "$IGW" ] && [ "$IGW" != "None" ]; then
    echo "Detaching Internet Gateway: $IGW"
    aws ec2 detach-internet-gateway --internet-gateway-id $IGW --vpc-id $VPC_ID --region $REGION
    
    echo "Deleting Internet Gateway: $IGW"
    aws ec2 delete-internet-gateway --internet-gateway-id $IGW --region $REGION
fi

echo "=== Cleanup completed! ==="
echo "Now try: terraform destroy -auto-approve"