function Watch-FileEvents {
    #param([string]$folder)
    $watcher = New-Object System.IO.FileSystemWatcher
    $watcher.Path = $folder
    $watcher.IncludeSubdirectories = $true
    $watcher.EnableRaisingEvents = $true

    $eventsOccurred = $false

    Register-ObjectEvent $watcher "Created" -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "New file created: $path"
        $global:eventsOccurred = $true
    }

    Register-ObjectEvent $watcher "Deleted" -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "File deleted: $path"
        $global:eventsOccurred = $true
    }

    Register-ObjectEvent $watcher "Changed" -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "File changed: $path"
        $global:eventsOccurred = $true
    }

    Register-ObjectEvent $watcher "Renamed" -Action {
        $path = $Event.SourceEventArgs.FullPath
        Write-Host "File renamed: $path"
        $global:eventsOccurred = $true
    }

    return $eventsOccurred
}

$folder = 'C:\Work\1\MBD\chat_gpt\Jenkins_Automation\Filewatch'
$eventsOccurred = Watch-FileEvents $folder

if ($eventsOccurred) {
    Write-Host "File events occurred."
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
        Write-Host "Jenkins job is not success."
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
