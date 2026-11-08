<# DotNetData/Public/Common/PublicFunctions.ps1
#>


<# ErrorRecord

   Write-Warning -Message "Type:                  $($ErrorRecord.GetType().FullName)"
   Write-Warning -Message "ToString():            $($ErrorRecord.ToString())"
   if ($ErrorRecord.ErrorDetails -ne $null) {
      Write-Warning -Message "ErrorDetails:          $($ErrorRecord.ErrorDetails)"
   }
   Write-Warning -Message "Exception:             $($ErrorRecord.Exception)"
   Write-Warning -Message "FullyQualifiedErrorId: $($ErrorRecord.FullyQualifiedErrorId)"
   if ($ErrorRecord.PipelineIterationInfo -ne $null) {
      Write-Warning -Message "PipelineIterationInfo: $($ErrorRecord.PipelineIterationInfo)"
   }
   Write-Warning -Message "ScriptStackTrace:      $($ErrorRecord.ScriptStackTrace)"
   if ($ErrorRecord.TargetObject -ne $null) {
      Write-Warning -Message "TargetObject:          $($ErrorRecord.TargetObject)"
   }

# InvocationInfo

   Write-Warning -Message 'InvocationInfo:'
   Write-Warning -Message "   BoundParameters:       $($ErrorRecord.InvocationInfo.BoundParameters)"
   Write-Warning -Message "   CommandOrigin:         $($ErrorRecord.InvocationInfo.CommandOrigin)"
   Write-Warning -Message "   DisplayScriptPosition: $($ErrorRecord.InvocationInfo.DisplayScriptPosition)"
   Write-Warning -Message "   ExpectingInput:        $($ErrorRecord.InvocationInfo.ExpectingInput)"
   Write-Warning -Message "   HistoryId:             $($ErrorRecord.InvocationInfo.HistoryId)"
   Write-Warning -Message "   InvocationName:        $($ErrorRecord.InvocationInfo.InvocationName)"
   Write-Warning -Message "   Line:                  $($ErrorRecord.InvocationInfo.Line)"
   Write-Warning -Message "   MyCommand:             $($ErrorRecord.InvocationInfo.MyCommand)"
   Write-Warning -Message "   MyCommand.Name:        $($ErrorRecord.InvocationInfo.MyCommand.Name)"
   Write-Warning -Message "   OffsetInLine:          $($ErrorRecord.InvocationInfo.OffsetInLine)"
   Write-Warning -Message "   PipelineLength:        $($ErrorRecord.InvocationInfo.PipelineLength)"
   Write-Warning -Message "   PipelinePosition:      $($ErrorRecord.InvocationInfo.PipelinePosition)"
   Write-Warning -Message "   PositionMessage:       $($ErrorRecord.InvocationInfo.PositionMessage)"
   Write-Warning -Message "   PSCommandPath:         $($ErrorRecord.InvocationInfo.PSCommandPath)"
   Write-Warning -Message "   PSScriptRoot:          $($ErrorRecord.InvocationInfo.PSScriptRoot)"
   Write-Warning -Message "   ScriptLineNumber:      $($ErrorRecord.InvocationInfo.ScriptLineNumber)"
   Write-Warning -Message "   ScriptName:            $($ErrorRecord.InvocationInfo.ScriptName)"
   Write-Warning -Message "   UnboundArguments:      $($ErrorRecord.InvocationInfo.UnboundArguments)"
#>


<#
function Write-ErrorRecord {
   [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName='AsWarning')]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(ParameterSetName = 'AsWarning', Mandatory = $false, ValueFromPipeline = $false)]
      [Switch] $AsWarning,
#      [Parameter(ParameterSetName = 'AsOther', Mandatory = $true, ValueFromPipeline = $false)]
#      [Switch] $AsOther,
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Management.Automation.ErrorRecord] $ErrorRecord,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [string] $Message
   )

   [Management.Automation.CallStackFrame] $csf = (gcs)[0]; if ($PSCmdlet.ParameterSetName -eq 'AsWarning') {
      Write-Warning -Message ($ErrorRecord.ToString(), $ErrorRecord.InvocationInfo.PositionMessage -join "$([Environment]::NewLine)         ")
   }
   else {
   # Warning Message with location in this module
      [string[]] $msgs = , '$($MyInvocation.MyCommand.Name): Parameter set not recognized in DotNetData module, PublicFunctions.ps1, Write-ErrorRecord'
      [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
      Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
   }

}
#>

<# Find the absolute path of a specific DLL file

Define objects with pairs of parameters

