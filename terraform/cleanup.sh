#!/bin/bash

# Set your region and VPC
REGION="ap-south-1"
VPC_ID="vpc-02668c40315e48050"

echo "=== Step 1: Checking EKS Resources ==="

# Check for EKS clusters
CLUSTERS=$(aws eks list-clusters --region $REGION --query "clusters" --output text)
echo "EKS Clusters found: $CLUSTERS"

if [ ! -z "$CLUSTERS" ] && [ "$CLUSTERS" != "None" ]; then
    for CLUSTER in $CLUSTERS; do
        echo "Deleting EKS cluster: $CLUSTER"
        
        # Delete node groups first
        NODE_GROUPS=$(aws eks list-nodegroups --cluster-name $CLUSTER --region $REGION --query "nodegroups" --output text)
        for NODE_GROUP in $NODE_GROUPS; do
            echo "Deleting node group: $NODE_GROUP"
            aws eks delete-nodegroup --cluster-name $CLUSTER --nodegroup-name $NODE_GROUP --region $REGION
        done
        
        # Wait for node groups to delete
        if [ ! -z "$NODE_GROUPS" ]; then
            echo "Waiting for node groups to be deleted..."
            sleep 180
        fi
        
        # Delete the cluster
        aws eks delete-cluster --name $CLUSTER --region $REGION
        echo "EKS cluster $CLUSTER deletion initiated"
    done
fi

echo "=== Step 2: Checking Load Balancers ==="

# Delete Application Load Balancers
ALBS=$(aws elbv2 describe-load-balancers --region $REGION --query "LoadBalancers[?VpcId=='$VPC_ID'].LoadBalancerArn" --output text)
for ALB in $ALBS; do
    echo "Deleting ALB: $ALB"
    aws elbv2 delete-load-balancer --load-balancer-arn $ALB --region $REGION
done

# Delete Classic Load Balancers
CLBS=$(aws elb describe-load-balancers --region $REGION --query "LoadBalancerDescriptions[?VPCId=='$VPC_ID'].LoadBalancerName" --output text)
for CLB in $CLBS; do
    echo "Deleting Classic LB: $CLB"
    aws elb delete-load-balancer --load-balancer-name $CLB --region $REGION
done

echo "=== Step 3: Checking NAT Gateways ==="

# Delete NAT Gateways
NAT_GATEWAYS=$(aws ec2 describe-nat-gateways --region $REGION --filter "Name=vpc-id,Values=$VPC_ID" --query "NatGateways[?State!='deleted'].NatGatewayId" --output text)
for NAT in $NAT_GATEWAYS; do
    echo "Deleting NAT Gateway: $NAT"
    aws ec2 delete-nat-gateway --nat-gateway-id $NAT --region $REGION
done

# Wait for NAT Gateways to delete
if [ ! -z "$NAT_GATEWAYS" ]; then
    echo "Waiting 2 minutes for NAT Gateways to be deleted..."
    sleep 120
fi

echo "=== Step 4: Checking Network Interfaces ==="

# Get all subnets in the VPC
SUBNETS=$(aws ec2 describe-subnets --region $REGION --filters "Name=vpc-id,Values=$VPC_ID" --query "Subnets[].SubnetId" --output text)

for SUBNET in $SUBNETS; do
    # Delete network interfaces in each subnet
    ENIS=$(aws ec2 describe-network-interfaces --region $REGION --filters "Name=subnet-id,Values=$SUBNET" --query "NetworkInterfaces[?Status!='available'].NetworkInterfaceId" --output text)
    for ENI in $ENIS; do
        echo "Deleting Network Interface: $ENI in subnet $SUBNET"
        aws ec2 delete-network-interface --network-interface-id $ENI --region $REGION
    done
done

echo "=== Step 5: Cleanup Complete ==="
echo "Now try: terraform destroy -auto-approve"