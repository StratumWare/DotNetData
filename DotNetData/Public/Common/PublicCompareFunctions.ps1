<#
#>


[int] $Script:DefaultCommandTimeout = 30
[int] $Script:LongCommandTimeout = 600


<# Database Permissions
#>

function Compare-DatabasePermissions {
   [CmdletBinding(PositionalBinding = $false, SupportsShouldProcess = $true)]
   [OutputType([Data.DataRow[]])]
   Param(
      [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
      [ValidateCount(2, 2)]
      [Data.Common.DbConnection[]] $Connection,
      [Parameter(Position = 2, Mandatory = $false, ValueFromPipeline = $false)]
      [int] $CommandTimeout = $Script:LongCommandTimeout,
      [Parameter(Mandatory = $false, ValueFromPipeline = $false)]
      [AllowNull()]
      [Management.Automation.CallStackFrame] $CallStackFrame = $NULL
   )

   Begin {

      [Collections.Generic.List[Data.Common.DbConnection]] $dbConnList = New-Object -TypeName 'Collections.Generic.List[Data.Common.DbConnection]'

   } # Begin

   Process {

      $Connection | % {
         $dbConnList.Add($_)
      }

   }

   End {

      [Data.Common.DbDataAdapter[]] $dataAdapters, [string[]] $matchColumns, [string[]] $compareColumns = Get-DataAdapterForDatabasePermissions -Connection $dbConnList -CommandTimeout $CommandTimeout

      $objList.Clear()

      Compare-DataFromTwoDataAdapters -DataAdapters $dataAdapters -MatchColumns $matchColumns -CompareColumns $compareColumns `
         -WhenMatched {
            param([Data.DataRow] $row1, [Data.DataRow] $row2, [int] $same, [int] $diff)
            if ($diff -eq 0) {
               [string] $comparison = "all ${same} same, none different"
            }
            else {
               [string] $comparison = "${same} same, ${diff} different"
            }
            [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
               'MatchStatus     '                   = 'Match'
               'Server_1'                           = $servers[0]
               'ServerName_1'                       = $row1['ServerName']
               'database_name_1'                    = $row1['database_name']
               'class_1'                            = $row1['class']
               'class_desc_1'                       = $row1['class_desc']
               'major_type_1'                       = $row1['major_type']
               'major_id_1'                         = $row1['major_id']
               'minor_id_1'                         = $row1['minor_id']
               'securable_type_1'                   = $row1['securable_type']
               'securable_type_desc_1'              = $row1['securable_type_desc']
               'securable_schema_name_1'            = $row1['securable_schema_name']
               'securable_major_id_1'               = $row1['securable_major_id']
               'securable_name_1'                   = $row1['securable_name']
               'securable_minor_id_1'               = $row1['securable_minor_id']
               'column_name_1'                      = $row1['column_name']
               'securable_qualified_name_1'         = $row1['securable_qualified_name']
               'owner_name_1'                       = $row1['owner_name']
               'owner_type_1'                       = $row1['owner_type']
               'owner_type_desc_1'                  = $row1['owner_type_desc']
               'owner_is_fixed_role_1'              = $row1['owner_is_fixed_role']
               'owner_authentication_type_1'        = $row1['owner_authentication_type']
               'owner_authentication_type_desc_1'   = $row1['owner_authentication_type_desc']
               'grantee_principal_id_1'             = $row1['grantee_principal_id']
               'grantor_principal_id_1'             = $row1['grantor_principal_id']
               'permission_type_1'                  = $row1['permission_type']
               'permission_name_1'                  = $row1['permission_name']
               'state_1'                            = $row1['state']
               'state_desc_1'                       = $row1['state_desc']
               'grantee_name_1'                     = $row1['grantee_name']
               'grantee_type_1'                     = $row1['grantee_type']
               'grantee_type_desc_1'                = $row1['grantee_type_desc']
               'grantee_is_fixed_role_1'            = $row1['grantee_is_fixed_role']
               'grantee_authentication_type_1'      = $row1['grantee_authentication_type']
               'grantee_authentication_type_desc_1' = $row1['grantee_authentication_type_desc']
               'grantor_name_1'                     = $row1['grantor_name']
               'grantor_type_1'                     = $row1['grantor_type']
               'grantor_type_desc_1'                = $row1['grantor_type_desc']
               'grantor_is_fixed_role_1'            = $row1['grantor_is_fixed_role']
               'grantor_authentication_type_1'      = $row1['grantor_authentication_type']
               'grantor_authentication_type_desc_1' = $row1['grantor_authentication_type_desc']
               'database_name_2'                    = $row2['database_name']
               'class_2'                            = $row2['class']
               'class_desc_2'                       = $row2['class_desc']
               'major_type_2'                       = $row2['major_type']
               'major_id_2'                         = $row2['major_id']
               'minor_id_2'                         = $row2['minor_id']
               'securable_type_2'                   = $row2['securable_type']
               'securable_type_desc_2'              = $row2['securable_type_desc']
               'securable_schema_name_2'            = $row2['securable_schema_name']
               'securable_major_id_2'               = $row2['securable_major_id']
               'securable_name_2'                   = $row2['securable_name']
               'securable_minor_id_2'               = $row2['securable_minor_id']
               'column_name_2'                      = $row2['column_name']
               'securable_qualified_name_2'         = $row2['securable_qualified_name']
               'owner_name_2'                       = $row2['owner_name']
               'owner_type_2'                       = $row2['owner_type']
               'owner_type_desc_2'                  = $row2['owner_type_desc']
               'owner_is_fixed_role_2'              = $row2['owner_is_fixed_role']
               'owner_authentication_type_2'        = $row2['owner_authentication_type']
               'owner_authentication_type_desc_2'   = $row2['owner_authentication_type_desc']
               'grantee_principal_id_2'             = $row2['grantee_principal_id']
               'grantor_principal_id_2'             = $row2['grantor_principal_id']
               'permission_type_2'                  = $row2['permission_type']
               'permission_name_2'                  = $row2['permission_name']
               'state_2'                            = $row2['state']
               'state_desc_2'                       = $row2['state_desc']
               'grantee_name_2'                     = $row2['grantee_name']
               'grantee_type_2'                     = $row2['grantee_type']
               'grantee_type_desc_2'                = $row2['grantee_type_desc']
               'grantee_is_fixed_role_2'            = $row2['grantee_is_fixed_role']
               'grantee_authentication_type_2'      = $row2['grantee_authentication_type']
               'grantee_authentication_type_desc_2' = $row2['grantee_authentication_type_desc']
               'grantor_name_2'                     = $row2['grantor_name']
               'grantor_type_2'                     = $row2['grantor_type']
               'grantor_type_desc_2'                = $row2['grantor_type_desc']
               'grantor_is_fixed_role_2'            = $row2['grantor_is_fixed_role']
               'grantor_authentication_type_2'      = $row2['grantor_authentication_type']
               'grantor_authentication_type_desc_2' = $row2['grantor_authentication_type_desc']
               'ServerName_2'                       = $row2['ServerName']
               'Server_2'                           = $servers[1]
               'Comparison'                         = $comparison
            })
            $objList.Add($obj)
         } `
         -WhenNotMatched {
            param([int] $which, [Data.DataRow] $row)
            if ($which -eq 1) {
               [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                  'MatchStatus     '                   = 'Extra / Missing'
                  'Server_1'                           = $servers[0]
                  'ServerName_1'                       = $row['ServerName']
                  'database_name_1'                    = $row['database_name']
                  'class_1'                            = $row['class']
                  'class_desc_1'                       = $row['class_desc']
                  'major_type_1'                       = $row['major_type']
                  'major_id_1'                         = $row['major_id']
                  'minor_id_1'                         = $row['minor_id']
                  'securable_type_1'                   = $row['securable_type']
                  'securable_type_desc_1'              = $row['securable_type_desc']
                  'securable_schema_name_1'            = $row['securable_schema_name']
                  'securable_major_id_1'               = $row['securable_major_id']
                  'securable_name_1'                   = $row['securable_name']
                  'securable_minor_id_1'               = $row['securable_minor_id']
                  'column_name_1'                      = $row['column_name']
                  'securable_qualified_name_1'         = $row['securable_qualified_name']
                  'owner_name_1'                       = $row['owner_name']
                  'owner_type_1'                       = $row['owner_type']
                  'owner_type_desc_1'                  = $row['owner_type_desc']
                  'owner_is_fixed_role_1'              = $row['owner_is_fixed_role']
                  'owner_authentication_type_1'        = $row['owner_authentication_type']
                  'owner_authentication_type_desc_1'   = $row['owner_authentication_type_desc']
                  'grantee_principal_id_1'             = $row['grantee_principal_id']
                  'grantor_principal_id_1'             = $row['grantor_principal_id']
                  'permission_type_1'                  = $row['permission_type']
                  'permission_name_1'                  = $row['permission_name']
                  'state_1'                            = $row['state']
                  'state_desc_1'                       = $row['state_desc']
                  'grantee_name_1'                     = $row['grantee_name']
                  'grantee_type_1'                     = $row['grantee_type']
                  'grantee_type_desc_1'                = $row['grantee_type_desc']
                  'grantee_is_fixed_role_1'            = $row['grantee_is_fixed_role']
                  'grantee_authentication_type_1'      = $row['grantee_authentication_type']
                  'grantee_authentication_type_desc_1' = $row['grantee_authentication_type_desc']
                  'grantor_name_1'                     = $row['grantor_name']
                  'grantor_type_1'                     = $row['grantor_type']
                  'grantor_type_desc_1'                = $row['grantor_type_desc']
                  'grantor_is_fixed_role_1'            = $row['grantor_is_fixed_role']
                  'grantor_authentication_type_1'      = $row['grantor_authentication_type']
                  'grantor_authentication_type_desc_1' = $row['grantor_authentication_type_desc']
                  'database_name_2'                    = ''
                  'class_2'                            = ''
                  'class_desc_2'                       = ''
                  'major_type_2'                       = ''
                  'major_id_2'                         = ''
                  'minor_id_2'                         = ''
                  'securable_type_2'                   = ''
                  'securable_type_desc_2'              = ''
                  'securable_schema_name_2'            = ''
                  'securable_major_id_2'               = ''
                  'securable_name_2'                   = ''
                  'securable_minor_id_2'               = ''
                  'column_name_2'                      = ''
                  'securable_qualified_name_2'         = ''
                  'owner_name_2'                       = ''
                  'owner_type_2'                       = ''
                  'owner_type_desc_2'                  = ''
                  'owner_is_fixed_role_2'              = ''
                  'owner_authentication_type_2'        = ''
                  'owner_authentication_type_desc_2'   = ''
                  'grantee_principal_id_2'             = ''
                  'grantor_principal_id_2'             = ''
                  'permission_type_2'                  = ''
                  'permission_name_2'                  = ''
                  'state_2'                            = ''
                  'state_desc_2'                       = ''
                  'grantee_name_2'                     = ''
                  'grantee_type_2'                     = ''
                  'grantee_type_desc_2'                = ''
                  'grantee_is_fixed_role_2'            = ''
                  'grantee_authentication_type_2'      = ''
                  'grantee_authentication_type_desc_2' = ''
                  'grantor_name_2'                     = ''
                  'grantor_type_2'                     = ''
                  'grantor_type_desc_2'                = ''
                  'grantor_is_fixed_role_2'            = ''
                  'grantor_authentication_type_2'      = ''
                  'grantor_authentication_type_desc_2' = ''
                  'ServerName_2'                       = ''
                  'Server_2'                           = $servers[1]
                  'Comparison'                         = ''
               })
            }
            else { # $which -eq 2
               [Object] $obj = New-Object -TypeName 'PSObject' -Property ([ordered]@{
                  'MatchStatus     '                   = 'Missing / Extra'
                  'Server_1'                           = $servers[0]
                  'ServerName_1'                       = ''
                  'database_name_1'                    = ''
                  'class_1'                            = ''
                  'class_desc_1'                       = ''
                  'major_type_1'                       = ''
                  'major_id_1'                         = ''
                  'minor_id_1'                         = ''
                  'securable_type_1'                   = ''
                  'securable_type_desc_1'              = ''
                  'securable_schema_name_1'            = ''
                  'securable_major_id_1'               = ''
                  'securable_name_1'                   = ''
                  'securable_minor_id_1'               = ''
                  'column_name_1'                      = ''
                  'securable_qualified_name_1'         = ''
                  'owner_name_1'                       = ''
                  'owner_type_1'                       = ''
                  'owner_type_desc_1'                  = ''
                  'owner_is_fixed_role_1'              = ''
                  'owner_authentication_type_1'        = ''
                  'owner_authentication_type_desc_1'   = ''
                  'grantee_principal_id_1'             = ''
                  'grantor_principal_id_1'             = ''
                  'permission_type_1'                  = ''
                  'permission_name_1'                  = ''
                  'state_1'                            = ''
                  'state_desc_1'                       = ''
                  'grantee_name_1'                     = ''
                  'grantee_type_1'                     = ''
                  'grantee_type_desc_1'                = ''
                  'grantee_is_fixed_role_1'            = ''
                  'grantee_authentication_type_1'      = ''
                  'grantee_authentication_type_desc_1' = ''
                  'grantor_name_1'                     = ''
                  'grantor_type_1'                     = ''
                  'grantor_type_desc_1'                = ''
                  'grantor_is_fixed_role_1'            = ''
                  'grantor_authentication_type_1'      = ''
                  'grantor_authentication_type_desc_1' = ''
                  'database_name_2'                    = $row['database_name']
                  'class_2'                            = $row['class']
                  'class_desc_2'                       = $row['class_desc']
                  'major_type_2'                       = $row['major_type']
                  'major_id_2'                         = $row['major_id']
                  'minor_id_2'                         = $row['minor_id']
                  'securable_type_2'                   = $row['securable_type']
                  'securable_type_desc_2'              = $row['securable_type_desc']
                  'securable_schema_name_2'            = $row['securable_schema_name']
                  'securable_major_id_2'               = $row['securable_major_id']
                  'securable_name_2'                   = $row['securable_name']
                  'securable_minor_id_2'               = $row['securable_minor_id']
                  'column_name_2'                      = $row['column_name']
                  'securable_qualified_name_2'         = $row['securable_qualified_name']
                  'owner_name_2'                       = $row['owner_name']
                  'owner_type_2'                       = $row['owner_type']
                  'owner_type_desc_2'                  = $row['owner_type_desc']
                  'owner_is_fixed_role_2'              = $row['owner_is_fixed_role']
                  'owner_authentication_type_2'        = $row['owner_authentication_type']
                  'owner_authentication_type_desc_2'   = $row['owner_authentication_type_desc']
                  'grantee_principal_id_2'             = $row['grantee_principal_id']
                  'grantor_principal_id_2'             = $row['grantor_principal_id']
                  'permission_type_2'                  = $row['permission_type']
                  'permission_name_2'                  = $row['permission_name']
                  'state_2'                            = $row['state']
                  'state_desc_2'                       = $row['state_desc']
                  'grantee_name_2'                     = $row['grantee_name']
                  'grantee_type_2'                     = $row['grantee_type']
                  'grantee_type_desc_2'                = $row['grantee_type_desc']
                  'grantee_is_fixed_role_2'            = $row['grantee_is_fixed_role']
                  'grantee_authentication_type_2'      = $row['grantee_authentication_type']
                  'grantee_authentication_type_desc_2' = $row['grantee_authentication_type_desc']
                  'grantor_name_2'                     = $row['grantor_name']
                  'grantor_type_2'                     = $row['grantor_type']
                  'grantor_type_desc_2'                = $row['grantor_type_desc']
                  'grantor_is_fixed_role_2'            = $row['grantor_is_fixed_role']
                  'grantor_authentication_type_2'      = $row['grantor_authentication_type']
                  'grantor_authentication_type_desc_2' = $row['grantor_authentication_type_desc']
                  'ServerName_2'                       = $row['ServerName']
                  'Comparison'                         = ''
               })
            }
            $objList.Add($obj)
         } # -WhenNotMatched

      $dataAdapters | % {
         $_.Dispose()
      }

      return $objList

   } # End

}
