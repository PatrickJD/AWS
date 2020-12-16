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

#Requires -Modules aws.tools.common,aws.tools.cloudwatch

# Uncomment to send the input event to CloudWatch Logs
#Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)


function Remove-StaleCWAlarms
{
  [CmdletBinding()]
  param ()
  try 
  {
    # Get alarms with an Insufficient State and then filter for alarms last updated greater than 30 days ago
    $alarms = get-cwalarm | Where-Object StateValue -eq "INSUFFICIENT"
    $stalealarms = $alarms | Where-Object StateUpdatedTimestamp -lt (Get-Date).adddays(-30)
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }

  try 
  {
    # Remove alarms with no status change in over 30 days an insufficient status
    $stalealarms | Remove-CwAlarm -Force
  }
  catch 
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }
}

Remove-StaleCWAlarms