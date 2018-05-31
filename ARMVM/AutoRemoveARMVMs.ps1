$WarningPreference = "SilentlyContinue"

$strResourceGroupName = "rg-mcsecloud01"

$objVirtualMachines = Get-AzureRmVM -ResourceGroupName $strResourceGroupName -Status

foreach ( $objVirtualMachine in $objVirtualMachines )
{
    $strPowerState = $objVirtualMachine.PowerState
    # Write-Host $strVirtualMachineName $strPowerState

    if ( $strPowerState -eq "VM deallocated" )
    {
        $strVirtualMachineName = $objVirtualMachine.Name
        Write-Host "Removing virtual machine $strVirtualMachineName..."
        # Remove-AzureRmVM -ResourceGroupName $strResourceGroupName -Name $strVirtualMachineName
    }
}