$WarningPreference = "SilentlyContinue"

$strResourceGroupName = "rg-mcsecloud01"

$objVirtualMachines = Get-AzureRmVM -ResourceGroupName $strResourceGroupName -Status

foreach ( $objVirtualMachine in $objVirtualMachines )
{
    $strVirtualMachineName = $objVirtualMachine.Name
    $strPowerState = $objVirtualMachine.PowerState
    # Write-Host $strVirtualMachineName $strPowerState

    if ( $strPowerState -eq "VM deallocated" )
    {
        Write-Host "Removing virtual machine $strVirtualMachineName..."
        # Remove-AzureRmVM -ResourceGroupName $strResourceGroupName -Name $strVirtualMachineName
    }
}