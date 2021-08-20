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

@description('Size of the virtual machine.')
@allowed([
  'Standard_B2s'
  'Standard_B2ms'
])
param vmSize string = 'Standard_B2s'

@description('Location for all resources.')
param location string = resourceGroup().location

@description('Name of the virtual machine. cd-server-nicht-exchange.nennen!wegenISDoof!111elf!!')
param vmName string

var storageAccountName = 'bootdiags${uniqueString(resourceGroup().id)}'
var nicName = '${vmName}-nic01'
// var addressPrefix = '10.0.0.0/16'
// var subnetName = 'Subnet'
// var subnetPrefix = '10.0.0.0/24'
// var virtualNetworkName = 'MyVNET'
// var networkSecurityGroupName = 'default-NSG'

resource stg 'Microsoft.Storage/storageAccounts@2021-04-01' = {
  name: storageAccountName
  location: location
  sku: {
    name: 'Standard_LRS'
  }
  kind: 'Storage'
}

// resource securityGroup 'Microsoft.Network/networkSecurityGroups@2021-02-01' = {
//   name: networkSecurityGroupName
//   location: location
//   properties: {
//     securityRules: [
//       {
//         name: 'default-allow-3389'
//         properties: {
//           priority: 1000
//           access: 'Allow'
//           direction: 'Inbound'
//           destinationPortRange: '3389'
//           protocol: 'Tcp'
//           sourcePortRange: '*'
//           sourceAddressPrefix: '*'
//           destinationAddressPrefix: '*'
//         }
//       }
//     ]
//   }
// }

// resource vn 'Microsoft.Network/virtualNetworks@2021-02-01' = {
//   name: virtualNetworkName
//   location: location
//   properties: {
//     addressSpace: {
//       addressPrefixes: [
//         addressPrefix
//       ]
//     }
//   }
// }

// resource subnet 'Microsoft.Network/virtualNetworks/subnets@2021-02-01' = {
//   parent: vn
//   name: subnetName
//   properties: {
//     addressPrefix: subnetPrefix
//     networkSecurityGroup: {
//       id: securityGroup.id
//     }
//   }
// }

resource nic 'Microsoft.Network/networkInterfaces@2021-02-01' = {
  name: nicName
  location: location
  // properties: {
  //   ipConfigurations: [
  //     {
  //       name: '${vmName}-ipconfig1'
  //       properties: {
  //         privateIPAllocationMethod: 'Dynamic'
  //         // subnet: {
  //         //   id: subnet.id
  //         // }
  //       }
  //     }
  //   ]
  // }
}

resource vm 'Microsoft.Compute/virtualMachines@2021-03-01' = {
  name: vmName
  location: location
  properties: {
    hardwareProfile: {
      vmSize: vmSize
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
    // networkProfile: {
    //   networkInterfaces: [
    //     {
    //       id: nic.id
    //     }
    //   ]
    // }
    diagnosticsProfile: {
      bootDiagnostics: {
        enabled: true
        storageUri: stg.properties.primaryEndpoints.blob
      }
    }
  }
}

// output hostname string = pip.properties.dnsSettings.fqdn
output storageName string = stg.name
