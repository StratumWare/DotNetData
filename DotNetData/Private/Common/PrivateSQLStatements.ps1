<# PrivateSQLStatements.ps1

These functions return a [Data.Common.DbDataAdapter[]].

For any given function, the same set of columns is returned for each DBMS.

#>

[int] $Script:DefaultCommandTimeout = 30


<# ServerProperties

#>

function Get-DataAdapterForServerProperties {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.Common.DbDataAdapter[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
   }

   Process {
      $Connection | % {
         [Data.Common.DbConnection] $conn = $_
         [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($conn.GetType()) {
            'Npgsql.NpgsqlConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select version(), current_database();
'@
            }
            'System.Data.SqlClient.SqlConnection' {
# sys.dm_os_host_info added in SQL Server 2019, Major version 14
               [int] $majorVersion = ([version]$conn.ServerVersion).Major
               if ($majorVersion -lt 14) {
                  New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select cast(ServerProperty('ServerName') as nvarchar(128)) [ServerName],
   ServerProperty('MachineName') [MachineName],
   ServerProperty('ComputerNamePhysicalNetBIOS') [ComputerNamePhysicalNetBIOS],
   ServerProperty('InstanceName') [InstanceName],
   N'Microsoft' [Vendor],
   N'SQL Server' [Product],
   ServerProperty('ProductVersion') [ProductVersion],
   ServerProperty('ProductMajorVersion') [ProductMajorVersion],
   ServerProperty('ProductMinorVersion') [ProductMinorVersion],
   ServerProperty('ProductLevel') [ProductLevel],
   ServerProperty('ProductUpdateType') [ProductUpdateType],
   ServerProperty('ProductUpdateLevel') [ProductUpdateLevel],
   ServerProperty('ProductBuildType') [ProductBuildType],
   ServerProperty('ProductUpdateReference') [ProductUpdateReference],
   ServerProperty('ProductBuild') [ProductBuild],
   ServerProperty('Edition') [Edition],
   ServerProperty('EngineEdition') [EngineEdition],
   ServerProperty('IsIntegratedSecurityOnly') [IsIntegratedSecurityOnly],
   ServerProperty('IsExternalAuthenticationOnly') [IsExternalAuthenticationOnly],
   ServerProperty('Collation') [Collation],
   ServerProperty('SqlCharSetName') [SqlCharSetName],
   ServerProperty('SqlSortOrder') [SqlSortOrder],
   ServerProperty('ComparisonStyle') [ComparisonStyle],
   ServerProperty('IsLocalDB') [IsLocalDB],
   ServerProperty('IsClustered') [IsClustered],
   ServerProperty('IsHadrEnabled') [IsHadrEnabled],
   ServerProperty('InstanceDefaultDataPath') [InstanceDefaultDataPath],
   ServerProperty('InstanceDefaultLogPath') [InstanceDefaultLogPath],
   ServerProperty('InstanceDefaultBackupPath') [InstanceDefaultBackupPath],
   ServerProperty('IsSingleUser') [IsSingleUser],
   ServerProperty('PathSeparator') [PathSeparator];
'@
               }
               else { # SQL Server 2019+
                  New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select cast(ServerProperty('ServerName') as nvarchar(128)) [ServerName],
   ServerProperty('MachineName') [MachineName],
   ServerProperty('ComputerNamePhysicalNetBIOS') [ComputerNamePhysicalNetBIOS],
   ServerProperty('InstanceName') [InstanceName],
   N'Microsoft' [Vendor],
   N'SQL Server' [Product],
   ServerProperty('ProductVersion') [ProductVersion],
   ServerProperty('ProductMajorVersion') [ProductMajorVersion],
   ServerProperty('ProductMinorVersion') [ProductMinorVersion],
   ServerProperty('ProductLevel') [ProductLevel],
   ServerProperty('ProductUpdateType') [ProductUpdateType],
   ServerProperty('ProductUpdateLevel') [ProductUpdateLevel],
   ServerProperty('ProductBuildType') [ProductBuildType],
   ServerProperty('ProductUpdateReference') [ProductUpdateReference],
   ServerProperty('ProductBuild') [ProductBuild],
   ServerProperty('Edition') [Edition],
   ServerProperty('EngineEdition') [EngineEdition],
   ServerProperty('IsIntegratedSecurityOnly') [IsIntegratedSecurityOnly],
   ServerProperty('IsExternalAuthenticationOnly') [IsExternalAuthenticationOnly],
   ServerProperty('Collation') [Collation],
   ServerProperty('SqlCharSetName') [SqlCharSetName],
   ServerProperty('SqlSortOrder') [SqlSortOrder],
   ServerProperty('ComparisonStyle') [ComparisonStyle],
   ServerProperty('IsLocalDB') [IsLocalDB],
   ServerProperty('IsClustered') [IsClustered],
   ServerProperty('IsHadrEnabled') [IsHadrEnabled],
   ServerProperty('InstanceDefaultDataPath') [InstanceDefaultDataPath],
   ServerProperty('InstanceDefaultLogPath') [InstanceDefaultLogPath],
   ServerProperty('InstanceDefaultBackupPath') [InstanceDefaultBackupPath],
   ServerProperty('IsSingleUser') [IsSingleUser],
   ServerProperty('PathSeparator') [PathSeparator],
   dohi.[host_platform],
   dohi.[host_release],
   dohi.[host_distribution],
   db_id() [database_id],
   db_name() [database_name]
from [sys].[dm_os_host_info] dohi;
'@
               }
            }
            'System.Data.SQLite.SQLiteConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query 'select seq, name, file, auto_vacuum, cache_size, freelist_count, journal_mode, max_page_count, page_count, page_size from pragma_database_list(), pragma_auto_vacuum(), pragma_cache_size(), pragma_freelist_count(), pragma_journal_mode(), pragma_max_page_count(), pragma_page_count(), pragma_page_size() where seq = 0;'
            }
            default {
               Write-Error -Message "$($MyInvocation.MyCommand.Name): Connection.Type '$($conn.GetType())' not recognized" -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity 'switch ($conn.GetType())' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module File'
            }
         }
      }
   }

   End {
   }

}


<# Databases

#>

function Get-DataAdapterForDatabases {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.Common.DbDataAdapter[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
   }

   Process {
      $Connection | % {
         [Data.Common.DbConnection] $conn = $_
         [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($conn.GetType()) {
            'Npgsql.NpgsqlConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select version(), current_database();
'@
            }
            'System.Data.SqlClient.SqlConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select db.[name] [database_name] from [sys].[databases] db where db.[name] = N'StorageProd';
'@
            }
            'System.Data.SQLite.SQLiteConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query 'select ???;'
            }
            default {
               Write-Error -Message "$($MyInvocation.MyCommand.Name): Connection.Type '$($conn.GetType())' not recognized" -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity 'switch ($conn.GetType())' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module File'
            }
         }
      }
   }

   End {
   }

}
