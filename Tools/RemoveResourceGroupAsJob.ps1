select-AzureSubscription -subscriptionid 85182b66-6daa-40c6-bfa8-42dcc6d6845e


switch-azuremode -name AzureResourceManager

$location = "*"
$rgPrefix = "NHA*"

$c = get-content C:\daily\2015-8-28\rgs.txt

$sb = {
        param($rgname)
        function deleteSharepointDeployments($rgname)
        {
            Remove-AzureResourceGroup -Name $rgname -Force -Verbose 
        }
        deleteSharepointDeployments $rgname
    }

$rg = Get-AzureResourceGroup | where {$_.Location -like $location } | where {$_.ResourceGroupName -like $rgPrefix } #| where {$c -notcontains $_.ResourceGroupName}
foreach($g in $rg)
{
    Start-job -Name "job" -ScriptBlock $sb -ArgumentList $g.ResourceGroupName
}

