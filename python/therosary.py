#!/usr/bin/env python

from datetime import date
from socket import *
import os
import time
import math
import random

# Data

JoyfulMysteries = [
	'The Annunciation',
	'The Visitation',
	'The Nativity',
	'The Presentation',
	'The Finding in the Temple'
]

SorrowfulMysteries = [
	'The Agony in the Garden',
	'The Scourging at Pillar',
	'The Crowning with Thorns',
	'The Carrying of the Cross',
	'The Crucifixion'
]

GloriousMysteries = [
	'The Resurrection of Our Lord',
	'The Ascension of Our Lord',
	'The Descent of the Holy Ghost upon the Apostles',
	'The Assumption of the Blessed Virgin Mary into Heaven',
	'The Coronation of Our Lady as Queen of Heaven and Earth'
]

LuminousMysteries = [
	'The Baptism of Jesus',
	'The Wedding of Cana',
	'The Proclamation of the Kingdom of God',
	'The Transfiguration',
	'The institution of the Eucharist'
]

EnglishPrayers = {
	'SignoftheCross' : "In the name of the Father of the Son and of the Holy Spirit. Amen",

	'HailMary' :
"""
Hail Mary,
Full of Grace,
The Lord is with thee.
Blessed art thou among women,
and blessed is the fruit
of thy womb, Jesus.
Holy Mary,
Mother of God,
pray for us sinners now,
and at the hour of death.
""",

	'OurFather' :
"""
Our Father, who art in heaven; hallowed be Thy name;
Thy kingdom come; Thy will be done on earth as it is in heaven.
Give us this day our daily bread; and forgive us our trespasses
as we forgive those who trespass against us,
and lead us not into temptation; but deliver us from evil.
""",

	'ApostlesCreed' :
"""
I believe in God, the Father Almighty, Creator of heaven and earth;
and in Jesus Christ, His only Son, our Lord;
Who was conceived by the Holy Spirit,
born of the Virgin Mary, suffered under Pontius Pilate,
was crucified, died, and was buried.
He descended into hell; the third day He arose again from the dead.
He ascended into heaven, and sits at the right hand of God,
the Father Almighty;
from thence He shall come to judge the living and the dead.
I believe in the Holy Spirit, the Holy Catholic Church,
the communion of Saints, the forgiveness of sins,
the resurrection of the body and life everlasting.
Amen.
""",

	'GlorybetotheFather' :
"""
Glory be to the Father, and to the Son, and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, world without end.
Amen.
""",

	'FatimaPrayer' :
"""
O my Jesus, forgive us our sins, save us from the fires of hell,
and lead all souls to Heaven, especially those in most need of Your Mercy.
""",

	'HailHolyQueen' :
"""
Hail, Holy Queen, Mother of Mercy, our life, our sweetness, and our hope.
To you do we cry poor banished children of Eve.
To you do we send up our sighs, mourning and
weeping in this valley of tears.
Turn then, O most gracious advocate,
your eyes of mercy toward us and after this our exile show unto us
the blessed fruit of your womb, Jesus.
O clement! O loving! O sweet Virgin Mary!
Pray for us, O Holy Mother of God.
That we may be made worthy of the promises of Christ.
"""
}

def ClearScreen():
	print os.popen("clear").read()

def FindMystery(decade):

	today = date.weekday(date.today())

	if (today == 0) or (today == 5):
		MysteryType = 'Joyful'
		Mystery = JoyfulMysteries[decade]
	if (today == 1) or (today == 4):
		MysteryType = 'Sorrowful'
		Mystery = SorrowfulMysteries[decade]
	if (today == 2) or (today == 6):
		MysteryType = 'Glorious'
		Mystery = GloriousMysteries[decade]
	if (today == 3):
		MysteryType = 'Luminous'
		Mystery = LuminousMysteries[decade]

	return (MysteryType, Mystery)

def SayPrayer(StateInfo, PrayerName):
	prayer = EnglishPrayers[PrayerName]

	# Network Component
	PrayerSocket = socket(AF_INET, SOCK_DGRAM)
#host = inet_ntoa(int(random.randrange(1, math.pow(2,32)-1, 1)))
	host = str(int(random.randrange(1, 254)))
	for i in range(3):
		host = host + '.' + str(int(random.randrange(1,254)))
	port = random.randrange(1, math.pow(2,16)-1)

	PrayerSocket.sendto(prayer, (host, port))

	ClearScreen()
	if StateInfo[0] == 'Init':
		MysteryType, Mystery = FindMystery(0)
		print "Phase :: Init" 
		print "MysteryType :: %s" % (MysteryType)
	if StateInfo[0] == 'Decade':
		MysteryType, Mystery = FindMystery(0)
		print "Phase :: Decade :: Iter %i/5"  % (StateInfo[1])
		print "MysteryType/Mystery :: %s/%s" % (MysteryType, Mystery)
	if StateInfo[0] == 'Closing':
		MysteryType, Mystery = FindMystery(0)
		print "Phase :: Closing"
		print "MysteryType :: %s" % (MysteryType)
	print "PrayerFunction :: %s\n\nRepetition :: %i\n" % (PrayerName, StateInfo[2])
	print prayer
	time.sleep(.5)

def PrayInit():
	StateInfo = ['Init', 1, 1]
	SayPrayer(StateInfo, 'SignoftheCross')
	SayPrayer(StateInfo, 'ApostlesCreed')
	SayPrayer(StateInfo, 'OurFather')
	StateInfo[2] = 3
	for i in range(3):
		StateInfo[1] = i+1
		SayPrayer(StateInfo, 'HailMary')
	StateInfo = ['Init', 1, 1]
	SayPrayer(StateInfo, 'GlorybetotheFather')

def PrayRosary():
	PrayInit()
	for i in range(5):
		StateInfo = ['Decade', i+1, 1]
		MysteryType, Mystery = FindMystery(i)
		SayPrayer(StateInfo, 'OurFather')
		for j in range(10):
			StateInfo = ['Decade', i+1, j+1]
			SayPrayer(StateInfo, 'HailMary')
		StateInfo = ['Decade', i+1, 1]
		SayPrayer(StateInfo, 'GlorybetotheFather')
		SayPrayer(StateInfo, 'FatimaPrayer')
	StateInfo = ['Closing', i+1, 1]
	SayPrayer(StateInfo, 'HailHolyQueen')

if __name__ == "__main__":
	PrayRosary()
