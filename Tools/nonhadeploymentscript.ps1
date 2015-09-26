Switch-AzureMode -name AzureResourceManager

#######################################
###       NON HA SHAREPOINT         ###
#######################################

# Count of runs
$count = 1

# Variables
#$templateFile = "C:\Users\kenazk\Desktop\GitHub\sharepoint\nonha\mainTemplate.json"
$templateFile = "C:\daily\2015-9-22\mainTemplate.json"
$paramsFile = "C:\Users\kenazk\Desktop\GitHub\sharepoint\nonha\parameters.json"
$params = Get-content $paramsFile | convertfrom-json
$location = "westus"
$rgprefix = "NHA1"
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
    $hash.spDnsPrefix = "spnonha" + $dsuffix
    $hash.storageAccountName = "sa" + $dsuffix
    $hash.location = $location
    $hash.adminUsername = "admin123"

    if ($premium)
    {
        $hash.StorageAccountType = "Premium_LRS"
        $hash.spVMSize = "Standard_DS3"
        $hash.sqlVMSize = "Standard_DS3"
        $hash.adVMSize = "Standard_DS1"
    } 
    else
    {
        $hash.StorageAccountType = "Standard_LRS"
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


