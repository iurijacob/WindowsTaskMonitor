##################################################################################
# Author:Iuri Jacob
# Date: 2019-03-19
# modified: 2019-04-04
# Description: Script to monitor windows scheduled tasks. 
#				It checks for tasks failures in the last minutes and sends
#				e-mails alerts if such tasks exists.
##################################################################################

## Settings
$checkperiod = "-60"							# Last minutes to check for task failures (must be negative)
$matchtitle = "MyTask"							# Only tasks which title contains this string will be monitored
$matchfolder = "\MonitoredTasks"				# Only tasks within this folder will be monitored
$emailto = "monitor@mytask.com"					# sender e-mail 
$emailfrom = "monitor@mytask.com"				# receivers e-mail 
$smtpserver ="smtp.mytask.com"				
$smtpport="587"									
$smtpuser="user@mytask.com"			
$smtppassword="mytask password"						


# current date/time strings
$nowdate = get-date -format d
$nowtime = get-date -format t
$nowdate = $nowdate.ToString().Replace("/", "-")
$nowtime = $nowtime.ToString().Replace(":", "-")
$nowtime = $nowtime.ToString().Replace(" ", "")

# Log files
$pwlogs = ".\Logs" + "\" + "Powershell" + $nowdate + "_" + $nowtime + "_.txt"
$maillogs = ".\Logs" + "\" + "emailcheck" + $nowdate + "_.txt"

Start-Transcript -Path $pwlogs 

if((test-path $maillogs) -like $false)
{
	new-item $maillogs -type file
}

# Get the server list
$serverlist= Get-Content .\servers.txt

foreach ($server in $serverlist)
{
	$schedule = new-object -com("Schedule.Service")
	$schedule.connect("$server")
	$tasks = $schedule.getfolder(matchfolder).gettasks(0)

	# Get all tasks that contains $matchtitle in the title and has any failure in the last $checkperiod minutes
	$failures = $tasks | where-object{($_.LastTaskResult -ne 0) -and ($_.State -eq 3) -and ($_.Name -match $matchtitle)  -and ((get-date).addminutes($checkperiod) -lt $_.LastRunTime)}

	if ($failures -eq $Null)
	{
		 write-host "No task failed in the last minutes in the server $server"
	}
	else
	{
		# Sends an e-mail for each task found
		foreach ($task in $failures)
		{
			$b = $null > ".\Failures.txt"
			$task >> ".\Failures.txt"
			$taskdata = [IO.File]::ReadAllText($pwd.Path+"\Failures.txt")
			$taskskname = $task.Name
			$lastrun = $task.LastRunTime
			write-host "The task " + $taskskname + " have failed recently in server " + $server

			$subject ="[TaskMonitor][Failure]" + " - [" +$server + "]." + $taskskname  + " "+" Last run: " + $lastrun
			write-host "$subject" -ForegroundColor green

			add-content $maillogs $subject
			$body = $taskdata
			$message = new-object Net.Mail.MailMessage
			$smtp = new-object Net.Mail.SmtpClient($smtpserver, $smtpport)
			$smtp.Credentials = New-Object System.Net.NetworkCredential("$smtpuser", "$smtppassword") 
			$message.From = $emailfrom
			$message.To.Add($emailto)
			$message.body = $body
			$message.subject = $subject
			$message.IsBodyHTML = $false
			$smtp.Send($message)
			$message.dispose()

		}
	}
}

Stop-Transcript
