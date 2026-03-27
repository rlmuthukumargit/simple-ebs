locals {
  # --- Auto Scaling Group settings for Elastic Beanstalk ---
  asg_settings = [
    {
      namespace = "aws:autoscaling:asg"
      name      = "MinSize"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "MaxSize"
      value     = "1"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "CustomAvailabilityZones"
      value     = "Any" # Match image "Any"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "Availability Zones" # For older stacks or specific naming
      value     = "Any"
    },
    {
      namespace = "aws:autoscaling:asg"
      name      = "ScalingCooldown"
      value     = "360" # Match image 360
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "MeasureName"
      value     = "NetworkOut" # Match image NetworkOut
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Unit"
      value     = "Bytes" # Match image Bytes
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "UpperThreshold"
      value     = "6000000" # Match image 6000000
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "LowerThreshold"
      value     = "2000000" # Match image 2000000
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Statistic"
      value     = "Average" # Match image Average
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "Period"
      value     = "5" # Match image 5
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "EvaluationPeriods"
      value     = "5" # Match image breach duration 5
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "UpperBreachScaleIncrement"
      value     = "1" # Match image scale up increment 1
    },
    {
      namespace = "aws:autoscaling:trigger"
      name      = "LowerBreachScaleIncrement"
      value     = "-1" # Match image scale down increment -1
    }
  ]
}
