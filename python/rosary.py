#!/usr/bin/env python
"""
rosary package
adapted by rjbs
from 'therosary.py' by adam
public domain
	because all computers should be able to pray
"""

from datetime import date
from socket import *
import os
import time
import random

# Data

mysteries = { 
	'joyful' : [
		'The Annunciation',
		'The Visitation',
		'The Nativity',
		'The Presentation',
		'The Finding in the Temple'
	],

	'sorrowful' : [
		'The Agony in the Garden',
		'The Scourging at Pillar',
		'The Crowning with Thorns',
		'The Carrying of the Cross',
		'The Crucifixion'
	],

	'glorious' : [
		'The Resurrection of Our Lord',
		'The Ascension of Our Lord',
		'The Descent of the Holy Ghost upon the Apostles',
		'The Assumption of the Blessed Virgin Mary into Heaven',
		'The Coronation of Our Lady as Queen of Heaven and Earth'
	],

	'luminous' : [
		'The Baptism of Jesus',
		'The Wedding of Cana',
		'The Proclamation of the Kingdom of God',
		'The Transfiguration',
		'The institution of the Eucharist'
	]
}

prayers = {
	'Sign of the Cross' :
"""
In the name of the Father, of the Son, and of the Holy Spirit.
Amen
""",

	'Hail Mary' :
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

	"Our Father" :
"""
Our Father, who art in heaven; hallowed be Thy name;
Thy kingdom come; Thy will be done on earth as it is in heaven.
Give us this day our daily bread; and forgive us our trespasses
as we forgive those who trespass against us,
and lead us not into temptation; but deliver us from evil.
""",

	"Apostle's Creed" :
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

	'Glory Be to the Father' :
"""
Glory be to the Father, and to the Son, and to the Holy Spirit.
As it was in the beginning, is now, and ever shall be, world without end.
Amen.
""",

	'Fatima Prayer' :
"""
O my Jesus, forgive us our sins, save us from the fires of hell,
and lead all souls to Heaven, especially those in most need of Your Mercy.
""",

	'Hail Holy Queen' :
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

def clear_screen():
	print os.popen("clear").read()

class Rosarist:

	def find_mysterytype(self):
		today = date.weekday(date.today())

		if (today in (0,5)): return 'joyful'
		if (today in (1,4)): return 'sorrowful'
		if (today in (2,6)): return 'glorious'
		if (today == 3):     return 'luminous'

	def find_mystery(self, decade):
		return mysteries[self.mysterytype][decade]

	def say_prayer(self, prayer_name, repetition=None):
		prayer = prayers[prayer_name]

		# Network Component
		prayer_socket = socket(AF_INET, SOCK_DGRAM)
		host = str(int(random.randrange(1, 254)))
		for i in range(3):
			host = host + '.' + str(int(random.randrange(1,254)))
		port = random.randrange(1, (2 ** 16)-1)

		prayer_socket.sendto(prayer, (host, port))

		clear_screen()

		print "Phase       : %s" % (self.phase)
		print "MysteryType : %s" % (self.mysterytype)
		if (self.mystery): print "Mystery     : %s" % (self.mystery)
		print "Prayer      : %s" % (prayer_name)
		if (repetition):   print "Repetition  : %i" % (repetition)
	
		print prayer
		time.sleep(.5)

	def begin_prayer(self):
		self.mysterytype = self.find_mysterytype()
		self.mystery = None
		self.say_prayer('Sign of the Cross')
		self.say_prayer("Apostle's Creed")
		self.say_prayer('Our Father')
		for repetition in range(3):
			self.say_prayer('Hail Mary', repetition)
		self.say_prayer('Glory Be to the Father')

	def pray_rosary(self):
		self.phase = 'Opening'
		self.begin_prayer()
		self.phase = 'Decade'
		for decade in range(5):
			self.mystery = self.find_mystery(decade)
			self.say_prayer('Our Father')
			for repetition in range(10):
				self.say_prayer('Hail Mary', repetition+1)
			self.say_prayer('Glory Be to the Father')
			self.say_prayer('Fatima Prayer')
		self.phase   = 'Closing'
		self.mystery = None
		self.say_prayer('Hail Holy Queen')

if __name__ == "__main__":
	rosarist = Rosarist()
	rosarist.pray_rosary()
