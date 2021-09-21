path = WScript.Arguments.item(0)
destinationPath = WScript.Arguments.item(1)

Set fileSystemObject = WScript.CreateObject("Scripting.FileSystemObject")
If NOT fileSystemObject.FolderExists(destinationPath) Then
    fileSystemObject.CreateFolder(destinationPath)
End If

Set application = WScript.CreateObject("Shell.Application")
Set pathNameSpace = application.NameSpace(fileSystemObject.GetAbsolutePathName(path))
Set destinationPathNameSpace = application.NameSpace(fileSystemObject.GetAbsolutePathName(destinationPath))

destinationPathNameSpace.CopyHere pathNameSpace.items, 4 + 16
