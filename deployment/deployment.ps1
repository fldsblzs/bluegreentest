Param
(
    [Parameter(Mandatory=$true)]
    [string]
    $CurrentDeployment,

    [Parameter(Mandatory=$true)]
    [string]
    $ApplicationYamlFile,

    [Parameter(Mandatory=$true)]
    [string]
    $ServiceYamlFile,

    [Parameter(Mandatory=$false)]
    [bool]
    $IsDebug = $false
)
Begin {
    Write-Output "Blue-green deployment script."

    if ($IsDebug -eq $true) {
        Write-Output "Current deployment: $CurrentDeployment"
        Write-Output "Application manifest location: $ApplicationYamlFile"
        Write-Output "Service manifest location: $ServiceYamlFile"
    }
    
    $newDeployment = "blue"
    $previousDeployment = "green"
}
 
Process {
    ### Set new deployment configuration
    if ($CurrentDeployment.ToLowerInvariant() -match "blue") {
        Write-Output "The current deployment is in blue slot. New version will be deployed into green slot."
        $newDeployment = "green"
        $previousDeployment = "blue"
    }

    if (!(Test-Path $ApplicationYamlFile)) {
        Write-Error "File not found: $ApplicationYamlFile!"
    }

    if (!(Test-Path $ServiceYamlFile)) {
        Write-Error "File not found: $ServiceYamlFile!"
    }

    ### Replace tokens in application yaml manifest
    Write-Output "Replacing tokens in: $ApplicationYamlFile."
    $applicationYaml = Get-Content -Path $ApplicationYamlFile 
    $replaceCount = 0;

    for ($i = 0; $i -lt $applicationYaml.Count; $i++) {
        $currentLine = $applicationYaml[$i]

        if ($currentLine -match "{{{DEPLOYMENT}}}") {
            $replaceCount++
            $applicationYaml[$i] = $currentLine -replace [regex]::Escape("{{{DEPLOYMENT}}}"), $newDeployment
        }     
    }

    Write-Output "Replaced $replaceCount tokens in $ApplicationYamlFile."
    
    if ($IsDebug -eq $true) {
        Write-Output $applicationYaml
    }

    Write-Output "Overriding yaml file: $ApplicationYamlFile"
    Set-Content -Path $ApplicationYamlFile -Value $applicationYaml

    ### Replace tokens in service yaml manifest
    Write-Output "Replacing tokens in: $ServiceYamlFile."
    $serviceYaml = Get-Content -Path $ServiceYamlFile 
    $replaceCount = 0;

    for ($i = 0; $i -lt $serviceYaml.Count; $i++) {
        $currentLine = $serviceYaml[$i]

        if ($currentLine -match "{{{DEPLOYMENT}}}") {
            $replaceCount++
            $serviceYaml[$i] = $currentLine -replace [regex]::Escape("{{{DEPLOYMENT}}}"), $newDeployment
        }        
    }

    Write-Output "Replaced $replaceCount tokens in $ServiceYamlFile."

    if ($IsDebug -eq $true) {
        Write-Output $serviceYaml
    }

    Write-Output "Overriding yaml file: $ServiceYamlFile"
    Set-Content -Path $ServiceYamlFile -Value $serviceYaml

    ### Set up output variables for later tasks to consume
    Write-Host "##vso[task.setvariable variable=newSlot;isOutput=true]$newDeployment"
    Write-Host "##vso[task.setvariable variable=previousSlot;isOutput=true]$previousDeployment"
}
End {
    Write-Host "Script finished!"
}