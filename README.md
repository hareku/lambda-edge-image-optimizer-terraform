# CloudFront + Lambda@Edge Image optimizer

## Terraform
`docker run -i -t -v $(pwd):/app/ -w /app/ hashicorp/terraform:light apply`

https://github.com/hashicorp/docker-hub-images/tree/master/terraform  

## NPM
https://github.com/lovell/sharp/blob/master/docs/install.md

docker run -v "$PWD":/var/task lambci/lambda:build-nodejs8.10 npm install
