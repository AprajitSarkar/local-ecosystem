# Setup licenses
$licensesDir = "C:\Users\Aprajit\tools\android-sdk\licenses"
New-Item -ItemType Directory -Force -Path $licensesDir

$androidSdkLicense = @"
24333f8a63b1d99d69792a64e08fa88df8be5267
893fb4a22e3d7904e4cb7f651e5ea033b0799e4d
d56f5187479451eabf01fb78712b9385a4619d62
84831b9409646a53dec715091663267b14650c76
601085b94cd77f0b54ff86406957099150001076
33b6a2b649fd21da0b66f42921a02c69f2155cc1
e9acab5b5fbb560a723e1ec946b9636a6ee76ffc
"@

$androidPreviewLicense = @"
84831b9409646a53dec715091663267b14650c76
"@

[System.IO.File]::WriteAllText("$licensesDir\android-sdk-license", $androidSdkLicense)
[System.IO.File]::WriteAllText("$licensesDir\android-sdk-preview-license", $androidPreviewLicense)

Write-Host "Android licenses written successfully."
