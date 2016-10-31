#################################################################################  
## Top 5 Highly Utilized Folder 
## Created by Prashant Dev Pandey  
## Date : 20 OCT 2016  
## Version : 1.0  
## Email: pdppandey@hotmail.com    
## This scripts check  the top utilized folder in a drive like "C:\" etc  
## Output will generate in Html format in specified path
## These script and functions are tested in my environment and it is recommended that you test these scripts in a test environment before using in your production environment.
################################################################################ 


$Style = "<style>
TABLE{ border-width: 1px;border-style: solid;border-color: black;border-collapse: collapse;align:center;margin-left:auto; margin-right:auto;}
TH{background-color:darkgray;border-width: 1px;bgcolor=#FF0000;padding: 3px;border-style: solid;border-color: black;}
TD{border-width: 1px;padding: 3px;border-style: solid;border-color: black;}
h1{text-shadow: 1px 1px 1px #000,3px 3px 5px blue; text-align: center;font-style: calibri;font-family: Calibri;
</style>";

get-ChildItem -path "D:\" -recurse -ErrorAction "SilentlyContinue" | ? { $_.GetType().Name -eq "FileInfo" } | where-Object {$_.Length -gt 0} | sort-Object -property length -Descending| Select-Object @{Name="Path";Expression={$_.directory}} -first 5|select -Unique Path|foreach {gci $_.Path -recurse -ErrorAction "SilentlyContinue"|Where-Object {$_.PSParentPath -notmatch "Program Files|Users|Windows"}|? { $_.GetType().Name -eq "FileInfo" }|select -Property Directory,FullName,@{Name="SIZE(MB)";Expression={[decimal]("{0:N2}" -f($_.Length / 1mb))}}|sort-object @{Expression="SIZE(MB)";Descending=$true}|select -first 5}|ConvertTo-Html -head $style -title "Process Information" -body "<H2 bgcolor=blue align=center>TOP DISK UTILIZATION ${IssueSubject} </H2>"|out-file C:\Scripts\DiskUtilization.html

