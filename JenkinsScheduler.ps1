function JenkinsTriggerOnTime {
    #param([string]$folder)

    Write-Host "Invoking Job Trigger."
    # Invoke Jenkins job using REST API
    $jenkinsUrl = "http://localhost:8080/job/jenkins-api-call/build"

    $username = "dhilip"
 #  $password = "jenkins123"
 # api token enabled credentials
	$password = "117e09e877033d767d84032b58d61d019d"
    $authInfo = "${username}:${password}"
	
	$bytes = [System.Text.Encoding]::UTF8.GetBytes($authInfo)
	$encodedAuthInfo = [System.Convert]::ToBase64String($bytes)
 
	
	$crumbUrl = "http://localhost:8080/crumbIssuer/api/json"
	$headers = @{
    Authorization = "Basic $encodedAuthInfo"
		"Jenkins-Crumb" = "6b384f701c0627aa7689065fc461f588b8c3a6d34e47adbeb2f228c691fef15e"
	}
	$crumb = Invoke-RestMethod -Uri $crumbUrl -Method GET -Headers $headers
	
try {
    # Set the URL for the crumb issuer endpoint
    $crumbUrl = "http://localhost:8080/crumbIssuer/api/json"

    # Set the headers for the API request, including the basic authentication credentials and the crumb value
    $headers = @{
        Authorization = "Basic $encodedAuthInfo"
        "Jenkins-Crumb" = (Invoke-RestMethod -Uri $crumbUrl -Method Get -Headers @{Authorization = "Basic $encodedAuthInfo"}).crumb
    }
	
	#Set the jenkins job information in json format
	$jobInfo = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/job/jenkins-api-call/api/json" -Headers $headers
	
	 #Write-Host "Job name : $jobInfo.name"
	 #Write-Host "Job url : $jobInfo.url"
	 #Write-Host "Previous build : $jobInfo.lastBuild.number"
	 
	 # Print the job information
	Write-Host "Job name : $($jobInfo.name)"
	Write-Host "Job url : $($jobInfo.url)"
	Write-Host "Previous build : $($jobInfo.lastBuild.number)"
	
    # Set the URL for the build endpoint and invoke a POST request to trigger a build
    $jobTrigger = Invoke-RestMethod -Method POST -Uri "http://localhost:8080/job/jenkins-api-call/build"  -Headers $headers
	
	
	$jobInfo = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/job/jenkins-api-call/api/json" -Headers $headers
	
	Start-Sleep -Seconds 15
	
	$jobInfoAfterBuild = Invoke-RestMethod -Method GET -Uri "http://localhost:8080/job/jenkins-api-call/api/json" -Headers $headers
	

    # Get the status code from the response object
	    if ($jobInfoAfterBuild.lastCompletedBuild.number -ge $jobInfo.lastBuild.number) {
        Write-Host "Jenkins job triggered and success"
    }
    else {
        Write-Host "Jenkins job trigger is not success."
    }
 

    # Output the status code to the console
    #Write-Host "Status code: $status"
}
catch {
    Write-Host "Error: $_.Exception.Message"
}

    #$response = Invoke-RestMethod -Uri $jenkinsUrl -Method Post -Headers $headers  -TimeoutSec 15
	#if ($LASTEXITCODE -eq 0 -and $response.StatusCode -ge 200 -and $response.StatusCode -lt 300) {
    # Success
    #Write-Host "Job triggered successfully. Response: $($response.Content)"
	#} elseif ($LASTEXITCODE -eq 0 -and $response.StatusCode -eq 403) {
    # Authentication failed
	#   Write-Host "Authentication failed. Please check your API token."
	#} else {
    # Other errors
	#   Write-Host "Failed to trigger job. StatusCode: $($response.StatusCode) Reason: $($response.StatusDescription)"
	#}
	
}

# Set the time when the job should be triggered (every day at 8 PM)
$triggerTime = "20:00"

# Loop indefinitely to check the current time
while($true)
{
    # Get the current time
    $currentTime = Get-Date

    # Check if the current time is after the trigger time
    if($currentTime.ToShortTimeString() -ge $triggerTime)
    {
        # Invoke the JenkinsTriggerOnTime function
        JenkinsTriggerOnTime

        # Wait for 24 hours before checking the time again
        Start-Sleep -Seconds 86400
    }
    else
    {
        # Wait for 5 minutes before checking the time again
        Start-Sleep -Seconds 300
    }
}