(
   New-Object -TypeName 'PSObject' -Property @{
      PackageName = ...
      DllName = ...
   }
) | Get-PackageDll
#>
function Get-PackageDll {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([string[]])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [string[]] $PackageName,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipelineByPropertyName = $true)]
      [string[]] $DllName
   )

   Begin {
      [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($PSEdition) {
         'Core' {
         # NuGet global-packages path (dotnet nuget locals global-packages --list)
            [string] $nugetBasePath = Join-Path $env:USERPROFILE -ChildPath '.nuget' | Join-Path -ChildPath 'packages'
         }
         'Desktop' {
            [string] $nugetBasePath = Join-Path $env:ProgramFiles -ChildPath 'PackageManagement' | Join-Path -ChildPath 'NuGet' | Join-Path -ChildPath 'Packages'
         }
         default {
         # Error Message with location in this module
            [string[]] $msgs = , "Unrecognized PSEdition '${PSEdition}'"
            [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            [string] $activity = "switch ('${PSEdition}')"
            Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         }
      }
   }

   Process {
      for ($i = 0; $i -lt $PackageName.Count; $i++) {
         [string] $aPackageName = $PackageName[$i]
         [string] $aDllName = $DllName[$i]
#         [string] $packageDirPath = Join-Path -Path $nugetBasePath -ChildPath $aPackageName
         [string] $packageDirPath = $nugetBasePath
#         Write-Warning -Message "Searching '${packageDirPath}' for '${aDllName}'"
         [IO.FileInfo[]] $file = Get-ChildItem -Path $packageDirPath -Filter $aDllName -Recurse
         [IO.FileInfo] $file1 = $null
         $file | % {
            [IO.FileInfo] $f = $_
 # Desktop / Legacy
 # TO DO: Core
            if ($f.Directory.Name -eq 'netstandard2.0') {
               $file1 = $f
            }
         } # % $file
         if (-not $file1) { 
            throw "Required dependency package '${aPackageName}' is missing. Run `"Install-Package`" first." 
         }
         Write-Output -InputObject $file1.FullName
      } # for ($i = 0; $i -lt $PackageName.Count; $i++) {
   } # Process

   End {
   }

}


function Set-DotNetDataConfiguration {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(ParameterSetName = 'System', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $System,
      [Parameter(ParameterSetName = 'User', Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $User,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [ValidateSet( 'MySQL', 'Oracle', 'PostgreSQL', 'Redshift', 'SQLite' )]
      [string] $DBMS,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateSet( 'Desktop', 'Core' )]
      [string] $Edition
   )
   DynamicParam {

      [Management.Automation.RuntimeDefinedParameterDictionary] $paramDict = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameterDictionary'
      [Collections.ObjectModel.Collection[System.Attribute]] $attribCollection = New-Object -TypeName 'Collections.ObjectModel.Collection[System.Attribute]'

      [Collections.Generic.Dictionary[[string], [Type]]] $paramNameTypeDict = New-Object -TypeName 'Collections.Generic.Dictionary[[string], [Type]]'

      [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($DBMS) {

         'MySQL' {
            $paramNameTypeDict['DllPath'] = [string[]]
         }

         'Oracle' {
            $paramNameTypeDict['DllPath'] = [string[]]
         }

         'PostgreSQL' {
            $paramNameTypeDict['DllPath'] = [string[]]
         }

         'SQLite' {
            $paramNameTypeDict['DllPath'] = [string[]]
         }

# IMPL: Using $msgs1, $functionAndScriptLocation1, $activity1 due to: Cannot overwrite variable msgs because the variable has been optimized.
         default {
         # Error Message with location in this module
            [string[]] $msgs1 = , "$($MyInvocation.MyCommand.Name): Unrecognized DBMS '${DBMS}'"
            [string] $functionAndScriptLocation1 = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            [string] $activity1 = "switch ('${DBMS}')"
            Write-Error -Message (@( $msgs1; $functionAndScriptLocation1 ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity1 -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         }

      } # switch ($DBMS)

      $paramNameTypeDict.Keys | % {
         [string] $paramName = $_
         [Type] $paramType = $paramNameTypeDict[$paramName]
         $attribCollection.Clear()
         [Management.Automation.ParameterAttribute] $attrib = New-Object -TypeName 'Management.Automation.ParameterAttribute'
         $attrib.ParameterSetName = '__AllParameterSets'
         $attrib.Mandatory = $true
         $attribCollection.Add($attrib)
         [Management.Automation.RuntimeDefinedParameter] $param = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameter' ($paramName, $paramType, $attribCollection)
         $paramDict.Add($paramName, $param)
      }

      return $paramDict
   } # DynamicParam

   Begin {

      [string[]] $msgs = [string[]]::new(0)
      [string] $functionAndScriptLocation = [NullString]::Value
      [string] $activity = [NullString]::Value

   }

   Process {

      [Boolean] $ok = $true

      [Boolean] $hasDllPath = $false

      [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($DBMS) {

         'MySQL' {
            $hasDllPath = $true
         }

         'Oracle' {
            $hasDllPath = $true
         }

         'PostgreSQL' {
            $hasDllPath = $true
         }

         'SQLite' {
            $hasDllPath = $true
         }

         default {
         # Error Message with location in this module
            [string[]] $msgs = , "$($MyInvocation.MyCommand.Name): Unrecognized DBMS '${DBMS}'"
            [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            [string] $activity = "switch ('${DBMS}')"
            Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         }

      } # switch ($DBMS)

      if ($hasDllPath) {
         [string[]] $DllPath = $PSBoundParameters['DllPath']
         $DllPath | % {
            [string] $aDllPath = $_

            if ( -not ( Test-Path -LiteralPath $aDllPath ) ) {
            # Error Message with location of calling statement
               $msgs = , "File '${aDllPath}' not found."
               [Management.Automation.CallStackFrame] $csf = (gcs)[1]
               $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
               $activity = 'Set-DotNetDataConfiguration'
               Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -CategoryReason 'File not found' -CategoryActivity $activity -CategoryTargetName $aDllPath -CategoryTargetType 'File Path'
               $ok = $false
            }

         } # % $DllPath

         [Object] $obj = New-Object -TypeName 'PSObject' -Property @{
            DllPath = $DllPath
         }

      } # if ($hasDllPath)

      if ($ok) {
         if ($Edition) {
            [string] $configEdition = $Edition
         }
         else {
            [string] $configEdition = $PSEdition
         }
         Write-DotNetDataConfiguration -SystemOrUser $PSCmdlet.ParameterSetName -DBMS $DBMS -Edition $configEdition -InputObject $obj
      }

   }

   End {
   }

}


<#
#>

function Set-DatabaseCredentials {
   [CmdletBinding(PositionalBinding = $false)]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $false)]
      [string] $Username,
      [Parameter(ParameterSetName = 'AddServer', Mandatory = $false, ValueFromPipeline = $true)]
      [string[]] $Server = [NullString]::Value,
      [Parameter(ParameterSetName = 'Delete', Mandatory = $false, ValueFromPipeline = $false)]
      [Switch] $Delete
   )

   Begin {

   # Read credentials file if it exists

      [string] $userProfile = $env:USERPROFILE
      if ($userProfile -eq 'C:\Users\Default') {
         [string] $whoami = whoami
         Write-Warning -Message "$($MyInvocation.MyCommand.Name): env:USERPROFILE should not be '$($userProfile)' env:USERNAME='$($env:USERNAME)' whoami = '${whoami}'", 'User''s profile might be missing.', "Start Command Prompt with `"Run as a different user`" using '$($env:USERDOMAIN)\$($env:USERNAME)' and run again while Command Prompt is still open to create the user`s profile."
      }
      [string] $credDirPath = Join-Path -Path $env:USERPROFILE -ChildPath 'Credentials'
      [string] $credFilePath = Join-Path -Path $credDirPath -ChildPath "${Username}.creds"
      [string] $jsonFilePath = Join-Path -Path $credDirPath -ChildPath "${Username}.json"

      if (Test-Path -LiteralPath $credFilePath -PathType 'Leaf') {
         [Collections.Hashtable] $credMap = Import-Clixml -LiteralPath $credFilePath
      } # if ($exists)
      else { # -not $exists
         [Collections.Hashtable] $credMap = [Collections.Hashtable]::new([System.StringComparer]::OrdinalIgnoreCase)
      } # else (-not $exists)

   } # Begin

   Process {

   # Get password for each Server

      $Server | % {
         [string] $aServer = $_
         [Security.SecureString] $securePasswordString = Read-Host "Enter password for user '${Username}' on server '${aServer}' (no password deletes credentials for server):" -AsSecureString
         [Management.Automation.PSCredential] $cred = New-Object -TypeName 'Management.Automation.PSCredential' ($Username, $securePasswordString)
         $credMap[$aServer] = New-Object -TypeName 'PSObject' -Property @{
            Credential = $cred
            Username   = $Username
            Password   = ConvertFrom-SecureString -SecureString $securePasswordString
         }
      } # % $Server

   } # Process

   End {

   # Create the Credentials directory if it does not already exist

      if (-not (Test-Path -Path $credDirPath -PathType Container)) {
         New-Item -Path $credDirPath -ItemType 'Directory'
      }

   # Write the credentials files

      Export-Clixml -LiteralPath $credFilePath -InputObject $credMap -Encoding 'UTF8'
      ConvertTo-Json -InputObject $credMap | Out-File -FilePath $jsonFilePath -Encoding 'UTF8'

   } # End

} # function Set-DatabaseCredentials


<#
.EXAMPLE
   [DateTime] $startTime = Get-Date
   # ...
   [TimeSpan] $ts = New-TimeSpan -Start $startTime
   [string] $duration = Convert-TimeSpanToString $ts
#>

function Convert-TimeSpanToString {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([string[]])]
   Param (
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [TimeSpan[]] $TimeSpan
   )

   Begin {
   }

   Process {

      $TimeSpan | % {

         [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
            # else errors in this script block are reported at the ForEach-Object level

            [TimeSpan] $ts = $_

            [int] $roundedMinutes = [Math]::Round($ts.TotalMinutes, 0, [System.MidpointRounding]::AwayFromZero)
            if ($roundedMinutes -ge 1440) {
               [int] $durationDays = [Math]::Floor($roundedMinutes / 1440.0)
               [int] $durationHours = [Math]::Floor($roundedMinutes / 60.0) - $durationDays * 24
               [int] $durationMinutes = $roundedMinutes - $durationDays * 1440 + $durationHours * 60
               if ($durationDays -eq 1) {
                  $pluralDays = ''
               }
               else {
                  $pluralDays = 's'
               }
               if ($durationHours -eq 1) {
                  $pluralHours = ''
               }
               else {
                  $pluralHours = 's'
               }
               if ($durationMinutes -eq 1) {
                  $pluralMinutes = ''
               }
               else {
                  $pluralMinutes = 's'
               }
               $duration = "${durationDays} day${pluralDays} ${durationHours} hour${pluralHours} ${durationMinutes} minute${pluralMinutes}"
            }
            elseif ($roundedMinutes -ge 60) {
               [int] $durationHours = [Math]::Floor($durationMinutes / 60)
               [int] $durationMinutes = $roundedMinutes - $durationHours * 60
               if ($durationHours -eq 1) {
                  $pluralHours = ''
               }
               else {
                  $pluralHours = 's'
               }
               if ($durationMinutes -eq 1) {
                  $pluralMinutes = ''
               }
               else {
                  $pluralMinutes = 's'
               }
               $duration = "${durationHours} hour${pluralHours} ${durationMinutes} minute${pluralMinutes}"
            }
            else {
               [Double] $durationSeconds = [Math]::Round($ts.TotalSeconds, 1, [System.MidpointRounding]::AwayFromZero)
               if ($durationSeconds -gt 60.0) {
                  [int] $durationMinutes = [Math]::Floor($durationSeconds / 60)
                  [Double] $durationSeconds = [Math]::Round($ts.TotalSeconds - $durationMinutes * 60.0, 1, [System.MidpointRounding]::AwayFromZero)
                  if ($durationMinutes -eq 1) {
                     $pluralMinutes = ''
                  }
                  else {
                     $pluralMinutes = 's'
                  }
                  if ($durationSeconds -eq 1.0) {
                     $pluralSeconds = ''
                  }
                  else {
                     $pluralSeconds = 's'
                  }
                  $duration = "${durationMinutes} minute${pluralMinutes} ${durationSeconds} second${pluralSeconds}"
               }
               else {
                  if ($durationSeconds -eq 1.0) {
                     $pluralSeconds = ''
                  }
                  else {
                     $pluralSeconds = 's'
                  }
                  $duration = "${durationSeconds} second${pluralSeconds}"
               }
            }

            Write-Output -InputObject $duration

         } # try
         catch {
            [Management.Automation.ErrorRecord] $er1 = $_
            Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
         } # catch

      }

   }

   End {
   }

}


function ConvertTo-SqlQuotedName {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([string])]
   Param(
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $false)]
      [string] $Name
   ) # Param
   return "[$($Name -replace ']', ']]')]"
}


function New-DataSet {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.DataRowCollection])]
   Param(
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $true)]
      [string[]] $DataSetName = ( , 'data' )
   ) # Param

   Begin {
   }

   Process {

      $DataSetName | % {
         $dsname = $_

         [Data.DataSet] $dataset = New-Object -TypeName 'Data.DataSet' ($dsname)
         Write-Output -InputObject $dataset

      }

   }

   End {
   }

}


function Get-DBMS {
   [CmdletBinding()]
   [OutputType([string])]
   param(
      [Parameter(Mandatory)]
      [object] $InputObject
   )

   [string] $dbms = [NullString]::Value
   [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($InputObject.GetType().FullName) {
      'Npgsql.NpgsqlDataAdapter' {
         $dbms = 'PostgreSQL'
      }
      'System.Data.SqlClient.SqlDataAdapter' {
         $dbms = 'SQL Server'
      }
      'System.Data.SQLite.SQLiteDataAdapter' {
         $dbms = 'SQLite'
      }
      default {
      # Error Message with location in this module
         [string[]] $msgs = , "Type name '$($InputObject.GetType().FullName)' not recognized"
         [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
         [string] $activity = "switch ('$($InputObject.GetType().FullName)')"
         Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
      }
   }
   Write-Output -InputObject $dbms

}


function Get-DataSourceNameOrAddress {
   [CmdletBinding()]
   [OutputType([string])]
   param(
      [Parameter(Mandatory)]
      [object] $InputObject
   )

# Extract the connection object

   [Management.Automation.CallStackFrame] $csf = (gcs)[0]; $conn = switch ($InputObject.GetType().FullName) {
      'System.Data.SqlClient.SqlConnection'  { $InputObject }
      'System.Data.SqlClient.SqlDataAdapter' { $InputObject.SelectCommand.Connection }
      'System.Data.SQLite.SQLiteConnection'  { $InputObject }
      'System.Data.SQLite.SQLiteDataAdapter' { $InputObject.SelectCommand.Connection }
      default {
      # Error Message with location in this module
         [string[]] $msgs = , "InputObject type '$($InputObject.GetType().FullName)' not recognized"
         [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
         [string] $activity = "switch ('$($InputObject.GetType())')"
         Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         [Type] $paramType = $null
         return $null
      }
   }

   [Management.Automation.CallStackFrame] $csf = (gcs)[0]; $conn = switch ($conn.GetType().FullName) {
      'System.Data.SQLite.SQLiteConnection' {
      # for SQLite, extract the DataSource from the ConnectionString ($conn.DataSource is the file name without the path or ".db" extension)
         [Management.Automation.CallStackFrame] $csf0 = (gcs)[0]; [System.Data.SQLite.SQLiteConnectionStringBuilder] $csb = New-Object -TypeName 'System.Data.SQLite.SQLiteConnectionStringBuilder' ($conn.ConnectionString)
         [string] $dataSource = [NullString]::Value
         foreach ($key in $csb.Keys) {
            if ($key -eq 'datasource') {
               $dataSource = $csb[$key]
            }
         }
         if ($dataSource -eq $null) {
            [string[]] $msgs = , "$($MyInvocation.MyCommand.Name): Did not find 'datasource' in Connection String $($conn.ConnectionString)"
            [string] $functionAndScriptLocation = "in $($csf0.FunctionName) at $($csf0.ScriptName): $($csf0.ScriptLineNumber)"
            Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
            $csb.PSObject.Properties | % {
               Write-Warning -Message "   $($_.Name): $($_.Value)"
            }
         }
      }
      default {
         [string] $dataSource = $conn.DataSource
      }
   }

# Extract SQL Server instance name and/or port
# Examples:
#   server.domain.com\instance
#   server.domain.com,1433
#   10.1.2.3,1433

   [string] $pattern = '^(?<ServerNameOrAddress>[^\\,]+)(?<DelimAndInstanceName>[\\,].*)?$'
   if ($dataSource -match $pattern) {
      [string] $serverNameOrAddress = $Matches.ServerNameOrAddress
      if ($Matches.ContainsKey('DelimAndInstanceName')) {
         [string] $delimAndInstanceName = $Matches.DelimAndInstanceName
      }
      else {
         [string] $delimAndInstanceName = ''
      }
   }
   else {
      Write-Warning -Message "$($MyInvocation.MyCommand.Name): '${dataSource}' did not match '${pattern}'"
      [string] $serverNameOrAddress = $dataSource
      [string] $delimAndInstanceName = ''
   }

   $ipAddress = $null
   if ([Net.IPAddress]::TryParse($serverNameOrAddress, [ref]$ipAddress)) {
      if ($ipAddress.ToString() -eq $serverNameOrAddress) {
         return "${serverNameOrAddress}${delimAndInstanceName}"
      }
      else {
         return "${serverNameOrAddress}${delimAndInstanceName} ($($ipAddress.ToString())${delimAndInstanceName})"
      }
   }
   else {
      return "${serverNameOrAddress}${delimAndInstanceName}"
   }

}

<# If there are any parameters, all Connections must be the same type as for the first Connection #>

<# PgSqlType enumeration values:
   Row
   Array
   LargeObject
   Boolean
   ByteA
   BigInt
   SmallInt
   Int
   Text
   Json
   Xml
   Point
   LSeg
   Path
   Box
   Polygon
   Line
   CIdr
   Real
   Double
   Circle
   MacAddr8
   Money
   MacAddr
   Inet
   Char
   VarChar
   Date
   Time
   TimeStamp
   TimeStampTZ
   Interval
   TimeTZ
   Bit
   VarBit
   Numeric
   Uuid
   JsonB
   IntRange
   NumericRange
   TimeStampRange
   TimeStampTZRange
   DateRange
   BigIntRange
#>

function New-DataAdapter {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbDataAdapter])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [string] $Query = [NullString]::Value,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   ) # Param
   DynamicParam {

      [Management.Automation.RuntimeDefinedParameterDictionary] $paramDict = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameterDictionary'
      [Collections.ObjectModel.Collection[System.Attribute]] $attribCollection = New-Object -TypeName 'Collections.ObjectModel.Collection[System.Attribute]'

   # Avoid: Cannot overwrite variable {name} because the variable has been optimized.
      [string[]] $msgs = [string[]]::new(0)
      [string] $functionAndScriptLocation = [NullString]::Value
      [string] $activity = [NullString]::Value

      [string] $paramName = 'ParameterTypeDictionary'

      [Data.Common.DbConnection] $conn = $Connection[0]
      [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($conn.GetType()) {
      # MySQL
         'MySql.Data.MySqlClient.MySqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[string], [MySql.Data.MySqlClient.MySqlDbType]]]
         }
      # PostgreSQL
         'Devart.Data.PostgreSql.PgSqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[string], [Devart.Data.PostgreSql.PgSqlType]]]
         }
         'Npgsql.NpgsqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[string], [Data.DbType]]]
         }
      # SQLite
         'System.Data.SQLite.SQLiteConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[string], [Data.DbType]]]
         }
      # SQL Server
         'System.Data.SqlClient.SqlConnection' {
            [Type] $paramType = [Collections.Generic.Dictionary[[string], [Data.SqlDbType]]]
         }
         default {
         # Error Message with location in this module
            [string[]] $msgs = , "Connection type '$($conn.GetType())' not recognized"
            [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            [string] $activity = "switch ('$($conn.GetType())')"
            Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
            [Type] $paramType = $null
         }
      }

      if ($paramType -ne $null) {

         $attribCollection.Clear()
         [Management.Automation.ParameterAttribute] $attrib = New-Object -TypeName 'Management.Automation.ParameterAttribute'
         $attrib.ParameterSetName = '__AllParameterSets'
<#
         $attrib.Mandatory = $false
#>
         $attribCollection.Add($attrib)

         [Management.Automation.RuntimeDefinedParameter] $param = New-Object -TypeName 'Management.Automation.RuntimeDefinedParameter' ($paramName, $paramType, $attribCollection)

         $paramDict.Add($paramName, $param)

      }

      return $paramDict
   } # DynamicParam

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      $nNull = 0
      $nConn = 0

   }

   Process {

      $ParameterTypeDictionary = $PSBoundParameters['ParameterTypeDictionary']

      $Connection | % {
         if ($_ -eq $NULL) {
            $nNull += 1
            $nConn += 1
         }
         else { # $_ -ne $NULL
            [Data.Common.DbConnection] $conn = $_
            $nConn += 1

            [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($conn.GetType()) {
               'Devart.Data.PostgreSql.PgSqlConnection' {
                  $cmdClass = 'Devart.Data.PostgreSql.PgSqlCommand'
                  $daClass = 'Devart.Data.PostgreSql.PgSqlDataAdapter'
               }
               'MySql.Data.MySqlClient.MySqlConnection' {
                  $cmdClass = 'MySql.Data.MySqlClient.MySqlCommand'
                  $daClass = 'MySql.Data.MySqlClient.MySqlDataAdapter'
               }
               'Npgsql.NpgsqlConnection' {
                  $cmdClass = 'Npgsql.NpgsqlCommand'
                  $daClass = 'Npgsql.NpgsqlDataAdapter'
               }
               'System.Data.SqlClient.SqlConnection' {
                  $cmdClass = 'Data.SqlClient.SqlCommand'
                  $daClass = 'Data.SqlClient.SqlDataAdapter'
               }
               'System.Data.SQLite.SQLiteConnection' {
                  $cmdClass = 'System.Data.SQLite.SQLiteCommand'
                  $daClass = 'System.Data.SQLite.SQLiteDataAdapter'
               }
               default {
               # Error Message with location in this module
                  [string[]] $msgs = , "$($MyInvocation.MyCommand.Name): Connection type '$($conn.GetType())' not recognized"
                  [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                  [string] $activity = "switch ('$($conn.GetType())')"
                  Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
                  return $NULL
               }
            }

if ($cmdClass -eq $null) {
   Write-Warning -Message "$($MyInvocation.MyCommand.Name): cmdClass is null for $($conn.GetType())"
}
            $cmd = New-Object -TypeName $cmdClass
            $cmd.Connection = $conn
            $cmd.CommandTimeout = $CommandTimeout
            $cmd.CommandText = $Query
<# Exception setting "UpdateBatchSize": "Specified method is not supported."
            if ($cmd.PSObject.Properties.Name -contains 'UpdateBatchSize') {
               $cmd.UpdateBatchSize = 0 # unlimited
                  # requires .NET Framework 2.0 or later - https://docs.microsoft.com/en-us/dotnet/api/system.data.common.dbdataadapter.updatebatchsize?view=netframework-2.0
            }
#>

            if ($ParameterTypeDictionary -ne $NULL) {
               $ParameterTypeDictionary.Keys | % {
                  $key = $_
                  [void] $cmd.Parameters.Add($key, $ParameterTypeDictionary[$key])
               }
            }

            $da = New-Object -TypeName $daClass

            $da.SelectCommand = $cmd

<# Assigning to DbDataAdapter.UpdateBatchSize failed on PowerShell Version 4.8.10008
   in <ScriptBlock> at C:\Program Files\WindowsPowerShell\Modules\DotNetData\Public\Common\PublicFunctions.ps1: 764
   Exception setting "UpdateBatchSize": "Specified method is not supported."

            [int] $errorStartIndex = $Global:Error.Count
            [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
               $da.UpdateBatchSize = 0 # unlimited
                  # requires .NET Framework 2.0 or later - https://docs.microsoft.com/en-us/dotnet/api/system.data.common.dbdataadapter.updatebatchsize?view=netframework-2.0
                  # but fails on .NET Framework v4.8.03761
            } # try
            catch {
            # Warning for suppressed Error
               [Management.Automation.ErrorRecord] $er1 = $_
               $msgs = , "Assigning to DbDataAdapter.UpdateBatchSize failed on PowerShell Version $( ( Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full' ).Version )"
               $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)"
               Write-Warning -Message (@( $msgs; $functionAndScriptLocation; $Global:Error[0..($Global:Error.Count - $errorStartIndex - 1)] ) -join "$([Environment]::NewLine)         ")
               Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
            } # catch
#>

            Write-Output -InputObject $da

         } # else ($_ -ne $NULL)

      } # % $Connection

   } # Process

   End {
      if ($nNull -gt 0) {
         if ($nNull -lt $nConn) {
            $msgs = , "$($MyInvocation.MyCommand.Name): ${nNull} of ${nConn} connections are null"
         }
         elseif ($nConn -eq 1) {
            $msgs = , "$($MyInvocation.MyCommand.Name): Connection is null"
         }
         else {
            $msgs = , "$($MyInvocation.MyCommand.Name): All ${nConn} connections are null"
         }
         Write-Warning -Message ($msgs -join "$([Environment]::NewLine)         ")
      }
   }

}


<# Get-Rows
   If DbDataAdapter parameter is included, returns the first result set.
   Example:
      [Data.DataRowCollection] $rows = Get-Rows -DataAdapter $da -DataSet $ds
         # if "[Data.DataRowCollection]" type is omitted, then "$rows" will be NULL if no rows are returned
#>
function Get-Rows {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   [OutputType([Data.DataRow[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $false, ValueFromPipeline = $false)]
      [Data.Common.DbDataAdapter[]] $DataAdapter = $NULL,
         # requires relational DbDataAdapter for *Command rather than generic DataAdapter
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [Data.DataSet[]] $DataSet,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $DataSetIndex = 0,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $TableIndex = 0,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      [string[]] $msgs = [string[]]::new(0)
      [string] $functionAndScriptLocation = [NullString]::Value
      [string] $activity = [NullString]::Value

      if ($DataAdapter -ne $NULL) {

         if (1, $DataAdapter.Count -notcontains $DataSet.Count) {
         # Error Message with location of calling statement
            $msgs = , "$($MyInvocation.MyCommand.Name): Number of DataSet elements ($($DataSet.Count)) must be 1 or match the number of DataAdapter elements ($($DataAdapter.Count))"
            [Management.Automation.CallStackFrame] $csf = (gcs)[1]
            $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            $activity = 'Get-Rows using DataAdapter(s)'
            Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::InvalidArgument) -CategoryReason 'Invalid parameter' -CategoryActivity $activity -CategoryTargetName 'DataSet' -CategoryTargetType 'Parameter'
         }

         if ($DataSet.Count -eq 1) {
            $DataSet[0].Clear()
         }

      } # if ($DataAdapter -ne $NULL)

      [Collections.Generic.List[Data.DataRow[]]] $dataRowsList = New-Object -TypeName 'Collections.Generic.List[Data.DataRow[]]'

   } # Begin

   Process {

      [Boolean] $ok = $true

      if ($DataAdapter -ne $NULL) {

         for ($i = 0; $i -lt $DataAdapter.Count; $i += 1) {
            $da = $DataAdapter[$i]

            if ($DataSet.Count -eq 1) {
               $ds = $DataSet[0]
               $msgDataSet = 'DataSet'
            }
            else {
               $ds = $DataSet[$i]
               $msgDataSet = "DataSet[${i}]"
            }
            [Management.Automation.CallStackFrame] $csf = (gcs)[0]; if ($ds -eq $null) {
            # Error Message with location in this module (or calling function? should not occur?)
               $msgs = , "$($MyInvocation.MyCommand.Name): ${msgDataSet} is null"
               $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
               $activity = "switch ('${SystemOrUser}')"
               Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::InvalidArgument) -CategoryReason 'DataSet is null' -CategoryActivity $activity -CategoryTargetName $msgDataSet -CategoryTargetType 'DataSet'
               [Boolean] $ok = $false
            } # if ($ds -eq $null)
            else { # $ds -ne $null

               $ds.Clear()

               [Data.Common.DbCommand] $cmd = $da.SelectCommand
               if ($cmd -eq $NULL) {
               # Error Message with location of calling statement
                  $msgs = , "$($MyInvocation.MyCommand.Name): Command has not been set in DataAdapter"
                  [Management.Automation.CallStackFrame] $csf = (gcs)[1]
                  $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                  $activity = 'Get-Rows using DataAdapter(s)'
                  Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::InvalidArgument) -CategoryReason 'Command not set' -CategoryActivity $activity -CategoryTargetName 'SelectCommand' -CategoryTargetType 'DataAdapter.Command'
               }

               if ($cmd.Connection.State -ne 'Open') {
               # Error Message with location of calling statement
                  $msgs = , "$($MyInvocation.MyCommand.Name): Connection to instance `"$($cmd.Connection.DataSource)`" is not 'Open'"
                  [Management.Automation.CallStackFrame] $csf = (gcs)[1]
                  $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                  $activity = 'Get-Rows using DataAdapter(s)'
                  Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ConnectionError) -CategoryReason 'Connection not Open' -CategoryActivity $activity -CategoryTargetName $cmd.Connection.DataSource -CategoryTargetType 'DataSource'
                  if ($DataAdapter.Count -eq 1) {
                     [Boolean] $ok = $false
                  }
# TO DO:          # else return data from other instances
               } # if ($cmd.Connection.State -ne 'Open')
               else { # $cmd.Connection.State -eq 'Open'
                  [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                     [int] $nRows = $da.Fill($ds)
                        # nRows - number of rows in first DataTable
                  } # try
                  catch {
                  # ErrorRecord
                     [Management.Automation.ErrorRecord] $er1 = $_
                     [string] $activity = 'DataAdapter.Fill'
                     [string] $dataSource = Get-DataSourceNameOrAddress -InputObject $da
                     $msgs = "$($MyInvocation.MyCommand.Name): [$($da.GetType().FullName)].Fill() threw an error", "DataSource: ${dataSource}"
                     [Management.Automation.CallStackFrame] $csf1 = (gcs)[1]
                     $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)", "in $($csf1.FunctionName) at $($csf1.ScriptName): $($csf1.ScriptLineNumber)"
                     Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
                     Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
                     [Boolean] $ok = $false
                  } # catch
               } # else ($cmd.Connection.State -eq 'Open')

            } # else ($ds -ne $null)
         } # for ($i = 0; $i -lt $DataAdapter.Count; $i += 1)

      } # if ($DataAdapter -ne $NULL)

      if ($ok) {

         if ($DataSetIndex -ge $DataSet.Count) {
            Write-Warning -Message "$($MyInvocation.MyCommand.Name): DataSetIndex ${DataSetIndex} not valid. DataSet.Count=$($DataSet.Tables.Count)"
            [void] $dataRowsList.Add($NULL)
         } # if ($DataSetIndex -ge $DataSet.Count)
         else { # $DataSetIndex -lt $DataSet.Count
            if ($TableIndex -ge $DataSet[$DataSetIndex].Tables.Count) {
               if ($DataSet.Count -eq 1) {
                  [string] $msgDataSet = "DataSet"
               }
               else {
                  [string] $msgDataSet = "DataSet[${DataSetIndex}]"
               }
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): TableIndex ${TableIndex} not valid. ${msgDataSet}.Tables.Count=$($DataSet[$DataSetIndex].Tables.Count)"
               [void] $dataRowsList.Add($NULL)
            }
            else {
               [Data.DataTable] $table = $Dataset[$DataSetIndex].Tables[$TableIndex]
               [void] $dataRowsList.Add($table.Rows)
            }
         } # else ($DataSetIndex -lt $DataSet.Count)

      } # if ($ok)

   } # Process

   End {
      [int] $count = 0
      $dataRowsList | % {
         $count += $_.Count
      }
      if ($count -eq 0) {
         return , @()
      }
      else {
         return $dataRowsList
      }
   } # End

}


