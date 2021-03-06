function Test-DocumentationQuality
{
    #region     ScriptTokenValidation Parameter Statement
    param(
    <#    
    This parameter will contain the tokens in the script, and will be automatically 
    provided when this command is run within ScriptCop.
    
    This parameter should not be used directly, except for testing purposes.        
    #>
    [Parameter(ParameterSetName='TestScriptToken',
        Mandatory=$true,
        ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.PSToken[]]
    $ScriptToken,
    
    <#   
    This parameter will contain the command that was tokenized, and will be automatically
    provided when this command is run within ScriptCop.
    
    This parameter should not be used directly, except for testing purposes.
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [Management.Automation.CommandInfo]
    $ScriptTokenCommand,
    
    <#
    This parameter contains the raw text of the script, and will be automatically
    provided when this command is run within ScriptCop
    
    This parameter should not be used directly, except for testing purposes.    
    #>
    [Parameter(ParameterSetName='TestScriptToken',Mandatory=$true,ValueFromPipelineByPropertyName=$true)]
    [string]
    $ScriptText
    )
    #endregion  ScriptTokenValidation Parameter Statement
                
    
    process {    
        #region Comment Ratio
    
        # A quick tight little loop to sum
        # the lengths of different types in one 
        # pass (Group-Object would work, but would be slower)
        $commentLength= 0
        $otherLength = 0
        $totalLength = 0 
        foreach ($token in $ScriptToken) {
            $totalLength+=$token.Length
            if ($token.Type -eq 'Comment') {
                $commentLength+=$token.Length
            } else {
                $otherLength+=$token.Length
            }
        }
        
        # The percent is easy to calculate
        $percent =$commentLength * 100 / $totalLength 

        # As for arriving @ the RIGHT %, I asked StackOverflow:
        # http://stackoverflow.com/questions/111563/whats-the-golden-code-comment-ratio
        # Realized people could not agree, and that the low numbers thrown out there
        # had the best intent (say something, anything), and so picked 7.5%
        
        # Then realized inline help and regions would buck the trend a little, and
        # tried 12.5%.
        
        # Noticed a bunch of my own code that had good help, but little inline docs,
        # and settled upon one of two time-honored ratios.  
        # Pareto Principle, aka the 80/20 ratio
        # http://en.wikipedia.org/wiki/Pareto_principle
        if ($percent -lt 20) {
            Write-Error "Code is sparsely documented (Only $([Math]::Round($percent,2)) % comments)."
        }
        
        #endregion Comment Ratio                
        
        
        #region Check For Regions
        
        $hasRegion = $ScriptToken |
            Where-Object { 
                $_.Type -eq "Comment" -and (
                    $_.Content -like "#region*" -or 
                    $_.Content -like "#endregion*"
                ) 
            }
        
        if (-not $hasRegion) {
            $errorParams = @{
                Message ="$ScriptTokenCommand does not define any #regions"
                RecommendedAction="Add Regions"
                ErrorId="TestDocumentationQuality.AddRegions" 
            }
            Write-Error @errorParams
            return
        }
        
        #endregions
        
        
        #region Common Documentation Help Mistakes
        
        $dotExamples = $ScriptToken |
            Where-Object { 
                $_.Type -eq "Comment" -and $_.Content -like "*.examples*"
            }
            
        if ($dotExamples) {
            @{
                Message ="$ScriptTokenCommand has a common typo in comment based help, .EXAMPLES should be .EXAMPLE"                
                ErrorId="TestDocumentationQuality.DotExamples" 
                TargetObject = $dotExamples
            }
            return
        }
        

        $dotNote = $ScriptToken |
            Where-Object { 
                $_.Type -eq "Comment" -and $_.Content -like "*.note*" -and $_.Content -notlike "*.notes*"
            }
            
        if ($dotNote) {
            @{
                Message ="$ScriptTokenCommand has a common typo in comment based help, .NOTE should be .NOTES"                
                ErrorId="TestDocumentationQuality.DotNote" 
                TargetObject = $dotNote
            }
            return
        }


        $dotLinks = $ScriptToken |
            Where-Object { 
                $_.Type -eq "Comment" -and $_.Content -like "*.links*"
            }
            
        if ($dotLinks ) {
            @{
                Message ="$ScriptTokenCommand has a common typo in comment based help, .LINKS should be .LINK"                
                ErrorId="TestDocumentationQuality.DotLinks" 
                TargetObject = $dotLinks
            }
            return
        }

        #endregion
        
        
    }
} 
