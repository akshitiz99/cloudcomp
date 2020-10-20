
provider "aws"{
 region =  "ap-south-1"

 profile = "kshitiz1"
}



resource "aws_security_group""sg1"{


 ingress {
    description = "TLS from VPC"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    description = "TLS from VPC"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "kshitiz_1"{
 depends_on = [aws_security_group.sg1]
 ami = "ami-0e306788ff2473ccb"
 instance_type  = "t2.micro"
 key_name       = "mykey1"
 security_groups = [aws_security_group.sg1.name]
 
connection {
 type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/my pc/Desktop/mykey1.pem")
    host     = aws_instance.kshitiz_1.public_ip
  }
 provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd amazon-efs-utils -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd"
    ]
  }
 }   

 
resource "aws_efs_file_system" "cf" {
depends_on = [aws_instance.kshitiz_1]
  creation_token = "my-product"

}
resource "aws_efs_mount_target" "cft" {
 depends_on = [aws_efs_file_system.cf]
  file_system_id = aws_efs_file_system.cf.id
  subnet_id = aws_instance.kshitiz_1.subnet_id
  
}
resource "aws_s3_bucket" "my_bucket"{
 bucket = "bucket838482435"
 acl = "public-read-write"
  

 

}
 resource "aws_s3_bucket_object""document"{
   depends_on = [aws_s3_bucket.my_bucket]
   bucket  = "bucket838482435"
   key    =  "pic"
   acl    =  "public-read-write"
   source =  "C:/Users/my pc/Desktop/kk.jpg"
   
}
 
 
 output "bucketid" {
  value = aws_s3_bucket.my_bucket.bucket
} 
resource "aws_cloudfront_distribution" "s3b" {
  depends_on=[aws_s3_bucket.my_bucket]
  
  origin {
    domain_name = aws_s3_bucket.my_bucket.bucket_regional_domain_name
    origin_id   = "custom-bucket838482435"
    }
    enabled             = true
    is_ipv6_enabled     = true
    
    default_cache_behavior {
    target_origin_id= "custom-bucket838482435"
    allowed_methods  = ["DELETE", "GET", "HEAD", "OPTIONS", "PATCH", "POST", "PUT"]
    cached_methods   = ["GET", "HEAD"]
    
    forwarded_values {
      query_string = false

      cookies {
        forward = "none"
      }
    }
    
    viewer_protocol_policy = "allow-all"
    min_ttl                = 0
    default_ttl            = 3600
    max_ttl                = 86400
    }
    
    restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

    
    viewer_certificate {
    cloudfront_default_certificate = true
  }
}

output "cdn-domain"{
depends_on=[ aws_cloudfront_distribution.s3b ]
value= aws_cloudfront_distribution.s3b.domain_name
}  
resource "null_resource" "conn"{
  depends_on = [aws_cloudfront_distribution.s3b,
                aws_instance.kshitiz_1,
                aws_efs_mount_target.cft]
 connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/my pc/Desktop/mykey1.pem")
    host        = aws_instance.kshitiz_1.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo mount -t efs -o tls ${aws_efs_file_system.cf.id}:/ /var/www/html",
      "sudo su <<END",
      "echo \"<img src='http://${aws_cloudfront_distribution.s3b.domain_name}/${aws_s3_bucket_object.document.key}' >\" >> /var/www/html/myweb.html",
      "END",
    ]
  }

}


output "local-exec" {
    value = "curl http://${aws_instance.kshitiz_1.public_ip}/myweb.html"
   }




