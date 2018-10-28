#!/usr/bin/env python
"""
This health check scripts is used to find the URL for the created load
balancer in Amazon AWS, sends a http request to the pre-defined URL /now and
compares the returned time in HH:MM:SS format to the current server time
"""

from datetime import datetime
import requests
import boto3

CLIENT = boto3.client('elbv2')

def health_check():
    """
    Main health check function
    """

    load_balancer = CLIENT.describe_load_balancers(Names=['ecs-services'])
    load_balancer_dns_name = load_balancer['LoadBalancers'][0]['DNSName']
    # compose URL based on requirements and dns name
    url = 'http://%s/now' % (load_balancer_dns_name)
    # get URL response
    response = requests.get(url)
    if response.status_code != 200:
        print 'ERR: Wrong HTTP status code received!'
        print 'Expected [200] | Received: [%s]' % (response.status_code)
        return None
    response_text = response.text
    # UTC time with miliseconds
    ltm = datetime.utcnow()
    # removing the miliseconds from the local datetime object
    local_server_time = datetime(
        ltm.year,
        ltm.month,
        ltm.day,
        ltm.hour,
        ltm.minute,
        ltm.second
        ).time()
    # parse remote time
    remote_server_time = (datetime.strptime(response_text, "%H:%M:%S")).time()
    # perform check and return result
    if local_server_time != remote_server_time:
        print 'ERR: Expected time: [%s] | Received time [%s]' % (
            local_server_time,
            remote_server_time,
            )
        # define custom alert here
    else:
        print 'OK: Time sync correct!'
        print 'Expected time: [%s] | Received time [%s]' % (
            local_server_time,
            remote_server_time,
            )
    return None

if __name__ == "__main__":
    health_check()
