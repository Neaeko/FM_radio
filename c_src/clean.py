

#open file and get lines
file1 = open('audio_output.txt', 'r')
file2 = open('audio_trimmed.txt', 'w')

lines = file1.readlines()
count = 0
print("Starting trim")
for line in lines:
    file2.writelines(line.strip()[10:58])
    file2.writelines("\n")

print("Ending trim")
file1.close()
file2.close()
    
