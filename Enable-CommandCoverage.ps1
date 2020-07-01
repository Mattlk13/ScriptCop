function Enable-CommandCoverage
{
    <#
    .Synopsis
        Enables command coverage for a module
    .Description
        Enables command coverage for a PowerShell module.

        Command coverage tracks which functions are called, and which parameters are used.
    .Example
        Test-Module -Name ScriptCop -GetCommandCoverage # this will Enable-CommandCoverage
    .Example
        Enable-CommandCoverage -Module ScriptCop
        Test-Command -ScriptBlock {
            function foo() {
            }
        }
        Get-CommandCoverage -Module ScriptCop
        Disable-CommandCoverage -Module ScriptCop
    .Link
        Disable-CommandCoverage
    .Link
        Test-Module
    #>
    [OutputType([Nullable])]
    param(
    # The name of the module that will be instrumented for command coverage
    [Parameter(Mandatory=$true,Position=0,ValueFromPipelineByPropertyName=$true)]
    [Alias('Name')]
    [string]
    $Module
    )

    process {
        $Global:CommandCoverage = @{}
        #region Initialize Debugger Action
        $commandDebuggerAction = {
            $callstack = Get-PSCallStack
            $calledCommand = $callstack[1].InvocationInfo.InvocationName
            $commandParameters= $callstack[1].InvocationInfo.BoundParameters
            if (-not $global:CommandCoverage[$calledCommand]) {
                $global:CommandCoverage[$calledCommand] = New-Object Collections.ArrayList
            }
            $null = $global:CommandCoverage[$calledCommand].AddRange(@($commandParameters.Keys))
        }
        #endregion Initialize Debugger Action

        #region Create Command Breakpoints
        $moduleCommands = Get-Command -Module $module -commandType Function

        $null = @($moduleCommands | Where-Object { $_.CommandType -eq 'Function' } |
            ForEach-Object {
                Set-PSBreakpoint -Command $_ -Action $commandDebuggerAction
            })
        #endregion Create Command Breakpoints
    }


}
