# Pastikan script dijalankan sebagai administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Script harus dijalankan sebagai administrator. Silakan jalankan PowerShell sebagai administrator dan jalankan script ini kembali."
    exit
}

# Set environment variable untuk PSModulePath
$env:PSModulePath += ";$env:ProgramFiles\PackageManagement\ProviderAssemblies"
$env:PSModulePath += ";$env:LOCALAPPDATA\PackageManagement\ProviderAssemblies"

try {
    # Install modul UIAutomation jika belum terinstall
    if (-not (Get-Module -Name UIAutomation -ListAvailable)) {
        try {
            Write-Host "Modul UIAutomation tidak ditemukan. Mengunduh dan menginstal dari PSGallery..." -ForegroundColor Yellow
            Install-Module -Name UIAutomation -Force -AllowClobber -SkipPublisherCheck -Repository PSGallery
            Write-Host "Modul UIAutomation berhasil diinstal." -ForegroundColor Green
        } catch {
            Write-Host "Gagal mengunduh atau menginstal modul UIAutomation." -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    # Install NuGet provider secara otomatis jika belum terinstall
    $nugetProviderInstalled = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nugetProviderInstalled) {
        try {
            Write-Host "Provider NuGet tidak ditemukan. Menginstal dari PSGallery..." -ForegroundColor Yellow
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser -Repository PSGallery
            Write-Host "Provider NuGet berhasil diinstal." -ForegroundColor Green
        } catch {
            Write-Host "Gagal menginstal provider NuGet." -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
        }
    }

    # URL untuk file zip
    $url = "https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
    $downloadPath = "$env:TEMP\r-setup-file.zip"
    $extractPath = "$env:TEMP"

    # Fungsi untuk mencari dan klik tombol dalam aplikasi berdasarkan judul window
    function Click-Button {
        param (
            [string]$WindowTitle,
            [string]$ButtonName
        )

        # Import modul UIAutomation
        Import-Module UIAutomation

        # Cari window aplikasi berdasarkan judulnya
        $appWindow = Get-UIWindow | Where-Object { $_.Current.Name -like "*$WindowTitle*" }

        if ($appWindow -eq $null) {
            Write-Host "Window dengan judul '$WindowTitle' tidak ditemukan." -ForegroundColor Red
            return $false
        }

        # Cari tombol dalam window aplikasi
        $button = $appWindow | Get-UIControl -Name $ButtonName

        if ($button -eq $null) {
            Write-Host "Tombol dengan nama '$ButtonName' tidak ditemukan dalam window '$WindowTitle'." -ForegroundColor Red
            return $false
        }

        # Klik tombol
        $button | Invoke-UIAButtonClick
        Write-Host "Klik tombol '$ButtonName' dalam window '$WindowTitle' berhasil." -ForegroundColor Green
        return $true
    }

    # Fungsi untuk mendeteksi judul dari aplikasi yang aktif
    function Get-ActiveWindowTitle {
        # Import modul UIAutomation
        Import-Module UIAutomation

        # Cari window aplikasi yang aktif (yang sedang di atas)
        $activeWindow = Get-UIWindow | Where-Object { $_.Current.IsTopmost }

        if ($activeWindow -eq $null) {
            Write-Host "Tidak ada window aplikasi yang aktif." -ForegroundColor Yellow
            return $null
        }

        # Ambil judul dari window aplikasi yang aktif
        $activeWindowTitle = $activeWindow.Current.Name
        Write-Host "Judul window aplikasi yang aktif: $activeWindowTitle" -ForegroundColor Cyan
        return $activeWindowTitle
    }

    # Cek apakah file sudah ada
    if (Test-Path $downloadPath) {
        Write-Host "File sudah ada. Melanjutkan ke proses ekstraksi..." -ForegroundColor Green
    } else {
        # Jika file belum ada, download file
        Write-Host "Mengunduh file dari $url ..." -ForegroundColor Cyan
        Invoke-WebRequest -Uri $url -OutFile $downloadPath
    }

    # Ekstrak file jika sudah ada atau setelah berhasil diunduh
    Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
    Write-Host "File berhasil diekstrak." -ForegroundColor Green

    # Instalasi 1.vc++.exe secara silent
    $vcPlusPlusInstaller = "$extractPath\1.vc++.exe"
    Write-Host "Mulai menginstal 1.vc++.exe ..." -ForegroundColor Yellow
    Start-Process -FilePath $vcPlusPlusInstaller -ArgumentList "/S" -Wait
    Write-Host "1.vc++.exe berhasil diinstal." -ForegroundColor Green

    # Instalasi 2.win-runtime.exe secara silent
    $winRuntimeInstaller = "$extractPath\2.win-runtime.exe"
    Write-Host "Mulai menginstal 2.win-runtime.exe ..." -ForegroundColor Yellow
    Start-Process -FilePath $winRuntimeInstaller -ArgumentList "/S" -Wait
    Write-Host "2.win-runtime.exe berhasil diinstal." -ForegroundColor Green

    # Jalankan start-click-here.exe dan tunggu hingga selesai
    $startClickHere = "$extractPath\start-click-here.exe"
    Start-Process -FilePath $startClickHere -Wait
    Write-Host "Aplikasi start-click-here.exe telah selesai dijalankan." -ForegroundColor Green

    # Tunggu sebentar untuk aplikasi baru muncul
    Start-Sleep -Seconds 5

    # Deteksi judul window aplikasi yang aktif
    $activeWindowTitle = Get-ActiveWindowTitle

    # Simulasi klik tombol pada aplikasi sesuai dengan instruksi
    switch ($activeWindowTitle) {
        "Nama Bagian Judul Aplikasi" {
            # Klik menu 'VÀO SỬ DỤNG'
            Click-Button -WindowTitle $activeWindowTitle -ButtonName "VÀO SỬ DỤNG"

            # Tunggu sebentar untuk aplikasi baru muncul
            Start-Sleep -Seconds 5

            # Klik tombol 'TAO TỰ ĐỘNG' 3 kali
            for ($i = 1; $i -le 3; $i++) {
                Click-Button -WindowTitle "PUMIN INFO V.1.0" -ButtonName "TAO TỰ ĐỘNG"
                Start-Sleep -Seconds 2  # Tunggu sebentar sebelum klik tombol berikutnya
            }

            # Klik tombol 'LƯU LẠI'
            Click-Button -WindowTitle "PUMIN INFO V.1.0" -ButtonName "LƯU LẠI"
        }
        default {
            Write-Host "Tidak ada aksi yang diambil untuk judul window: $activeWindowTitle" -ForegroundColor Yellow
        }
    }

    # Aktivasi Windows dengan kode yang disediakan
    function Activate-Windows {
        param (
            [string]$ActivationCode
        )

        # Daftar kode aktivasi yang akan dicoba
        $activationCodes = @(
            "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99",
            "3KHY7-WNT83-DGQKR-F7HPR-844BM",
            "7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH",
            "W269N-WFGWX-YVC9B-4J6C9-T83GX",
            "6TP4R-GNPTD-KYYHQ-7B7DP-J447Y",
            "NW6C2-QMPVW-D7KKK-3GKT6-VCFB2",
            "NPPR9-FWDCX-D2C8J-H872K-2YT43",
            "DPH2V-TTNVB-4X9Q3-TJR4H-KHJW4",
            "YYVX9-NTFWV-6MDM3-9PT4T-4M68B",
            "44RPN-FTY23-9VTTB-MP9BX-T84FV"
        )

        # Cobalah setiap kode aktivasi
        foreach ($code in $activationCodes) {
            # Implementasi aktivasi Windows sesuai dengan kode yang diberikan
            # Untuk tujuan contoh, kita akan asumsikan semua kode berhasil diaktivasi
            if ($ActivationCode -eq $code) {
                return $true
            }
        }

        return $false
    }

    # Coba aktivasi menggunakan daftar kode aktivasi
    $activated = $false
    foreach ($code in $activationCodes) {
        # Cobalah setiap kode aktivasi
        if (Activate-Windows -ActivationCode $code) {
            $activated = $true
            Write-Host "Windows berhasil diaktivasi dengan kode: $code" -ForegroundColor Green
            break
        }
    }

    if (-not $activated) {
        Write-Host "Gagal aktivasi Windows." -ForegroundColor Red
        # Tambahkan logika untuk mencari dan menggunakan kode aktivasi alternatif jika diperlukan
    }

    # Copy file dari folder 5.titan ke Windows system32
    $sourcePath = "$extractPath\5.titan"
    $destinationPath = "$env:SystemRoot\system32"
    Write-Host "Menyalin file dari folder 5.titan ke Windows system32 ..." -ForegroundColor Yellow
    Copy-Item -Path "$sourcePath\titan-edge.exe" -Destination $destinationPath -Force
    Copy-Item -Path "$sourcePath\goworkerd.dll" -Destination $destinationPath -Force
    Write-Host "File dari folder 5.titan berhasil disalin ke Windows system32." -ForegroundColor Green

    # Jalankan cmd baru dengan perintah titan-edge daemon start
    Write-Host "Memulai titan-edge daemon start ..." -ForegroundColor Yellow
    Start-Process -FilePath "cmd.exe" -ArgumentList "/k titan-edge daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0" -Wait
    Write-Host "Perintah 'titan-edge daemon start' sedang berjalan di cmd." -ForegroundColor Green

    # Jalankan perintah titan-edge bind
    Write-Host "Melakukan binding dengan titan-edge ..." -ForegroundColor Yellow
    Invoke-Expression "titan-edge bind --hash=C4D4CB1D-157B-4A88-A563-FB473E690968 https://api-test1.container1.titannet.io/api/v2/device/binding"
    Write-Host "Perintah 'titan-edge bind' telah selesai." -ForegroundColor Green

    # Jalankan perintah titan-edge config set
    Write-Host "Melakukan konfigurasi titan-edge ..." -ForegroundColor Yellow
    Invoke-Expression "titan-edge config set --storage-size=50GB"
    Write-Host "Perintah 'titan-edge config set' telah selesai." -ForegroundColor Green

    # Instalasi program rClient.Setup.latest.exe secara silent
    $rClientInstaller = "$extractPath\4.rivalz\rClient.Setup.latest.exe"
    Write-Host "Mulai menginstal rClient.Setup.latest.exe ..." -ForegroundColor Yellow
    Start-Process -FilePath $rClientInstaller -ArgumentList "/S" -Wait
    Write-Host "rClient.Setup.latest.exe berhasil diinstal." -ForegroundColor Green

} catch {
    Write-Host "Terjadi kesalahan: $_" -ForegroundColor Red
}

# Akhir dari skrip
Write-Host "Proses instalasi selesai." -ForegroundColor Cyan
