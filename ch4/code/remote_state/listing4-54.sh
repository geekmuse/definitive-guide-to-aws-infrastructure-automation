terraform init \
    -backend=true \
    -backend-config "bucket=my-s3-state-bucket" \
    -backend-config "region=${DEPLOY_REGION}" \
    -backend-config "encrypt=true" \
    -backend-config "key=${DEPLOY_ENV}/${DEPLOY_REGION}/terraform.tfstate"
