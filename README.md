# tp_examen_pipeline_symphoris


the goal of this project is to build a complete data pipeline on aws using Terraform.

I have developed a sparkStreaming application which retrieves tweets every 30 seconds.
The steps to get there are as follows:

- I made an architecture diagram that you will find in the root of the project.
- I made a sequence diagram to show the interactions between the different departments.
However, you need to create a Twitter app developer account if you don't have one. You will then create an application and retrieve the credetials that you will use in the Scala spark application.
I was inspired by the Terraform platform to produce the Terraform code, the variable names are self-explanatory enough to understand the reation of each resource.
If you want to test my application you have to follow the following steps:

create a working directory in your local workstation
- open git bash and do a git init
- git clone url
- Terraform cd
- Terraform init
- Terraform plan
- Terraform apply


All these commands will allow you to create the infra of the data pipipeline.

Then connect to your AWS account and retrieve the ssh key to connect to the created instance. Open a command prompt that is still in your directory and type the following commands:
cd twitter_app_scala
sbt compiles
cd target
scp [artifact name] user @ IP: / home /

Then run your artifact on your EC2 instance and wait 5 to 10 minutes you go to your s3 directory and open the "buckettarget" folder you will find the file sent by the twitter application. You can therefore go to Athena and execute the sql queries on the "tp_pipeline" table.
