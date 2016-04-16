from twisted.internet.protocol import Protocol, Factory
from twisted.internet import reactor

import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)

GPIO.setwarnings(False)

GPIO.setup(17, GPIO.OUT)
GPIO.setup(18, GPIO.OUT)
GPIO.setup(22, GPIO.OUT)
GPIO.setup(23, GPIO.OUT)



class MotorController(Protocol):
    def connectionMade(self):
        print "Connection established"
    
    def connectionLost(self, reason):
        print "Connection lost"


    def dataReceived(self, data):
        msg = ""
        
        if (data == 'FWD'):
            msg = "Move Forward"
            GPIO.output(18, True)
            GPIO.output(22, True)
    
        elif (data == 'FWDSTOP'):
            msg = "Move Forward STOP"
            GPIO.output(18, False)
            GPIO.output(22, False)
        
        elif (data == 'BKWD'):
            msg = "Move Backward"
            GPIO.output(17, True)
            GPIO.output(23, True)

        elif (data == 'BKWDSTOP'):
            msg = "Move Backward STOP"
            GPIO.output(17, False)
            GPIO.output(23, False)
        
        elif (data == 'RIGHT'):
            msg = "Right"
            GPIO.output(18, True)
        
        elif (data == 'RIGHTSTOP'):
            msg = "Right STOP"
            GPIO.output(18, False)
        
        elif (data == 'LEFT'):
            msg = "Left"
            GPIO.output(22, True)
        
        elif (data == 'LEFTSTOP'):
            msg = "Left STOP"
            GPIO.output(22, False)
        
        print msg



# Creation code
factory = Factory()
factory.protocol = MotorController
factory.clients = []

reactor.listenTCP(6666, factory)
print "MotorController server starting...\n"
reactor.run()



