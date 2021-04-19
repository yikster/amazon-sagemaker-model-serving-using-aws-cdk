#!/bin/bash

echo Install prerequiste 
sudo yum install -y jq
npm audit fix -y

REGION=ap-northeast-2
REPOSITORY_NAME=mlop-apne2
STS_IDENTITY=`aws sts get-caller-identity --output text | gawk '{print $2 }' `
ACCOUNT=$(cut -d':' -f5<<< $STS_IDENTITY)
JQ_PARM="'"".Project.Profile=\"default\" | .Project.Account=\"$ACCOUNT\"""'"
ECR_ARN="763104351884.dkr.ecr.$REGION.amazonaws.com/pytorch-inference:1.4.0-cpu-py36-ubuntu16.04"

aws codecommit create-repository --repository-name $REPOSITORY_NAME
git push https://git-codecommit.$REGION.amazonaws.com/v1/repos/$REPOSITORY_NAME
cp config/app-config.json config/app-config.json.old
echo $( jq '.Project.Profile="default" | .Project.Account='\"$ACCOUNT\"' | .Project.Region='\"$REGION\"'  | .Stack.ModelServing.ModelList[].ModelDockerImage='\"$ECR_ARN\"' | .Stack.CICDPipeline.RepositoryName='\"$REPOSITORY_NAME\"' | .Stack.CICDPipeline.BranchName='\"main\"'' config/app-config.json  ) > tmp_jq
jq . tmp_jq > config/app-config.json
cat tmp_jq
#rm -rf tmp_jq

echo copy model files
aws s3 cp s3://textclassificationdemo-model-archiving-ap-northeast-2-51959/models/model-a/model/model.tar.gz models/model-a/src/
cd models/model-a/src
tar zxvf model.tar.gz

cd ../../../

echo - Start packing models
#sh script/pack_models.sh
 
echo - Start setup initial
#sh script/setup_initial.sh

echo - Start deploy stacks
#sh script/deploy_stacks.sh

echo - Start Test
#sh script/trigger_tests.sh
