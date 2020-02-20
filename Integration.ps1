#path of a nagios file 
pscp -pw sopr@@123 root@10.133.104.9:/usr/local/nagios/var/nagios.log D:\|out-null
Start-Sleep -s 2
$nagiospath="D:\nagios.log"
$LogPat="D:\Create_incident_Log\create_Incident.text"
#filtering service alert string from the log file 
$seclaststring=[int]((((gc $nagiospath|select-string -Pattern "SERVICE ALERT"|select -last 2|select -First 1|out-string).trim()).split("]")[0]).Replace("[",""))
$laststring=[int]((((gc $nagiospath|select-string -Pattern "SERVICE ALERT"|select -last 1|out-string).trim()).split("]")[0]).Replace("[",""))
$diff=$laststring - $seclaststring
Start-Sleep -s 1
if( $diff -ge 0 ){
    $last_Line=((gc $nagiospath|select-string -Pattern "SERVICE ALERT"|select -last 1|out-string).trim())
	$title=((((gc $nagiospath|select-string -Pattern "SERVICE ALERT"|select -last 1|out-string).trim()).split(":")[0]).split("]")[1]).trim()
	$Description=(((gc $nagiospath|select-string -Pattern "SERVICE ALERT"|select -last 1|out-string).trim()).split(":")[1])+": Stopped"
	if ($Description.Contains("Stopped") -eq "True"){
                 function Execute-SOAPRequest_CreateIncident
                      ( 
                           [Xml]    $SOAPRequest, 
                           [String] $URL 
                      ) 
                    { 
                        #write-host "Sending SOAP Request To Server: $URL" 
                        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                        $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")            
                        $soapWebRequest.Headers.Add("SOAPAction", "Create")
                        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
                        $soapWebRequest.Accept      = "text/xml" 
                        $soapWebRequest.Method      = "POST" 
                        #write-host "Initiating Send." 
                        $requestStream = $soapWebRequest.GetRequestStream() 
                        $SOAPRequest.Save($requestStream) 
                        $requestStream.Close() 
                        #write-host "Send Complete, Waiting For Response." 
                        $resp = $soapWebRequest.GetResponse() 
                        $responseStream = $resp.GetResponseStream() 
                        $soapReader = [System.IO.StreamReader]($responseStream) 
                        #write-host $soapReader.ReadToEnd() 
                        $ReturnXml = ($soapReader.ReadToEnd()) 
                        $responseStream.Close() 
                        #write-host "Response Received."
                        #write-host $ReturnXml
						return $ReturnXml 
                    }
Start-Sleep -s 1
$url = 'http://10.153.64.181:15098/SM/7/IncidentManagement.wsdl'
$soap = [xml]@"
<?xml version="1.0" encoding="UTF-8"?>
<soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com=`"http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:CreateIncidentRequest>
         <ns:model>
            <ns:keys>
            </ns:keys>
            <ns:instance>
               <ns:Category>incident</ns:Category>
               <ns:Area>HPOM</ns:Area>
               <ns:Subarea>MONITORING</ns:Subarea>
               <ns:Impact>1</ns:Impact>
               <ns:Urgency>1</ns:Urgency>
               <ns:AssignmentGroup>STERIA_IN_AUTO</ns:AssignmentGroup>
               <ns:OpenedBy> </ns:OpenedBy>
               <ns:Description>
                  <ns:Description>$Description</ns:Description>
               </ns:Description>
               <ns:Company>STERIA</ns:Company>
               <ns:Title>$title</ns:Title>
               <ns:Service>TEST</ns:Service>
               <ns:AffectedCI></ns:AffectedCI>
               <ns:Contact>STERIA_PRASHANT_PANDEY_682594</ns:Contact>
            </ns:instance>
         </ns:model>
      </ns:CreateIncidentRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@
$ret_CreateIncident = Execute-SOAPRequest_CreateIncident $soap $url
Start-Sleep -s 1
$RetriveIncidentData_Desc=([xml]$ret_CreateIncident).GetElementsByTagName("Description").'#text'
$RetriveIncidentData_Description=($RetriveIncidentData_Desc|out-string).trim()
$RetriveIncidentData_Title=([xml]$ret_CreateIncident).GetElementsByTagName("Title").'#text'
$RetriveIncidentData_Affectedci=([xml]$ret_CreateIncident).GetElementsByTagName("Logical.Name").'#text'
$RetriveIncidentData_Affectedci="10.133.104.28"
$RetriveIncidentData_IncidentID=(([xml]$ret_CreateIncident).GetElementsByTagName("IncidentID").'#text')[0]
$RetriveIncidentData_AssignmentGroup=([xml]$ret_CreateIncident).GetElementsByTagName("AssignmentGroup").'#text'
$RetriveIncidentData_Assignee=([xml]$ret_CreateIncident).GetElementsByTagName("Assignee").'#text'
$RetriveIncidentData_Phase=([xml]$ret_CreateIncident).GetElementsByTagName("Phase").'#text'
$RetriveIncidentData_Statuss=([xml]$ret_CreateIncident).GetElementsByTagName("Status").'#text'
Add-Content -Path $LogPat -Value ("-"*(($(((Get-Host).UI.RawUI).BufferSize).Width)-1))
Add-Content -Path $LogPat -Value "$RetriveIncidentData_IncidentID has been Logged at $(get-date -Format "dd:MM:yyyy_hh:mm:ss") with below details:-`r`nINCIDENT NO :: $RetriveIncidentData_IncidentID`r`nSTATUS :: $RetriveIncidentData_Statuss`r`nASSIGNMENT GROUP :: $RetriveIncidentData_AssignmentGroup`r`nTITLE :: $RetriveIncidentData_Title`r`nDESCRIPTION :: $RetriveIncidentData_Description`r`nAFFECTED_CI :: $RetriveIncidentData_Affectedci`r`nPHASE :: $RetriveIncidentData_Phase"
Start-Sleep -s 2
}else {
    Add-Content -Path $LogPat -Value ("-"*(($(((Get-Host).UI.RawUI).BufferSize).Width)-1))
	Add-Content -Path $LogPat -Value "Execute time stamp :: $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"
       }
}

Start-Sleep -s 10
$Timestamp=get-date -Format "dd:MM:yyyy_hh:mm:ss"
###Start of Function for fetching the list from stars ###
function Execute-SOAPRequest_RetrieveList 
( 
        [Xml]    $SOAPRequest, 
        [String] $URL 
) 
{ 
        #write-host "Sending SOAP Request To Server: $URL" 
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                                $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")            
                                $soapWebRequest.Headers.Add("SOAPAction", "RetrieveList")


        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
                                #write-host $soapReader.ReadToEnd() 
        $ReturnXml = ($soapReader.ReadToEnd()) 
        $responseStream.Close() 
                                
                                
        
        #write-host "Response Received."
        #write-host $ReturnXml

        return $ReturnXml 
}
####End of Retrieve List Function###
###Start of resolving function###
function Execute-SOAPRequest_Resolve 
( 
        [Xml]    $SOAPRequest, 
        [String] $URL 
) 
{ 
        #write-host "Sending SOAP Request To Server: $URL" 
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                                $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")      
                                $soapWebRequest.Headers.Add("SOAPAction", "Resolve")


        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
                                #write-host $soapReader.ReadToEnd() 
        $ReturnXml = ($soapReader.ReadToEnd()) 
        $responseStream.Close() 
                                
                                
        
        #write-host "Response Received."
        #write-host $ReturnXml

        return $ReturnXml 
}

###End Of Close###
### Start Of a Function To Update The Ticket ### 
function Execute-SOAPRequest_Update
( 
        [Xml]    $SOAPRequest, 
        [String] $URL 
) 
{ 
        #write-host "Sending SOAP Request To Server: $URL" 
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                                $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")      
                                $soapWebRequest.Headers.Add("SOAPAction", "Update")


        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
                                #write-host $soapReader.ReadToEnd() 
        $ReturnXml = ($soapReader.ReadToEnd()) 
        $responseStream.Close() 
                                
                                
        
        #write-host "Response Received."
        #write-host $ReturnXml

        return $ReturnXml 
}

###End of Update Function###
###Start of a Function to Close the Ticket ###
function Execute-SOAPRequest_Close 
( 
        [Xml]    $SOAPRequest, 
        [String] $URL 
) 
{ 
        #write-host "Sending SOAP Request To Server: $URL" 
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                                $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")      
                                $soapWebRequest.Headers.Add("SOAPAction", "Close")


        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
                                #write-host $soapReader.ReadToEnd() 
        $ReturnXml = ($soapReader.ReadToEnd()) 
        $responseStream.Close() 
                                
                                
        
        #write-host "Response Received."
        #write-host $ReturnXml

        return $ReturnXml 
}

###End of Close Function ###
### Start Of a Retrive The Single Incident Data ###
function Execute-SOAPRequest_RetriveIncidentData 
( 
        [Xml]    $SOAPRequest, 
        [String] $URL 
) 
{ 
        #write-host "Sending SOAP Request To Server: $URL" 
        $soapWebRequest = [System.Net.WebRequest]::Create($URL) 
                                $soapWebRequest.Credentials = new-object System.Net.NetworkCredential("praspandey", "steria@12345")      
                                $soapWebRequest.Headers.Add("SOAPAction", "Retrieve")


        $soapWebRequest.ContentType = "text/xml;charset=`"utf-8`"" 
        $soapWebRequest.Accept      = "text/xml" 
        $soapWebRequest.Method      = "POST" 
        
        #write-host "Initiating Send." 
        $requestStream = $soapWebRequest.GetRequestStream() 
        $SOAPRequest.Save($requestStream) 
        $requestStream.Close() 
        
        #write-host "Send Complete, Waiting For Response." 
        $resp = $soapWebRequest.GetResponse() 
        $responseStream = $resp.GetResponseStream() 
        $soapReader = [System.IO.StreamReader]($responseStream) 
                                #write-host $soapReader.ReadToEnd() 
        $ReturnXml = $soapReader.ReadToEnd() 
        $responseStream.Close() 
                                
                                
        
        #write-host "Response Received."
        #write-host $ReturnXml

        return $ReturnXml 
}
Start-Sleep -s 2
###End of Retrieve Function ###
###Declaring the Url ###
$url = 'http://10.153.64.181:15098/SM/7/IncidentManagement.wsdl'
$soap = [xml]@'
<soapenv:Envelope xmlns:soapenv="http://schemas.xmlsoap.org/soap/envelope/" xmlns:ns="http://schemas.hp.com/SM/7" xmlns:com="http://schemas.hp.com/SM/7/Common" xmlns:xm="http://www.w3.org/2005/05/xmlmime">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:RetrieveIncidentList>
         <ns:model>
            <ns:keys query = "AssignmentGroup=&quot;STERIA_IN_AUTO&quot;and problem.status=&quot;Open&quot;" >
               <!--Optional:-->
			   
			   </ns:keys>
            <ns:instance />
         </ns:model>
       </ns:RetrieveIncidentList>
   </soapenv:Body>
</soapenv:Envelope>
'@
$ret_RetrieveList = Execute-SOAPRequest_RetrieveList $soap $url
Start-Sleep -s 2
$Incident_Count=(([xml]$ret_RetrieveList).Envelope.Body.RetrieveIncidentListResponse.Instance.IncidentID).'#text'

foreach($incident in $Incident_Count){ 

$soap_IncidentStatus = [xml]@"
 <soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com=`"http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
    <soapenv:Header/>
    <soapenv:Body>
       <ns:RetrieveIncidentRequest >
          <ns:model>
             <ns:keys >
                <!--Optional:-->
                <ns:IncidentID >$Incident</ns:IncidentID>
             </ns:keys>
             <ns:instance />
          </ns:model>
       </ns:RetrieveIncidentRequest>
    </soapenv:Body>
 </soapenv:Envelope>
"@
$ret_RetriveIncidentData = Execute-SOAPRequest_RetriveIncidentData $soap_IncidentStatus $url
$RetriveIncidentData_Status=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Status").'#text'
Start-Sleep -s 1
#write-host "INCIDENT NUMBER::" $Incident "WITH STATUS:" $RetriveIncidentData_Status
Start-Sleep -s 1

$RetriveIncidentData_Desc=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Description").'#text'
$RetriveIncidentData_Description=($RetriveIncidentData_Desc|out-string).trim()
$RetriveIncidentData_Title=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Title").'#text'
$RetriveIncidentData_Affectedci=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Logical.Name").'#text'
$RetriveIncidentData_Affectedci="10.133.104.28"
$RetriveIncidentData_IncidentID=([xml]$ret_RetriveIncidentData).GetElementsByTagName("IncidentID").'#text'
$RetriveIncidentData_AssignmentGroup=([xml]$ret_RetriveIncidentData).GetElementsByTagName("AssignmentGroup").'#text'
$RetriveIncidentData_Assignee=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Assignee").'#text'
$RetriveIncidentData_Phase=([xml]$ret_RetriveIncidentData).GetElementsByTagName("Phase").'#text'
$Servicename="BITS"
If ($RetriveIncidentData_Status  -eq 'Work In Progress' -or $RetriveIncidentData_Status  -eq 'Open')  {
    $LogPath="D:\Star_Ticket_Log\$incident.txt"
	Add-Content -Path $LogPath -Value "Activity Started time :: $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"
	Start-Sleep -s 1
    Add-Content -Path $LogPath -Value ("-"*(($(((Get-Host).UI.RawUI).BufferSize).Width)-1))
	Start-Sleep -s 1
	Add-Content -Path $LogPath -Value "Incident assigned for the Automatic execution at $(get-date -Format "dd:MM:yyyy_hh:mm:ss") with below details:-`r`nINCIDENT NO :: $incident`r`nSTATUS :: $RetriveIncidentData_Status`r`nASSIGNMENT GROUP :: $RetriveIncidentData_AssignmentGroup`r`nASSIGNEE :: $RetriveIncidentData_Assignee`r`nTITLE :: $RetriveIncidentData_Title`r`nDESCRIPTION :: $RetriveIncidentData_Description`r`nAFFECTED_CI :: $RetriveIncidentData_Affectedci`r`nPHASE :: $RetriveIncidentData_Phase"
	Start-Sleep -s 2
    $soap_UpdateIncident = [xml]@"
<soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com=`"http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:UpdateIncidentRequest>
         <ns:model>
            <ns:keys query = "number=&quot;$incident&quot;" >
               <!--Optional:-->
            </ns:keys>
            <ns:instance>
               <ns:JournalUpdates type="StringType">Incident assigned for the Automatic execution at $Timestamp</ns:JournalUpdates>
             </ns:instance >
         </ns:model>
       </ns:UpdateIncidentRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@
$ret_Update = Execute-SOAPRequest_Update $soap_UpdateIncident $url
Start-Sleep -s 1
       
     If (($RetriveIncidentData_Description|out-string).contains('Service') -eq "True" ) {
           $username = "AUTOPOCTEST\praspandey"
           $password = convertto-securestring -String "sopra@123" -AsPlainText -Force
           $cred = new-object -typename System.Management.Automation.PSCredential -argumentlist $username, $password
           $resul=Invoke-Command -ComputerName 10.133.104.28 -Credential $cred -ScriptBlock{ $Servicename="BITS";if (((gsv $Servicename).Status) -eq 'Stopped'){ gsv $Servicename|Start-Service;Write-host "Currently Service name $($Servicename) is in  $(((gsv $Servicename).Status)) Status"  }else {"Given Service name $($Servicename)  is in $(((gsv $Servicename).Status)) status" }; }   
		   $result= ($resul|out-string)
		   #Add-Content -Path $LogPath -Value "`n"
		   Start-Sleep -s 1
		   Add-Content -Path $LogPath -Value "Resolution :: $($result)"
		   Start-Sleep -s 1
		   
		   $soap_UpdateIncident = [xml]@"
<soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com=`"http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:UpdateIncidentRequest>
         <ns:model>
            <ns:keys query = "number=&quot;$incident&quot;" >
               <!--Optional:-->
            </ns:keys>
            <ns:instance>
               <ns:JournalUpdates type="StringType">Action Taken At time $(get-date -Format "dd:MM:yyyy_hh:mm:ss") with the output $result</ns:JournalUpdates>
             </ns:instance >
         </ns:model>
       </ns:UpdateIncidentRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@
$ret_Update = Execute-SOAPRequest_Update $soap_UpdateIncident $url
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "Activity Updated on $incident at $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "`n"
Start-Sleep -s 1
$soap_Resolve = [xml]@"
<soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com="http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:ResolveIncidentRequest >
         <ns:model>
            <ns:keys query = "number=&quot;$incident&quot;" >
               <!--Optional:-->
               
            </ns:keys>
              
              <ns:instance />
         </ns:model>
      </ns:ResolveIncidentRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@
$ret_Resolve = Execute-SOAPRequest_Resolve $soap_Resolve $url
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "$incident has been Resolve at $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "`n"
Start-Sleep -s 1
$soap_Close = [xml]@"
<soapenv:Envelope xmlns:soapenv=`"http://schemas.xmlsoap.org/soap/envelope/`" xmlns:ns=`"http://schemas.hp.com/SM/7`" xmlns:com=`"http://schemas.hp.com/SM/7/Common`" xmlns:xm=`"http://www.w3.org/2005/05/xmlmime`">
   <soapenv:Header/>
   <soapenv:Body>
      <ns:CloseIncidentRequest >
         <ns:model>
            <ns:keys query = "number=&quot;$incident&quot;" >
               <!--Optional:-->
            </ns:keys>
            <ns:instance>
              <ns:status>Closed</ns:status>
              <ns:ClosureCode>Code Fix</ns:ClosureCode>
			  
              <ns:message>Resolution has been provided with the status $result $(get-date -Format "dd:MM:yyyy_hh:mm:ss") </ns:message>
              <ns:Solution>Resolution has been provided with the status $result $(get-date -Format "dd:MM:yyyy_hh:mm:ss")</ns:Solution>
			  
			  
            </ns:instance>
              
         </ns:model>
      </ns:CloseIncidentRequest>
   </soapenv:Body>
</soapenv:Envelope>
"@
$ret_Close = Execute-SOAPRequest_Close $soap_Close $url
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "$incident has been closed at $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "`n"
Start-Sleep -s 1
Add-Content -Path $LogPath -Value ("-"*(($(((Get-Host).UI.RawUI).BufferSize).Width)-1))	
Start-Sleep -s 1
Add-Content -Path $LogPath -Value "Activity End time :: $(get-date -Format "dd:MM:yyyy_hh:mm:ss")"	   
Start-Sleep -s 1
       }Else{ 
"False Alert"
             }
        }Else{ 
"False Alert"
             }
    }
