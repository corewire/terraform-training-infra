output "base_client_ips" {
	value = "${hcloud_server.client-base.*.ipv4_address}"
}

output "base_client_hostnames" {
	value = "${hcloud_server.client-base.*.name}"
}

output "vscode_client_ips" {
	value = "${hcloud_server.client-vscode.*.ipv4_address}"
}

output "vscode_client_hostnames" {
	value = "${hcloud_server.client-vscode.*.name}"
}

output "server_ip" {
	value = "${hcloud_server.server.ipv4_address}"
}

output "server_hostname" {
	value = "${hcloud_server.server.name}"
}

#output "passes" {
#  value = "${random_password.password.*.result}"
#}