#!/bin/bash

OUTPUT_FILE="system_performance.txt"

primary_adapter=$(route get 8.8.8.8 | grep interface | awk '{print $2}')
num_cores=$(sysctl -n hw.ncpu)
high_cpu_threshold=$(awk "BEGIN {print $num_cores * 90}")

# Determine the primary network adapter
primary_adapter=$(route get 8.8.8.8 | grep interface | awk '{print $2}')

interval=1
duration=5
iterations=$(awk "BEGIN {print int($duration / $interval)}")

total_cpu=0
total_netstat=0
total_iostat=0
total_ping=0

echo  "Completed cycle"

for i in $(seq 1 $iterations); do
    cpu_value=$(ps -A -o %cpu | awk '{sum+=$1} END {print sum}')
    netstat_value=$(netstat -tn | wc -l)
    iostat_value=$(iostat -n 1 | awk 'NR==3 {print $3}')
    ping_value=$(ping -c 1 8.8.8.8 | tail -1 | awk -F '/' '{print $5}')
    
    total_cpu=$(awk "BEGIN {print $total_cpu + $cpu_value}")
    total_netstat=$(awk "BEGIN {print $total_netstat + $netstat_value}")
    total_iostat=$(awk "BEGIN {print $total_iostat + $iostat_value}")
    total_ping=$(awk "BEGIN {print $total_ping + $ping_value}")
    
    sleep $interval
    echo "..." $i " of " $iterations
done

average_cpu=$(awk "BEGIN {print $total_cpu / $iterations}")
average_netstat=$(awk "BEGIN {print $total_netstat / $iterations}")
average_iostat=$(awk "BEGIN {print $total_iostat / $iterations}")
average_ping=$(awk "BEGIN {print $total_ping / $iterations}")

# Memory Utilization
used_mem=$(vm_stat | grep "Pages active" | awk '{print $3}')
free_mem=$(vm_stat | grep "Pages free" | awk '{print $3}')
inactive_mem=$(vm_stat | grep "Pages inactive" | awk '{print $3}')
memory_threshold=$(awk "BEGIN {print ($used_mem / ($free_mem + $used_mem + $inactive_mem)) * 100}")

# Disk Space
disk_usage=$(df -h / | grep / | awk '{print $5}' | sed 's/%//g')
disk_threshold=90

# Network Analysis (You can loop this for all network interfaces)
network_errors=$(netstat -i | grep -m 1 $primary_adapter | awk '{print $7}')
network_drops=$(netstat -i | grep -m 1 $primary_adapter | awk '{print $9}')

{
  echo "Top Output:"
  top -l 1 -n 0
  echo ""
  echo "Iostat Output:"
  iostat
  echo ""
  echo "Nettop Output:"
  nettop -P -L 1 -k time,interface,state,rx_dupe,rx_ooo,re-tx,bytes_in,bytes_out -t external
  echo ""
  echo "VM Stat Output:"
  vm_stat
  echo ""
  echo "Netstat Output:"
  netstat -i
  echo ""
  echo "Traceroute Output:"
  ping -c 1 8.8.8.8
  echo "Determining primary network adapter..."
  primary_adapter=$(route get default | grep "interface" | awk '{print $2}')
  echo "Primary network adapter: $primary_adapter"
  echo ""
  echo "Average CPU: $average_cpu%"
  echo "Average netstat: $average_netstat connections"
  echo "Average iostat: $average_iostat tps"
  echo "Average ping: $average_ping ms"
  echo "Memory Utilization:"
  echo "Used Memory: $used_mem pages"
  echo "Free Memory: $free_mem pages"
  echo "Inactive Memory: $inactive_mem pages"
  echo "Disk Usage: $disk_usage%"
  echo "Network Errors on $primary_adapter: $network_errors errors"
  echo "Network Drops on $primary_adapter: $network_drops drops"
} >> $OUTPUT_FILE

# Analyze the data
slow_ping_threshold=50
high_iostat_threshold=10
high_active_memory_percentage=80
high_wired_memory_percentage=80

echo "List of Identified Bottlenecks:"

if (( $(echo "$average_cpu > $high_cpu_threshold" | bc -l) )); then
    echo "- The average CPU usage is high. Possible CPU bottleneck."
fi

if (( $(echo "$average_ping > $slow_ping_threshold" | bc -l) )); then
    echo "- The average ping to 8.8.8.8 is slow. Possible network bottleneck."
fi

if (( $(echo "$average_iostat > $high_iostat_threshold" | bc -l) )); then
    echo "- The average IO is high. Possible disk bottleneck."
fi

if [[ "$primary_adapter" && $(echo "$average_netstat > 1000" | bc) -eq 1 ]]; then
    echo "- The primary network adapter ($primary_adapter) has a high number of connections. Possible network bottleneck."
fi

if (( $(echo "$average_cpu > $high_cpu_threshold" | bc -l) )); then
    analysis_output+="- The average CPU usage is high. Possible CPU bottleneck.\n"
fi

if (( $(echo "$average_ping > $slow_ping_threshold" | bc -l) )); then
    analysis_output+="- The average ping to 8.8.8.8 is slow. Possible network bottleneck.\n"
fi

if (( $(echo "$average_iostat > $high_iostat_threshold" | bc -l) )); then
    analysis_output+="- The average IO is high. Possible disk bottleneck.\n"
fi

if [[ "$primary_adapter" && $(echo "$average_netstat > 1000" | bc) -eq 1 ]]; then
    analysis_output+="- The primary network adapter ($primary_adapter) has a high number of connections. Possible network bottleneck.\n"
fi

if (( $(echo "$memory_threshold > 80" | bc -l) )); then
  analysis_output+="- High memory utilization. Memory usage is more than 80%.\n"
fi

if [[ "$disk_usage" -gt "$disk_threshold" ]]; then
  analysis_output+="- Disk space usage is more than 90%. Consider freeing up space.\n"
fi

if [[ "$network_drops" -gt 0 ]]; then
  analysis_output+="- Network interface en0 has packet drops. Consider investigating.\n"
fi

# Checking for memory bottlenecks
active_memory=$(vm_stat | grep -m 1 "Pages active" | awk '{print $3}' | tr -d '.')
total_memory=$(sysctl -n hw.memsize)
active_memory_percentage=$(awk "BEGIN {print ($active_memory * 4096) / $total_memory * 100}")

if (( $(echo "$active_memory_percentage > $high_active_memory_percentage" | bc -l) )); then
  analysis_output+="- High active memory usage. Possible memory bottleneck.\n"
fi

wired_memory=$(vm_stat | grep -m 1 "Pages wired down" | awk '{print $4}' | tr -d '.')
wired_memory_percentage=$(awk "BEGIN {print ($wired_memory * 4096) / $total_memory * 100}")

if (( $(echo "$wired_memory_percentage > $high_wired_memory_percentage" | bc -l) )); then
  analysis_output+="- High wired memory usage. Possible memory bottleneck.\n"
fi

# Network bottleneck analysis based on primary adapter
if [[ "$primary_adapter" ]]; then
  net_errors=$(netstat -i | grep -m 1 "$primary_adapter" | awk '{print $5+$7}')
  if (( "$net_errors" > 0 )); then
    analysis_output+="- The primary network adapter ($primary_adapter) has errors. Possible network bottleneck. NOTE: On its own this may not be an issue\n"
  fi
fi

# Print the analysis output to console
echo -e "$analysis_output" 

# Append the analysis output to the file
echo -e "\nList of Identified Bottlenecks:\n$analysis_output" >> $OUTPUT_FILE
