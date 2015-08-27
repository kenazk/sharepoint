﻿Switch-AzureMode -name AzureResourceManager

# Count of runs
$count = 2

# Variables
$templateFile = "C:\Users\kenazk\Desktop\GitHub\sharepoint\mainTemplate-nonic.json"
$paramsFile = "C:\Users\kenazk\Desktop\GitHub\sharepoint\parameters.json"
$params = Get-content $paramsFile | convertfrom-json
$location = "westeurope"
$rgprefix = "T23p"
$premium = $true

# Generate parameter object
$hash = @{};
foreach($param in $params.psobject.Properties)
{
    $hash.Add($param.Name, $param.Value.Value);
}

#Create new Resource Groups and Deployments for each run
for($i = 0; $i -lt $count; $i++)
{
    # Create new Resource Group
    $d = get-date
    $rgname = $rgprefix + '-'+ $d.Year + $d.Month + $d.Day + '-' + $d.Hour + $d.Minute + $d.Second
    New-AzureResourceGroup -Name $rgname -Location $location -Verbose 
    
    # Construct parameter set
    $dsuffix = "" + $d.hour + $d.minute + $d.Second
    $hash.dnsPrefix = "spha" + $dsuffix
    $hash.spCADNSPrefix = "spha" + $dsuffix + "ca"
    $hash.storageAccountNamePrefix = "sa" + $dsuffix
    $hash.location = $location

    if ($premium)
    {
        $hash.StorageAccountType = "Premium_LRS"
        $hash.witnessVMSize = "Standard_DS1"
        $hash.spVMSize = "Standard_DS3"
        $hash.sqlVMSize = "Standard_DS3"
        $hash.adVMSize = "Standard_DS1"
    } 
    else
    {
        $hash.StorageAccountType = "Standard_LRS"
        $hash.witnessVMSize = "Standard_D1"
        $hash.spVMSize = "Standard_D3"
        $hash.sqlVMSize = "Standard_D3"
        $hash.adVMSize = "Standard_D1"
    }

    # Run as asynchronous job
    $jobName = "spDeployment-" + $i;
    $sb = {
        param($rgname, $templateFile, $hash)
        function createSharepointDeployment($rgname, $templateFile, $hash)
        {
            $dep = $rgname + "-dep"; 
            New-AzureResourceGroupDeployment -ResourceGroupName $rgname -Name $dep -TemplateFile $templateFile -TemplateParameterObject $hash -Verbose 
        }
        createSharepointDeployment $rgname $templateFile $hash
    }
    $job = start-job -Name $jobName -ScriptBlock $sb -ArgumentList $rgname, $templateFile, $hash

    Start-sleep -s 5
}

