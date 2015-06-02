# VisualServiceMonitor
A real-time visualization for monitoring Windows Services written in Powershell

-Functions by invoking get-service on a background job, which generates an event consumed by the console

-The monitor can handle any number of services up to the vertical buffer size of the screen

-Supports dynamic resizing triggered by adding or removing service

-Can be pointed at remote servers through command line arguments

Instructions:

-Run InvokeServiceMonitor with Powershell

Requires:

-PowerShell 4.0 or greater

![alt tag](http://i.imgur.com/KzwPFD2.gif)
