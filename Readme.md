# README.md

## System Bottleneck Analysis Script

This repository contains a Bash script that performs a series of system analyses on a macOS to detect potential performance bottlenecks. The script checks various system metrics such as CPU usage, memory utilization, disk usage, network performance, and more. The results of the analysis are written to a file named `system_performance.txt` and also displayed in the console.

### What the Script Does

- **Primary Network Adapter Detection**: Determines the primary network adapter being used by the system.
  
- **Performance Metrics Collection**: Over a specified duration and interval, the script calculates:
    - Average CPU usage
    - Average number of connections from `netstat`
    - Average transactions per second from `iostat`
    - Average ping time to 8.8.8.8
  
- **Memory Utilization**: Calculates the amount of used, free, and inactive memory.
  
- **Disk Space Utilization**: Checks the disk usage of the root directory.
  
- **Network Analysis**: Determines network errors and drops for the primary adapter.
  
- **System Outputs**: Captures and logs the output of commands like `top`, `iostat`, `nettop`, `vm_stat`, and `netstat`.
  
- **Bottleneck Identification**: Analyzes the collected metrics to identify potential bottlenecks in the system related to CPU, memory, disk, and network. The findings are printed to the console and saved to `system_performance.txt`.

### How to Download and Use

#### 1. Clone the Repository

To download the script to your macOS, you need to have `git` installed. If you don't have `git` installed, you can install it using Homebrew:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
brew install git
```

Once `git` is installed, you can clone the repository:

```bash
git clone https://github.com/chriswilson2020/bottlenecks.git
```

#### 2. Navigate to the Directory

Change directory into the cloned repository:

```bash
cd bottlenecks
```

#### 3. Make the Script Executable

By default, the script might not have execution permissions. You can grant execute permissions to the script using the following command:

```bash
chmod +x ./bottleneck.sh
```

#### 4. Run the Script

Execute the script:

```bash
./bottleneck.sh
```

After completion, you can check the `system_performance.txt` file for the collected metrics and the identified bottlenecks.

### Contribution

Feel free to raise issues, make pull requests, or provide feedback to enhance the capabilities of this script. Your contributions are highly appreciated! 

---

**Note**: Always run scripts from external sources with caution. It's recommended to inspect any script you download from the internet before executing it to ensure it doesn't contain malicious or harmful code.
