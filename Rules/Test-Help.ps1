function Test-Help
{
    <#
    .Synopsis
        Tests the quality of a commands's help
    .Description
        Tests the quality of a command's help.  Checks for the following things:
        
        - Presence of a Help Topic
        - The same content in the synopsis and description
        - The presence of examples
        - The presence of links
    .Notes
        Version History            
            10/30/2011 - ScriptCop 1.5
                - Length of Synopsis should be less than 100 characters
            7/1/2011 - ScriptCop 1.2            
                - Links are present
            5/1/2011 - Initial Draft
                - Help Topic Exists
                - Synopsis -ne Description
                - Examples are present
            
            
                    
    #>
    param(
    [Parameter(ParameterSetName='TestHelpContent',ValueFromPipelineByPropertyName=$true)]   
    $HelpContent,
    
    [Parameter(ParameterSetName='TestHelpContent',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.CommandInfo]
    $HelpCommand
    )
    
    process {
        if (-not $HelpContent) {
            Write-Error "$HelpCommand does not have a help topic"
            return
        }
        
        $description = ($helpContent.Description | Out-String -Width 5kb).Trim()
        if ($HelpContent.Synopsis -eq $description) {
            Write-Error "$HelpCommand has the same synopsis and description"
        }
        
        
        if ($HelpContent.Synopsis.Length -gt 100) {
            Write-Error "I've heard that brevity is the soul of wit.  $HelpCommand has a synopsis that is over 100 characters long."
        }
        
        if (-not $helpContent.Examples) {
            Write-Error "$HelpCommand does not have examples"
        } else {
        
            $c = 0 
            foreach ($example in $helpContent.Examples.example) {
                $c++
                if (($example | Out-String) -notmatch "$HelpCommand") {
                    Write-Error "$HelpCommand example $c does not mention $helpCommand"
                }
            }
        }
        
        $parameterNames = ([Management.Automation.CommandMetaData]$helpCommand).Parameters.Keys
        $parametersWithoutHelp = @()
        foreach ($parameter in $parameterNames) {
            $parameterHasHelp = $helpContent.parameters.parameter | 
                ? { $_.Name -eq $parameter } | 
                Select-Object -ExpandProperty Description | 
                Select-Object -ExpandProperty Text
            if (-not $parameterHasHelp) {
                $parametersWithoutHelp += $parameter
            }
        }
        
        if ($parametersWithoutHelp) {
            Write-Error "Not all parameters in $helpCommand have help.  Parameters without help: $parametersWithoutHelp"
        }
        
        $relatedLinks = @(($helpContent.relatedLinks | Out-String).Trim())
        if (-not $relatedLinks) {
            Write-Error "No command is an island.  Please add at least one .LINK ."
        }

        
        
    }
} 