function Compare-Data {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true, ConfirmImpact = 'Medium')]
   [OutputType([Data.DataRow[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateCount(2, 2)]
      [Data.Common.DbDataAdapter[]] $DataAdapters,
      [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $false)]
      [string[]] $MatchColumns,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [string[]] $CompareColumns,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [scriptblock] $WhenMatched,
      [Parameter(Position = 4, Mandatory = $false, ValueFromPipeline = $false)]
      [scriptblock] $WhenNotMatched,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {
      [Collections.Generic.List[[Data.Common.DbDataAdapter]]] $dataAdapterList = New-Object -TypeName 'Collections.Generic.List[[Data.Common.DbDataAdapter]]'
      [Collections.Generic.List[[Data.DataRow[]]]] $dataRowsList = New-Object -TypeName 'Collections.Generic.List[[Data.DataRow[]]]'
   } # Begin

   Process {
      $DataAdapters | % {
         [Data.Common.DbDataAdapter] $da = $_
         $dataAdapterList.Add($da)
         [Data.DataSet] $ds = New-DataSet
         [Data.DataRow[]] $rows = Get-Rows -DataAdapter $da -DataSet $ds
         $dataRowsList.Add($rows)
      }
   } # Process

   End {

      [int] $i1 = 0
      [int] $i2 = 0

      [Data.DataRow] $row1 = $null
      if ($dataRowsList[0].Count -gt 0) {
         $row1 = $dataRowsList[0][$i1]
      }
      else {
         Write-Warning -Message "$($MyInvocation.MyCommand.Name): No rows in input #1"
      }

      [Data.DataRow] $row2 = $null
      if ($dataRowsList[1].Count -gt 0) {
         $row2 = $dataRowsList[1][$i2]
      }
      else {
         Write-Warning -Message "$($MyInvocation.MyCommand.Name): No rows in input #2"
      }

      [Data.DataRow] $prev1 = $null
      [Data.DataRow] $prev2 = $null

      while ($i1 -lt $dataRowsList[0].Count -or $i2 -lt $dataRowsList[1].Count) {

      # Make sure input data is in the correct order

         if ($i1 -gt 0 -and $i1 -lt $dataRowsList[0].Count) {
            [Int32] $c = 0
            for ($i = 0; $i -lt $MatchColumns.Count -and $c -eq 0; $i += 1) {
               if ($prev1[$MatchColumns[$i]] -is [DBNull]) {
                  if ($row1[$MatchColumns[$i]] -is [DBNull]) {
                     $c = 0
                  }
                  else {
                     $c = -1
                  }
               }
               else {
                  if ($row1[$MatchColumns[$i]] -is [DBNull]) {
                     $c = 1
                  }
                  else {
                     [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                        $c = [StringComparer]::Ordinal.Compare($prev1[$MatchColumns[$i]], $row1[$MatchColumns[$i]])
                     } # try
                     catch {
                        [Management.Automation.ErrorRecord] $er1 = $_
                     # Error Message with location of calling statement
                        [Management.Automation.CallStackFrame] $csf1 = (gcs)[1]
                        $msgs = "$($MyInvocation.MyCommand.Name): `"[StringComparer]::Ordinal.Compare`" for match column '$($MatchColumns[$i])' threw an error", "rows1[$($i1-1)]['$($MatchColumns[$i])'] type is $($prev1[$MatchColumns[$i]].GetType().FullName)", "rows1[$($i1)]['$($MatchColumns[$i])'] type is $($row1[$MatchColumns[$i]].GetType().FullName)"
                        $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)", "in $($csf1.FunctionName) at $($csf1.ScriptName): $($csf1.ScriptLineNumber)"
                        Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
                        Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
                     } # catch
                  }
               }
            }
            if ($c -eq 0) {
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): Input #1 has duplicate match columns, rows ${i1} and $($i1+1), column '$($MatchColumns[$i-1])', [$($prev1[$MatchColumns[$i-1]].GetType().FullName)] '$($prev1[$MatchColumns[$i-1]])' = [$($row1[$MatchColumns[$i-1]].GetType().FullName)] '$($row1[$MatchColumns[$i-1]])'"
            }
            elseif ($c -gt 0) {
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): Input #1 is not in the correct order, rows ${i1} and $($i1+1), column '$($MatchColumns[$i-1])', [$($prev1[$MatchColumns[$i-1]].GetType().FullName)] '$($prev1[$MatchColumns[$i-1]])' > [$($row1[$MatchColumns[$i-1]].GetType().FullName)] '$($row1[$MatchColumns[$i-1]])'"
            }
         }

         if ($i2 -gt 0 -and $i2 -lt $dataRowsList[1].Count) {
            [Int32] $c = 0
            for ($i = 0; $i -lt $MatchColumns.Count -and $c -eq 0; $i += 1) {
               [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                  $c = [StringComparer]::Ordinal.Compare($prev2[$MatchColumns[$i]], $row2[$MatchColumns[$i]])
               } # try
               catch {
                  [Management.Automation.ErrorRecord] $er1 = $_
               # Error Message with location of calling statement
                  [Management.Automation.CallStackFrame] $csf1 = (gcs)[1]
                  $msgs = "$($MyInvocation.MyCommand.Name): `"[StringComparer]::Ordinal.Compare`" for match column '$($MatchColumns[$i])' threw an error", "rows2[$($i2-1)]['$($MatchColumns[$i])'] type is $($prev2[$MatchColumns[$i]].GetType().FullName)", "rows2[$($i2)]['$($MatchColumns[$i])'] type is $($row2[$MatchColumns[$i]].GetType().FullName)"
                  $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)", "in $($csf1.FunctionName) at $($csf1.ScriptName): $($csf1.ScriptLineNumber)"
                  Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
                  Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
               }
            }
            if ($c -eq 0) {
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): Input #2 has duplicate match columns, rows ${i2} and $($i2+1), column '$($MatchColumns[$i-1])', [$($prev2[$MatchColumns[$i-1]].GetType().FullName)] '$($prev2[$MatchColumns[$i-1]])' >= [$($row2[$MatchColumns[$i-1]].GetType().FullName)] '$($row2[$MatchColumns[$i-1]])'"
            }
            elseif ($c -gt 0) {
               Write-Warning -Message "$($MyInvocation.MyCommand.Name): Input #2 is not in the correct order, rows ${i2} and $($i2+1), column '$($MatchColumns[$i-1])', [$($prev2[$MatchColumns[$i-1]].GetType().FullName)] '$($prev2[$MatchColumns[$i-1]])' >= [$($row2[$MatchColumns[$i-1]].GetType().FullName)] '$($row2[$MatchColumns[$i-1]])'"
            }
         }

         [Int32] $c = 0
         if ($i1 -ge $dataRowsList[0].Count) {
            $c = 1
         }
         elseif ($i2 -ge $dataRowsList[1].Count) {
            $c = -1
         }
         else { # $i1 -lt $dataRowsList[0].Count -and $i2 -lt $dataRowsList[1].Count

            for ($i = 0; $i -lt $MatchColumns.Count -and $c -eq 0; $i += 1) {
               if ($row1 -eq $null) {
                  Write-Warning -Message "$($MyInvocation.MyCommand.Name): row1 is null for `$i1 = ${i1}"
               }
               if ($row2 -eq $null) {
                  Write-Warning -Message "$($MyInvocation.MyCommand.Name): row2 is null for `$i2 = ${i2}"
               }
               [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                  $c = [StringComparer]::Ordinal.Compare($row1[$MatchColumns[$i]], $row2[$MatchColumns[$i]]);
               } # try
               catch {
                  [Management.Automation.ErrorRecord] $er1 = $_
               # Error Message with location of calling statement
                  [Management.Automation.CallStackFrame] $csf1 = (gcs)[1]
                  $msgs = "$($MyInvocation.MyCommand.Name): `"[StringComparer]::Ordinal.Compare`" for match column '$($MatchColumns[$i])' threw an error", "rows1[$($i1-1)]['$($MatchColumns[$i])'] type is $($row1[$MatchColumns[$i]].GetType().FullName)", "rows2[$($i2)]['$($MatchColumns[$i])'] type is $($row2[$MatchColumns[$i]].GetType().FullName)"
                  $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)", "in $($csf1.FunctionName) at $($csf1.ScriptName): $($csf1.ScriptLineNumber)"
                  Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
                  Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
               }
            }

         } # else ($i1 -le $dataRowsList[0].Count -and $i2 -le $dataRowsList[1].Count)

         if ($c -lt 0) {
            $WhenNotMatched.InvokeReturnAsIs(1, $row1)
            $prev1 = $row1
            $i1 += 1
            if ($i1 -lt $dataRowsList[0].Count) {
               $row1 = $dataRowsList[0][$i1]
            }
         }
         elseif ($c -gt 0) {
            $WhenNotMatched.InvokeReturnAsIs(2, $row2)
            $prev2 = $row2
            $i2 += 1
            if ($i2 -lt $dataRowsList[1].Count) {
               $row2 = $dataRowsList[1][$i2]
            }
         }
         else {
         # Compare the CompareColumns
            [int] $same = 0
            [int] $diff = 0
            for ($i = 0; $i -lt $CompareColumns.Count; $i += 1) {
               if ($row1[$CompareColumns[$i]] -is [DBNull]) {
                  $c = -1
               }
               elseif ($row2[$CompareColumns[$i]] -is [DBNull]) {
                  $c = 1
               }
               else {
               [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
                  if ([StringComparer]::Ordinal.Compare($row1[$CompareColumns[$i]], $row2[$CompareColumns[$i]]) -eq 0) {
                     $same += 1
                  }
                  else {
                     $diff += 1
                  }
               } # try
               catch {
                  [Management.Automation.ErrorRecord] $er1 = $_
               # Error Message with location of calling statement
                  [Management.Automation.CallStackFrame] $csf1 = (gcs)[1]
                  $msgs = "$($MyInvocation.MyCommand.Name): `"[StringComparer]::Ordinal.Compare`" for compare column '$($CompareColumns[$i])' threw an error", "rows1[$($i1-1)]['$($CompareColumns[$i])'] type is $($row1[$CompareColumns[$i]].GetType().FullName)", "rows2[$($i2)]['$($CompareColumns[$i])'] type is $($row2[$CompareColumns[$i]].GetType().FullName)"
                  $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)", "in $($csf1.FunctionName) at $($csf1.ScriptName): $($csf1.ScriptLineNumber)"
                  Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
                  Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
               } # catch
               }
            }
            $WhenMatched.InvokeReturnAsIs($row1, $row2, $same, $diff)
            $prev1 = $row1
            $prev2 = $row2
            $i1 += 1
            $i2 += 1
            if ($i1 -lt $dataRowsList[0].Count) {
               $row1 = $dataRowsList[0][$i1]
            }
            if ($i2 -lt $dataRowsList[1].Count) {
               $row2 = $dataRowsList[1][$i2]
            }
         }

      } # while ($i1 -lt $dataRowsList[0].Count -or $i2 -lt $dataRowsList[1].Count)

      $dataAdapterList | % {
         [Data.Common.DataAdapter] $da = $_
         $da.Dispose()
      }

   } # End

}
