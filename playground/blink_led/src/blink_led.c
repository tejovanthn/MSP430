#include <msp430.h>
#include <signal.h>


#define     LED0                  BIT0
#define     LED1                  BIT6
#define     LED_DIR               P1DIR
#define     LED_OUT               P1OUT


void initLEDs(void) {
    LED_DIR |= LED0 + LED1;        //Set LED pins as outputs
    LED_OUT |= LED0 + LED1;        //Turn on both LEDs
}


int main(void) {

    WDTCTL = WDTPW + WDTHOLD;        // Stop WDT

    initLEDs();                //Setup LEDs

    BCSCTL3 |= LFXT1S_2;        //Set ACLK to use internal VLO (12 kHz clock)

    TACTL = TASSEL_1 | MC_1;        //Set TimerA to use auxiliary clock in UP mode
    TACCTL0 = CCIE;        //Enable the interrupt for TACCR0 match
    TACCR0 = 11999;        /*Set TACCR0 which also starts the timer. At
                             12 kHz, counting to 12000 should output
                             an LED change every 1 second. Try this
                             out and see how inaccurate the VLO can be */

    WRITE_SR(GIE);        //Enable global interrupts

    while(1) {
        //Loop forever, interrupts take care of the rest
    }
}

interrupt(TIMER0_A0_VECTOR) TIMER0_A0_ISR(void) {
    LED_OUT ^= (LED0 + LED1);        //Toggle both LEDs
}

