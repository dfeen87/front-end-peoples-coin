# Use an official Python runtime as a parent image
# Using 'slim-buster' or 'alpine' variants are generally good for smaller images
FROM python:3.9-slim-buster

# Set the working directory in the container to /app
WORKDIR /app

# Copy the requirements file into the container at /app
# This step is done separately to leverage Docker's layer caching
# If your requirements.txt rarely changes, this layer won't rebuild often
COPY requirements.txt ./

# Install any needed packages specified in requirements.txt
# --no-cache-dir reduces image size
RUN pip install --no-cache-dir -r requirements.txt

# Copy the rest of your backend application code into the container at /app
COPY . .

# Make port 8080 available to the world outside this container
# Cloud Run expects your application to listen on the port defined by the PORT environment variable (default 8080)
EXPOSE 8080

# Define the command to run your application
# This is the most crucial part for your backend to start correctly
# You will need to replace 'your_module_name:your_app_object' with your specific entry point
#
# Common examples:
# For a Flask app where your Flask app instance is named 'app' in 'main.py':
# CMD ["gunicorn", "--bind", "0.0.0.0:8080", "main:app"]
#
# For a FastAPI app where your FastAPI app instance is named 'app' in 'main.py':
# CMD ["uvicorn", "main:app", "--host", "0.0.0.0", "--port", "8080"]
#
# You will likely need to install gunicorn or uvicorn in your requirements.txt if using them.
CMD ["gunicorn", "--bind", "0.0.0.0:$PORT", "your_module_name:your_app_object"]
