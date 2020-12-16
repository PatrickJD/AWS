function Get-STSTempCreds {
  [CmdletBinding()]
  param
  (
    [parameter(mandatory=$true, HelpMessage="Enter the MFA code from your MFA Device")]
    [int]
    $MFACode
  )
  
  # Get the current user's identity from CLI
  $identity = aws sts get-caller-identity | ConvertFrom-Json
  $username = $identity -replace "^[^/]+?/\s*"
  $username = $username.trimend("}")
  Write-Output "Identified you as user: $username"

  # Get the user's MFA serial for the script
  $mfa = aws iam list-mfa-devices --user-name "$username" | ConvertFrom-Json

  # Get temporary credentials and save to aws configuration
  $temporarycreds = aws sts get-session-token --serial-number "$($mfa.mfadevices.serialnumber)" --token-code $mfacode | ConvertFrom-Json
  aws configure set --profile mfa  aws_access_key_id "$($temporarycreds.credentials.AccessKeyId)"
  aws configure set --profile mfa  aws_secret_access_key "$($temporarycreds.credentials.SecretAccessKey)"
  aws configure set --profile mfa  aws_session_token "$($temporarycreds.credentials.SessionToken)"
  Write-Output "Updated MFA Profile"
}
Get-STSTempCreds