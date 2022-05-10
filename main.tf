locals {
	zone_domain = length(var.custom_domains) == 0 ? "" : substr(var.custom_domains[0], 0, length(split(".", var.custom_domains[0]) ) )
	dns_records = [ for v in var.custom_domains : { name = replace(v, ".${local.zone_domain}", ""),
													type = "CNAME",
													records = [ keys(module.app_runner.app_runner_custom_domains) ] } ]
	iam_roles = { "ecr" = { name = "my-app-runner-role-for-ecr",
							policy = module.app_runner.app_runner_standard_policies.ecr,
							description = "Role for App Runner to access ECR",
							policy_attachments = [ "arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess" ],
							tags = var.tags } }
	image_tag = split(":", var.image)[1]
}

module "iam_roles" {
	source = "github.com/jonatan-buus-aws/terraform-modules/iam-role"

	for_each = local.iam_roles

	iam_role_name = each.value.name
	iam_assume_role_policy = each.value.policy
	iam_role_description = each.value.description
	iam_policy_attachments = each.value.policy_attachments
	iam_tags = each.value.tags
}
module "ecr" {
	source = "github.com/jonatan-buus-aws/terraform-modules/ecr"

	ecr_repository_name = var.repository
}
resource "null_resource" "docker" {
	provisioner "local-exec" {
		command = "aws ecr get-login-password | docker login --username AWS --password-stdin ${module.ecr.ecr_repository_url}"
	}
	provisioner "local-exec" {
		command = "docker tag ${var.image} ${module.ecr.ecr_repository_url}:${local.image_tag}"
	}
	provisioner "local-exec" {
		command = "docker push ${module.ecr.ecr_repository_url}:${local.image_tag}"
	}
}
module "app_runner" {
	depends_on = [ null_resource.docker ]

	source = "github.com/jonatan-buus-aws/terraform-modules/app-runner"

	app_runner_depends_on = [ module.iam_roles["ecr"].iam_role.arn ]
	app_runner_service_name = var.service_name
	app_runner_image = { identifier = "${module.ecr.ecr_repository_url}:${local.image_tag}",
						 role = module.iam_roles["ecr"].iam_role.arn }
	app_runner_custom_domains = var.custom_domains
	app_runner_environment_variables = var.environment_variables
	app_runner_tags = var.tags
}

resource "null_resource" "output" {
	provisioner "local-exec" {
		command = "echo API Documentation available at: https://${module.app_runner.app_runner_service.domain}/swagger-ui/"
	}
}