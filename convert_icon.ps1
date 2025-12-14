
$source = "assets\logo.png"
$dest = "windows\runner\resources\app_icon.ico"

Add-Type -AssemblyName System.Drawing
$bmp = [System.Drawing.Bitmap]::FromFile("$pwd\$source")
$icon = [System.Drawing.Icon]::FromHandle($bmp.GetHicon())
$fs = [System.IO.File]::OpenWrite("$pwd\$dest")
$icon.Save($fs)
$fs.Close()
$icon.Dispose()
$bmp.Dispose()
Write-Host "Icon created successfully at $dest"
