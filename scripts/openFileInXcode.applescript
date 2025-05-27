on run argv
	if (count of argv) is not 3 then
		display dialog "Three parameters are required: application name, file path, and line number." with icon stop
		return
	end if
	
	set appName to item 1 of argv as string
	set filePath to item 2 of argv
	set lineNumberString to item 3 of argv
	
	try
		set lineNumber to lineNumberString as integer
	on error
		display dialog "The line number parameter must be a valid number." with icon stop
		return
	end try
	
	using terms from application "Xcode"
		tell application appName
			activate
			open filePath
			
			set targetDocument to missing value
			try
				repeat with aDoc in every document
					if aDoc's path is equal to filePath then
						if class of aDoc is in {text document, source document} then
							set targetDocument to aDoc
							exit repeat
						end if
					end if
				end repeat
				
				if targetDocument is not missing value then
					tell targetDocument
						set selected paragraph range to {lineNumber, lineNumber}
					end tell
				else
					display dialog "Could not find text document for " & filePath with icon stop
				end if
				
			on error errMsg
				display dialog "Error opening file or selecting line: " & errMsg with icon stop
			end try
		end tell
	end using terms from
end run