<# Public/SQLite/SQLiteConnection.ps1

Uses System.Data.SQLite for Desktop / Legacy, Microsoft.Data.Sqlite for Core

System.Data.SQLite

   Install-Package -Name 'System.Data.SQLite' -RequiredVersion '1.0.119' -Scope 'AllUsers' -Force

System.Data.SQLite.SQLiteConnection properties:
PoolCount:                 0
ConnectionString:          DataSource=C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
DataSource: 
FileName: 
Database:                  main
GetPasswordCallback: 
DefaultTimeout:            30
DefaultMaximumSleepTime:   150
BusyTimeout:               0
WaitTimeout:               30000
PrepareRetries:            3
StepRetries:               40
ProgressOps:               0
ParseViaFramework:         False
Flags:                     Default
DefaultDbType: 
DefaultTypeName: 
VfsName: 
OwnHandle: 
ServerVersion:             3.46.1
LastInsertRowId: 
Changes: 
AutoCommit: 
MemoryUsed: 
MemoryHighwater: 
Tag: 
State:                     Closed
TraceFlags:                SQLITE_TRACE_NONE
ConnectionTimeout:         15
Site: 
Container: 

SQLiteConnectionStringBuilder properties:
DataSource: 
FileName: 
Version:                   3
SyncMode:                  Normal
UseUTF16Encoding: 
Pooling:                   False
BinaryGUID: 
DataSource: 
Uri: 
FullUri: 
DefaultTimeout:            30
DefaultMaximumSleepTime:   0
BusyTimeout:               0
WaitTimeout:               0
PrepareRetries:            0
StepRetries:               0
ProgressOps:               0
Enlist:                    True
FailIfMissing: 
LegacyFormat:              False
ReadOnly:                  False
Password: 
HexPassword: 
TextPassword: 
TextHexPassword: 
PageSize:                  4096
MaxPageCount:              0
CacheSize:                 -2000
DateTimeFormat:            ISO8601
DateTimeKind:              Unspecified
DateTimeFormatString: 
BaseSchemaName: 
JournalMode:               Default
DefaultIsolationLevel: 
DefaultDbType:             -1
DefaultTypeName: 
VfsName: 
ForeignKeys:               False
RecursiveTriggers:         False
ZipVfsVersion: 
Flags:                     Default
SetDefaults: 
ToFullPath: 
NoDefaultFlags: 
NoSharedFlags: 
BrowsableConnectionString: True
ConnectionString:          datasource=C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
Count:                     1
IsReadOnly:                False
IsFixedSize:               False
Keys:                      datasource
Values:                    C:\Users\robsimpson\AppData\Local\Devolutions\RemoteDesktopManager\WebView2.Cache\UI\EBWebView\GPUPersistentCache\DawnGraphiteCache\TLVJWQT6NJWKNBUVMWJ4BCR6DK7MJALX\cache.db
SyncRoot:                  System.Object
IsSynchronized:            False

#>

[Boolean] $Script:firstSQLiteConn = $true

[Data.Common.DbConnectionStringBuilder] $Script:slcsb1 = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

<# Test-SQLite

Call before New-SQLiteConnection to load types needed for parameters there.

#>

function Test-SQLite {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([bool])]
   Param(
   )

# Load System.Data.SQLite.dll or Microsoft.Data.Sqlite.dll

   if ($Script:firstSQLiteConn) {
      $Script:firstSQLiteConn = $false

#      [Object] $sqliteConfig = Get-DotNetDataConfiguration -DBMS 'SQLite'

   # Load the DLLs for SQLite

      Import-Dll -UsingAddType -DllDirPath 'C:\Program Files\PackageManagement\NuGet\Packages\Stub.System.Data.SQLite.Core.NetFramework.1.0.119.0\lib\net46' -DllName 'System.Data.SQLite.dll' -Verbose

   } # if ($Script:firstSQLiteConn)

   return $true

}


