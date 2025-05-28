on run argv
	if (count of argv) is not 5 then
		display dialog "Five parameters are required: application name, file path, start value, end value, and selection mode ('character' or 'paragraph')." with icon stop
		return
	end if
	
	set appName to item 1 of argv as string
	set filePath to item 2 of argv
	set startString to item 3 of argv
	set endString to item 4 of argv
	set selectionMode to item 5 of argv as string
	
	try
		set startVal to startString as integer
		set endVal to endString as integer
	on error
		display dialog "The start and end value parameters must be valid numbers." with icon stop
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
							if selectionMode is "character" then
								-- Treat startVal and endVal as 0-based character offsets from VSCode
								set startCharacter to startVal
								set endCharacter to endVal

								-- Ensure startCharacter is not greater than endCharacter
								-- For VSCode selections, start is typically <= end.
								-- This handles cases where inputs might not strictly follow that.
								if startCharacter > endCharacter then
									set temp to startCharacter
									set startCharacter to endCharacter
									set endCharacter to temp
								end if
								
								-- AppleScript character ranges are 1-based.
								-- VSCode provides 0-based offsets. `endCharacter` is exclusive for selections.
								set finalStartCharacter to startCharacter + 1
								
								-- If it's a cursor position (start == end in VSCode), AppleScript needs {pos, pos-1}
								if startCharacter is equal to endCharacter then
									set finalEndCharacter to finalStartCharacter - 1
								else
									-- For a selection, if VSCode's endCharacter is an exclusive 0-based offset,
									-- AppleScript's 1-based inclusive end is that same value.
									-- e.g., VSCode (0,1) exclusive -> AppleScript {1,1} inclusive
									-- e.g., VSCode (0,2) exclusive -> AppleScript {1,2} inclusive
									set finalEndCharacter to endCharacter 
								end if
								
								set selected character range to {finalStartCharacter, finalEndCharacter}

							else if selectionMode is "line" then
								-- Treat startVal and endVal as 1-based paragraph indices
								set startParagraph to startVal
								set endParagraph to endVal

								-- Ensure startParagraph is not greater than endParagraph
								if startParagraph > endParagraph then
									set temp to startParagraph
									set startParagraph to endParagraph
									set endParagraph to temp
								end if

								-- Ensure paragraph numbers are at least 1
								if startParagraph < 1 then
									set startParagraph to 1
								end if
								-- Note: No check for endParagraph exceeding total paragraphs, relies on Xcode handling.

								set selected paragraph range to {startParagraph, endParagraph}
								
							else
								display dialog "Invalid selection mode: " & selectionMode & ". Must be 'character' or 'paragraph'." with icon stop
								return
							end if
						end tell
					else
						display dialog "Could not find text document for " & filePath with icon stop
					end if
				
				on error errMsg
					display dialog "Error processing file or selection: " & errMsg with icon stop
			end try
		end tell
	end using terms from
end run