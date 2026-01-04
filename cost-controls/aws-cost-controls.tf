# AWS Cost Controls Configuration

# Budget for the SaaS platform
resource "aws_budgets_budget" "saas_platform_monthly" {
  name              = "saas-platform-monthly-budget"
  budget_type       = "COST"
  limit_amount      = "5000.0"  # $5,000 USD monthly budget
  limit_unit        = "USD"
  time_unit         = "MONTHLY"
  time_period_start = "2026-01-01_00:00"

  # Cost allocation tags to track spending by application
  cost_types {
    include_tax         = true
    include_subscription = true
    include_support     = true
    include_recurring_charges = true
    include_upfront_costs = true
    include_usage       = true
    include_other_subscription_costs = true
  }

  # Track costs by application tags
  tags {
    key      = "Application"
    match_tags = ["multitenant-api"]
  }

  # Notification for forecasted budget usage at 80%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 80
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_arns        = [aws_sns_topic.budget_alerts.arn]
  }

  # Notification for forecasted budget usage at 90%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 90
    threshold_type             = "PERCENTAGE"
    notification_type          = "FORECASTED"
    subscriber_sns_arns        = [aws_sns_topic.budget_alerts.arn]
  }

  # Notification for actual budget usage at 100%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 100
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_arns        = [aws_sns_topic.budget_alerts.arn]
  }

  # Notification for actual budget usage at 110%
  notification {
    comparison_operator        = "GREATER_THAN"
    threshold                  = 110
    threshold_type             = "PERCENTAGE"
    notification_type          = "ACTUAL"
    subscriber_sns_arns        = [aws_sns_topic.budget_alerts.arn]
  }
}

# SNS Topic for budget alerts
resource "aws_sns_topic" "budget_alerts" {
  name = "saas-platform-budget-alerts"

  tags = {
    Environment = var.environment
    Application = "cost-controls"
  }
}

# SNS Topic Subscription for email notifications
resource "aws_sns_topic_subscription" "budget_alerts_email" {
  count  = length(var.budget_alert_emails)
  topic_arn = aws_sns_topic.budget_alerts.arn
  protocol  = "email"
  endpoint  = var.budget_alert_emails[count.index]
}

# CloudWatch Alarm for resource quotas
resource "aws_cloudwatch_metric_alarm" "ec2_cpu_utilization_high" {
  alarm_name          = "EC2-CPU-Utilization-High"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = "2"
  metric_name        = "CPUUtilization"
  namespace          = "AWS/EC2"
  period             = "300"
  statistic          = "Average"
  threshold          = "80"
  alarm_description  = "This metric monitors EC2 CPU utilization"
  
  dimensions = {
    InstanceId = var.ec2_instance_ids
  }

  alarm_actions = [aws_sns_topic.budget_alerts.arn]
}

# Service quotas for EC2 instances
resource "aws_servicequotas_service_quota" "ec2_running_ondemand_standard_instances" {
  quota_code   = "L-1216C47A"
  service_code = "ec2"
  desired_value = 50  # Adjust based on requirements
}

# IAM policy for cost management
resource "aws_iam_policy" "cost_management_policy" {
  name        = "saas-platform-cost-management"
  description = "Policy for managing cost controls and optimization"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "budgets:ViewBudget",
          "budgets:ModifyBudget",
          "ce:GetCostAndUsage",
          "ce:GetCostForecast",
          "ce:GetDimensionValues",
          "ce:GetReservationUtilization",
          "s3:GetBucketTagging",
          "s3:ListAllMyBuckets",
          "cloudwatch:GetMetricStatistics",
          "ec2:DescribeSpotPriceHistory",
          "ec2:DescribeInstances",
          "ec2:DescribeInstanceTypes"
        ]
        Resource = "*"
      }
    ]
  })
}

# Variables for the cost controls configuration
variable "environment" {
  description = "The environment name (dev, staging, prod)"
  type        = string
  default     = "prod"
}

variable "budget_alert_emails" {
  description = "List of email addresses to receive budget alerts"
  type        = list(string)
  default     = ["finance@company.com", "engineering@company.com"]
}

variable "ec2_instance_ids" {
  description = "Map of EC2 instance IDs for monitoring"
  type        = map(string)
  default     = {}
}

# Outputs
output "budget_alerts_sns_topic_arn" {
  description = "ARN of the SNS topic for budget alerts"
  value       = aws_sns_topic.budget_alerts.arn
}

output "cost_management_policy_arn" {
  description = "ARN of the cost management IAM policy"
  value       = aws_iam_policy.cost_management_policy.arn
}