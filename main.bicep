@description('Username for the Virtual Machine.')
param adminUsername string

@description('Password for the Virtual Machine.')
@minLength(12)
@secure()
param adminPassword string

@description('The Windows version for the VM. This will pick a fully patched image of this given Windows version.')
@allowed([
  '2019-Datacenter-smalldisk'
])
param OSVersion string = '2019-Datacenter-smalldisk'

@description('Boolean indicating whether the VNet is new or existing')
param virtualNetworkNewOrExisting string

@description('New or Existing VNet Name')
param virtualNetworkName string

@description('VNet address prefix')
param virtualNetworkAddressPrefix string

@description('Resource group of the VNet')
param virtualNetworkResourceGroup string

@description('New or Existing subnet Name')
param subnetName string

@description('Subnet address prefix')
param subnetAddressPrefix string

@description('Size of the virtual machine.')
param virtualMachineSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine.')
param vmName string

var storageAccountName_var = 'bootdiags${uniqueString(resourceGroup().id)}'
var vmName_var = vmName
var nicName_var = '${vmName}-nic01'
var vnetId = {
  new: resourceId('Microsoft.Network/virtualNetworks', virtualNetworkName)
  existing: resourceId(virtualNetworkResourceGroup, 'Microsoft.Network/virtualNetworks', virtualNetworkName)
}
var subnetId_var = '${vnetId[virtualNetworkNewOrExisting]}/subnets/${subnetName}'

resource storageAccountName 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName_var
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

resource nicName 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName_var
  location: location
  properties: {
    ipConfigurations: [
      {
        name: '${vmName}-ipconfig1'
        properties: {
          privateIPAllocationMethod: 'Dynamic'
          subnet: {
            id: subnetId_var
          }
        }
      }
    ]
  }
}

resource vmName_resource 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: virtualMachineSize
    }
    osProfile: {
      computerName: vmName
      adminUsername: adminUsername
      adminPassword: adminPassword
    }
    storageProfile: {
      imageReference: {
        publisher: 'MicrosoftWindowsServer'
        offer: 'WindowsServer'
        sku: OSVersion
        version: 'latest'
      }
      osDisk: {
        createOption: 'FromImage'
        managedDisk: {
          storageAccountType: 'StandardSSD_LRS'
        }
      }
      dataDisks: [
        {
          diskSizeGB: 32
          lun: 0
          createOption: 'Empty'
        }
      ]
    }
    networkProfile: {
      networkInterfaces: [
        {
          id: nicName.id
        }
      ]
    }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: storageAccountName.properties.primaryEndpoints.blob
      }
    }
  }
}

output storageName string = storageAccountName_var
