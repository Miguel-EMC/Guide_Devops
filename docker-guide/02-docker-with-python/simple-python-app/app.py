# app.py
import time

print("Hello from inside the Docker container!")
print("This is a Python application.")

for i in range(5):
    print(f"Counting: {i+1}")
    time.sleep(1)

print("Python application finished.")
