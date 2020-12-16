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

function Write-EC2CPUAlarms 
{
[CmdletBinding()]
param()

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
# Write High CPU Alarms to template
$ec2 | ForEach-Object {$i=0} {
try 
{
$name = get-ec2tag -Filter @{ Name="key";Values="Name"},@{ Name="resource-id";Values="$($ec2.instances.instanceid[$i])"}
$codeblock = @"
  CPUThresholdAlarm$($i):
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: $($name.value)-CPUAlarm
      Dimensions:
      - Name: InstanceId
        Value: $($ec2.instances.instanceid[$i])
      Namespace: AWS/EC2
      MetricName: CPUUtilization
      Statistic: Average
      Period: 60
      EvaluationPeriods: 5
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Threshold: 90
      OKActions:
        - !Ref snsTopic
      AlarmActions:
        - !Ref snsTopic
"@

$codeblock | Out-File -FilePath EC2alarms.yml -Append
Write-Output "EC2 CPU Alarm written to CloudFormation for instance $($ec2.instances.instanceid[$i])"
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

function Write-EC2StatusAlarms 
{
[CmdletBinding()]
param()

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
# Write High CPU Alarms to template
$ec2 | ForEach-Object {$i=0} {
try 
{
  $name = get-ec2tag -Filter @{ Name="key";Values="Name"},@{ Name="resource-id";Values="$($ec2.instances.instanceid[$i])"}
  $codeblock = @"
  EC2StatusAlarm$($i):
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: $($name.value)-StatusAlarm
      Dimensions:
      - Name: InstanceId
        Value: $($ec2.instances.instanceid[$i])
      Namespace: AWS/EC2
      MetricName: StatusCheckFailed
      Statistic: Maximum
      Period: 60
      EvaluationPeriods: 1
      ComparisonOperator: GreaterThanOrEqualToThreshold
      Threshold: 1
      OKActions:
        - !Ref snsTopic
      AlarmActions:
        - !Ref snsTopic
"@

$codeblock | Out-File -FilePath EC2alarms.yml -Append
Write-Output "EC2 Status alarm written to CloudFormation for instance $($ec2.instances.instanceid[$i])"
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

function Write-EC2CpuCreditAlarms 
{
[CmdletBinding()]
param()

# Get EC2 instances
try 
{
  $ec2 = Get-EC2Instance -ErrorAction stop
  $tec2 = $ec2.instances | Where-Object {$_.InstanceType -like "t*"}
}
catch 
{
  Write-Warning $error[0]
  Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
  exit
}
# Write CPU Credits alarms to template
$tec2 | ForEach-Object {$i=0} {
try 
{
$name = get-ec2tag -Filter @{ Name="key";Values="Name"},@{ Name="resource-id";Values="$($tec2[$i].instanceid)"}
$codeblock = @"
  CPUCreditAlarm$($i):
    Type: AWS::CloudWatch::Alarm
    Properties:
      AlarmName: $($name.value)-CPUCreditAlarm
      Dimensions:
      - Name: InstanceId
        Value: $($tec2[$i].instanceid)
      Namespace: AWS/EC2
      MetricName: CPUCreditBalance
      Statistic: Maximum
      Period: 60
      EvaluationPeriods: 1
      ComparisonOperator: LessThanOrEqualToThreshold
      Threshold: 50
      OKActions:
        - !Ref snsTopic
      AlarmActions:
        - !Ref snsTopic
"@

$codeblock | Out-File -FilePath EC2alarms.yml -Append
Write-Output "EC2 CPU credit alarm written to CloudFormation for instance $($tec2[$i].instanceid)"
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

function Write-EC2CWAlarmsCFTemplate {
  [CmdletBinding()]
  param (
    [parameter(mandatory=$true)]
    [string]
    $snstopic
  )

$TemplateHeader = @"
AWSTemplateFormatVersion: 2010-09-09
Description:  >
  ** This CloudFormation Template creates the CloudWatch alarms for EC2 **
Parameters: 
  snsTopic:
    Type: String
    Description: Name of the SNS Topic for CloudWatch alarms
    Default: $snstopic
Resources:
"@
# Write Header Shell of CloudFormation Template
$TemplateHeader | Out-File -FilePath EC2Alarms.yml
# Write CPU Threshold alarms
Write-EC2CPUAlarms
# Write status alarms
Write-EC2StatusAlarms
# Write CPU Credit Alarms
Write-EC2CpuCreditAlarms
}

Write-EC2CWAlarmsCFTemplate