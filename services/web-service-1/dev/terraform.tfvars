project            = "web-service-1"
env                = "dev"

#
ami_id             = "ami-035f4c601044a7af4"
key_name           = "seoul-ed25519"

app_instance_type  = "t3.micro"
app_instance_count = 2
app_port           = 8080

db_instance_type   = "t3.micro"
db_port            = 3306
db_volume_size_gb  = 1
