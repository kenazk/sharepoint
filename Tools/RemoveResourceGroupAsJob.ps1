﻿switch-azuremode -name AzureResourceManager

$location = "*"
$rgPrefix = "T63*"

$c = get-content C:\daily\2015-9-15\keep.txt

$sb = {
        param($rgname)
        function deleteSharepointDeployments($rgname)
        {
            Remove-AzureResourceGroup -Name $rgname -Force -Verbose 
        }
        deleteSharepointDeployments $rgname
    }

$rg = Get-AzureResourceGroup | where {$_.Location -like $location } | where {$_.ResourceGroupName -like $rgPrefix } | where {$c -notcontains $_.ResourceGroupName}
foreach($g in $rg)
{
    Start-job -Name "job" -ScriptBlock $sb -ArgumentList $g.ResourceGroupName
}

