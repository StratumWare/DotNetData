<#

# IMPL: PostgreSQL Providers classes:
# Open Source: [Npgsql.NpgsqlConnectionStringBuilder]
# Commercial:  [Devart.Data.PostgreSql.PgSqlConnectionStringBuilder], [Devart.Data.PostgreSql.PgSqlConnection]

#>

function Initialize-PostgreSqlConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [Npgsql.NpgsqlConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [Npgsql.NpgsqlConnectionStringBuilder] $csb = $_

         $csb.Clear()

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}
