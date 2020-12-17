# PowerShell script file to be executed as a AWS Lambda function. 
# 
# When executing in Lambda the following variables will be predefined.
#   $LambdaInput - A PSObject that contains the Lambda function input data.
#   $LambdaContext - An Amazon.Lambda.Core.ILambdaContext object that contains information about the currently running Lambda environment.
#
# The last item in the PowerShell pipeline will be returned as the result of the Lambda function.
#
# To include PowerShell modules with your Lambda function, like the AWS.Tools.S3 module, add a "#Requires" statement
# indicating the module and version. If using an AWS.Tools.* module the AWS.Tools.Common module is also required.

#Requires -Modules aws.tools.common,aws.tools.rekognition

# Uncomment to send the input event to CloudWatch Logs
# Write-Host (ConvertTo-Json -InputObject $LambdaInput -Compress -Depth 5)

$Detections = Find-REKProtectiveEquipment -ImageBucket salaunch-team2-capstone -ImageName mask1.jpg
$Persons = $Detections.Persons
$LambdaOutput = ConvertTo-Json -Depth 10 -InputObject $Detections

#Find People without masks
$Persons | ForEach-Object {
    if (($_.BodyParts.EquipmentDetections -eq $null) -and ($_.BodyParts.Name -eq "Face") ){
        Write-Host "NonCompliant Person Detected!"
        ConvertTo-Json $_.BodyParts.EquipmentDetections | Write-Host
    }
}