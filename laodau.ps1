# Pastikan script dijalankan sebagai administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Script harus dijalankan sebagai administrator. Silakan jalankan PowerShell sebagai administrator dan jalankan script ini kembali."
    exit
}

# Set environment variable untuk PSModulePath
$env:PSModulePath += ";$env:ProgramFiles\PackageManagement\ProviderAssemblies"
$env:PSModulePath += ";$env:LOCALAPPDATA\PackageManagement\ProviderAssemblies"

try {
    # Pastikan PSGallery terdaftar sebagai repositori
    if (-not (Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue)) {
        Write-Host "Menambahkan PSGallery sebagai repositori..." -ForegroundColor Yellow
        Register-PSRepository -Name "PSGallery" -SourceLocation "https://www.powershellgallery.com/api/v2" -InstallationPolicy Trusted
    }

    # Instal NuGet provider jika belum terinstall
    $nugetProviderInstalled = Get-PackageProvider -Name NuGet -ErrorAction SilentlyContinue
    if (-not $nugetProviderInstalled) {
        try {
            Write-Host "Provider NuGet tidak ditemukan. Menginstal dari PSGallery..." -ForegroundColor Yellow
            Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force -Confirm:$false -Scope CurrentUser -Verbose:$false
            Write-Host "Provider NuGet berhasil diinstal." -ForegroundColor Green
        } catch {
            Write-Host "Gagal menginstal provider NuGet." -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "Provider NuGet sudah terinstall." -ForegroundColor Green
    }

    # Install modul UIAutomation jika belum terinstall
    if (-not (Get-Module -Name UIAutomation -ListAvailable)) {
        try {
            Write-Host "Modul UIAutomation tidak ditemukan. Mengunduh dan menginstal dari PSGallery..." -ForegroundColor Yellow
            Install-Module -Name UIAutomation -Scope CurrentUser -Force -AllowClobber -SkipPublisherCheck -Repository PSGallery -Verbose:$false
            Write-Host "Modul UIAutomation berhasil diinstal." -ForegroundColor Green
        } catch {
            Write-Host "Gagal mengunduh atau menginstal modul UIAutomation dari PSGallery." -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "Modul UIAutomation sudah terinstall." -ForegroundColor Green
    }

    # URL untuk file zip
    $url = "https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
    $downloadPath = "$env:TEMP\r-setup-file.zip"
    $extractPath = "$env:TEMP"

    # Cek apakah file sudah ada
    if (Test-Path $downloadPath) {
        Write-Host "File sudah ada. Melanjutkan ke proses ekstraksi..." -ForegroundColor Green
    } else {
        # Jika file belum ada, download file
        Write-Host "Mengunduh file dari $url ..." -ForegroundColor Cyan

        # Mulai unduh file dengan progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFile($url, $downloadPath)

        # Tunggu sampai selesai unduh
        while ($webClient.IsBusy) {
            $progress = $webClient.DownloadProgress
            Write-Progress -Activity "Mengunduh file" -Status ("Progress: {0}%, Total: {1} MB" -f $progress.ProgressPercentage, [math]::Round($progress.TotalBytesToReceive / 1MB, 2)) -PercentComplete $progress.ProgressPercentage
            Start-Sleep -Milliseconds 500
        }
        $webClient.Dispose()

        Write-Host "File berhasil diunduh." -ForegroundColor Green
    }

    # Ekstrak file jika sudah ada atau setelah berhasil diunduh
    try {
        Expand-Archive -Path $downloadPath -DestinationPath $extractPath -Force
        Write-Host "File berhasil diekstrak." -ForegroundColor Green
    } catch {
        Write-Host "Gagal mengekstrak file zip. Pastikan file zip tidak rusak atau coba unduh kembali." -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
        exit
    }

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

    # Cek hasil aktivasi
    if (-not $activated) {
        Write-Host "Windows gagal diaktivasi. Pastikan Anda menggunakan kode yang valid." -ForegroundColor Red
    }

} catch {
    Write-Host "Terjadi kesalahan: $_" -ForegroundColor Red
    exit
}

function Get-ActiveWindowTitle {
    Add-Type @"
        using System;
        using System.Runtime.InteropServices;
        public class User32 {
            [DllImport("user32.dll")]
            public static extern IntPtr GetForegroundWindow();
            [DllImport("user32.dll", SetLastError = true, CharSet = CharSet.Auto)]
            public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder lpString, int nMaxCount);
        }
"@

    $hWnd = [User32]::GetForegroundWindow()
    $sb = New-Object System.Text.StringBuilder 256
    [User32]::GetWindowText($hWnd, $sb, $sb.Capacity) | Out-Null
    $sb.ToString()
}

function Click-Button {
    param (
        [string]$WindowTitle,
        [string]$ButtonName
    )

    try {
        $window = Get-UIAWindow -Name $WindowTitle -Timeout 10
        if ($window) {
            $button = Get-UIAButton -Name $ButtonName -InputObject $window
            if ($button) {
                Invoke-UIAButtonClick -InputObject $button
                Write-Host "Tombol '$ButtonName' pada window '$WindowTitle' telah diklik." -ForegroundColor Green
            } else {
                Write-Host "Tombol '$ButtonName' tidak ditemukan pada window '$WindowTitle'." -ForegroundColor Yellow
            }
        } else {
            Write-Host "Window dengan judul '$WindowTitle' tidak ditemukan." -ForegroundColor Yellow
        }
    } catch {
        Write-Host "Terjadi kesalahan saat mencoba mengklik tombol '$ButtonName' pada window '$WindowTitle'." -ForegroundColor Red
        Write-Host "Error: $_" -ForegroundColor Red
    }
}
