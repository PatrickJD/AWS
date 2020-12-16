# PowerShell script file to be executed as a AWS Lambda function. 
# 
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
#
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
#
# To include PowerShell modules with your Lambda function, like the AWSPowerShell.NetCore module, add a "#Requires" statement 
# indicating the module and version.

#Requires -Modules aws.tools.common,aws.tools.cloudwatch,aws.tools.ec2

# Uncomment to send the input event to CloudWatch Logs
# Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)

function Set-EC2CPUUtilizationAlarms 
{
  [CmdletBinding()]
  param
  (
    [parameter(mandatory=$true)]
    [string]
    $snstopic
  )
  
  # Get EC2 instances
  try 
  {
    $ec2 = Get-EC2Instance -ErrorAction stop
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  # Write High CPU Alarms
  $ec2 | ForEach-Object {$i=0} {
  # Set dimensions for each object in the loop
  $dimension = New-Object Amazon.CloudWatch.Model.Dimension
  $dimension.set_Name("InstanceId")
  $dimension.set_Value("$($ec2.instances.instanceid[$i])")
  try 
  {
    Write-CWMetricAlarm -AlarmAction $snstopic -OKAction $snstopic -AlarmDescription "Alarms when average CPU is above 90% for 5 consecutive datapoints." -AlarmName "$($ec2.instances.instanceid[$i])-CPU-Alarm" -ComparisonOperator "GreaterThanOrEqualToThreshold" -MetricName "CPUUtilization" -Namespace "AWS/EC2" -Dimension $dimension -Threshold 90 -Period 60 -EvaluationPeriod 5 -Statistic "Average" -ErrorAction stop
    Write-Output "EC2 CPU Alarm Set for instance $($ec2.instances.instanceid[$i])"
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  $i++
  }
}

function Set-EC2StatusCheckAlarms 
{
  [CmdletBinding()]
  param
  (
    [parameter(mandatory=$true)]
    [string]
    $snstopic
  )
  
  # Get EC2 instances
  try 
  {
    $ec2 = Get-EC2Instance -ErrorAction stop
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  # Write Status Check Alarms
  $ec2 | ForEach-Object {$i=0} {
  # Set dimensions for each object in the loop
  $dimension = New-Object Amazon.CloudWatch.Model.Dimension
  $dimension.set_Name("InstanceId")
  $dimension.set_Value("$($ec2.instances.instanceid[$i])")
  try 
  {
    Write-CWMetricAlarm -AlarmAction $snstopic -OKAction $snstopic -AlarmDescription "Alarms when any status check fails on an EC2 instance." -AlarmName "$($ec2.instances.instanceid[$i])-HealthCheck-Alarm" -ComparisonOperator "GreaterThanOrEqualToThreshold" -MetricName "StatusCheckFailed" -Namespace "AWS/EC2" -Dimension $dimension -Threshold 1 -Period 60 -EvaluationPeriod 1 -Statistic "Maximum" -ErrorAction stop
    Write-Output "EC2 Status Check Alarm Set for instance $($ec2.instances.instanceid[$i])"
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  $i++
  }
}

function Set-EC2CreditBalanceAlarms 
{
  [CmdletBinding()]
  param
  (
    [parameter(mandatory=$true)]
    [string]
    $snstopic
  )
  
  # Get EC2 instances
  try 
  {
    $ec2 = Get-EC2Instance -ErrorAction stop
    $tec2 = $ec2.instances | Where-Object InstanceType -like "t*"
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  # Write Credit Balance Alarms
  $tec2 | ForEach-Object {
  # Set dimensions for each object in the loop
  $dimension = New-Object Amazon.CloudWatch.Model.Dimension
  $dimension.set_Name("InstanceId")
  $dimension.set_Value("$($tec2.instanceid)")
  try 
  {
    Write-CWMetricAlarm -AlarmAction $snstopic -OKAction $snstopic -AlarmDescription "Alarms when any status check fails on an EC2 instance." -AlarmName "$($tec2.instanceid)-CreditBalance-Alarm" -ComparisonOperator "LessThanOrEqualToThreshold" -MetricName "CPUCreditBalance" -Namespace "AWS/EC2" -Dimension $dimension -Threshold 50 -Period 300 -EvaluationPeriod 1 -Statistic "Average" -ErrorAction stop
    Write-Output "EC2 Credit Balance Check Set for instance $($tec2.instanceid)"
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
  }
}

Set-EC2CPUUtilizationAlarms -snstopic "TOPIC_ARN"
Set-EC2StatusCheckAlarms -snstopic "TOPIC_ARN"
Set-EC2CreditBalanceAlarms -snstopic "TOPIC_ARN"