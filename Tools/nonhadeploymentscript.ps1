Select-AzureSubscription -SubscriptionId 85182b66-6daa-40c6-bfa8-42dcc6d6845e -Current

Switch-AzureMode -name AzureResourceManager

#######################################
###         NONHA SHAREPOINT        ###
#######################################

# Count of runs
$count = 3

# Variables
$templateFile = "C:\Users\kenazk\Desktop\GitHub\azure-quickstart-templates\sharepoint-three-vm\azuredeploy.json"
$paramsFile = "C:\Users\kenazk\Desktop\GitHub\sharepoint\nonha\azuredeploy.parameters.json"
$params = Get-content $paramsFile | convertfrom-json
$location = "southeastasia"
$rgprefix = "NHAF"
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
    $hash.spDNSPrefix = "nha" + $dsuffix
    $hash.storageAccountName = "storage" + $dsuffix
    $hash.location = $location

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

    $hash | ft
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


