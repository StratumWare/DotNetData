<# Public/Oracle/OracleConnection.ps1
#>

[Oracle.DataAccess.Client.OracleConnectionStringBuilder] $Script:sscsb = $NULL

function New-OracleConnection {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [String[]] $Server,
      [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $false)]
      [ValidateRange(-1,65535)]
      [Int] $Port = -1,
      [Parameter(Position = 2, Mandatory = $true, ValueFromPipeline = $false)]
      [String] $UserName = [NullString]::Value,
      [Parameter(Position = 3, Mandatory = $false, ValueFromPipeline = $false)]
      [String] $DatabaseName = [NullString]::Value
   )

   Begin {

   # Initialize script variable - ConnectionStringBuilder

      if ($Script:sscsb -eq $NULL) {
         [Oracle.DataAccess.Client.OracleConnectionStringBuilder] $Script:sscsb = New-Object -TypeName 'Oracle.DataAccess.Client.OracleConnectionStringBuilder'
      }

   }

   Process {

   # When $Server is from "-Server" parameter, each item in [String[]] $Server list is processed separately
   # for each item, return a single connection for just one name in $queue (vs. adding all $Server items to $queue at once)
      $Server | % {
         [String] $aServer = $_

         Initialize-OracleConnectionStringBuilder -ConnectionStringBuilder $Script:sscsb

         [string] $connstr = $Script:sscsb.ToString()

      # Connect to Oracle instance

         [Oracle.DataAccess.Client.OracleConnection] $conn = New-Object -TypeName 'Oracle.DataAccess.Client.OracleConnection' ($connstr)

         Try {
            $conn.Open()
            if ($conn.State -ne 'Open') {
               [String[]] $msgs = "$($MyInvocation.MyCommand.Name): conn.Open() with Data Source=${server}", "Connection.Type             = $($conn.GetType().FullName)", "Connection.State            = $($conn.State)", "Connection.DataSource       = $($conn.DataSource)", "Connection.Database         = $($conn.Database)", "Connection.ConnectionString = $($conn.ConnectionString)"
               Write-Error -Message ($msgs -join [Environment]::NewLine) -Category ([Management.Automation.ErrorCategory]::ConnectionError) -CategoryReason 'OracleConnection.Open failed' -CategoryTargetName $aServer -CategoryTargetType 'Server'
            }
            return
         } # Try
         Catch {
            [Management.Automation.ErrorRecord] $er = $_
            Write-Error -ErrorRecord $er -CategoryTargetName $aServer -CategoryTargetType 'Server'
         } # Catch

      # Return the Connection regardless of State 'Open' or not
         Write-Output -InputObject $conn

      } # % $Server

   } # Process

   End {
   }

}
