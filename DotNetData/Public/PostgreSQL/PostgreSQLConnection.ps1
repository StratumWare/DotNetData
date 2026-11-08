<# PostgreSQLConnection.ps1

Requires System.Threading.Tasks.Extensions 4.2.0.0
else Open() throws error:
Exception calling "Open" with "0" argument(s): "Could not load file or assembly 'System.Threading.Tasks.Extensions, Version=4.2.0.0, Culture=neutral, 
PublicKeyToken=cc7b13ffcd2ddd51' or one of its dependencies. The system cannot find the file specified."

Use Npgsql 4.0.12
Install-Package -Name 'Npgsql' -RequiredVersion '4.0.12' -Source 'nuget.org' -Scope 'AllUsers'

#>

[Boolean] $Script:firstPostgreSQLConn = $true

$Script:pgcsb = $null

function New-PostgreSqlConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [Switch] $Redshift,
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [int] $Port = -1,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = 'postgres',
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      if ($Script:firstPostgreSQLConn) {
         $Script:firstPostgreSQLConn = $false

         [bool] $ok = Test-IsTypeLoaded -FullTypeName 'Npgsql.NpgsqlConnection'
         if (-not $ok) {

#            [Object] $pgsqlConfig = Get-DotNetDataConfiguration -DBMS 'PostgreSQL'

         # Load the DLLs for PostgreSQL

<#
$DllDir = "C:\YourFolderWithNet461Binaries"
# 1. Load the lowest core runtime dependencies first
Add-Type -Path (Join-Path $DllDir "System.Runtime.CompilerServices.Unsafe.dll")
Add-Type -Path (Join-Path $DllDir "System.ValueTuple.dll")
# 2. Load mid-tier extensions
Add-Type -Path (Join-Path $DllDir "System.Memory.dll")
Add-Type -Path (Join-Path $DllDir "System.Threading.Tasks.Extensions.dll")
# 3. Load Npgsql last, now that its environment dependencies are loaded
Add-Type -Path (Join-Path $DllDir "Npgsql.dll")
#>

            Write-Warning -Message 'Loading Npgsql DLLs for PostgreSQL'
            [string] $binDirPath = Join-Path -Path $env:USERPROFILE -ChildPath 'bin'
            [string] $npgsqlDirPath = Join-Path -Path $binDirPath -ChildPath 'Npgsql_4.0.12' | Join-Path -ChildPath $PSEdition
            Import-Dll -UsingAddType -DllDirPath $npgsqlDirPath -DllName 'System.Runtime.CompilerServices.Unsafe.dll', 'System.ValueTuple.dll', 'System.Memory.dll', 'System.Threading.Tasks.Extensions.dll', 'Npgsql.dll'

         } # if (-not $ok)

      } # if ($Script:firstPostgreSQLConn)

   # Initialize script variable - ConnectionStringBuilder

# IMPL: PostgreSQL Providers classes:
# Open Source: [Npgsql.NpgsqlConnectionStringBuilder], [Npgsql.NpgsqlConnection]
# Commercial:  [Devart.Data.PostgreSql.PgSqlConnectionStringBuilder], [Devart.Data.PostgreSql.PgSqlConnection]

      if ($Script:pgcsb -eq $NULL) {
         [Npgsql.NpgsqlConnectionStringBuilder] $Script:pgcsb = New-Object -TypeName 'Npgsql.NpgsqlConnectionStringBuilder'
      }

      [Boolean] $writeServerArray = $false

   } # Begin

   Process {

   # When $Server is from "-Server" parameter, each item in [String[]] $Server list is processed separately
      $Server | % {
         [String] $aServer = $_

         if ($aServer -eq $null) {
            Write-Warning -Message 'An item in the $Server array should not be null'
            $writeServerArray = $true
            return
         }

         Initialize-PostgreSqlConnectionStringBuilder -ConnectionStringBuilder $Script:pgcsb

         $Script:pgcsb['Server'] = $aServer

      # For Redshift, the default port is 5439 rather than 5432; ServerCompatibilityMode ensures the driver handles Redshift's older underlying system tables smoothly

         if ($Redshift) {
            if ($Port -lt 0) {
               $Script:pgcsb['Port'] = 5439
            }
            elseif ($Port -eq 5432) {
               Write-Warning -Message "The default port for Redshift should be 5439 rather than PostgreSQL 5432."
            }
            $Script:pgcsb['ServerCompatibilityMode'] = [Npgsql.ServerCompatibilityMode]::Redshift
         }
         elseif ($Port -ge 0) {
            $Script:pgcsb['Port'] = $Port
         }
         
         $Script:pgcsb['Database'] = $DatabaseName
         $Script:pgcsb['UserId'] = $UserName
         [Management.Automation.PSCredential] $Credential = Get-CredentialForUserName -UserName $UserName -Server $aServer -CallStackFrame $CallStackFrame
         if ($Credential -eq $NULL) {
            return $null
         }
         $Script:pgcsb['UserId'] = $Credential.UserName
         $Script:pgcsb['Password'] = $Credential.GetNetworkCredential().Password

         [string] $connstr = $Script:pgcsb.ToString()

      # Connect to PostgreSQL instance

         [Npgsql.NpgsqlConnection] $conn = New-Object -TypeName 'Npgsql.NpgsqlConnection' ($connstr)

         Try {
            $conn.Open()
            if ($conn.State -ne 'Open') {
               [String[]] $msgs = "conn.Open() with Server=${aServer}", "$($MyInvocation.MyCommand.Name): Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
               Write-Error -Message ($msgs -join "$([Environment]::NewLine)         ") -Category ([Management.Automation.ErrorCategory]::OpenError) -CategoryReason 'MySqlConnection.Open failed' -CategoryActivity $($MyInvocation.MyCommand.Name) -CategoryTargetName $aServer -CategoryTargetType 'Server'
            }
         }
         Catch {
            [Management.Automation.ErrorRecord] $er = $_
            Write-Error -ErrorRecord $er -CategoryActivity $($MyInvocation.MyCommand.Name) -CategoryTargetName $aServer -CategoryTargetType 'Server'
         }

      # Return the Connection regardless of State 'Open' or not
         Write-Output -InputObject $conn

      } # % $Server

   } # Process

   End {

      if ($writeServerArray) {
         Write-Warning -Message 'Server List'
         [int] $i = -1
         $Server | % {
            $i += 1
            Write-Warning -Message "Server[${i}]: ${_}"
         }      
      }

   } # End

} # function New-PostgreSqlConnection
