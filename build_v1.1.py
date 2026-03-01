import os
import shutil
import subprocess
import sys

# 配置路径
ROOT_DIR = os.path.dirname(os.path.abspath(__file__))
CORE_DIR = os.path.join(ROOT_DIR, "core")
GUI_DIR = os.path.join(ROOT_DIR, "gui")
RELEASE_DIR = os.path.join(ROOT_DIR, "release")
DIST_DIR = os.path.join(RELEASE_DIR, "Blipboard_v1.1_Win")

# 定位虚拟环境的 Python
if sys.platform == "win32":
    VENV_PYTHON = os.path.join(CORE_DIR, ".venv", "Scripts", "python.exe")
else:
    VENV_PYTHON = os.path.join(CORE_DIR, ".venv", "bin", "python")

def run_command(command, cwd=None):
    print(f"Running: {command}")
    result = subprocess.run(command, shell=True, cwd=cwd)
    if result.returncode != 0:
        print(f"Error: Command failed with exit code {result.returncode}")
        # Not exiting here to allow cleanup to try and continue
    return result.returncode

def main():
    # 0. 确保虚拟环境 Python 存在
    if not os.path.exists(VENV_PYTHON):
        print(f"Error: Virtual environment not found at {VENV_PYTHON}")
        print("Please create it first using: python -m venv .venv (inside core directory)")
        sys.exit(1)

    # 0.5 尝试清理正在运行的进程
    if sys.platform == "win32":
        print("Checking for running processes...")
        subprocess.run("taskkill /F /IM blipboard_server.exe /T", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        subprocess.run("taskkill /F /IM blipboard_client.exe /T", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)
        subprocess.run("taskkill /F /IM Blipboard.exe /T", shell=True, stderr=subprocess.DEVNULL, stdout=subprocess.DEVNULL)

    # 1. 清理旧的发布目录
    if os.path.exists(DIST_DIR):
        print(f"Cleaning old release directory: {DIST_DIR}")
        shutil.rmtree(DIST_DIR)
    
    if not os.path.exists(RELEASE_DIR):
        os.makedirs(RELEASE_DIR)
    os.makedirs(DIST_DIR)

    # 2. 打包 Python CLI 版本
    print("\n--- Building CLI Version with PyInstaller ---")
    
    # 确保虚拟环境中安装了 pyinstaller
    print("Ensuring PyInstaller is installed in venv...")
    run_command(f'"{VENV_PYTHON}" -m pip install pyinstaller', cwd=CORE_DIR)

    py_scripts = ["blipboard_client.py", "blipboard_server.py"]
    for script in py_scripts:
        script_path = os.path.join(CORE_DIR, script)
        dist_path = os.path.join(DIST_DIR, "core")
        # 增加 hidden-import 以防止打包缺失
        cmd = f'"{VENV_PYTHON}" -m PyInstaller --onefile --distpath "{dist_path}" --hidden-import=socket --hidden-import=uuid --hidden-import=pyperclip "{script_path}"'
        run_command(cmd, cwd=CORE_DIR)

    # 3. 打包 Flutter GUI 版本
    print("\n--- Building GUI Version with Flutter ---")
    run_command("flutter build windows", cwd=GUI_DIR)
    
    # 4. 移动 Flutter 编译产物到发布目录
    flutter_build_output = os.path.join(GUI_DIR, "build", "windows", "x64", "runner", "Release")
    print("\n--- Assembling final package ---")
    if os.path.exists(flutter_build_output):
        for item in os.listdir(flutter_build_output):
            s = os.path.join(flutter_build_output, item)
            d = os.path.join(DIST_DIR, item)
            if os.path.isdir(s):
                shutil.copytree(s, d)
            else:
                shutil.copy2(s, d)
    else:
        print(f"Error: Flutter build output not found at {flutter_build_output}")
        sys.exit(1)

    # 5. 重命名主程序以方便识别
    gui_exe = os.path.join(DIST_DIR, "gui.exe")
    if os.path.exists(gui_exe):
        os.rename(gui_exe, os.path.join(DIST_DIR, "Blipboard.exe"))

    # 6. 清理临时文件夹 (PyInstaller 生成的 build 文件夹和 spec 文件)
    print("\n--- Cleaning up temporary build files ---")
    spec_files = [f for f in os.listdir(CORE_DIR) if f.endswith(".spec")]
    for spec in spec_files:
        os.remove(os.path.join(CORE_DIR, spec))
    
    py_build_dir = os.path.join(CORE_DIR, "build")
    if os.path.exists(py_build_dir):
        shutil.rmtree(py_build_dir)

    print(f"\n✅ Release build completed! Check the directory: {DIST_DIR}")
    print("You can now zip the 'Blipboard_v1.1_Win' folder and distribute it.")

if __name__ == "__main__":
    main()
