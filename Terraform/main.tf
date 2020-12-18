                        ## Tp Examen Pipeline de traitement de données   ###
                        ## Nom : Tsague Nguegang ##
                        ## Prenom: Symphoris ##




# créeation du vpc

resource "aws_vpc" "main_vpc" {
  cidr_block = "10.0.0.0/24"
}

# création du subnet

resource "aws_subnet" "submet_vpc" {
  vpc_id = aws_vpc.main_vpc.id
  cidr_block = "10.0.0.0/24"
}

# création de la table de routage

resource "aws_route_table" "r" {
  vpc_id = aws_vpc.main_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
  tags = {
    Name = "main route table"
  }
}

# création de la gateway 
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main_vpc.id

  tags = {
    Name = "main gateway"
  }
}


# creation de l'image ubuntu

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-focal-20.04-amd64-server-*"]
  }
  owners = ["099720109477"]
}

# creation de l'instance t2.micro aws

resource "aws_instance" "pipeline" {
	ami = data.aws_ami.ubuntu.id
	instance_type = "t2.nano"
  security_groups = ["${aws_security_group.tp_pipeline_donnees.name}"]
	key_name = "tp_data"
	tags = {
		Name = "Terraform-Pipeline"	
		Batch = "5AM"
	}
}

# zone de disponibilité
data "aws_availability_zones" "available" {
  state = "available"
}

# création du groupe de sécurité: autorisation de la connection ssh et http
resource "aws_security_group" "tp_pipeline_donnees" {
  name        = "tp_pipeline_donnees"
  description = "Allow ssh and http traffic"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
    ingress{
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
     ingress{
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]

    }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

}


 # création de Kinesis Stream
resource "aws_kinesis_stream" "test_stream" {
  name             = "tp_exam_pipeline_flux"
  shard_count      = 1
  retention_period = 48

  shard_level_metrics = [
    "IncomingBytes",
    "OutgoingBytes",
  ]

  tags = {
    Environment = "dev"
  }
}

# création du bucket s3

resource "aws_s3_bucket" "bucket" {
  bucket = "tpexamen1"
  acl    = "private"
}

resource "aws_s3_bucket" "result" {
  bucket = "buckettarget1"
  acl    = "private"
}

# création d'un role iam
resource "aws_iam_role" "firehose_role" {
  name = "symphoris3"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
  "Action": "sts:AssumeRole",
  "Principal": { "Service": "firehose.amazonaws.com" },
  "Effect": "Allow",
  "Sid": "" } ]
}
EOF
}

# création de la stratégie
resource "aws_iam_role_policy" "inline-policy" {
  name   = "tpexampolicy"
  role   = aws_iam_role.firehose_role.id
  policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "s3:AbortMultipartUpload",
        "s3:GetBucketLocation",
        "s3:GetObject",
        "s3:ListBucket",
        "s3:ListBucketMultipartUploads",
        "s3:PutObject"
        
      ],
      "Resource": "*"
    },
    {
      "Effect": "Allow",
      "Action": [
        "kinesis:DescribeStream",
        "kinesis:PutRecord",
        "kinesis:PutRecords",
        "kinesis:GetShardIterator",
        "kinesis:GetRecords",
        "kinesis:ListShards",
        "kinesis:DescribeStreamSummary",
        "kinesis:RegisterStreamConsumer"
      
      ],
      "Resource": "*"
    }
  ]
}
EOF
}

# création de Kinesis firehose
resource "aws_kinesis_firehose_delivery_stream" "test_stream" {
  name        = "pipeline_exam_fluxdiff1"
  destination = "s3"

kinesis_source_configuration{
    kinesis_stream_arn = aws_kinesis_stream.test_stream.arn
    role_arn = aws_iam_role.firehose_role.arn
}
  s3_configuration {
    role_arn   = aws_iam_role.firehose_role.arn
    bucket_arn = aws_s3_bucket.bucket.arn
  }
}

# création du crawler et du role
resource "aws_iam_role" "crawler_role" {
  name = "glue_crawler"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [ {
  "Action": "sts:AssumeRole",
  "Principal": { "Service": "glue.amazonaws.com" },
  "Effect": "Allow",
  "Sid": "" } ]
}
EOF
}
resource "aws_glue_crawler" "tpcrawler" {
  database_name = aws_athena_database.database.name
  name          = "tp_pipeline_crawler"
  role          = aws_iam_role.crawler_role.arn

  s3_target {
    path = "s3://sympho111"
  }
}
resource "aws_athena_database" "database" {
  name   = "tp_pipeline_data"
  bucket = aws_s3_bucket.result.bucket
}









