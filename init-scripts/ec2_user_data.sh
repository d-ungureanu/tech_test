#!/bin/bash

echo "<h1>Hello World from $(hostname -f)</h1>" > /var/www/html/index.html
systemctl reload httpd