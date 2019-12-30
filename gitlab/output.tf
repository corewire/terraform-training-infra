output "api-user-demo-projects" {
    value = gitlab_project.api-users.*.http_url_to_repo
}

output "git_01" {
    value = gitlab_project.git_01.http_url_to_repo
}

output "git_02" {
    value = gitlab_project.git_02.http_url_to_repo
}