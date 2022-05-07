# define terraform module output values here 

output "rs_cluster_endpoint" {
  description             = "Redshift Cluster Endpoint"
  value                   = aws_redshift_cluster.rs_cluster.endpoint
}

output "client_ec2_public_dns" {
  value                   = aws_instance.client_app.public_dns
}
 
output "client_ec2_ssh_command" {
  value                   = "ssh -i '${var.client_ssh_keypair_name}.pem' ec2-user@${aws_instance.client_app.public_dns}"
}

output "client_psql_command" {
  value                   = "psql -h ${aws_redshift_cluster.rs_cluster.dns_name} -U ${aws_redshift_cluster.rs_cluster.master_username} -d ${aws_redshift_cluster.rs_cluster.database_name} -p ${aws_redshift_cluster.rs_cluster.port}"
}
