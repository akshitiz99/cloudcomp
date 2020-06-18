provider "aws" {
 region  = "ap-south-1"
 profile = "kshitiz1"
} 
resource "aws_security_group""imbound-outbound" {
 
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
                       


 resource "aws_instance""kshitiz_1" {
   depends_on     = [aws_security_group.imbound-outbound]
   ami            = "ami-005956c5f0f757d37"
   instance_type  = "t2.micro"
   key_name       = "mykey1"
   security_groups = [aws_security_group.imbound-outbound.name]
   connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/my pc/Desktop/mykey1.pem")
    host     = aws_instance.kshitiz_1.public_ip
  }
 
     
     provisioner "remote-exec" {
    inline = [
      "sudo yum install httpd  php git -y",
      "sudo systemctl restart httpd",
      "sudo systemctl enable httpd",
    ]
  }   
}
    


 resource "aws_s3_bucket""bucket"{ 
   bucket     = "bucket8273009469"
   acl        = "public-read-write"
   region     = "ap-south-1"

}
 resource "aws_ebs_volume""my_vol"{
  depends_on     = [aws_instance.kshitiz_1]
  availability_zone = aws_instance.kshitiz_1.availability_zone
  size              = 1
}
 resource "aws_volume_attachment""ebs_attch" {
   depends_on  = [aws_ebs_volume.my_vol]
   device_name = "/dev/sdh"
   volume_id =  "${aws_ebs_volume.my_vol.id}"
   instance_id = "${aws_instance.kshitiz_1.id}"

}
 resource "null_resource""commands"{
  depends_on = [aws_volume_attachment.ebs_attch]
   connection {
    type     = "ssh"
    user     = "ec2-user"
    private_key = file("C:/Users/my pc/Desktop/mykey1.pem")
    host     = aws_instance.kshitiz_1.public_ip
  }
  provisioner "remote-exec"{
  inline = [
      "sudo mkfs.ext4  /dev/xvdh",
      "sudo mount  /dev/xvdh  /var/www/html",
      "sudo rm -rf /var/www/html/*",
      "sudo git clone https://github.com/akshitiz99/cloudcomp_basic_site.git  /var/www/html/"
    ] 
}
}
  

 resource "aws_s3_bucket_object""document"{
   depends_on = [aws_s3_bucket.bucket]
   bucket  = "bucket8273009469"
   key    =  "pic"
   acl    =  "public-read-write"
   source =  "C:/Users/my pc/Desktop/kk.jpg"
   
}
 
 resource "aws_cloudfront_distribution" "s3_cloud"{
    depends_on = [aws_s3_bucket_object.document]
     origin {
       domain_name = aws_s3_bucket.bucket.bucket_regional_domain_name
       origin_id   = "custom-bucket8273009469"
    }
      enabled = "true"    
   default_cache_behavior{
      allowed_methods = ["GET","POST","PUT","DELETE","HEAD","OPTIONS","PATCH"]
      cached_methods  = ["GET","HEAD"]
      target_origin_id = "custom-bucket8273009469"
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
  restrictions{
   geo_restriction{
     restriction_type = "none"
 }
}
  viewer_certificate {
    cloudfront_default_certificate = true
}
}
            

  output "bucketid" {
  value = aws_s3_bucket.bucket.bucket
}
output "myos_ip" {
  value = aws_instance.kshitiz_1.public_ip
}
  
resource "null_resource""conn"{
  depends_on = [aws_cloudfront_distribution.s3_cloud]
 connection {
    type        = "ssh"
    user        = "ec2-user"
    private_key = file("C:/Users/my pc/Desktop/mykey1.pem")
    host        = aws_instance.kshitiz_1.public_ip
  }

 provisioner "remote-exec" {
    inline = [
      "sudo su <<END",
      "echo \"<img src='http://${aws_cloudfront_distribution.s3_cloud.domain_name}/${aws_s3_bucket_object.document.key}' height='6300' width='1200'>\" >> /var/www/html/index.php",
      "END",
    ]
  
}
}
/*resource "null_resource" "openwebsite"  {
depends_on = [null_resource.conn
    
  ]
 provisioner "local-exec" {
    command = "curl 
   http://${aws_instance.kshitiz_1.public_ip}/myweb.html"
   }
} */





	



















     
     
 