#!/bin/bash

export AWS_SHARED_CREDENTIALS_FILE=/home/nahian/projects/data3404_a2/credentials

S3=$1
PYFILE=$2

aws emr create-cluster \
--profile data3404 \
--applications Name=Hadoop Name=Spark \
--ec2-attributes "{\"InstanceProfile\":\"EMR_EC2_DefaultRole\",\"SubnetId\":\"subnet-bf6c96d9\",\"EmrManagedSlaveSecurityGroup\":\"sg-004e51bf2bffe8293\",\"EmrManagedMasterSecurityGroup\":\"sg-01664dd568e24e464\"}" \
--release-label emr-5.29.0 \
--log-uri "s3n://data3404-nhas9102-a2/logs/" \
--steps "[{\"Args\":[\"spark-submit\",\"--deploy-mode\",\"cluster\",\"${S3}/${PYFILE}\"],\"Type\":\"CUSTOM_JAR\",\"ActionOnFailure\":\"TERMINATE_CLUSTER\",\"Jar\":\"command-runner.jar\",\"Properties\":\"\",\"Name\":\"Spark application\"}]" \
--instance-groups "[{\"InstanceCount\":1,\"EbsConfiguration\":{\"EbsBlockDeviceConfigs\":[{\"VolumeSpecification\":{\"SizeInGB\":32,\"VolumeType\":\"gp2\"},\"VolumesPerInstance\":2}]},\"InstanceGroupType\":\"MASTER\",\"InstanceType\":\"m5.xlarge\",\"Name\":\"Master Instance Group\"},{\"InstanceCount\":2,\"EbsConfiguration\":{\"EbsBlockDeviceConfigs\":[{\"VolumeSpecification\":{\"SizeInGB\":32,\"VolumeType\":\"gp2\"},\"VolumesPerInstance\":2}]},\"InstanceGroupType\":\"CORE\",\"InstanceType\":\"m5.xlarge\",\"Name\":\"Core Instance Group\"}]" \
--configurations "[{\"Classification\":\"spark\",\"Properties\":{}}]" \
--auto-terminate \
--service-role EMR_DefaultRole \
--enable-debugging \
--name "${PYFILE}" \
--scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
--region us-east-1