function New-SQLiteConnection {
   [CmdletBinding(PositionalBinding = $false, DefaultParameterSetName = 'ReadWrite')]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $DataSource,
      [Parameter(ParameterSetName = 'ReadWriteCreate', Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $ReadWriteCreate,
      [Parameter(ParameterSetName = 'ReadWrite', Mandatory = $false, ValueFromPipeline = $false)]
      [Switch] $ReadWrite,
      [Parameter(ParameterSetName = 'ReadOnly', Mandatory = $true, ValueFromPipeline = $false)]
      [Switch] $ReadOnly,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

      [bool] $ok = Test-SQLite

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:slcsb1 -eq $NULL) {
         [System.Data.SQLite.SQLiteConnectionStringBuilder] $Script:slcsb1 = New-Object -TypeName 'System.Data.SQLite.SQLiteConnectionStringBuilder'
      }

      Initialize-SQLiteConnectionStringBuilder -ConnectionStringBuilder $Script:slcsb1
#      Initialize-MicrosoftSqliteConnectionStringBuilder -ConnectionStringBuilder $Script:slcsb2

         [Management.Automation.CallStackFrame] $csf = (gcs)[0]; switch -Exact ($PSCmdlet.ParameterSetName) {

         'ReadWriteCreate' {
#            $Script:slcsb1['ReadOnly'] = $false
         }

         'ReadWrite' {
#            $Script:slcsb1['ReadOnly'] = $false
         }

         'ReadOnly' {
#            $Script:slcsb1['ReadOnly'] = $true
         }

         default {
         # Error Message with location in this module
            [String[]] $msgs = , "Unrecognized ParameterSetName '$($PSCmdlet.ParameterSetName)'"
            [String] $functionAndScriptLocation = "in $($csf.FunctionName) at $($csf.ScriptName): $($csf.ScriptLineNumber)"
            [String] $activity = "switch ('$($PSCmdlet.ParameterSetName)')"
            Write-Error -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::NotImplemented) -CategoryReason 'Coding error in module!' -CategoryActivity $activity -CategoryTargetName $MyInvocation.MyCommand.Name -CategoryTargetType 'Module'
         }

      }

      [Management.Automation.ErrorRecord] $er1 = $null
      [string] $activity = [NullString]::Value
      [string[]] $msgs = [string[]]::new(0)
      [string] $functionAndScriptLocation = [NullString]::Value
         # to avoid: Cannot overwrite variable ... because the variable has been optimized.

   } # Begin

   Process {

   # When $DataSource is from "-DataSource" parameter, each item in [String[]] $DataSource list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $DataSource items to $queue at once)
      $DataSource | % {
         [String] $aDataSource = $_

         $Script:slcsb1['DataSource'] = $aDataSource

         [String] $connstr = $Script:slcsb1.ToString()

         [Management.Automation.CallStackFrame] $csfTryCatchLine = (gcs)[0]; try {
            
            [int] $gec = $Global:Error.Count
            [System.Data.SQLite.SQLiteConnection] $conn = New-Object -TypeName 'System.Data.SQLite.SQLiteConnection' ($connstr)

         } # try
         catch [System.TypeInitializationException] {
            [Management.Automation.ErrorRecord] $er1 = $_
            Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
            $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)"
            [String[]] $msgs = , "New-Object -TypeName 'System.Data.SQLite.SQLiteConnection' ($connstr)"
            Write-Error -Exception $er1.Exception -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ConnectionError) -ErrorId 'ErrorId' -TargetObject $connstr -RecommendedAction 'RecommendedAction' -CategoryActivity 'CategoryActivity' -CategoryReason 'CategoryReason' -CategoryTargetName 'CategoryTargetName' -CategoryTargetType 'CategoryTargetType'
            [String[]] $msgs = 'Exception.InnerException', $er1.Exception.InnerException
            Write-Error -Exception $er1.Exception.InnerException -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::ConnectionError) -ErrorId 'ErrorId' -TargetObject $connstr -RecommendedAction 'RecommendedAction' -CategoryActivity 'CategoryActivity' -CategoryReason 'CategoryReason' -CategoryTargetName 'CategoryTargetName' -CategoryTargetType 'CategoryTargetType'
            return $null
         }
         catch {
            [Management.Automation.ErrorRecord] $er1 = $_
            $functionAndScriptLocation = "in $($csfTryCatchLine.FunctionName) at $($csfTryCatchLine.ScriptName): $($csfTryCatchLine.ScriptLineNumber)"
            Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
            return $null
         } # catch

         try {
            $conn.Open()
            if ($conn.State -ne 'Open') {
               [String[]] $msgs = "conn.Open() with Data Source=${aDataSource}", "Connection.Type             = $($conn.GetType().FullName)", "Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
               Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::OpenError) -CategoryReason 'SQLiteConnection.Open failed' -CategoryTargetName $aDataSource -CategoryTargetType 'DataSource'
            }
         } # try
         catch {
            [Management.Automation.ErrorRecord] $er1 = $_
            $activity = '[System.Data.SQLite.SQLiteConnection].Open'
            [string] $dataSource1 = Get-DataSourceNameOrAddress -InputObject $conn
            $msgs = "[System.Data.SQLite.SQLiteConnection].Open() threw an error", "DataSource: ${dataSource1}"
            [Management.Automation.CallStackFrame] $csf2 = (gcs)[2]
               # (gcs)[1] is % $DataSource above
            $functionAndScriptLocation = "in $($csf2.FunctionName) at $($csf2.ScriptName): $($csf2.ScriptLineNumber)"
            Write-Warning -Message (@( $msgs; $functionAndScriptLocation ) -join "$([Environment]::NewLine)         ")
            Write-Error -ErrorRecord $er1 -CategoryActivity $er1.CategoryInfo.Activity -CategoryTargetName $er1.CategoryInfo.TargetName -CategoryTargetType $er1.CategoryInfo.TargetType
         } # catch

      # Return the Connection regardless of State 'Open' or not
         Write-Output -InputObject $conn

      } # % $DataSource

   } # Process

   End {
   } # End

} # function New-SQLiteConnection
