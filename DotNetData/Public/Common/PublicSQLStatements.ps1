<# PublicSQLStatements.ps1

For any given function, the same set of columns is returned for each DBMS.

#>


<# ServerProperties

#>

function Get-ServerProperties {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType()]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
      [Data.DataSet] $ds1 = New-DataSet
      [Collections.Generic.List[PSCustomObject]] $list = New-Object -TypeName 'Collections.Generic.List[PSCustomObject]'
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
      $list | Select-Object -Property 'DBMS', 'DataSourceName', 'MajorVersion', 'ServerVersion', 'CurrentDatabase', 'ServerName', 'MachineName', 'ComputerName', 'InstanceName', 'Vendor', 'Product', 'ProductLevel', 'ProductUpdateType', 'ProductUpdateLevel', 'ProductBuildType', 'ProductUpdateReference', 'ProductVersion', 'ProductMajorVersion', 'ProductMinorVersion', 'ProductBuild', 'Edition', 'EngineEdition', 'IsIntegratedSecurityOnly', 'IsExternalAuthenticationOnly', 'Collation', 'SqlCharSetName', 'SqlSortOrder', 'ComparisonStyle', 'IsLocalDB', 'IsClustered', 'IsHadrEnabled', 'InstanceDefaultDataPath', 'InstanceDefaultLogPath', 'InstanceDefaultBackupPath', 'IsSingleUser', 'PathSeparator', 'host_platform', 'host_release', 'host_distribution' | Write-Output
   }

}


<# ServerProperties

#>

function Get-Databases {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType()]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Data.Common.DbConnection[]] $Connection
   )

   Begin {
      [Data.DataSet] $ds1 = New-DataSet
      [Collections.Generic.List[PSCustomObject]] $list = New-Object -TypeName 'Collections.Generic.List[PSCustomObject]'
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
                     $rows1 | % {
                        [Data.DataRow] $row1 = $_
                        [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                           'DBMS'                         = $dbms
                           'DataSourceName'               = $Connection.DataSource.Split('.')[0]
                           'database_name'                = $row1.database_name
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
      $list | Select-Object -Property 'DBMS', 'DataSourceName', 'database_name' | Write-Output
   }

}
