#!/usr/bin/env python
"""
Simple Flask app to display current UTC time
"""
from datetime import datetime
from flask import Flask, redirect, url_for
TIMEAPP = Flask(__name__)

@TIMEAPP.route("/")
def index():
    """
    Root URL with redirect to /now
    """
    return redirect(url_for('now'))

@TIMEAPP.route("/now")
def now():
    """
    /now URL that returns UTC time in HH:MM:SS format
    """
    utc_now = datetime.utcnow()
    now_str = utc_now.strftime("%H:%M:%S")
    return now_str

if __name__ == "__main__":
    TIMEAPP.run(host="0.0.0.0", port=8080)
