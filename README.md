# AWS ECS (ec2 launch type) service hosting the containers Kong API gateway and a test application

Kong API gateway acts as proxy, routing the default route to test application

## KONG API Gateway

- KONG Container is deployed deployed in DB-less mode.
- The source of truth is the kong config file.
- Routes the default path to test application

Chose DB-less mode, where each of the running container will have the same config file (Kong.yml). The main advantage are,

- Easy to automate end to end
- Eliminates the need for DB overhead and configuration.

Refer to [Kong HQ](https://konghq.com/blog/kong-1-1-released/) for more information of DB-less mode.

## Test Application

- Its a simple web server exposing 'info' and 'health' endpoint
- Test application is just a demo app to show kong service forwarding.
- It does not have any application logic other than fixed response to the GET(info and health) and POST(/api).

## AWS Deployment

Deploys
- ECS Cluster using EC2 launch type
- Task definition host kong container and test container definition
- Configuration controls desired number of instances
- Containers are published in ECR
- Application Load Balancer(**ALB**) forwards to TargetGroup and exposes **public** DNS.
- Target Group health checks on service port which verifies health of both kong gateway and test application.
- Containers are run in **private** subnet
- Auto Scaling Group(**ASG**) takes care of scaling up the instances. 
- Container logs updated to **CloudWatch** log group

![Architecture](https://github.com/kulkarni-1983/kong-proxy-app/blob/master/docs/Arch_diagram.JPG)

## Deployment guide

 ### Quick start

 ```
# setup .env file for development.
make envfile

# YOU ARE STRONGLY ADVISED TO UPDATE .env file to succeed in deployment

# package the applications(Kong api gateway and test application) into a container 
make container

# Run the containers locally and verify the container respond appropriately.
make container_test

# Tag the container with version information
make tag

# publish the container to the docker registry
make publish

# deploy to aws (or update existing deployment)
make infra

# Perform a smoketest hitting healthcheck until cluster is up
make infra_test

# cleanup aws
make infra_destroy
```

### Process

Build and Deployment process is controlled via Makefile.

Environment variables are used to control service and deployment configuration. These are set via .env files used by docker-compose automatically.
*NOTE:* The intention is to follow a [12-factor app config approach](https://12factor.net/config), though the current .env generation process somewhat resembles deploy-specific environs. 
The build and deploy also follows [3 musketeers](https://amaysim.engineering/the-3-musketeers-how-make-docker-and-compose-enable-us-to-release-many-times-a-day-e92ca816ef17) approach of docker-compose, dockerfile and Makefile.

### Workflow
 - First step is `make envfile` and update ENV in it for their environment.
 - All the variables in `.env` file **MUST** be updated before proceeding to next steps. 
 - Then `make container && make tag && make publish && make infra` should build container, tag, publish to ECR, and deploy the KONG gateway and test application.
 - Test the deployment using `make infra_test` 
 
Note that 
- `make container tag publish` will build and publish **both kong api gateway and test application**
- unless an image tag has changed, `make infra` will not take effect if the cluster is already running tasks with the previous tag.

### Make environment overrides
The below generally do not need changing in regular process and mostly one time activity.
 - **ENV** - environment name used AWS resource names
 - **AWS_REGION** and **AWS_DEFAULT_REGION** - AWS Region where the stack should be deployed
 - **REPOSITORY_URL**- Deployment assumes that Repository is already create and uploads the container images to the specified location
 - **VPC_NAME** - VPC and subnet across multiple AZs must be setup before starting the deployment process. 
 - **AWS_ACCESS_KEY_ID** and **AWS_SECRET_ACCESS_KEY** - Access for the AWS Cli and cloudformation. **Please note NOT to checkin the keys to repository**
 - **DESIRED_CAPACITY** and **MAX_CAPACITY** - Desired and max capacity of number Instances and Tasks
 - **APP_PORT** - Port mapping for test application
 - **KONG_PROXY_LISTEN** - Kong api gateway proxy listener port

### TODO

- Separate Infra code to setup VPC and subnets if not already present
- Docs: Architecture diagram of AWS deployment.
- Verify `make infra_destroy` has successfully destroyed the stack.
- Generate the .env file using a script which takes input from the user instead of manually updating the .env file
