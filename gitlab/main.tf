# Configure the GitLab Provider
provider "gitlab" {
    token           = "${var.gitlab_token}"
    base_url        = "${var.base_url}"
}

locals {
    user_ids                    = gitlab_user.users.*.id
    project_api-users_ids       = gitlab_project.api-users.*.id
    git-group                   = gitlab_group.git-users.id
}

resource "gitlab_user" "users" {
    count           = "${var.user_count}"
    username        = "user-${count.index}"
    name            = "user ${count.index}"
    email           = "user-${count.index}@example.com"
    password        = "${var.user_pass}"
    projects_limit  = 0
}

resource "gitlab_project" "api-users" {
    depends_on              = [
        gitlab_user.users,
        gitlab_group.git-users
    ]
    count                   = "${var.user_count}"
    namespace_id            = "${element(local.user_ids, count.index)}"
    name                    = "api-users"
    shared_runners_enabled  = "true"
    default_branch          = "master"
}

resource "gitlab_project_membership" "api_users_admin_access" {
    count                   = "${var.user_count}"
    access_level            = "maintainer"
    user_id                 = 1
    project_id              = "${element(local.project_api-users_ids, count.index)}"
}

resource "gitlab_group" "git-users" {
    depends_on  = [gitlab_user.users]
    name        = "git-users"
    path        = "git-users"
}

resource "gitlab_group_membership" "git-users-member" {
    depends_on          = [
        gitlab_user.users,
        gitlab_group.git-users
    ]
    count               = "${var.user_count}"
    group_id            = "${gitlab_group.git-users.id}"
    user_id             = "${element(local.user_ids, count.index)}"
    access_level        = "developer"
}

resource "gitlab_project" "git_01" {
    namespace_id            = "${gitlab_group.git-users.id}"
    name                    = "git-01"
    shared_runners_enabled  = "false"
    default_branch          = "master"
}

resource "gitlab_project" "git_02" {
    namespace_id            = "${gitlab_group.git-users.id}"
    name                    = "git-02"
    shared_runners_enabled  = "false"
    default_branch          = "master"
}

resource "gitlab_project_variable" "reg_pass" {
    count                   = "${var.user_count}"
    project                 = "${element(local.project_api-users_ids, count.index)}"
    key                     = "REG_PASS"
    value                   = "${var.registry_password}"
    environment_scope       = "*"
}