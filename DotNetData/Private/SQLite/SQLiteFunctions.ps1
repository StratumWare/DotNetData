
#[int] $Script:DefaultCommandTimeout = 300 # default is 30

function Initialize-SQLiteConnectionStringBuilder {
   [CmdletBinding(PositionalBinding = $false)]
   [OutputType([Data.Common.DbConnection[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [System.Data.SQLite.SQLiteConnectionStringBuilder[]] $ConnectionStringBuilder
   )

   Begin {
   }

   Process {

      $ConnectionStringBuilder | % {
         [System.Data.SQLite.SQLiteConnectionStringBuilder] $csb = $_

         $csb.Clear()

<#
   int CacheSize
   string DataSource
   int DefaultTimeout
   bool ForeignKeys
   bool FailIfMissing
   SQLiteJournalModeEnum JournalMode
   long MmapSize
   int PageSize
   string Password
   bool ReadOnly
   SynchronizationModes SyncMode
   SQLiteTemporaryStore TempStore
   long JournalSizeLimit
   bool PersistWal
   enum SQLiteJournalModeEnum
   enum SynchronizationModes
   enum SQLiteTemporaryStore
#>

#          $csb['CacheSize'] = ???
#          $csb['DataSource'] = ???
#          $csb['DefaultTimeout'] = ???
#          $csb['ForeignKeys'] = ???
#          $csb['FailIfMissing'] = ???
#          $csb['JournalMode'] = ???
#          $csb['MmapSize'] = ???
#          $csb['PageSize'] = ???
#          $csb['Password'] = ???
<# Keyword not supported: 'ReadOnly'.
          $csb['ReadOnly'] = $false
#>
#          $csb['SyncMode'] = ???
#          $csb['TempStore'] = ???
#          $csb['JournalSizeLimit'] = ???
#          $csb['PersistWal'] = ???
#          $csb['SQLiteJournalModeEnum'] = ???
#          $csb['SynchronizationModes'] = ???
#          $csb['SQLiteTemporaryStore'] = ???

      } # % $ConnectionStringBuilder

   } # Process

   End {
   }

}
