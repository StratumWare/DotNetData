<# Private/Oracle/OracleFunctions.ps1
#>

function Initialize-OracleConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Oracle.DataAccess.Client.OracleConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [Oracle.DataAccess.Client.OracleConnectionStringBuilder] $csb = $_

         $csb.Clear()

#         $csb['???'] = 

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}
