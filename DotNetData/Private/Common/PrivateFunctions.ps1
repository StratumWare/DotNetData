<# DotNetData/Private/Common/PrivateFunctions.ps1

   System Configuration File Location: C:\ProgramData\DotNetData\
   User Configuration File Location:   $($env:USERPROFILE)\AppData\Local\DotNetData\
   Configuration File Name:            DotNetData_config.json

#>

[String] $Script:ConfigDirName = 'DotNetData'
[String] $Script:ConfigFileNamePrefix = 'DotNetData_'
[String] $Script:ConfigFileNameSuffix = '_config.json'

[Collections.Generic.Dictionary[String, Object]] $Script:Configuration = New-Object -TypeName 'Collections.Generic.Dictionary[String, Object]'


function Write-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $SystemOrUser,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $DBMS,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $Edition,
      [Parameter(Position = 3, Mandatory = $true, ValueFromPipeline = $true)]
      [Object] $InputObject
   )

   [String] $userAppDataDirPath = [Environment]::GetFolderPath('LocalApplicationData')
   [String] $userConfigDirPath = Join-Path -Path $userAppDataDirPath -ChildPath $Script:ConfigDirName
   [String] $userConfigFilePath = Join-Path -Path $userConfigDirPath -ChildPath "${Script:ConfigFileNamePrefix}${Edition}${Script:ConfigFileNameSuffix}"

   [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($SystemOrUser) {
      'System' {
         [String] $appdataDirPath = [Environment]::GetFolderPath('CommonApplicationData')
         [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath $Script:ConfigDirName
         [String] $configFilePath = Join-Path -Path $configDirPath -ChildPath "${Script:ConfigFileNamePrefix}${Edition}${Script:ConfigFileNameSuffix}"
         [Boolean] $checkForUserConfig = $true
      }
      'User' {
         [String] $configDirPath = $userConfigDirPath
         [String] $configFilePath = $userConfigFilePath
         [Boolean] $checkForUserConfig = $false
      }
      default {
      # Error Message with location in this module
         [String[]] $msgs = , "Unrecognized SystemOrUser '${SystemOrUser}'"
         [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
         [String] $activity = "switch ('${SystemOrUser}')"
         Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
      }
   }

   if ( Test-Path -LiteralPath $configFilePath ) {
      [Object[]] $configJSON = Get-Content -Path $configFilePath
      [Object] $config = $configJSON | ConvertFrom-Json
   }
   else {

   # Make sure directory exists

      if ( -not ( Test-Path -LiteralPath $configDirPath -PathType 'Container' ) ) {
         [IO.DirectoryInfo] $dir = New-Item -Path $configDirPath -ItemType 'Directory'
      }

   # Initialize configuration

      [Object] $config = New-Object -TypeName 'PSObject'

   }
   [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
   if ($member -eq $null) {
      Add-Member -InputObject $config -MemberType 'NoteProperty' -Name $DBMS -Value $InputObject
   }
   else {
      $config.$DBMS = $InputObject
   }

   $config | ConvertTo-Json | Out-File $configFilePath -Encoding UTF8
   Write-Warning -Message "Wrote configuration file '${configFilePath}'"

<# Same DBMS in User configuration file overrides entire DBMS in System configuration file #>

   if ($checkForUserConfig) {
      if ( Test-Path -LiteralPath $userConfigFilePath ) {
         [Object[]] $userConfigJSON = Get-Content -Path $userConfigFilePath
         [Object] $userConfig = $userConfigJSON | ConvertFrom-Json
         [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $userConfig -Name $DBMS
         if ($member -ne $null) {
            Write-Warning -Message "User configuration for ${DBMS} also exists; will override System configuration"
         }
      }
   }

}


function Get-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $DBMS
   )

   [Boolean] $missingConfig = $true

# User-specific configuration file

   [String] $appdataDirPath = [Environment]::GetFolderPath('LocalApplicationData')
   [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath $Script:ConfigDirName
   [String] $userConfigFilePath = Join-Path -Path $configDirPath -ChildPath "${Script:ConfigFileNamePrefix}${PSEdition}${Script:ConfigFileNameSuffix}"
   if ( Test-Path -LiteralPath $userConfigFilePath ) {
      [Object[]] $configJSON = Get-Content -Path $userConfigFilePath
      [Object] $config = $configJSON | ConvertFrom-Json
      [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
      if ($member -ne $null) {
         [Object] $dbmsConfig = $config.$DBMS
         Write-Output -InputObject $dbmsConfig
         $missingConfig = $false
      }
   }

# System-wide configuration file

   if ($missingConfig) {

      [String] $appdataDirPath = [Environment]::GetFolderPath('CommonApplicationData')
      [String] $configDirPath = Join-Path -Path $appdataDirPath -ChildPath $Script:ConfigDirName
      [String] $systemConfigFilePath = Join-Path -Path $configDirPath -ChildPath "${Script:ConfigFileNamePrefix}${PSEdition}${Script:ConfigFileNameSuffix}"
      if ( Test-Path -LiteralPath $systemConfigFilePath ) {
         [Object[]] $configJSON = Get-Content -Path $systemConfigFilePath
         [Object] $config = $configJSON | ConvertFrom-Json
         [Microsoft.PowerShell.Commands.MemberDefinition] $member = Get-Member -InputObject $config -Name $DBMS
         if ($member -ne $null) {
            [Object] $dbmsConfig = $config.$DBMS
            Write-Output -InputObject $dbmsConfig
            $missingConfig = $false
         }
      }

   }

   if ($missingConfig) {
   # Error Message with location of calling statement
      [String[]] $msgs = , "Configuration for ${DBMS} not found. Use 'Set-DotNetDataConfiguration' to create it.", "User configuration file path: ${userConfigFilePath}", "System configuration file path: ${systemConfigFilePath}"
      [Management.Automation.CallStackFrame] $csf = (gcs)[1]
      [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
      [String] $activity = 'Get-DotNetDataConfiguration'
      Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryReason 'Missing configuration' -CategoryActivity $activity -CategoryTargetName "${Script:ConfigFileNamePrefix}${PSEdition}${Script:ConfigFileNameSuffix}" -CategoryTargetType 'Configuration File'
   }

}


function Test-IsTypeLoaded {
    param (
        [string]$FullTypeName
    )

    foreach ($assembly in [AppDomain]::CurrentDomain.GetAssemblies()) {
        try {
            # Look for the type in this assembly
            $type = $assembly.GetTypes() | Where-Object { $_.FullName -eq $FullTypeName }
            if ($type) { return $true }
        }
        catch [System.Reflection.ReflectionTypeLoadException] {
            # Safely check the types that DID successfully load in this assembly
            $type = $_.Exception.Types | Where-Object { $_ -and $_.FullName -eq $FullTypeName }
            if ($type) { return $true }
        }
        catch {
            # Ignore other errors (e.g., dynamic assemblies that don't support GetTypes)
            continue
        }
    }
    return $false
}


function Import-Dll {
   [CmdletBinding(PositionalBinding = $false)]
   Param (
      [Parameter(ParameterSetName = 'UsingAddType')]
      [Switch] $UsingAddType,
      [Parameter(ParameterSetName = 'UsingLoadFrom')]
      [Switch] $UsingLoadFrom,
      [Parameter(ParameterSetName = 'UsingLoadWithPartialName')]
      [Switch] $UsingLoadWithPartialName,
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $DllDirPath,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $DllName
   )

   Begin {
   }

   Process {

      $DllName | % {
         [String] $aDllName = $_

      # Import the DLL

         [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($PSCmdlet.ParameterSetName) {

            'UsingAddType' {

               [string] $dllPath = Join-Path -Path $dllDirPath -ChildPath $aDllName

               if ( Test-Path -LiteralPath $dllPath ) {

               [int] $errorStartIndex = $Global:Error.Count
               [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                  Write-Warning -Message "Loading '${dllPath}' using Add-Type"
                  Add-Type -LiteralPath $dllPath -Verbose
               } # try
               catch [Reflection.ReflectionTypeLoadException] {
                  [Management.Automation.ErrorRecord] $er1 = $_
                  [String[]] $msgs = ('HResult 0x{0:X8}' -f $er1.Exception.HResult), $er1.Exception.GetBaseException(), $er1.Exception.GetBaseException().LoaderExceptions
                  [String] $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)"
                  Write-Warning -Message (@( $msgs; $functionAndScriptLocation; $Global:Error[0..($Global:Error.Count - $errorStartIndex - 1)] ) -join "$([Environment]::NewLine)         ")
                  Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
               }
               catch {
                  [Management.Automation.ErrorRecord] $er1 = $_
                  if ($er1.Exception.HResult -eq 0x80131515) {
                     [String[]] $msgs = , 'HResult 0x80131515 indicates the DLL file has been downloaded from the Internet and is currently blocked.', "In the Properties of the file, please `"Unblock`" the file `"$($aDllName)`"", 'Then close and re-open the PowerShell session - PowerShell 5.1 caches assembly load failures. If you try to run your script in the same session, it ignores the fact that the file is now unblocked and will repeat the same error message.'
                  }
                  elseif ($er1.Exception.HResult -eq 0x80131602) {
                     [String[]] $msgs = $er1.Exception.GetBaseException(), $er1.Exception.GetBaseException().LoaderExceptions
                  }
                  else {
                     [String[]] $msgs = 'HResult 0x{0:X8}' -f $er1.Exception.HResult, $er1.Exception.GetBaseException()
#                     [String[]] $msgs = New-Object -TypeName 'String[]' 0
                  }
                  [String] $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)"
                  Write-Warning -Message (@( $msgs; $functionAndScriptLocation; $Global:Error[0..($Global:Error.Count - $errorStartIndex - 1)] ) -join "$([Environment]::NewLine)         ")
                  Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
               } # catch

               } # if ( Test-Path -LiteralPath $dllPath )
               else { # -not ( Test-Path -LiteralPath $dllPath )
               # Error Message with location of calling statement
                  [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): ${aDllName} not found at '${dllPath}'"
                  [Management.Automation.CallStackFrame] $csf = (gcs)[1]
                  [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                  [String] $activity = 'Set-DotNetDataConfiguration'
                  Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryReason 'File not found' -CategoryActivity $activity -CategoryTargetName $aDllName -CategoryTargetType 'File Path'
               } # else ( -not ( Test-Path -LiteralPath $dllPath ) )

            }

            'UsingLoadFrom' {

               [String] $assemblyName = $aDllName.Replace('.dll', '')

               if (([AppDomain]::CurrentDomain.GetAssemblies() | Select-Object -Property @{ n='ShortName'; e={$_.FullName.Substring(0, $_.FullName.IndexOf(','))} }).ShortName -contains $assemblyName) {
                  Write-Verbose -Message "$($MyInvocation.MyCommand.Name): ${assemblyName} assembly already loaded"
               } # if (already loaded)
               else { # needs loaded
                  $Global:Error.Clear()
                  [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                     [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; if (Test-Path -LiteralPath $aDllName) {
                        Write-Warning -Message "Loading ${aDllName} using LoadFrom"
                        [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; [void] [Reflection.Assembly]::LoadFrom($aDllName)
                        # or [System.Reflection.Assembly]::LoadWithPartialName($assemblyName)
                     }
                     else {
                     # Error Message with location of calling statement
                        [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): ${dllFileName} not found at '${aDllName}' - specify correct path in DllPath parameter or add it to paths being searched"
                        [Management.Automation.CallStackFrame] $csf = (gcs)[1]
                        [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                        [String] $activity = "Loading DLL from '${aDllName}'"
                        Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryReason 'File not found' -CategoryActivity $activity -CategoryTargetName 'DllPath' -CategoryTargetType 'Parameter'
                     }
                  }
                  catch {
                  # ErrorRecord
                     [Management.Automation.ErrorRecord] $er1 = $_
                     [String] $activity = "Calling [Reflection.Assembly]::LoadFrom('${aDllName}')"
                     Write-Error -ErrorRecord $er1 -CategoryActivity $activity -CategoryTargetName $aDllName -CategoryTargetType 'Parameter'
                  }
               } # else (needs loaded)

            } # 'UsingLoadFrom'

            'UsingLoadWithPartialName' {

               [String] $assemblyName = $aDllName.Replace('.dll', '')

               if (([AppDomain]::CurrentDomain.GetAssemblies() | Select-Object -Property @{ n='ShortName'; e={$_.FullName.Substring(0, $_.FullName.IndexOf(','))} }).ShortName -contains $assemblyName) {
                  Write-Verbose -Message "$($MyInvocation.MyCommand.Name): ${assemblyName} assembly already loaded"
               } # if (already loaded)
               else { # needs loaded
                  $Global:Error.Clear()
                  [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                     [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; if (Test-Path -LiteralPath $aDllName) {
                        Write-Warning -Message "Loading ${aDllName} using LoadWithPartialName"
                        [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; [void] [Reflection.Assembly]::LoadWithPartialName($aDllName)
                        # or [System.Reflection.Assembly]::LoadWithPartialName($assemblyName)
                     }
                     else {
                     # Error Message with location of calling statement
                        [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): ${dllFileName} not found at '${aDllName}' - specify correct path in DllPath parameter or add it to paths being searched"
                        [Management.Automation.CallStackFrame] $csf = (gcs)[1]
                        [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                        [String] $activity = "Loading DLL from '${aDllName}'"
                        Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryReason 'File not found' -CategoryActivity $activity -CategoryTargetName 'DllPath' -CategoryTargetType 'Parameter'
                     }
                  }
                  catch {
                  # ErrorRecord
                     [Management.Automation.ErrorRecord] $er1 = $_
                     [String] $activity = "Calling [Reflection.Assembly]::LoadWithPartialName('${aDllName}')"
                     Write-Error -ErrorRecord $er1 -CategoryActivity $activity -CategoryTargetName $aDllName -CategoryTargetType 'Parameter'
                  }
               } # else (needs loaded)

               default {
               # Error Message with location in this module
                  [String[]] $msgs = , "Unrecognized ParameterSetName '$($PSCmdlet.ParameterSetName)'"
                  [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                  [String] $activity = "switch ('$($PSCmdlet.ParameterSetName)')"
                  Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
               }

            } # 'UsingLoadWithPartialName'

         } # switch ($PSCmdlet.ParameterSetName)

      } # % $DllName

   }

   End {
   }

}


function Get-CredentialForUserName {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Management.Automation.PSCredential])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $Server = [NullString]::Value,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [AllowEmptyString()]
      [String] $LogFilePath = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   if ($CallStackFrame -eq $NULL) {
      [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
   }

   [String] $userProfile = $env:USERPROFILE
   if ($userProfile -eq 'C:\Users\Default') {
      [String] $whoami = whoami
      Write-Warning -Message "env:USERPROFILE should not be '$($userProfile)' env:USERNAME='$($env:USERNAME)' whoami = '${whoami}'", 'User''s profile might be missing.', "Start Command Prompt with `"Run as a different user`" using '$($env:USERDOMAIN)\$($env:USERNAME)' and run again while Command Prompt is still open to create the user`s profile."
   }

   [String] $credFilePath = Join-Path -Path $env:USERPROFILE -ChildPath 'Credentials' | Join-Path -ChildPath "${UserName}.creds"
   [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; [Boolean] $exists = Test-Path -LiteralPath $credFilePath -PathType 'Leaf'
   if ($exists) {

      [Collections.Hashtable] $credMap = Import-Clixml -LiteralPath $credFilePath
      [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; if ($credMap.ContainsKey($Server) -and [NullString]::Value, $null -notcontains $credMap[$Server].Password) {
         [object] $obj = $credMap[$Server]
         $csf0 = (gcs)[0]; if ($obj -eq $null) {
            [String[]] $msgs = , "$($MyInvocation.MyCommand.Name): Null value retrieved from password file `"${credFilePath}`" for UserName '${UserName}' Server '${Server}'"
         }
      }
      elseif ($credMap.ContainsKey('') -and [NullString]::Value, $null -notcontains $credMap[''].GetNetworkCredential().Password) {
         [object] $obj = $credMap['']
         $csf0 = (gcs)[0]; if ($obj -eq $null) {
            [String[]] $msgs = , "Null value retrieved from password file `"${credFilePath}`" for default for UserName '${UserName}'"
         }
      }
      else {
         [object] $obj = $null
         if ($Server -eq $null) {
            [String[]] $msgs = , "For user '${UserName}' credentials, Server not specified and no default exists."
         }
         else {
            [String[]] $msgs = , "For user '${UserName}', no credentials found for Server '${Server}' and no default fallback exists."
         }
      }

      if ($obj -eq $null) {
      # Error Message with location of calling statement
         [string[]] $functionAndScriptLocation = @(
            "in $($csf0.FunctionName) at $($csf0.ScriptName): $($csf0.ScriptLineNumber)"
            "in $($CallStackFrame.FunctionName) at $($CallStackFrame.ScriptName): $($CallStackFrame.ScriptLineNumber)"
         )
         Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::InvalidArgument) -CategoryReason 'Null password' -CategoryActivity $($MyInvocation.MyCommand.Name) -CategoryTargetName $credFilePath -CategoryTargetType 'Password File'
      }
      elseif ($obj.psobject.Properties.Name -contains 'Credential') {
         Write-Output -InputObject $obj.Credential # [Management.Automation.PSCredential]
      }
      else {
      # Error Message with location of calling statement
         [string[]] $msgs = @(
            "For user '${UserName}', 'Credentials' node is missing for Server '${Server}'."
            "in $($csf0.FunctionName) at $($csf0.ScriptName): $($csf0.ScriptLineNumber)"
            "in $($CallStackFrame.FunctionName) at $($CallStackFrame.ScriptName): $($CallStackFrame.ScriptLineNumber)"
         )
         Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::InvalidArgument) -CategoryReason 'Null password' -CategoryActivity $($MyInvocation.MyCommand.Name) -CategoryTargetName $credFilePath -CategoryTargetType 'Password File'
         Write-Warning -Message 'Properties of [Management.Automation.PSCredential] object:'
         $obj.psobject.Properties.Name | % {
            Write-Warning -Message "   ${_}"
         }
      }

   }
   else {
   # Error Message with location of calling statement
      [string[]] $msgs = @(
         "$($MyInvocation.MyCommand.Name): Missing password file `"${credFilePath}`""
         "in $($csf0.FunctionName) at $($csf0.ScriptName): $($csf0.ScriptLineNumber)"
         "in $($CallStackFrame.FunctionName) at $($CallStackFrame.ScriptName): $($CallStackFrame.ScriptLineNumber)"
      )
      [String] $activity = 'Get-CredentialForUserName'
      Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ObjectNotFound) -CategoryReason 'Missing password file' -CategoryActivity $activity -CategoryTargetName $credFilePath -CategoryTargetType 'Password File'
   }

}
