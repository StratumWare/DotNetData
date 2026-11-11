<# PublicSQLStatements.ps1

For any given function, the same set of columns is returned for each DBMS.

#>


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


function Get-ServerProperties {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Collections.Generic.List[PSObject]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
      [Data.DataSet] $ds1 = New-DataSet
      [Collections.Generic.List[PSObject]] $list = New-Object -TypeName 'Collections.Generic.List[PSObject]'
   }

   Process {
      [Data.Common.DbDataAdapter[]] $dataAdapters = Get-DataAdapterForServerProperties -Connection $Connection
      $dataAdapters | % {
         [Data.Common.DataAdapter] $da1 = $_
         if ($da1 -ne $null) {
            [string] $dbms = Get-DBMS -InputObject $da1
            Try {
               [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($dbms) {
                  'PostgreSQL' {
                        [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
                        $rows1 | % {
                           [Data.DataRow] $row1 = $_
                           [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                              'DBMS'            = $dbms
                              'DataSourceName'  = $Connection.DataSource.Split('.')[0]
                              'MajorVersion'    = $Connection.PostgreSqlVersion.Major
                              'ServerVersion'   = $Connection.ServerVersion
                              'VersionString'   = $row1.version
                              'CurrentDatabase' = $row1.current_database
                           })
                        } # % $rows1
                        [void] $list.Add($obj)
                  } # 'PostgreSQL'
                  'SQL Server' {
                     [int] $majorVersion = ([version]$Connection.ServerVersion).Major
                     [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
                     $rows1 | % {
                        [Data.DataRow] $row1 = $_
                        [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                           'DBMS'                         = $dbms
                           'DataSourceName'               = $Connection.DataSource.Split('.')[0]
                           'MajorVersion'                 = $majorVersion
                           'ServerVersion'                = $Connection.ServerVersion
#                           'PacketSize'                   = $Connection.PacketSize
                           'CurrentDatabase'              = $Connection.Database
                           'ServerName'                   = $row1.ServerName
                           'MachineName'                  = $row1.MachineName
                           'ComputerName'                 = $row1.ComputerNamePhysicalNetBIOS
                           'InstanceName'                 = $row1.InstanceName
                           'Vendor'                       = $row1.Vendor
                           'Product'                      = $row1.Product
                           'ProductVersion'               = $row1.ProductVersion
                           'ProductMajorVersion'          = $row1.ProductMajorVersion
                           'ProductMinorVersion'          = $row1.ProductMinorVersion
                           'ProductLevel'                 = $row1.ProductLevel
                           'ProductUpdateType'            = $row1.ProductUpdateType
                           'ProductUpdateLevel'           = $row1.ProductUpdateLevel
                           'ProductBuildType'             = $row1.ProductBuildType
                           'ProductUpdateReference'       = $row1.ProductUpdateReference
                           'ProductBuild'                 = $row1.ProductBuild
                           'Edition'                      = $row1.Edition
                           'EngineEdition'                = $row1.EngineEdition
                           'IsIntegratedSecurityOnly'     = $row1.IsIntegratedSecurityOnly
                           'IsExternalAuthenticationOnly' = $row1.IsExternalAuthenticationOnly
                           'Collation'                    = $row1.Collation
                           'SqlCharSetName'               = $row1.SqlCharSetName
                           'SqlSortOrder'                 = $row1.SqlSortOrder
                           'ComparisonStyle'              = $row1.ComparisonStyle
                           'IsLocalDB'                    = $row1.IsLocalDB
                           'IsClustered'                  = $row1.IsClustered
                           'IsHadrEnabled'                = $row1.IsHadrEnabled
                           'InstanceDefaultDataPath'      = $row1.InstanceDefaultDataPath
                           'InstanceDefaultLogPath'       = $row1.InstanceDefaultLogPath
                           'InstanceDefaultBackupPath'    = $row1.InstanceDefaultBackupPath
                           'IsSingleUser'                 = $row1.IsSingleUser
                           'PathSeparator'                = $row1.PathSeparator
                           'host_platform'                = $null
                           'host_release'                 = $null
                           'host_distribution'            = $null
                           'database_id'                  = $null
                           'database_name'                = $null
                           'database_file'                = $null
                        })
                        if ($majorVersion -ge 14) {
                           $obj.'host_platform'           = $row1.host_platform
                           $obj.'host_release'            = $row1.host_release
                           $obj.'host_distribution'       = $row1.host_distribution
                        }
                     } # % $rows1
                     [void] $list.Add($obj)
                  } # 'SQL Server'
                  'SQLite' {
                     [string] $dataSource = Get-DataSourceNameOrAddress -InputObject $da1
                     [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
                     $rows1 | % {
                        [Data.DataRow] $row1 = $_
                        [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                           'DBMS'                         = $dbms
                           'DataSourceName'               = $dataSource.Split('.')[0]
                           'seq'                          = $row1.seq
                           'name'                         = $row1.name
                           'file'                         = $row1.file
                           'auto_vacuum'                  = $row1.auto_vacuum
                           'cache_size'                   = $row1.cache_size
                           'freelist_count'               = $row1.freelist_count
                           'journal_mode'                 = $row1.journal_mode
                           'max_page_count'               = $row1.max_page_count
                           'page_count'                   = $row1.page_count
                           'page_size'                    = $row1.page_size
                        })
                     } # % $rows1
                     [void] $list.Add($obj)
                  } # 'SQLite'
                  default {
                  # Error Message with location in this module
                     [string[]] $msgs = , "DBMS '${dbms}' not recognized"
                     [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                     [string] $activity = "switch ('${dbms}')"
                     Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
                  } # default
               } # switch ($dbms) {
            } # Try
            Catch {
               [Management.Automation.ErrorRecord] $er1 = $_
               Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
            } # Catch
            Finally {
               $da1.Dispose()
               [Data.Common.DbDataAdapter] $da1 = $NULL
            } # Finally
         } # if ($da1 -ne $null)
      } # % $dataAdapters
   } # Process

   End {
      $ds1.Dispose()
      [Data.DataSet] $ds1 = $null
#      $list | Select-Object -Property 'DBMS', 'DataSourceName', 'MajorVersion', 'ServerVersion', 'CurrentDatabase', 'ServerName', 'MachineName', 'ComputerName', 'InstanceName', 'Vendor', 'Product', 'ProductLevel', 'ProductUpdateType', 'ProductUpdateLevel', 'ProductBuildType', 'ProductUpdateReference', 'ProductVersion', 'ProductMajorVersion', 'ProductMinorVersion', 'ProductBuild', 'Edition', 'EngineEdition', 'IsIntegratedSecurityOnly', 'IsExternalAuthenticationOnly', 'Collation', 'SqlCharSetName', 'SqlSortOrder', 'ComparisonStyle', 'IsLocalDB', 'IsClustered', 'IsHadrEnabled', 'InstanceDefaultDataPath', 'InstanceDefaultLogPath', 'InstanceDefaultBackupPath', 'IsSingleUser', 'PathSeparator', 'host_platform', 'host_release', 'host_distribution' | Write-Output
      return $list
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
select db.[database_id], db.[name] [database_name], db.[state], db.[state_desc] from [sys].[databases] db order by case when db.[database_id] <= 4 then db.[database_id] else 99 end asc, lower(db.[name]) collate Latin1_General_BIN asc;
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


function Get-Databases {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Collections.Generic.List[PSObject]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
      [Data.DataSet] $ds1 = New-DataSet
      [Collections.Generic.List[PSObject]] $list = New-Object -TypeName 'Collections.Generic.List[PSObject]'
   }
   Process {
      [Data.Common.DbDataAdapter[]] $dataAdapters = Get-DataAdapterForDatabases -Connection $Connection
      $dataAdapters | % {
         [Data.Common.DataAdapter] $da1 = $_
         if ($da1 -ne $null) {
            [string] $dbms = Get-DBMS -InputObject $da1
            Try {
               [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($dbms) {
                  'SQL Server' {
                     [int] $majorVersion = ([version]$Connection.ServerVersion).Major
                     [Data.DataRow[]] $rows1 = Get-Rows -DataAdapter $da1 -DataSet $ds1
                     if ($rows1.Count -eq 0) {
                        Write-Warning -Message "No rows returned from $($da1.SelectCommand.Connection.DataSource) `"$($da1.SelectCommand.CommandText)`""
                     }
                     $rows1 | % {
                        [Data.DataRow] $row1 = $_
                        [boolean] $isSystemDatabase = $row1.database_id -le 4
                        [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                           'DBMS'             = $dbms
                           'DataSourceName'   = $Connection.DataSource.Split('.')[0]
                           'DatabaseName'     = $row1.database_name
                           'IsSystemDatabase' = $isSystemDatabase
                           'State'            = $row1.State
                           'State_Desc'       = $row1.State_Desc
                        })
                        [void] $list.Add($obj)
                     } # % $rows1
                  } # 'SQL Server'
                  default {
                  # Error Message with location in this module
                     [string[]] $msgs = , "DBMS '${dbms}' not recognized"
                     [string] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
                     [string] $activity = "switch ('${dbms}')"
                     Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
                  } # default
               } # switch ($dbms) {
            } # Try
            Catch {
               [Management.Automation.ErrorRecord] $er1 = $_
               Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
            } # Catch
            Finally {
               $da1.Dispose()
               [Data.Common.DbDataAdapter] $da1 = $NULL
            } # Finally
         } # if ($da1 -ne $null)
      } # % $dataAdapters
   } # Process

   End {
      $ds1.Dispose()
      [Data.DataSet] $ds1 = $null
      return $list
   }

}



<# Database Permissions
#>

function Get-DataAdapterForDatabasePermissions {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Collections.Generic.List[Data.Common.DbDataAdapter]], [string[]], [string[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:DefaultCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      [Collections.Generic.List[Data.Common.DbDataAdapter]] $dataAdapterList = New-Object -TypeName 'Collections.Generic.List[Data.Common.DbDataAdapter]'
      [bool] $first = $true
      [string] $firstConnType = [NullString]::Value
      [bool] $allConnectionsAreSameType = $true

   }

   Process {

      if ($first) {
         $firstConnType = $Connection.GetType()
         $first = $false
      }
      elseif ($Connection.GetType() -ne $firstConnType) {
         $allConnectionsAreSameType = $false
      }

      $Connection | % {
         [Data.Common.DbConnection] $conn = $_
         [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($conn.GetType()) {
            'Npgsql.NpgsqlConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query @'
select version(), current_database();
'@
            }
            'System.Data.SqlClient.SqlConnection' {
               [Data.Common.DbDataAdapter] $da = New-DataAdapter -Connection $conn -CommandTimeout $CommandTimeout -CallStackFrame $CallStackFrame -Query @'
select cast(ServerProperty(N'ServerName') as nvarchar(128)) [ServerName],
   case
      when db_id() <= 4 then N'S ' + cast(db_id() as nvarchar(1))
      else N'U ' + lower(db_name())
   end [lower_database_type_and_id_or_name],
   db_name() [database_name],
   dp.[class],
   dp.[class_desc],
   concat(cast(dp.[class] as nvarchar(2)), N' ', dp.[class_desc]) [class_with_desc],
   case
      when dp.[major_id] < 0 then N'SYSTEM SECURABLE'
      when dp.[major_id] > 0 then N'USER SECURABLE'
      else N'DATABASE'
   end [major_type],
   dp.[major_id],
   dp.[minor_id],
   s.[securable_type],
   case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then case
         when 1 = 1 then N'System View'
         else N'???'
      end
      else s.[securable_type_desc]
   end [securable_type_desc],
   lower(case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_schema_name(dp.[major_id])
      else s.[securable_schema_name]
   end) [lower_securable_schema_name],
   case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_schema_name(dp.[major_id])
      else s.[securable_schema_name]
   end [securable_schema_name],
   s.[major_id] [securable_major_id],
   lower(case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_name(dp.[major_id])
      else s.[securable_name]
   end) [lower_securable_name],
   case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_name(dp.[major_id])
      else s.[securable_name]
   end [securable_name],
   s.[minor_id] [securable_minor_id],
   lower(s.[column_name]) [lower_column_name],
   s.[column_name],
   case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then concat(object_schema_name(dp.[major_id]), N'.', object_name(dp.[major_id]))
      else s.[securable_qualified_name]
   end [securable_qualified_name],
   s.[owner_name],
   s.[owner_type],
   s.[owner_type_desc],
   s.[owner_is_fixed_role],
   s.[owner_authentication_type],
   s.[owner_authentication_type_desc],
   dp.[grantee_principal_id],
   dp.[grantor_principal_id],
   dp.[type] [permission_type],
   dp.[permission_name],
   dp.[state],
   dp.[state_desc],
   lower(dpa.[name]) [lower_grantee_name],
   dpa.[name] [grantee_name],
   dpa.[type] [grantee_type],
   dpa.[type_desc] [grantee_type_desc],
   dpa.[is_fixed_role] [grantee_is_fixed_role],
   dpa.[authentication_type] [grantee_authentication_type],
   dpa.[authentication_type_desc] [grantee_authentication_type_desc],
   dpb.[name] [grantor_name],
   dpb.[type] [grantor_type],
   dpb.[type_desc] [grantor_type_desc],
   dpb.[is_fixed_role] [grantor_is_fixed_role],
   dpb.[authentication_type] [grantor_authentication_type],
   dpb.[authentication_type_desc] [grantor_authentication_type_desc]
from [sys].[database_permissions] dp
left outer join (
   select 1 [class],
      ao1a.[type] [securable_type],
      ao1a.[type_desc] [securable_type_desc],
      object_schema_name(ao1a.[object_id]) [securable_schema_name],
      ao1a.[object_id] [major_id],
      ao1a.[name] [securable_name],
      0 [minor_id],
      N'' [column_name],
      concat(object_schema_name(ao1a.[object_id]), N'.', ao1a.[name]) [securable_qualified_name],
      dp1a.[name] [owner_name],
      dp1a.[type] [owner_type],
      dp1a.[type_desc] [owner_type_desc],
      dp1a.[is_fixed_role] [owner_is_fixed_role],
      dp1a.[authentication_type] [owner_authentication_type],
      dp1a.[authentication_type_desc] [owner_authentication_type_desc]
   from [sys].[all_objects] ao1a
   left outer join [sys].[database_principals] dp1a
   on dp1a.[principal_id] = ao1a.[principal_id]
   union all
   select 1 [class],
      ao1b.[type] [securable_type],
      ao1b.[type_desc] [securable_type_desc],
      object_schema_name(ao1b.[object_id]) [securable_schema_name],
      ao1b.[object_id] [major_id],
      ao1b.[name] [securable_name],
      ac1b.[column_id] [minor_id],
      ac1b.[name] [column_name],
      concat(object_schema_name(ao1b.[object_id]), N'.', ao1b.[name], N'.', ac1b.[name]) [securable_qualified_name],
      dp1b.[name] [owner_name],
      dp1b.[type] [owner_type],
      dp1b.[type_desc] [owner_type_desc],
      dp1b.[is_fixed_role] [owner_is_fixed_role],
      dp1b.[authentication_type] [owner_authentication_type],
      dp1b.[authentication_type_desc] [owner_authentication_type_desc]
   from [sys].[all_objects] ao1b
   inner join [sys].[all_columns] ac1b
   on ac1b.[object_id] = ao1b.[object_id]
   left outer join [sys].[database_principals] dp1b
   on dp1b.[principal_id] = ao1b.[principal_id]
   union all
   select 3 [class],
      N'' [securable_type],
      N'SCHEMA' [securable_type_desc],
      s3.[name] [securable_schema_name],
      s3.[schema_id] [major_id],
      s3.[name] [securable_name],
      0 [minor_id],
      NULL [column_name],
      s3.[name] [securable_qualified_name],
      dp3.[name] [owner_name],
      dp3.[type] [owner_type],
      dp3.[type_desc] [owner_type_desc],
      dp3.[is_fixed_role] [owner_is_fixed_role],
      dp3.[authentication_type] [owner_authentication_type],
      dp3.[authentication_type_desc] [owner_authentication_type_desc]
   from [sys].[schemas] s3
   left outer join [sys].[database_principals] dp3
   on dp3.[principal_id] = s3.[principal_id]
) s
on exists (
   select dp.[class], dp.[major_id], dp.[minor_id]
   intersect
   select s.[class], s.[major_id], s.[minor_id]
)
left outer join [sys].[database_principals] dpa
on dpa.[principal_id] = dp.[grantee_principal_id]
left outer join [sys].[database_principals] dpb
on dpb.[principal_id] = dp.[grantor_principal_id]
order by case
      when db_id() <= 4 then N'S ' + cast(db_id() as nvarchar(1))
      else N'U ' + lower(db_name())
   end collate Latin1_General_BIN asc,
   dp.[class] asc,
   lower(case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_schema_name(dp.[major_id])
      else s.[securable_schema_name]
   end) collate Latin1_General_BIN asc,
   lower(case
      when s.[securable_type_desc] is null and dp.[major_id] < 0
      then object_name(dp.[major_id])
      else s.[securable_name]
   end) collate Latin1_General_BIN asc,
   lower(s.[column_name]) collate Latin1_General_BIN asc,
   dpa.[type] collate Latin1_General_BIN asc,
   lower(dpa.[name]) collate Latin1_General_BIN asc,
   dp.[permission_name] collate Latin1_General_BIN asc;
'@
            }
            'System.Data.SQLite.SQLiteConnection' {
               New-DataAdapter -Connection $conn -CommandTimeout $Script:DefaultCommandTimeout -Query 'select ???;'
            }
            default {
               Write-Error -Message "$($MyInvocation.MyCommand.Name): Connection.Type '$($conn.GetType())' not recognized" -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity 'switch ($conn.GetType())' -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module File'
            }
         } # switch ($conn.GetType())

         $dataAdapterList.Add($da)

      } # % $Connection

   } # Process

   End {

      [string[]] $matchColumns = 'lower_database_type_and_id_or_name', 'class_with_desc', 'lower_securable_schema_name', 'lower_securable_name', 'lower_column_name', 'grantee_type', 'lower_grantee_name', 'permission_name'
      [string[]] $compareColumns = 'major_type', 'securable_type', 'securable_type_desc', 'securable_qualified_name', 'owner_name', 'owner_type', 'owner_type_desc', 'owner_is_fixed_role', 'owner_authentication_type', 'owner_authentication_type_desc', 'state', 'state_desc', 'grantee_name', 'grantee_type', 'grantee_type_desc', 'grantee_is_fixed_role', 'grantee_authentication_type', 'grantee_authentication_type_desc', 'grantor_name', 'grantor_type', 'grantor_type_desc', 'grantor_is_fixed_role', 'grantor_authentication_type', 'grantor_authentication_type_desc'

      if ($allConnectionsAreSameType) {
         return $dataAdapterList, $matchColumns, $compareColumns
      }
      else {
         return $dataAdapterList
      }

   }

}
