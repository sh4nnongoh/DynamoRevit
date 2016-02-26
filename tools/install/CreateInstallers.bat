SET cwd=%0\..
echo %cwd%

copy %cwd%\..\..\src\DynamoRevitInstall\bin\x86\Release\DynamoRevitInstall.msi %cwd%\temp
copy %cwd%\..\..\..\Dynamo\src\DynamoInstall\bin\x86\Release\DynamoInstall.msi %cwd%\temp

"C:\Program Files (x86)\Inno Setup 5\iscc.exe" %cwd%\DynamoRevitInstaller.iss

rmdir /Q /S %cwd%\temp
