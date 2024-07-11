import os
import subprocess
import shutil
import urllib.request
import zipfile
import time
import sys
from colorama import init, Fore

# Inisialisasi colorama untuk warna teks
init(autoreset=True)

# Fungsi untuk menjalankan perintah shell dan mengembalikan output serta error
def run_command(command):
    process = subprocess.Popen(command, shell=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE, universal_newlines=True)
    output, error = process.communicate()
    return output.strip(), error.strip()

# Fungsi untuk mendownload file dari URL dan menangani ekstraksi
def download_and_extract(url, extract_dir):
    filename = url.split("/")[-1]
    if os.path.exists(filename):
        print(f"{Fore.YELLOW}File '{filename}' sudah ada. Melanjutkan ke proses ekstraksi...")
    else:
        print(f"{Fore.CYAN}Downloading '{filename}'...")
        try:
            urllib.request.urlretrieve(url, filename)
            print(f"{Fore.GREEN}Download selesai: '{filename}'")
        except Exception as e:
            print(f"{Fore.RED}Terjadi kesalahan saat mendownload '{filename}': {str(e)}")
            return False
    
    # Ekstraksi file ZIP
    try:
        with zipfile.ZipFile(filename, 'r') as zip_ref:
            print(f"{Fore.CYAN}Extracting '{filename}' to '{extract_dir}'...")
            zip_ref.extractall(extract_dir)
            print(f"{Fore.GREEN}Ekstraksi selesai.")
            return True
    except Exception as e:
        print(f"{Fore.RED}Terjadi kesalahan saat mengekstrak '{filename}': {str(e)}")
        if os.path.exists(filename):
            os.remove(filename)
        return False

# Fungsi untuk menjalankan aktivasi Windows dengan berbagai kode aktivasi
def activate_windows():
    # Daftar kode aktivasi yang akan dicoba secara berurutan jika sebelumnya gagal
    activation_keys = [
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
    ]
    
    success_message = f"{Fore.GREEN}Windows berhasil diaktifkan."
    failure_message = f"{Fore.RED}Gagal mengaktifkan Windows dengan semua kode yang disediakan."

    for key in activation_keys:
        result, error = run_command(f"slmgr /ipk {key}")  # Install product key
        if "Product key installation successful" in result:
            result, error = run_command("slmgr /ato")  # Activate Windows
            if "Activation successful" in result:
                print(success_message)
                return True
            else:
                print(f"{Fore.RED}Gagal mengaktifkan Windows dengan kode: {key}. Error: {error}")
        else:
            print(f"{Fore.RED}Gagal menginstall product key: {key}. Error: {error}")

    print(failure_message)
    return False

# Main script
if __name__ == "__main__":
    # URL file master installasi
    master_installation_url = "https://laodau.sgp1.cdn.digitaloceanspaces.com/storage/r-setup-file.zip"
    # Direktori tempat ekstraksi file
    extraction_dir = os.path.join(os.environ['TEMP'], "r-setup-file")

    # Membuat direktori ekstraksi jika belum ada
    os.makedirs(extraction_dir, exist_ok=True)

    # Memastikan skrip dijalankan sebagai administrator
    if not os.environ.get('ADMIN'):
        # Menjalankan skrip sebagai administrator
        script = os.path.abspath(__file__)
        params = " ".join([script] + sys.argv[1:])
        os.system(f'powershell -command "Start-Process \'{script}\' -ArgumentList \'{params}\' -Verb RunAs"')
        sys.exit(0)

    # Mendownload dan mengekstrak file master instalasi
    if download_and_extract(master_installation_url, extraction_dir):
        # Langkah-langkah instalasi setelah berhasil mendownload dan mengekstrak
        print(f"{Fore.GREEN}Mulai instalasi...\n")

        # 1. Instalasi 1.vc++.exe secara silent
        print(f"\n{Fore.CYAN}Installing 1.vc++.exe...")
        # Ganti dengan perintah instalasi silent sesuai kebutuhan

        # 2. Instalasi 2.win-runtime.exe secara silent
        print(f"\n{Fore.CYAN}Installing 2.win-runtime.exe...")
        # Ganti dengan perintah instalasi silent sesuai kebutuhan

        # 3. Menjalankan program start-click-here.exe
        print(f"\n{Fore.CYAN}Menjalankan start-click-here.exe...")
        # Ganti dengan kode untuk menjalankan program start-click-here.exe
        # Contoh: subprocess.Popen("start-click-here.exe")
        time.sleep(5)  # Menunggu beberapa detik untuk program selesai

        # 4. Aktivasi Windows setelah menjalankan start-click-here.exe
        print(f"\n{Fore.CYAN}Mencoba aktivasi Windows...")
        activate_windows()

        # 5. Menyalin file titan-edge.exe dan goworkerd.dll ke Windows system32
        print(f"\n{Fore.CYAN}Copying titan-edge.exe and goworkerd.dll to Windows system32...")
        # Ganti dengan perintah untuk menyalin file ke system32
        # Contoh: shutil.copy("path/to/titan-edge.exe", "C:/Windows/System32/titan-edge.exe")

        # 6. Menjalankan perintah titan-edge daemon start --init --url ...
        print(f"\n{Fore.CYAN}Menjalankan perintah 'titan-edge daemon start --init --url ...'")
        # Ganti dengan perintah untuk menjalankan titan-edge daemon

        # 7. Menjalankan perintah titan-edge bind --hash=... https://api-test1.container1.titannet.io/...
        print(f"\n{Fore.CYAN}Menjalankan perintah 'titan-edge bind --hash=...'")
        # Ganti dengan perintah untuk menjalankan bind command

        # 8. Instalasi program rClient.Setup.latest.exe dari folder 4.rivalz secara silent
        print(f"\n{Fore.CYAN}Installing rClient.Setup.latest.exe from 4.rivalz...")
        # Ganti dengan perintah instalasi silent sesuai kebutuhan

        print(f"\n{Fore.GREEN}Instalasi selesai.")
    else:
        print(f"\n{Fore.RED}Instalasi gagal karena kesalahan dalam mengekstrak file master.")
