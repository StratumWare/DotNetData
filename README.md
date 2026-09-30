# DotNetData
## PowerShell implementation of .NET Data

Returns rows of data from database as PowerShell objects, rather than just one line of text data per row.
This allows writing PowerShell code to perform operations involving different database instances or even different DBMS instances.
For example, data can be merged from different DBMS or synchronized from one database instance into another DBMS instance.
The original use case that prompted creating this code was synchronizing data in many edge MySQL instances with a centralized SQL Server instance.

Database Management Systems (DBMS) currently supported:
+ Microsoft SQL Server
+ MySQL from Oracle
+ Oracle
+ PostgreSQL
+ SQLite

CODE HERE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

### Usage
1. Download the `DotNetData.zip` archive file.
1. Extract the archive under one of directories in `$env:PSModulePath`, such as `C:\Program Files\WindowsPowerShell\Modules`.

### Design
This module uses a Class-to-Cmdlet Mapping style, rather than a more generic style, to provide the abstraction among the various DBMS, mirroring the .NET abstraction for the underlying DBMS engines. There is simply just a thin wrapper directly over the ADO.NET classes.
#### Advantages
1. The thin wrapper provides better visibility of the underlying ADO.NET classes to the developer. The raw, underlying .NET driver mechanics are exposed to the developer.
1. With the thin wrapper, cmdlet names and parameter behavior map almost 1-to-1 with the native classes. If you already are familiar with writing ADO.NET code in other languages, such as C#, writing the PowerShell code should be fairly easy.
1. The exposure of the underlying mechanics makes troubleshooting easier. If something goes wrong, you get the exact, unadulterated exception thrown by the underlying database driver, making the stack traces incredibly precise. (Unfortunately, this also exposes any flaws in the vendor's database driver, such as the case-sensitivity mismatch in the MySQL driver mentioned below - these flaws should be addressed directly with the driver vendor.)
1. The Class-to-Cmdlet abstraction avoids the "Lowest Common Denominator" limitation that would be imposed by a unified abstraction style.
1. Because it doesn't hide the underlying .NET data types, the developer has complete access to and control of vendor-specific features, data types and optimization hooks, such as query timeouts and memory-buffer tuning.

#### Connecting from an untrusted domain

When connecting to a database instance in one domain from another domain, where there is no trust relationship between those domains, `runas /netonly` can be used to provide authorization.

Using Integrated Security, if there is no trust relationship between the client domain and the server domain, an exception is thrown:

```New-SqlServerConnection : Exception calling "Open" with "0" argument(s): "Login failed. The login is from an untrusted domain and cannot be used with Integrated authentication."```

Running PowerShell with `runas /netonly` allows specifying the credentials for the target domain:

```runas /netonly /user:DOMAIN\username PowerShell_ise```

### Examples
See the files in the Examples directory for examples for each DBMS.

3. Try out some of the test scripts located in the `Examples` directory.
   For each example script:
   - Edit the example with a specific server name and username
   - Execute the test script in PowerShell

### Potential Issues

+ `Error: The field or property: “Datetime” for type: “MySql.Data.MySqlClient.MySqlDbType” differs only in letter casing from the field or property: “DateTime”. The type must be Common Language Specification (CLS) compliant.`\
This is a result of the existence of both DateTime and Datetime in case-insensitive DBMS libraries which violates the requirement (CA1708) in the case-sensitivite CLS runtime and its support of case-insensitive languages, where unique identifiers are required to be different by more than just their letter case. The error occurs when the class (`MySql.Data.MySqlCient.MySqlDbType`) is referenced and therefore occurs for any DB type, not just `DateTime`, such as:
```powershell
[MySql.Data.MySqlCient.MySqlDbType]::VarChar
```
As a workaround, use GetMember to get the constant value for the DB type, as in the following example for `VarChar`:
```powershell
[MySql.Data.MySqlClient.MySqlDbType].GetMember('VarChar').GetRawConstantValue()
```

+ `System.Management.Automation.MethodInvocationException Exception calling "Fill" with "1" argument(s): "Input string was not in a correct format."\
System.Management.Automation.ParentContainsErrorRecordException Exception calling "Fill" with "1" argument(s): "Input string was not in a correct format."\
System.FormatException Input string was not in a correct format.`\
Check the data type and length of the Parameter(s) in the DataAdapter:\
`Write-Verbose -Message "Type: $($da.SelectCommand.Parameters['@param1'].MySqlDbType) Size: $($da.SelectCommand.Parameters['@param1'].Size)"`\
Be sure to include the length for any data type that is not a fixed size:
```powershell
[void] $da.SelectCommand.Parameters.Add('@param1', [MySql.Data.MySqlClient.MySqlDbType].GetMember('VarChar').GetRawConstantValue(), 255)
```
