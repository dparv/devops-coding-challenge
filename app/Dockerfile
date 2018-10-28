# Use a minimalistic python image
FROM python:3.6-alpine

# Create our application directory
RUN mkdir /app

# Copy the application and python requirements
COPY app.py /app/app.py
COPY requirements.txt /app/requirements.txt

# Install the python requirements
RUN pip install -r /app/requirements.txt

# Go in the application directory
WORKDIR /app

EXPOSE 8080
# Start the time app service
CMD ["./app.py"]
