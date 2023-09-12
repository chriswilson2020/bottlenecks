#!/bin/bash

# Set output file name
OUTPUT_FILE="system_performance_avg.txt"

# Set the number of iterations and interval
ITERATIONS=300
INTERVAL=0.1

# Initialize variables for summing metrics
CPU_USAGE_SUM=0
MEM_USAGE_SUM=0
DISK_READ_SUM=0
DISK_WRITE_SUM=0
NET_IN_SUM=0
NET_OUT_SUM=0

# Collect data over time
for ((i=1; i<=ITERATIONS; i++)); do
  TOP_OUTPUT=$(top -l 1 -n 0)
  IOSTAT_OUTPUT=$(iostat)
  NETSTAT_OUTPUT=$(netstat -i)

  CPU_USAGE=$(echo "$TOP_OUTPUT" | awk '/CPU usage:/ {print $3}')
  MEM_USAGE=$(echo "$TOP_OUTPUT" | awk '/PhysMem:/ {print $2}' | tr -d 'A-Za-z')
  DISK_READ=$(echo "$IOSTAT_OUTPUT" | awk 'NR==4 {print $4}')
  DISK_WRITE=$(echo "$IOSTAT_OUTPUT" | awk 'NR==4 {print $7}')
  NET_IN=$(echo "$NETSTAT_OUTPUT" | awk '/en0/ {print $7}')
  NET_OUT=$(echo "$NETSTAT_OUTPUT" | awk '/en0/ {print $10}')

  CPU_USAGE_SUM=$(echo "$CPU_USAGE_SUM + $CPU_USAGE" | bc)
  MEM_USAGE_SUM=$(echo "$MEM_USAGE_SUM + $MEM_USAGE" | bc)
  DISK_READ_SUM=$(echo "$DISK_READ_SUM + $DISK_READ" | bc)
  DISK_WRITE_SUM=$(echo "$DISK_WRITE_SUM + $DISK_WRITE" | bc)
  NET_IN_SUM=$(echo "$NET_IN_SUM + $NET_IN" | bc)
  NET_OUT_SUM=$(echo "$NET_OUT_SUM + $NET_OUT" | bc)

  sleep $INTERVAL
done

# Calculate average values
CPU_USAGE_AVG=$(echo "scale=2; $CPU_USAGE_SUM / $ITERATIONS" | bc)
MEM_USAGE_AVG=$(echo "scale=2; $MEM_USAGE_SUM / $ITERATIONS" | bc)
DISK_READ_AVG=$(echo "scale=2; $DISK_READ_SUM / $ITERATIONS" | bc)
DISK_WRITE_AVG=$(echo "scale=2; $DISK_WRITE_SUM / $ITERATIONS" | bc)
NET_IN_AVG=$(echo "scale=2; $NET_IN_SUM / $ITERATIONS" | bc)
NET_OUT_AVG=$(echo "scale=2; $NET_OUT_SUM / $ITERATIONS" | bc)

# Write the average values to the output file
echo "Average CPU Usage: $CPU_USAGE_AVG%" > $OUTPUT_FILE
echo "Average Memory Usage: $MEM_USAGE_AVG MB" >> $OUTPUT_FILE
echo "Average Disk Read: $DISK_READ_AVG KB/s" >> $OUTPUT_FILE
echo "Average Disk Write: $DISK_WRITE_AVG KB/s" >> $OUTPUT_FILE
echo "Average Network In: $NET_IN_AVG packets" >> $OUTPUT_FILE
echo "Average Network Out: $NET_OUT_AVG packets" >> $OUTPUT_FILE

# Print the output file location
echo "System performance averages saved to $OUTPUT_FILE"
