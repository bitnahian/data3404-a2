## 1. Prerequisites

1. Follow the steps listed [here](https://aws.amazon.com/cli/) to install the AWS CLI. 
2. For Windows users, I highly suggest using the Git Bash terminal or Linux Subsystem as this tutorial is written using shell scripting.
3. Copy your data files into a subdirectory called data. Make sure you add the data directory to the .gitignore file so as not to push all your data into git.

## 2. Create credentials file

__NOTE__ - You will have to recreate this file every 3 hours, since classroom credentials time out every 3 hours.

1. Sign in to AWS Educate

2. Click on `Go to classroom`

3. Click on Account Details

4. Clock on the `Show` button next to AWS_CLI

From here on, you can either
- OPTION 1 - Copy the contents directly to your `~/.aws/credentials` file, or
- OPTION 2 - Copy the contents to a file called `credentials` in the local directory you're writing your Python scripts on (I prefer this method)

5. __NOTE__ Change [default] to [data3404] to use a special profile to run your commands.
```
[data3404]
aws_access_key_id=XXXXXXXXXXXXXX
aws_secret_access_key=XXXXXXXXXXXXXXXXXXX
aws_session_token=XXXXXXXXXXXXX
```

6. If you choose the second option in Step 4, you have to set your `AWS_SHARED_CREDENTIALS_FILE` environment variable to the directory you put your `credentials` file in.

```sh
export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/credentials
```


You should now be able to run aws cli commands with the correct credentials. To test, run the following. If you have s3 buckets, you should be able to see them.

```sh
aws --profile data3404 s3 ls
```

7. You have to repeat step 6 every time you close your terminal/powershell if you chose the second option in step 4.

8. You also need to reset your credentials file every 3 hours no matter which option you chose in step 4. This is why I prefer Option 2.

## Script to run EMRS using CLI

In this step, there is just one really uncouth step you need to perform before setting up some magical git hooks. Since you'll be running the AWS CLI, it's good to actually have a CLI command that will probably work. 

1. Run a cluster manually as you would have usually. 

2. From a successful run, click on the `AWS CLI export` button after you open the link to a cluster for inspection. 

3. It should look something like this - 

```sh
aws emr create-cluster --applications Name=Hadoop Name=Spark --ec2-attributes '{"InstanceProfile":"EMR_EC2_DefaultRole","SubnetId":"subnet-XXXXXXXX","EmrManagedSlaveSecurityGroup":"sg-XXXXXXXXXXXXXXXX","EmrManagedMasterSecurityGroup":"sg-XXXXXXXXXXXXXXXXX"}' --release-label emr-5.29.0 --log-uri 's3n://data3404-nhas9102-a2/logs/' --steps '[{"Args":["spark-submit","--deploy-mode","cluster","s3://data3404-nhas9102-a2/code/UserRatingAnalysis.py"],"Type":"CUSTOM_JAR","ActionOnFailure":"TERMINATE_CLUSTER","Jar":"command-runner.jar","Properties":"=","Name":"Spark application"}]' --instance-groups '[{"InstanceCount":1,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":2}]},"InstanceGroupType":"MASTER","InstanceType":"m5.xlarge","Name":"Master Instance Group"},{"InstanceCount":2,"EbsConfiguration":{"EbsBlockDeviceConfigs":[{"VolumeSpecification":{"SizeInGB":32,"VolumeType":"gp2"},"VolumesPerInstance":2}]},"InstanceGroupType":"CORE","InstanceType":"m5.xlarge","Name":"Core Instance Group"}]' --configurations '[{"Classification":"spark","Properties":{}}]' --auto-terminate --service-role EMR_DefaultRole --enable-debugging --name 'code/UserRatingAnalysis.py' --scale-down-behavior TERMINATE_AT_TASK_COMPLETION --region us-east-1
```

4. Now, there are a couple of things we need to do before we can actually parameterise this script. The first step is to escape all the double quotes using a backslash `\`. And the second thing to do would be to change all the single quotes to double quotes since bash doesn't like variables inside single quotes. Use your favourite editor to find and replace all to do this. Then, just add a couple of command line arguments to accept the bucket and path to your code. __NOTE__ - You also need to add a new argument `--profile data3404` to the cli to specify credentials for data3404. Finally, you should end up with something like this - 

```sh
#!/bin/bash

export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/credentials

S3=$1
PYFILE=$2

aws emr create-cluster \
--profile data3404 \
--applications Name=Hadoop Name=Spark \
--ec2-attributes "{\"InstanceProfile\":\"EMR_EC2_DefaultRole\",\"SubnetId\":\"subnet-XXXXXXXX\",\"EmrManagedSlaveSecurityGroup\":\"sg-XXXXXXXXXXXXXXXX\",\"EmrManagedMasterSecurityGroup\":\"sg-XXXXXXXXXXXXXXXXX\"}" \
--release-label emr-5.29.0 \
--log-uri "s3n://your-bucket/logs/" \
--steps "[{\"Args\":[\"spark-submit\",\"--deploy-mode\",\"cluster\",\"${S3}/${PYFILE}\"],\"Type\":\"CUSTOM_JAR\",\"ActionOnFailure\":\"TERMINATE_CLUSTER\",\"Jar\":\"command-runner.jar\",\"Properties\":\"\",\"Name\":\"Spark application\"}]" \
--instance-groups "[{\"InstanceCount\":1,\"EbsConfiguration\":{\"EbsBlockDeviceConfigs\":[{\"VolumeSpecification\":{\"SizeInGB\":32,\"VolumeType\":\"gp2\"},\"VolumesPerInstance\":2}]},\"InstanceGroupType\":\"MASTER\",\"InstanceType\":\"m5.xlarge\",\"Name\":\"Master Instance Group\"},{\"InstanceCount\":2,\"EbsConfiguration\":{\"EbsBlockDeviceConfigs\":[{\"VolumeSpecification\":{\"SizeInGB\":32,\"VolumeType\":\"gp2\"},\"VolumesPerInstance\":2}]},\"InstanceGroupType\":\"CORE\",\"InstanceType\":\"m5.xlarge\",\"Name\":\"Core Instance Group\"}]" \
--configurations "[{\"Classification\":\"spark\",\"Properties\":{}}]" \
--auto-terminate \
--service-role EMR_DefaultRole \
--enable-debugging \
--name "${PYFILE}" \
--scale-down-behavior TERMINATE_AT_TASK_COMPLETION \
--region us-east-1
```
5. Make a file called `execute-emr.sh` in the root directory of your project and put the above contents into the file.

6. Make the file executable 

```sh
chmod +x execute-emr.sh
```

## Set up Git Hooks 

__NOTE__ - You will need git as a prerequisite for this step.

This step will enable you to upload your code to S3 everytime you push your code to git, and run a EMR cluster for the changed python file.

1. Add a pre-commit hook to your repository.

```sh
cd /path-to-your-git-repo/.git/hooks
touch pre-commit
chmod +x pre-commit
```

2. Open the pre-commit file with your favourite text editor

3. Now, copy the following contents into it. This step will synchroinse the contents of your directory with your s3 bucket you want to upload your python files to. This will be performed after every commit so you can work directly from your local machine.

```sh
#!/bin/bash
# Place this file into the .git/hooks directory inside your project

bucket="s3://your-bucket";
localPath="<path-to-your-git-repo>";


echo "Synchronizing commit to AWS Server...";

aws --profile data3404 s3 sync $localPath $bucket --exclude ".git/*" --exclude "credentials" --exclude ".gitignore";

echo "Content synchronized successfully!";

for file in $(git diff --cached --name-only | grep -E '\.(py)$')
do
  ./execute-emr.sh $bucket $file 
  if [ $? -ne 0 ]; then
    echo "Could not successfully run EMR stage on '$file'. Please check your code and try again."
    exit 1 # exit with failure status
  fi
done

```

5. Profit $$$


Best of luck! 
