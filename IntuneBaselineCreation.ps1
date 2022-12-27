<#
.NOTES
Filename : IntuneBaselineCreation.ps1
Created by David Just
Date 12/27/2022 9:00 am
.DESCRIPTION
Create baseline policies for a new Intune deployment using the Microsoft Graph PowerShell SDK
#>
$ErrorActionPreference = 'Stop' #Set error action to stop script execution upon error
# Connect to graph using APP authentication. Requires global admin privelages. 
$Scopes = @(
    'Directory.ReadWrite.All'
    'DeviceManagementConfiguration.ReadWrite.All'
    'DeviceManagementApps.ReadWrite.All'
)
Connect-MGGraph -Scopes $Scopes -UseDeviceAuthentication -ForceRefresh
$TenantID = (Get-MGContext).TenantId
$ConfigProfileURI = 'https://graph.microsoft.com/beta/deviceManagement/deviceConfigurations'
$AdminTemplateURI = 'https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations'
# Bitlocker Baseline
$EndpointProtectionJSON = @'
{
    "id": "00000000-0000-0000-0000-000000000000",
    "displayName": "Bitlocker Settings",
    "roleScopeTagIds": [
      "0"
    ],
    "@odata.type": "#microsoft.graph.windows10EndpointProtectionConfiguration",
    "applicationGuardEnabledOptions": "notConfigured",
    "firewallCertificateRevocationListCheckMethod": "deviceDefault",
    "firewallPacketQueueingMethod": "deviceDefault",
    "deviceGuardLocalSystemAuthorityCredentialGuardSettings": "notConfigured",
    "defenderSecurityCenterNotificationsFromApp": "notConfigured",
    "windowsDefenderTamperProtection": "notConfigured",
    "defenderSecurityCenterITContactDisplay": "notConfigured",
    "xboxServicesAccessoryManagementServiceStartupMode": "manual",
    "xboxServicesLiveAuthManagerServiceStartupMode": "manual",
    "xboxServicesLiveGameSaveServiceStartupMode": "manual",
    "xboxServicesLiveNetworkingServiceStartupMode": "manual",
    "applicationGuardBlockClipboardSharing": "notConfigured",
    "defenderPreventCredentialStealingType": "notConfigured",
    "defenderAdobeReaderLaunchChildProcess": "notConfigured",
    "defenderOfficeCommunicationAppsLaunchChildProcess": "notConfigured",
    "defenderAdvancedRansomewareProtectionType": "notConfigured",
    "defenderNetworkProtectionType": "notConfigured",
    "localSecurityOptionsFormatAndEjectOfRemovableMediaAllowedUser": "notConfigured",
    "localSecurityOptionsSmartCardRemovalBehavior": "noAction",
    "localSecurityOptionsInformationDisplayedOnLockScreen": "notConfigured",
    "localSecurityOptionsMinimumSessionSecurityForNtlmSspBasedClients": "none",
    "localSecurityOptionsMinimumSessionSecurityForNtlmSspBasedServers": "none",
    "lanManagerAuthenticationLevel": "lmAndNltm",
    "localSecurityOptionsAdministratorElevationPromptBehavior": "notConfigured",
    "localSecurityOptionsStandardUserElevationPromptBehavior": "notConfigured",
    "userRightsAccessCredentialManagerAsTrustedCaller": null,
    "userRightsLocalLogOn": null,
    "userRightsAllowAccessFromNetwork": null,
    "userRightsActAsPartOfTheOperatingSystem": null,
    "userRightsBackupData": null,
    "userRightsChangeSystemTime": null,
    "userRightsCreateGlobalObjects": null,
    "userRightsCreatePageFile": null,
    "userRightsCreatePermanentSharedObjects": null,
    "userRightsCreateSymbolicLinks": null,
    "userRightsCreateToken": null,
    "userRightsDebugPrograms": null,
    "userRightsBlockAccessFromNetwork": null,
    "userRightsDenyLocalLogOn": null,
    "userRightsRemoteDesktopServicesLogOn": null,
    "userRightsDelegation": null,
    "userRightsGenerateSecurityAudits": null,
    "userRightsImpersonateClient": null,
    "userRightsIncreaseSchedulingPriority": null,
    "userRightsLoadUnloadDrivers": null,
    "userRightsLockMemory": null,
    "userRightsManageAuditingAndSecurityLogs": null,
    "userRightsManageVolumes": null,
    "userRightsModifyFirmwareEnvironment": null,
    "userRightsModifyObjectLabels": null,
    "userRightsProfileSingleProcess": null,
    "userRightsRemoteShutdown": null,
    "userRightsRestoreData": null,
    "userRightsTakeOwnership": null,
    "bitLockerRecoveryPasswordRotation": "enabledForAzureAd",
    "bitLockerPrebootRecoveryMsgURLOption": "default",
    "bitLockerEncryptDevice": true,
    "bitLockerDisableWarningForOtherDiskEncryption": true,
    "bitLockerAllowStandardUserEncryption": true,
    "bitLockerSyntheticSystemDrivePolicybitLockerDriveRecovery": true,
    "bitLockerSyntheticFixedDrivePolicybitLockerDriveRecovery": true,
    "applicationGuardAllowPrintToPDF": false,
    "applicationGuardAllowPrintToXPS": false,
    "applicationGuardAllowPrintToLocalPrinters": false,
    "applicationGuardAllowPrintToNetworkPrinters": false,
    "bitLockerFixedDrivePolicy": {
      "requireEncryptionForWriteAccess": false,
      "recoveryOptions": {
        "recoveryPasswordUsage": "allowed",
        "recoveryKeyUsage": "allowed",
        "enableRecoveryInformationSaveToStore": true,
        "recoveryInformationToStore": "passwordAndKey",
        "enableBitLockerAfterRecoveryInformationToStore": true
      },
      "encryptionMethod": "xtsAes256"
    },
    "bitLockerRemovableDrivePolicy": {
      "requireEncryptionForWriteAccess": false,
      "encryptionMethod": "xtsAes256"
    },
    "bitLockerSystemDrivePolicy": {
      "startupAuthenticationRequired": true,
      "startupAuthenticationTpmUsage": "allowed",
      "startupAuthenticationTpmPinUsage": "allowed",
      "startupAuthenticationTpmKeyUsage": "allowed",
      "startupAuthenticationTpmPinAndKeyUsage": "allowed",
      "startupAuthenticationBlockWithoutTpmChip": true,
      "minimumPinLength": 4,
      "recoveryOptions": {
        "recoveryPasswordUsage": "allowed",
        "recoveryKeyUsage": "allowed",
        "enableRecoveryInformationSaveToStore": true,
        "recoveryInformationToStore": "passwordAndKey",
        "enableBitLockerAfterRecoveryInformationToStore": true
      },
      "prebootRecoveryEnableMessageAndUrl": true,
      "prebootRecoveryMessage": null,
      "prebootRecoveryUrl": null,
      "encryptionMethod": "xtsAes256"
    },
    "firewallProfileDomain": null,
    "firewallProfilePrivate": null,
    "firewallProfilePublic": null,
    "deviceGuardEnableVirtualizationBasedSecurity": false,
    "deviceGuardEnableSecureBootWithDMA": false
  }
