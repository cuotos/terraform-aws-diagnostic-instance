#!/bin/bash

yum install -y \
  docker \
  git \
  htop \
  nc \
  inotify-tools

service docker start
chkconfig docker on
usermod -a -G docker ec2-user
usermod -a -G docker ssm-user

# install docker-compose
curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose

# Login to ECR
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
aws ecr get-login-password --region eu-west-1 | docker login --username AWS --password-stdin $${AWS_ACCOUNT_ID}.dkr.ecr.eu-west-1.amazonaws.com

${additional_user_data}
