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

#Requires -Modules aws.tools.ec2,aws.tools.common

function Remove-AWSDefaultVPC
{
  [CmdletBinding()]
  param()

  # Get all EC2 regions in account
  try
  {
    $ec2regions = Get-EC2Region -ErrorAction stop
    $regions = $ec2regions.RegionName
  }
  catch
  {
    Write-Warning $error[0]
    Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
    exit
  }

  # Iterate through EC2 regions and clean up/remove the default VPC
  Foreach ($region in $regions) 
  {
    try
    {
      # Get the VPC, subnets, routetables and IGW across current region
      $vpc = get-ec2vpc -region $region | Where-Object {$_.IsDefault -eq "true"} -ErrorAction stop
      $subnets = Get-EC2Subnet -region $region | Where-Object {$_.VpcId -eq $vpc.VpcId} -ErrorAction stop
      $routetables = Get-EC2RouteTable -region $region | Where-Object {$_.VpcId -eq $vpc.VpcId} -ErrorAction stop
      $internetgateways = Get-EC2InternetGateway -region $region | Where-Object {$_.Attachments.VpcId -eq $vpc.VpcId} -ErrorAction stop
    }
    catch 
    {
      Write-Warning $error[0]
      Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
      exit
    }

    # Check that VPC exists in current region and clean up VPC contents if it does
    if ($vpc) 
    {

      # Remove Internet Gateway
      if ($internetgateways)
      {
        Foreach ($internetgateway in $internetgateways)
        {
          try
          {
            Write-Output "Removing IGW: $($internetgateway.InternetGatewayId)"
            Dismount-EC2InternetGateway -InternetGatewayId $internetgateway.InternetGatewayId -VpcID $vpc.VpcId -Region $region -Force -ErrorAction stop
            Remove-EC2InternetGateway -InternetGatewayId $internetgateway.InternetGatewayId -Region $region -Force -ErrorAction stop
          }
          catch
          {
            Write-Warning $error[0]
            Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
            exit
          }
        }
      }
      else 
      {
        Write-Output "No Internet Gateway found in $region"
      }

      # Remove Subnets
      if ($subnets)
      {
        Foreach ($subnet in $subnets)
        {
          try
          {
            Write-Output "Removing Subnet: $($subnet.subnetID)"
            Remove-EC2Subnet -SubnetId $subnet.SubnetId -Region $region -Force -ErrorAction stop
          }
          catch
          {
            Write-Warning $error[0]
            Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
            exit
          }
        }
      }
      else 
      {
        Write-Output "No Subnets found in $region"
      }

      # Remove VPC
      try 
      {
        Write-Output "Removing VPC: $($vpc.VpcId)"
        Remove-EC2Vpc -VpcId $vpc.VpcId -region $region -Force -ErrorAction stop
      }
      catch 
      {
        Write-Warning $error[0]
        Write-Warning "Terminating Script, enable debug Logging for more detail by setting the DebugPreference variable"
        exit
      }
    }
    else
    {
      Write-Output "No Default VPC found in Region $region"
    }
  }
}
Remove-AWSDefaultVPC