/**********************************************************************
                      ldr2freq.c
                  ================
                  Uwe Berger; 2018
               
Ausgabe einer Impuls-Signals, dessen Frequenz abhaengig von der 
Helligkeit ist, auf PB1 eines ATtiny45. Die Helligkeit wird mit 
einem Fotowiderstand (LDR) via ADC gemessen.

Fotowiderstand
--------------
-verschaltet als Spannungsteiler an ADC2
	Vcc --> 10kOhm --> ADC2-Input --> LDR --> GND



---------
Have fun!
 
**********************************************************************/

#ifndef F_CPU
#define F_CPU 1000000UL     			
#endif

#include <avr/io.h>
#include <util/delay.h>

// ein paar Defines fuer Ausgabe-Pin
#define OUT_DDR			DDRB
#define OUT_PORT		PORTB
#define OUT_PIN			(1<<PB1)
#define OUT_PIN_HIGH	OUT_PORT |=  OUT_PIN
#define OUT_PIN_LOW		OUT_PORT &= ~OUT_PIN
#define OUT_PIN_TOGGLE	OUT_PORT ^=  OUT_PIN

//*********************************************************************
uint8_t adc_read(void) {
	// ADC-Ergebnis linksbuendig
	ADMUX |= 1 << ADLAR;
	// ADC einschalten; ADC-Vorteiler auf 8
	ADCSRA |= (1<<ADPS0) | (1<<ADPS1);
	ADCSRA |= 1 << ADEN;
	// Dummy-Messung	
	ADCSRA |= 1 << ADSC;
	while (ADCSRA & (1 << ADSC));
	// eigentliche Messung
	ADCSRA |= 1 << ADSC;
	while (ADCSRA & (1 << ADSC));
	ADCSRA = 0;
	// Ergebnis in ADCH
	return ADCH;
}

//**********************************************************************
//**********************************************************************
//**********************************************************************
int main(void)
{
	uint8_t val = 0;

	// Ausgang konfigurieren
	OUT_DDR |= OUT_PIN;
	// eine Sekunde High auf Ausgang...
	// (die Schaltung soll an einem ESP8266-Modul GPIO 0 verwendet 
	// werden; beim Start muss dort H-Pegel anliegen...)
	OUT_PIN_HIGH;
	_delay_ms(1000);

	// CTC-Mode mit toggeln von OC0A/OC0B (Tiny45)
	TCCR0A |= (1<<COM0A0 | 1<<COM0B0 | 1<<WGM01);
	// Prescaler 8
	TCCR0B = 1<<CS01;

	// ADC konfigurieren
	ADMUX = (1<<ADLAR) | (1<<REFS0) | (1<<MUX1) | (1<<MUX0);
	ADCSRA = (1<<ADEN) | (1<<ADPS0) | (1<<ADPS1);
	// ADC2
	ADMUX = (1<<MUX1);

	// Endlos-Loop
	while(1) {
		val = adc_read();
		OCR0A = val;
		OCR0B = val;
		_delay_ms(50);
	}
}
