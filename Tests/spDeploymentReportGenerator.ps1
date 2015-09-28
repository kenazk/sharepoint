Switch-AzureMode -name AzureResourceManager
#Get all AzureResourceGroups 
$groups = Get-AzureResourceGroup | where {$_.ResourceGroupName -like "NHA10*"} | where { $_.Location -like "*" }

$obj = @();
$obj2 = @();

foreach($rg in $groups)
{ 
    # Collect all VMs
    $vms = Get-AzureVM -ResourceGroupName $rg.ResourceGroupName

    # Collect Public IP to RDP
    $publicIp = Get-AzureResource -ResourceGroupName $rg.ResourceGroupName -ApiVersion "2015-06-15" -ResourceType Microsoft.Network/publicIpAddresses -Name "rdpIp"

    foreach($vm in $vms)
    {
        # Collect private IP of VM
        $privateIp = (Get-AzureNetworkInterface -ResourceGroupName $rg.ResourceGroupName -Name $($vm.Name + '-nic')).IpConfigurations.privateIPaddress
        # Get instance view of VM
       
        $vmStatus = Get-AzureVM -ResourceGroupName $rg.ResourceGroupName -Name $vm.Name -Status
        
        foreach($ext in $vmStatus.extensions)
        {
            if($ext.Name -notlike "EnableDnscLient*")
            {
                $ob = New-Object -TypeName PSObject
		        $ob | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $rg.ResourceGroupName -Force
		        $ob | Add-Member -MemberType NoteProperty -Name VMName -Value $vm.Name -Force
		        $ob | Add-Member -MemberType NoteProperty -Name VmProvisioningState -Value $vm.ProvisioningState -Force
                $ob | Add-Member -MemberType NoteProperty -Name ExtensionName -Value $ext.name -Force
                $ob | Add-Member -MemberType NoteProperty -Name ExtensionStatus -Value $ext.statuses.code -Force
                $ob | Add-Member -MemberType NoteProperty -Name ExtensionMessage -Value $ext.statuses.message -Force
                $ob | Add-Member -MemberType NoteProperty -Name RdpIP -Value $publicIP.Properties.ipAddress -Force
                $ob | Add-Member -MemberType NoteProperty -Name PrivateIp -value $privateIp -Force
		        $obj += $ob
            }
        }            
    }

    # Injecting a blank
    $ob = New-Object -TypeName PSObject
	$ob | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $null -Force
	$ob | Add-Member -MemberType NoteProperty -Name VMName -Value $null -Force
	$ob | Add-Member -MemberType NoteProperty -Name VmProvisioningState -Value $null -Force
    $ob | Add-Member -MemberType NoteProperty -Name ExtensionName -Value $null -Force
    $ob | Add-Member -MemberType NoteProperty -Name ExtensionStatus -Value $null -Force
    $ob | Add-Member -MemberType NoteProperty -Name ExtensionMessage -Value $null -Force
    $ob | Add-Member -MemberType NoteProperty -Name RdpIP -Value $null -Force
    $ob | Add-Member -MemberType NoteProperty -Name PrivateIp -value $null -Force
	$obj += $ob

    #Write-Progress -Activity "Generating deployment report for $($rg.ResourceGroupName)"
    # Generate report for Deployments
    $deployments = Get-AzureResourceGroupDeployment -ResourceGroupName $rg.ResourceGroupName
    $deployments | ft
    #foreach($dep in $deployments)
    #{
    #    Write-Progress -Activity "Generating deployment report for $($rg.ResourceGroupName)" -Status "Working on $($dep.DeploymentName)"
    #    $obk = New-Object -TypeName PSObject
    #    $obk | Add-Member -MemberType NoteProperty -Name ResourceGroupName -Value $dep.ResourceGroupName -Force
    #    $obk | Add-Member -MemberType NoteProperty -Name DeploymentName -Value $dep.DeploymentName -Force
    #    $obk | Add-Member -MemberType NoteProperty -Name ProvisioningState -Value $dep.ProvisioningState -Force
    #    $obk | Add-Member -MemberType NoteProperty -Name Timestamp -Value $dep.Timestamp -Force
    #    $obj2 += $obk
    #}

} 


$obj | ft

# Output to CSV 
#$d = get-date
#$folder = "C:\daily\" + $d.Year + '-' + $d.Month + '-' + $d.Day 
#$dsuffix = "" + $d.hour + $d.minute + $d.Second
#$file = '\rgOutput-' + $dsuffix + '-VMs.csv'
#$file2 = '\rgOutput-' + $dsuffix + '-deployments.csv'

#New-Item -ItemType Directory -Force -Path $folder

#$obj | export-csv -Path $($folder+$file)
#$obj2 | export-csv -Path $($folder+$file2)

#write-host "Completed"
   

