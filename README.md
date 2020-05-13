## 1. Download AWS CLI

Follow the steps listed [here](https://aws.amazon.com/cli/).

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

For __Linux/Mac OS__ users, run this from the working directory you put your credentials file in from your terminal. 
```sh
export AWS_SHARED_CREDENTIALS_FILE=$(pwd)/credentials
```

For __Windows__ users, run this (I don't know the equivalent of the pwd command in Windows) from your Powershell/Command Prompt
```bat
set AWS_SHARED_CREDENTIALS_FILE=<path_to_credentials>
```

You should now be able to run aws cli commands with the correct credentials. To test, run the following. If you have s3 buckets, you should be able to see them.

```sh
aws --profile data3404 s3 ls
```

7. You have to repeat step 6 every time you close your terminal/powershell if you chose the second option in step 4.

8. You also need to reset your credentials file every 3 hours no matter which option you chose in step 4. This is why I prefer Option 2.
