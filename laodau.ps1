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

    # Install modul UIAutomation jika belum terinstall dari GitHub
    if (-not (Get-Module -Name UIAutomation -ListAvailable)) {
        try {
            Write-Host "Modul UIAutomation tidak ditemukan. Mengunduh dan menginstal dari GitHub..." -ForegroundColor Yellow
            $uiAutomationUrl = "https://github.com/lextm/UIAutomation/releases/download/v0.8.0/UIAutomation.0.8.0.zip"
            $uiAutomationDownloadPath = "$env:TEMP\UIAutomation.zip"
            $uiAutomationExtractPath = "$env:TEMP\UIAutomation"

            # Unduh file UIAutomation
            Invoke-WebRequest -Uri $uiAutomationUrl -OutFile $uiAutomationDownloadPath

            # Ekstrak file UIAutomation
            Expand-Archive -Path $uiAutomationDownloadPath -DestinationPath $uiAutomationExtractPath -Force

            # Set path untuk modul UIAutomation
            $uiAutomationModulePath = "$uiAutomationExtractPath\UIAutomation"

            # Impor modul UIAutomation
            Import-Module -Name $uiAutomationModulePath

            Write-Host "Modul UIAutomation berhasil diinstal." -ForegroundColor Green
        } catch {
            Write-Host "Gagal mengunduh atau menginstal modul UIAutomation dari GitHub." -ForegroundColor Red
            Write-Host "Error: $_" -ForegroundColor Red
            exit
        }
    } else {
        Write-Host "Modul UIAutomation sudah terinstall." -ForegroundColor Green
    }

    # URL untuk file zip
    $url = "https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
    $downloadPath = "$env:TEMP\r-setup-file.zip"
    $extractPath = "$env:TEMP\r-setup-file"

    # Cek apakah file sudah ada
    if (Test-Path $downloadPath) {
        Write-Host "File sudah ada. Melanjutkan ke proses ekstraksi..." -ForegroundColor Green
    } else {
        # Jika file belum ada, download file
        Write-Host "Mengunduh file dari $url ..." -ForegroundColor Cyan

        # Mulai unduh file dengan progress
        $webClient = New-Object System.Net.WebClient
        $webClient.DownloadFileAsync($url, $downloadPath)

        # Tunggu sampai selesai unduh dengan progress
        while ($webClient.IsBusy) {
            $progress = [System.IO.FileInfo]::new($downloadPath).Length
            $totalSize = [System.IO.FileInfo]::new($downloadPath).Length
            if ($totalSize -gt 0) {
                $percentComplete = [math]::Round(($progress / $totalSize) * 100, 2)
                Write-Progress -Activity "Mengunduh file" -Status ("Progress: {0}%, Total: {1} MB" -f $percentComplete, [math]::Round($totalSize / 1MB, 2)) -PercentComplete $percentComplete
            }
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

    # Fungsi untuk mengaktifkan Windows
    function Activate-Windows {
        # Daftar kode aktivasi yang akan dicoba
        $activationCodes = @(
            "TX9XD-98N7V-6WMQ6-BX7FG-H8Q99",
            "3KHY7-WNT83-DGQKR-F7HPR-844BM",
            "7HNRX-D7KGG-3K4RQ-4WPJ4-YTDFH",
            "PVMJN-6DFY6-9CCP6-7BKTT-D3WVR",
            "W269N-WFGWX-YVC9B-4J6C9-T83GX",
            "MH37W-N47XK-V7XM9-C7227-GCQG9"
        )

        # Loop melalui setiap kode untuk mencoba mengaktifkan Windows
        foreach ($code in $activationCodes) {
            Write-Host "Mencoba mengaktifkan Windows dengan kode: $code" -ForegroundColor Yellow
            # Jalankan perintah untuk mengaktifkan Windows
            $result = slmgr /ipk $code
            Start-Sleep -Seconds 2  # Tunggu sebentar untuk proses aktivasi

            # Cek status aktivasi
            $status = slmgr /dli
            if ($status -match "Licensed") {
                Write-Host "Windows berhasil diaktifkan dengan kode: $code" -ForegroundColor Green
                break  # Keluar dari loop jika berhasil
            } else {
                Write-Host "Gagal mengaktifkan Windows dengan kode: $code" -ForegroundColor Red
            }
        }
    }

    # Panggil fungsi untuk mengaktifkan Windows
    Activate-Windows

    # Menjalankan perintah tambahan dengan feedback sukses atau gagal
    Write-Host "Menjalankan perintah tambahan Titan Edge..." -ForegroundColor Yellow
    Start-Process -FilePath "titan-edge" -ArgumentList "daemon start --init --url https://cassini-locator.titannet.io:5000/rpc/v0" -Wait

    # Simulasi input identitas
    $identityCode = Read-Host "Masukkan kode identitas Anda"

    # Menjalankan perintah binding dengan kode identitas
    Start-Process -FilePath "titan-edge" -ArgumentList "bind --hash=$identityCode https://api-test1.container1.titannet.io/api/v2/device/binding" -Wait
    Write-Host "Perintah binding berhasil dijalankan." -ForegroundColor Green

    # Menjalankan perintah konfigurasi storage
    Start-Process -FilePath "titan-edge" -ArgumentList "config set --storage-size=50GB" -Wait
    Write-Host "Perintah konfigurasi storage berhasil dijalankan." -ForegroundColor Green

    # Instalasi rClient.Setup.latest.exe secara silent
    $rClientInstaller = "$extractPath\4.rivalz\rClient.Setup.latest.exe"
    Write-Host "Mulai menginstal rClient.Setup.latest.exe ..." -ForegroundColor Yellow
    Start-Process -FilePath $rClientInstaller -ArgumentList "/S" -Wait
    Write-Host "rClient.Setup.latest.exe berhasil diinstal." -ForegroundColor Green

    Write-Host "Semua proses instalasi selesai." -ForegroundColor Green

} catch {
    Write-Host "Terjadi kesalahan dalam proses instalasi." -ForegroundColor Red
    Write-Host "Error: $_" -ForegroundColor Red
    exit
}

function Get-ActiveWindowTitle {
    Add-Type @"
    using System;
    using System.Runtime.InteropServices;
    public class Win32 {
        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern IntPtr GetForegroundWindow();

        [DllImport("user32.dll", CharSet = CharSet.Auto, SetLastError = true)]
        public static extern int GetWindowText(IntPtr hWnd, System.Text.StringBuilder text, int count);
    }
"@
    $handle = [Win32]::GetForegroundWindow()
    $title = New-Object System.Text.StringBuilder 256
    [void][Win32]::GetWindowText($handle, $title, 256)
    $title.ToString()
}

function Click-Button {
    param (
        [string]$WindowTitle,
        [string]$ButtonName
    )

    # Gunakan modul UIAutomation untuk mengklik tombol
    Import-Module UIAutomation
    $window = Get-UiaWindow -Name $WindowTitle
    if ($window) {
        $button = Get-UiaButton -Name $ButtonName -InputObject $window
        if ($button) {
            Invoke-UiaButtonClick -InputObject $button
            Write-Host "Klik tombol '$ButtonName' pada window '$WindowTitle' berhasil." -ForegroundColor Green
        } else {
            Write-Host "Tombol '$ButtonName' tidak ditemukan pada window '$WindowTitle'." -ForegroundColor Red
        }
    } else {
        Write-Host "Window dengan judul '$WindowTitle' tidak ditemukan." -ForegroundColor Red
    }
}
