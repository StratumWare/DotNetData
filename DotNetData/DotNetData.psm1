<# DotNetData.psm1

Troubleshooting:

   $Error[0].Exception.ErrorRecord

#>

$verbosePref = $Global:VerbosePreference
$Global:VerbosePreference = 'Continue'

Set-PSDebug -Strict              # Global scope, variables must be assigned a value before being referenced
Set-StrictMode -Version 'Latest' # Current and child scopes

[int] $Script:DefaultCommandTimeout = 300 # default is 30


# Get arrays of private and public source files

if ($PSVersionTable.PSVersion.Major -lt 3) {
   # -File and -Directory parameters added in PSv3
   [IO.FileInfo[]] $pvtFileInfo = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Include *.ps1 -Recurse
   [IO.FileInfo[]] $pubFileInfo = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Include *.ps1 -Recurse
}
else {
   [IO.FileInfo[]] $pvtFileInfo = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Private') -Include *.ps1 -File -Recurse
   [IO.FileInfo[]] $pubFileInfo = Get-ChildItem -Path (Join-Path -Path $PSScriptRoot -ChildPath 'Public') -Include *.ps1 -File -Recurse
}

# Source in the source files

($pvtFileInfo + $pubFileInfo) | % {
   [IO.FileInfo] $fileInfo = $_
   
   Try {
      Write-Verbose -Message "Sourcing $($fileInfo.FullName)"
      . $fileInfo.FullName
   } # Try
   Catch {
      [Management.Automation.ErrorRecord] $er = $_
      Write-Error -ErrorRecord $er -CategoryReason 'dot source threw exception' -CategoryTargetName $fileInfo.Name -CategoryTargetType 'File'
   } # Catch

}


<# CLASSES #>

class DbConnectionFactory {
   static [Collections.Generic.Dictionary[String, DbConnectionFactory]] $ConnectionFactoryDict = [Collections.Generic.Dictionary[String, DbConnectionFactory]]::new()
   [String] $DbmsName

   static [void] AddConnectionFactory([String] $dbmsName, [DbConnectionFactory] $cf) {
      if ([DbConnectionFactory]::ConnectionFactoryDict.ContainsKey($dbmsName)) {
         Write-Warning -Message "DotNetData.psm1: Connection factory for DBMS name '${dbmsName}' already exists - using first definition"
      }
      else {
         [DbConnectionFactory]::ConnectionFactoryDict[$dbmsName] = $cf
      }
   }

   static [DbConnectionFactory] GetConnectionFactory([String] $dbmsName) {
      if (-not [DbConnectionFactory]::ConnectionFactoryDict.ContainsKey($dbmsName)) {
         throw [ArgumentException]::new('$dbmsName', 'DotNetData.psm1: DBMS name not recognized')
      }
      return [DbConnectionFactory]::ConnectionFactoryDict[$dbmsName]
   }

   DbConnectionFactory([String] $dbmsName) {
      $this.DbmsName = $dbmsName
   }

   [Data.Common.DbConnection] CreateConnection([String] $server) {
      throw [NotImplementedException]::new('DotNetData.psm1: CreateConnection($server) method not implemented in subclass')
   }

   [Data.Common.DbConnection] CreateConnection([String] $server, [String] $userName) {
      throw [NotImplementedException]::new('DotNetData.psm1: CreateConnection($server, $userName) method not implemented in subclass')
   }

}

class OracleConnectionFactory : DbConnectionFactory {

   OracleConnectionFactory() : base('Oracle') {
   }

   [Data.SqlClient.SqlConnection] CreateConnection([String] $server, [String] $userName) {
#   [Data.Common.DbConnection] CreateConnection([String] $server) {
      return New-OracleConnection -Server $server -UserName $userName
   }

}

class SqlServerConnectionFactory : DbConnectionFactory {

   SqlServerConnectionFactory() : base('SQL Server') {
   }

   [Data.SqlClient.SqlConnection] CreateConnection([String] $server) {
#   [Data.Common.DbConnection] CreateConnection([String] $server) {
      return New-SqlServerConnection -Server $server -IntegratedSecurity
   }

   [Data.SqlClient.SqlConnection] CreateConnection([String] $server, [String] $userName) {
#   [Data.Common.DbConnection] CreateConnection([String] $server) {
      return New-SqlServerConnection -Server $server -UserName $userName
   }

}


<# Additional code here to:
   Create or read a config file
   Set variables visible only to the module's functions
   etc.
#>

$Global:VerbosePreference = $verbosePref
