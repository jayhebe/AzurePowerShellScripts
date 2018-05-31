
$WarningPreference = "silentlyContinue"
Function Read-Choice
{
    PARAM([string]$strPromptMsg, [string[]]$arrStrChoices)

    $intOrderNum = 0
    $intOrderLength = $arrStrChoices.Length - 1
    foreach ( $strChoice in $arrStrChoices )
    {
        Write-Host "[$intOrderNum] --- $strChoice"
        $intOrderNum++
    }
    $intChoiceIndex = Read-Host $strPromptMsg
    while ( $intChoiceIndex -notin 0..$intOrderLength )
    {
        $intChoiceIndex = Read-Host $strPromptMsg
    }

    return $intChoiceIndex
}

Function Write-LogMsg
{
    PARAM([string]$strLogMsg)

    $strDateTime = Get-Date -Format "yyyy-MM-dd HH:mm:ss "
    Write-Host $strDateTime $strLogMsg -foregroundcolor "Yellow"
}

Function Get-CSVFile
{
    PARAM([string]$strCSVFilePath)

    $objCSVFile = Import-Csv -Path $strCSVFilePath -Delimiter ","

    return $objCSVFile
}


# Choose Resource Group
$arrResourceGroups = @()
$objResourceGroups = Get-AzureRmResourceGroup | Select-Object -Property ResourceGroupName
foreach ( $objResourceGroup in $objResourceGroups )
{
    $arrResourceGroups += ( $objResourceGroup.ResourceGroupName )
}

if ( $arrResourceGroups.Length -eq 0 )
{
    Write-LogMsg -strLogMsg "Do not find any resource group, please create a new one first."
    exit 1
}
else
{
    $intResourceGroupChoiceIndex = Read-Choice -strPromptMsg "Please select which Resource Group you would like to deploy your VMs" -arrStrChoices $arrResourceGroups
    $strResourceGroupName = $arrResourceGroups[$intResourceGroupChoiceIndex]
}


# Choose Location
$arrLocations = @()
$objLocations = Get-AzureRmLocation | Select-Object -Property Location
foreach ( $objLocation in $objLocations )
{
    $arrLocations += ( $objLocation.Location )
}
$intLocationChoiceIndex = Read-Choice -strPromptMsg "Please select which Location you would like to deploy your VMs" -arrStrChoices $arrLocations
$strLocationName = $arrLocations[$intLocationChoiceIndex]

# Choose Network, the ARM Virtual Machine must be placed in the same location with the Virtual Network.
$arrVirtualNetworks = @()
$objVirtualNetworks = Get-AzureRmVirtualNetwork -ResourceGroupName $strResourceGroupName | Where-Object { $_.Location -eq $strLocationName }
foreach ( $objVirtualNetwork in $objVirtualNetworks )
{
    $arrVirtualNetworks += ( $objVirtualNetwork.Name )
}

if ( $arrVirtualNetworks.Length -eq 0 )
{
    Write-LogMsg -strLogMsg "Do not find any virtual network in this location, please create a new one first."
    exit 1
}
else
{
    $intVirtualNetworkIndex = Read-Choice -strPromptMsg "Please select which Virtual Network you would like to deploy your VMs" -arrStrChoices $arrVirtualNetworks
    $strVirtualNetworkName = $arrVirtualNetworks[$intVirtualNetworkIndex]
}

# Choose Subnet
$arrVirtualNetworkSubnets = @()
$objVirtualNetworkSubnets = Get-AzureRmVirtualNetworkSubnetConfig -VirtualNetwork (Get-AzureRmVirtualNetwork -ResourceGroupName $strResourceGroupName | Where-Object { ( $_.Location -eq $strLocationName ) -and ( $_.Name -eq $strVirtualNetworkName ) })
foreach ( $objVirtualNetworkSubnet in $objVirtualNetworkSubnets )
{
    $arrVirtualNetworkSubnets += ( $objVirtualNetworkSubnet.Name )
}

if ( $arrVirtualNetworkSubnets.Length -eq 0 )
{
    Write-LogMsg -strLogMsg "Do not find any subnet in this virtual network, please create a new one first."
    exit 1
}
else
{
    $intVirtualNetworkSubnetIndex = Read-Choice -strPromptMsg "Please select which subnet you would like to deploy your VMs" -arrStrChoices $arrVirtualNetworkSubnets
    $strVirtualNetworkSubnetName = $arrVirtualNetworkSubnets[$intVirtualNetworkSubnetIndex]
}

# Choose VM Size
$arrVirtualMachineSizes = @()
$objVirtualMachineSizes = Get-AzureRmVMSize -Location $strLocationName | Select-Object -Property Name
foreach ( $objVirtualMachineSize in $objVirtualMachineSizes )
{
    $arrVirtualMachineSizes += ( $objVirtualMachineSize.Name )
}
$intVirtualMachineSizeIndex = Read-Choice -strPromptMsg "Please select a VM size" -arrStrChoices $arrVirtualMachineSizes
$strVirtualMachineSizeName = $arrVirtualMachineSizes[$intVirtualMachineSizeIndex]

$strUsername = Read-host "Please enter an administrator user name"
$strPasswordInput = Read-Host -AsSecureString "Please enter the administrator password"
$strConfirmPasswordInput = Read-Host -AsSecureString "Please confirm the administrator password"
$strPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strPasswordInput))
$strConfirmPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strConfirmPasswordInput))

while ( $strPassword -ne $strConfirmPassword )
{
    Write-LogMsg -strLogMsg "The password doesn't match, please enter again."

    $strPasswordInput = Read-Host -AsSecureString "Please enter the administrator password"
    $strConfirmPasswordInput = Read-Host -AsSecureString "Please confirm the administrator password"
    $strPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strPasswordInput))
    $strConfirmPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($strConfirmPasswordInput))
}


$strAnswer = $null
while ( $strAnswer -notin ("Y", "N") )
{
    $strAnswer = Read-Host "You will deploy your VMs with the following profiles, please confirm if they are correct (Y/N):
    Location: $strLocationName
    Resource Group: $strResourceGroupName
    Virtual Network: $strVirtualNetworkName
    Subnet: $strVirtualNetworkSubnetName
    Virtual Machine Size: $strVirtualMachineSizeName
    Administrator User: $strUsername
    "
}

$strARMVMNameListFilePath = ".\AzureRMVMNameList.csv"

if ( $strAnswer -eq "Y" )
{
    $objARMVMNameList = Get-CSVFile -strCSVFilePath $strARMVMNameListFilePath

    foreach ( $objARMVMName in $objARMVMNameList )
    {
        $strARMVMName = $objARMVMName.ARMVMName
        $objARMVMCredential = New-Object System.Management.Automation.PSCredential($strUsername, $strPasswordInput)
        
        New-AzureRmVM -Name $strARMVMName -ResourceGroupName $strResourceGroupName -Location $strLocationName -VirtualNetworkName $strVirtualNetworkName -SubnetName $strVirtualNetworkSubnetName -Size $strVirtualMachineSizeName -Credential $objARMVMCredential
    }
}