// The module 'vscode' contains the VS Code extensibility API
// Import the module and reference it with the alias vscode in your code below
import * as vscode from 'vscode';
import * as cp from 'child_process';
import * as path from 'path';
import * as fs from 'fs';
import * as os from 'os';

// This method is called when your extension is activated
// Your extension is activated the very first time the command is executed
export function activate(context: vscode.ExtensionContext) {

	// Use the console to output diagnostic information (console.log) and errors (console.error)
	// This line of code will only be executed once when your extension is activated
	console.log('Congratulations, your extension "cursorsync-for-vscode" is now active!');

	// The command has been defined in the package.json file
	// Now provide the implementation of the command with registerCommand
	// The commandId parameter must match the command field in package.json
	const disposable = vscode.commands.registerCommand('cursorsync-for-vscode.openInXcode', async () => {
		// Check if the operating system is macOS
		if (os.platform() !== 'darwin') {
			vscode.window.showErrorMessage('This feature is only available on macOS.');
			return;
		}

        await vscode.window.activeTextEditor?.document.save();

        // 1. Get the file path of the currently active editor
        const activeEditor = vscode.window.activeTextEditor;
        if (!activeEditor) {
            vscode.window.showErrorMessage('No active editor.');
            return;
        }
        const currentFilePath = activeEditor.document.uri.fsPath;

        // 2. Get the current selection's start and end character offsets (0-based)
        const selection = activeEditor.selection;
        const startCharacterOffset = activeEditor.document.offsetAt(selection.start);
        const endCharacterOffset = activeEditor.document.offsetAt(selection.end);
        const currentLineNumber = selection.active.line + 1;


        // 3. Construct the path to the AppleScript
        // Assume openFileInXcode.applescript is in the 'scripts' folder of the extension directory
        const appleScriptPath = path.join(context.extensionPath, 'scripts', 'openFileInXcode.applescript');

        // Check if the AppleScript file exists
        if (!fs.existsSync(appleScriptPath)) {
            vscode.window.showErrorMessage(`AppleScript file not found: ${appleScriptPath}`);
            return;
        }

        // 4. Define arguments to pass to the AppleScript
        const configuration = vscode.workspace.getConfiguration('cursorsync');
        const appName = configuration.get<string>('openWithApp') || 'Xcode';
        const selectionMode = configuration.get<string>('selectionMode') || 'character'; // Default to 'character'
        var start = startCharacterOffset;
        var end = endCharacterOffset;
        if (selectionMode === 'line') {
            start = currentLineNumber;
            end = currentLineNumber;
        }
        const scriptArgs = [appName, currentFilePath, start.toString(), end.toString(), selectionMode];
        
        // 5. Execute the AppleScript
        // Using execFile is safer as it doesn't execute through a shell
        cp.execFile('osascript', [appleScriptPath, ...scriptArgs], (error, stdout, stderr) => {
            if (error) {
                console.error(`Failed to execute AppleScript: ${error.message}`);
                vscode.window.showErrorMessage(`Failed to execute AppleScript: ${error.message}`);
                if (stderr) {
                    console.error(`AppleScript error output: ${stderr}`);
                    // You can choose to show stderr to the user or log it in more detail
                    // vscode.window.showErrorMessage(`AppleScript error: ${stderr}`);
                }
                return;
            }

            if (stderr) {
                // Some AppleScript warnings or non-fatal errors might be output to stderr
                console.warn(`AppleScript stderr: ${stderr}`);
                // Consider whether to notify the user
            }

            if (stdout) {
                console.log(`AppleScript stdout: ${stdout}`);
                // AppleScript usually interacts via dialogs, stdout might be empty
            }

            vscode.window.showInformationMessage(`Attempting to open ${path.basename(currentFilePath)} in ${appName} and select characters from offset ${startCharacterOffset} to ${endCharacterOffset}.`);
        });
    });

    context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
export function deactivate() {}
