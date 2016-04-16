import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)

GPIO.setup(17, GPIO.OUT)
GPIO.setup(18, GPIO.OUT)
GPIO.setup(22, GPIO.OUT)
GPIO.setup(23, GPIO.OUT)

class MotorController(Protocol):
    def connectionMade(self):
        print "Connection established"
    
    def connectionLost(self, reason):
        print "Connection lost"



# Creation code
factory = Factory()
factory.protocol = MotorController
factory.clients = []

reactor.listenTCP(6666, factory)
reactor.run()
print "MotorController server started"