'@

$OneDriveKFM = @"
{
    "description": "OneDrive Autoconfig Settings. Policy Created using PowerShell Script",
    "displayName": "OneDrive Settings",
    "roleScopeTagIds": [
      "0"
    ]
  }
"@
$OneDriveKFMSettings = @"
{
    "added": [
      {
        "enabled": true,
        "presentationValues": [],
        "definition@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('81c07ba0-7512-402d-b1f6-00856975cfab')"
      },
      {
        "enabled": true,
        "presentationValues": [
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueText",
            "value": "$TenantID",
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')/presentations('9b39fd82-23c9-48f0-9fbd-9bcbee7380d7')"
          },
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueText",
            "value": "0",
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')/presentations('5f0ec54d-0abf-4559-8e5a-624e5a21e52d')"
          },
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueBoolean",
            "value": true,
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')/presentations('948a1d59-8746-4859-82b1-46b16d6dd0d3')"
          },
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueBoolean",
            "value": true,
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')/presentations('ec6c4518-1a67-4124-aa92-5e4a64d77aed')"
          },
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueBoolean",
            "value": true,
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')/presentations('9345dfaf-8259-42cf-bf02-e56905ee50f1')"
          }
        ],
        "definition@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('4875d227-e4c3-4bf3-a1e2-a7f41591fdb8')"
      },
      {
        "enabled": true,
        "presentationValues": [
          {
            "@odata.type": "#microsoft.graph.groupPolicyPresentationValueList",
            "values": [
              {
                "name": "\"*.pst\""
              }
            ],
            "presentation@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('29814681-ac59-4920-b4a9-07b380e5b530')/presentations('adc8f759-4405-417a-a8d9-2a4ea6df2e1d')"
          }
        ],
        "definition@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('29814681-ac59-4920-b4a9-07b380e5b530')"
      },
      {
        "enabled": true,
        "presentationValues": [],
        "definition@odata.bind": "https://graph.microsoft.com/beta/deviceManagement/groupPolicyDefinitions('2ce2f507-aae8-49a1-98ce-dc3faafcd331')"
      }
    ],
    "updated": [],
    "deletedIds": []
  }
"@
Write-Host "Creating OneDrive Config Policy" -ForegroundColor Green
$OneDrivePolicyInitialize = Invoke-MGGraphRequest -uri $AdminTemplateURI -Body $OneDriveKFM -Method POST
$ODPolicyID = $OneDrivePolicyInitialize.id
$OneDriveSettingsUpdate = Invoke-MgGraphRequest -uri "https://graph.microsoft.com/beta/deviceManagement/groupPolicyConfigurations('$ODPolicyID')/updateDefinitionValues" -Method POST -Body $OneDriveKFMSettings
Write-Host "Creating Bitlocker Policy" -ForegroundColor Green
$BitlockerCreation = Invoke-MgGraphRequest -URI $ConfigProfileURI -Method POST -Body $EndpointProtectionJSON
