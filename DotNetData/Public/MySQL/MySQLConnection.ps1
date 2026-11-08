
[Boolean] $Script:firstMySqlConn = $true

$Script:mycsb = $NULL

#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function New-MySqlConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [int] $Port = -1,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = 'MySQL',
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      [Management.Automation.ErrorRecord] $ex = $null
         # prevent variable from being optimized in nested scopes

      if ($CallStackFrame -eq $NULL) {
         [Management.Automation.CallStackFrame] $CallStackFrame = (gcs)[1]
      }

   # Load MySql.Data.dll

      if ($Script:firstMySqlConn) {
         $firstMySqlConn = $false

         [Object] $mysqlConfig = Get-DotNetDataConfiguration -DBMS 'MySQL'

      # Load the DLL for MySQL Connector for .NET

         try {
            Import-Dll -UsingLoadWithPartialName -DllPath $mysqlConfig.DllPath
         }
         catch {
            return $null
         }

      } # if ($Script:firstMySqlConn)

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:mycsb -eq $NULL) {
         [MySql.Data.MySqlClient.MySqlConnectionStringBuilder] $Script:mycsb = New-Object -TypeName 'MySql.Data.MySqlClient.MySqlConnectionStringBuilder'
      }

   }

   Process {

   # When $Server is from "-Server" parameter, each item in [String[]] $Server list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $Server items to $queue at once)
      $Server | % {
         [String] $aServer = $_

         Initialize-MySqlConnectionStringBuilder -ConnectionStringBuilder $Script:mycsb
         $Script:mycsb['Server'] = $Server
         if ($Port -ge 0) {
            $Script:mycsb['Port'] = $Port
         }
         $Script:mycsb['Database'] = $DatabaseName
         $Script:mycsb['UserID'] = $UserName
         [Management.Automation.PSCredential] $Credential = Get-CredentialForUserName -UserName $UserName -Server $aServer -CallStackFrame $CallStackFrame
         if ($Credential -eq $NULL) {
            return $null
         }
         $Script:mycsb['UserID'] = $Credential.UserName
         $Script:mycsb['Password'] = $Credential.GetNetworkCredential().Password
         [string] $connstr = $Script:mycsb.ToString()

      # Connect to MySQL instance

            [MySql.Data.MySqlClient.MySqlConnection] $conn = New-Object -TypeName 'MySql.Data.MySqlClient.MySqlConnection' ($connstr)

            [String] $server = $connstr.Substring($connstr.IndexOf('server=') + 7, $connstr.IndexOf(';', $connstr.IndexOf('server=')) - $connstr.IndexOf('server=') - 7)
            Try {
               $conn.Open()
               if ($conn.State -ne 'Open') {
                  [String[]] $msgs = "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}", "$($MyInvocation.MyCommand.Name): Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
                  Write-Error -Message ($msgs -join [Environment]::NewLine) -Category ([Management.Automation.ErrorCategory]::ConnectionError) -CategoryReason 'MySqlConnection.Open failed' -CategoryTargetName $server -CategoryTargetType 'Server'
               }
            }
            Catch {
               [Management.Automation.ErrorRecord] $er = $_
               Write-Error -ErrorRecord $er -CategoryTargetName $server -CategoryTargetType 'Server'
            }

         # Return the Connection regardless of State 'Open' or not
            Write-Output -InputObject $conn

      } # % $Server

   } # Process

   End {
   }

}
